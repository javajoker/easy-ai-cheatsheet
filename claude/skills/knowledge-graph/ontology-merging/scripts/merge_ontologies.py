#!/usr/bin/env python3
"""
merge_ontologies.py — Merge per-chunk ontology files into one canonical ontology.

Algorithm:
  1. Load all per-chunk ontology JSON files in --in-dir.
  2. Union-Find cluster entities by (type, normalized-name-or-alias).
  3. Assign canonical IDs ent_NNNNN; build a remap table.
  4. Apply the remap to relations, events, themes.
  5. Deduplicate relations by (subject, predicate, object).
  6. Deduplicate events by (normalized name, date).
  7. Deduplicate themes by normalized name.
  8. Write merged.json and an optional disambiguation report.

Decisions file format (for --apply-decisions):
  {
    "merge": [
      ["chunk_0001_ent_005", "chunk_0007_ent_012"],   # force-merge these into one entity
      ...
    ],
    "split": [
      ["chunk_0003_ent_002", "chunk_0005_ent_002"],   # forbid merging these two
      ...
    ]
  }
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

# Allow direct script execution alongside canonicalize.py
sys.path.insert(0, str(Path(__file__).parent))
from canonicalize import (  # type: ignore
    all_normalized_forms,
    normalize,
    ambiguous_match,
    confident_match,
)


# ---------- Union-Find ----------

class UnionFind:
    def __init__(self):
        self.parent: dict[str, str] = {}

    def add(self, x: str):
        self.parent.setdefault(x, x)

    def find(self, x: str) -> str:
        self.add(x)
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]   # path compression
            x = self.parent[x]
        return x

    def union(self, a: str, b: str):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            # keep lexicographically smaller as root for determinism
            if ra < rb:
                self.parent[rb] = ra
            else:
                self.parent[ra] = rb

    def groups(self) -> dict[str, list[str]]:
        out: dict[str, list[str]] = defaultdict(list)
        for x in list(self.parent.keys()):
            out[self.find(x)].append(x)
        return out


# ---------- loading ----------

def load_chunk_ontologies(in_dir: Path) -> list[dict]:
    files = sorted(in_dir.glob("chunk_*.json"))
    ontos: list[dict] = []
    for f in files:
        with open(f, "r", encoding="utf-8") as fp:
            data = json.load(fp)
        if "chunk_id" not in data:
            print(f"⚠ skipping {f}: no chunk_id (is this a merged file?)", file=sys.stderr)
            continue
        ontos.append(data)
    return ontos


# ---------- decisions ----------

@dataclass
class Decisions:
    force_merge: list[tuple[str, str]] = field(default_factory=list)
    forbid_merge: set[frozenset[str]] = field(default_factory=set)

    @classmethod
    def load(cls, path: Path | None) -> "Decisions":
        d = cls()
        if not path:
            return d
        with open(path, "r", encoding="utf-8") as fp:
            data = json.load(fp)
        for pair in data.get("merge", []):
            if len(pair) >= 2:
                d.force_merge.append((pair[0], pair[1]))
        for pair in data.get("split", []):
            if len(pair) >= 2:
                d.forbid_merge.add(frozenset((pair[0], pair[1])))
        return d


# ---------- clustering ----------

def cluster_entities(
    ontos: list[dict],
    decisions: Decisions,
) -> tuple[UnionFind, dict[str, dict]]:
    """
    Return (UnionFind over original entity IDs, original-ID → entity-record map).
    """
    uf = UnionFind()
    by_id: dict[str, dict] = {}

    # Index entities by (type, normalized-form) → list of original IDs
    by_form: dict[tuple[str, str], list[str]] = defaultdict(list)
    for onto in ontos:
        for e in onto["entities"]:
            eid = e["id"]
            by_id[eid] = {**e, "_chunk_id": onto["chunk_id"]}
            uf.add(eid)
            forms = all_normalized_forms(e.get("canonical_name", ""), e.get("aliases", []))
            for form in forms:
                by_form[(e["type"], form)].append(eid)

    # Confident automatic merges: same (type, form) → union
    for key, ids in by_form.items():
        if len(ids) < 2:
            continue
        first = ids[0]
        for other in ids[1:]:
            if frozenset((first, other)) in decisions.forbid_merge:
                continue
            uf.union(first, other)

    # Apply forced merges from decisions
    for a, b in decisions.force_merge:
        if a in by_id and b in by_id:
            uf.union(a, b)
        else:
            print(f"⚠ decisions.merge references unknown entity: {a} / {b}", file=sys.stderr)

    return uf, by_id


def find_ambiguous_clusters(by_id: dict[str, dict], uf: UnionFind, decisions: Decisions) -> list[dict]:
    """
    Pairs that are ambiguous (partial overlap) but NOT confidently merged
    and NOT forbidden — these are the disambiguation flags.
    """
    flags: list[dict] = []
    # only check across different UF roots
    ids = list(by_id.keys())
    seen_pairs: set[frozenset[str]] = set()
    # Index by type → list of (eid, forms, core)
    by_type: dict[str, list[str]] = defaultdict(list)
    for eid in ids:
        by_type[by_id[eid]["type"]].append(eid)

    for type_, group in by_type.items():
        # Compare pairwise — but cap the size to avoid quadratic blowup
        # In practice most types have <500 entities; we cap at 2000 with a warning.
        if len(group) > 2000:
            print(
                f"⚠ {type_}: {len(group)} entities; skipping ambiguity scan to keep merge fast. "
                f"Consider stricter extraction.",
                file=sys.stderr,
            )
            continue
        for i, a in enumerate(group):
            ea = by_id[a]
            for b in group[i + 1:]:
                eb = by_id[b]
                if uf.find(a) == uf.find(b):
                    continue
                pair = frozenset((a, b))
                if pair in seen_pairs or pair in decisions.forbid_merge:
                    continue
                seen_pairs.add(pair)
                if ambiguous_match(
                    ea.get("canonical_name", ""), ea.get("aliases", []),
                    eb.get("canonical_name", ""), eb.get("aliases", []),
                ):
                    flags.append({
                        "entity_a": {
                            "id": a, "chunk_id": ea["_chunk_id"], "type": type_,
                            "canonical_name": ea.get("canonical_name"),
                            "aliases": ea.get("aliases", []),
                            "description": ea.get("description", ""),
                        },
                        "entity_b": {
                            "id": b, "chunk_id": eb["_chunk_id"], "type": type_,
                            "canonical_name": eb.get("canonical_name"),
                            "aliases": eb.get("aliases", []),
                            "description": eb.get("description", ""),
                        },
                    })
    return flags


# ---------- building merged output ----------

def build_canonical_entities(
    ontos: list[dict],
    by_id: dict[str, dict],
    uf: UnionFind,
) -> tuple[list[dict], dict[str, str]]:
    """
    Return (merged_entities, remap from original ID -> canonical ID).
    """
    groups = uf.groups()
    # Deterministic ordering: sort group roots by their best canonical name
    def group_sort_key(root: str) -> tuple:
        members = groups[root]
        names = [by_id[m].get("canonical_name", "") for m in members]
        return (sorted(names)[0] if names else "", root)

    sorted_roots = sorted(groups.keys(), key=group_sort_key)
    remap: dict[str, str] = {}
    out: list[dict] = []
    for i, root in enumerate(sorted_roots, start=1):
        canonical_id = f"ent_{i:05d}"
        members = groups[root]
        for m in members:
            remap[m] = canonical_id

        # Pick the longest canonical_name as the primary
        members_data = [by_id[m] for m in members]
        primary = max(members_data, key=lambda e: len(e.get("canonical_name", "") or ""))
        # Aggregate aliases
        all_aliases: set[str] = set()
        for m in members_data:
            for a in m.get("aliases", []) or []:
                if a and a != primary["canonical_name"]:
                    all_aliases.add(a)
            # also fold other canonical_names of co-members in as aliases
            cn = m.get("canonical_name")
            if cn and cn != primary["canonical_name"]:
                all_aliases.add(cn)

        # Merge attributes: last-write-wins per key, with provenance tracked separately
        attrs: dict[str, Any] = {}
        for m in members_data:
            for k, v in (m.get("attributes") or {}).items():
                attrs[k] = v

        # Merge mentions (deduplicated by snippet)
        seen_mentions: set[str] = set()
        mentions: list[dict] = []
        for m in members_data:
            for mn in m.get("mentions", []) or []:
                snippet = mn.get("snippet", "")
                key = f"{m['_chunk_id']}::{snippet[:80]}"
                if key in seen_mentions:
                    continue
                seen_mentions.add(key)
                mentions.append({**mn, "chunk_id": m["_chunk_id"]})

        # Pick the most informative description (longest non-empty)
        descs = [m.get("description", "") for m in members_data if m.get("description")]
        description = max(descs, key=len) if descs else ""

        # Salience: max across mentions
        sals = [m.get("salience") for m in members_data if isinstance(m.get("salience"), (int, float))]
        salience = max(sals) if sals else None

        entity = {
            "id": canonical_id,
            "canonical_name": primary["canonical_name"],
            "type": primary["type"],
            "aliases": sorted(all_aliases),
            "description": description,
            "attributes": attrs,
            "salience": salience,
            "mentions": mentions,
            "provenance": {
                "source_entity_ids": sorted(members),
                "chunk_ids": sorted({by_id[m]["_chunk_id"] for m in members}),
            },
        }
        if salience is None:
            entity.pop("salience")
        out.append(entity)
    return out, remap


def build_canonical_relations(
    ontos: list[dict],
    entity_remap: dict[str, str],
) -> list[dict]:
    """Deduplicate by (subject, predicate, object). Accumulate chunk_ids and pick best context."""
    bucket: dict[tuple[str, str, str], dict] = {}
    for onto in ontos:
        for r in onto["relations"]:
            subj = entity_remap.get(r["subject"])
            obj = entity_remap.get(r["object"])
            if not subj or not obj:
                continue
            pred = r["predicate"]
            key = (subj, pred, obj)
            ctx = r.get("context", "") or ""
            conf = r.get("confidence")
            existing = bucket.get(key)
            if not existing:
                bucket[key] = {
                    "subject": subj,
                    "predicate": pred,
                    "object": obj,
                    "context": ctx,
                    "attributes": dict(r.get("attributes") or {}),
                    "confidence": conf if isinstance(conf, (int, float)) else None,
                    "chunk_ids": [onto["chunk_id"]],
                    "_best_context_len": len(ctx),
                }
            else:
                existing["chunk_ids"].append(onto["chunk_id"])
                # Keep highest-confidence non-empty context (or longest if confidence absent)
                better = False
                if conf is not None and existing["confidence"] is not None:
                    if conf > existing["confidence"]:
                        better = True
                elif len(ctx) > existing["_best_context_len"]:
                    better = True
                if better:
                    existing["context"] = ctx
                    existing["_best_context_len"] = len(ctx)
                    if conf is not None:
                        existing["confidence"] = max(existing["confidence"] or 0.0, conf)
                # merge attributes (last-write-wins on collisions)
                for k, v in (r.get("attributes") or {}).items():
                    existing["attributes"][k] = entity_remap.get(v, v) if isinstance(v, str) and v in entity_remap else v

    out = []
    for i, (key, rel) in enumerate(sorted(bucket.items()), start=1):
        rel.pop("_best_context_len", None)
        rel["chunk_ids"] = sorted(set(rel["chunk_ids"]))
        if rel["confidence"] is None:
            rel.pop("confidence")
        rel["id"] = f"rel_{i:05d}"
        # Move 'id' to front for readability
        out.append({"id": rel["id"], **{k: v for k, v in rel.items() if k != "id"}})
    return out


def build_canonical_events(
    ontos: list[dict],
    entity_remap: dict[str, str],
) -> tuple[list[dict], dict[str, str]]:
    """Deduplicate events by (normalized name, date). Return events and event_remap."""
    bucket: dict[tuple[str, str], dict] = {}
    event_remap: dict[str, str] = {}
    for onto in ontos:
        for ev in onto["events"]:
            name_norm = normalize(ev.get("name", ""))
            date = ev.get("date") or ""
            key = (name_norm, date)
            existing = bucket.get(key)
            participants = sorted({entity_remap[p] for p in (ev.get("participants") or []) if p in entity_remap})
            location = entity_remap.get(ev.get("location")) if ev.get("location") else None
            consequences = ev.get("consequences") or []  # remapped after pass 2
            if not existing:
                bucket[key] = {
                    "name": ev.get("name"),
                    "description": ev.get("description", ""),
                    "date": ev.get("date"),
                    "participants": participants,
                    "location": location,
                    "consequences_raw": list(consequences),
                    "context": ev.get("context", ""),
                    "chunk_ids": [onto["chunk_id"]],
                    "source_event_ids": [ev["id"]],
                }
            else:
                existing["participants"] = sorted(set(existing["participants"]) | set(participants))
                if not existing["location"] and location:
                    existing["location"] = location
                if len(ev.get("description", "")) > len(existing["description"]):
                    existing["description"] = ev["description"]
                if len(ev.get("context", "")) > len(existing["context"]):
                    existing["context"] = ev["context"]
                existing["chunk_ids"].append(onto["chunk_id"])
                existing["source_event_ids"].append(ev["id"])
                existing["consequences_raw"].extend(consequences)

    # Assign canonical IDs and build event_remap
    out: list[dict] = []
    for i, (key, ev) in enumerate(sorted(bucket.items()), start=1):
        canonical_id = f"evt_{i:05d}"
        for src in ev["source_event_ids"]:
            event_remap[src] = canonical_id
        ev["id"] = canonical_id
        ev["chunk_ids"] = sorted(set(ev["chunk_ids"]))
        out.append(ev)

    # Pass 2: remap consequences (event-to-event references) and clean up
    for ev in out:
        consequences = sorted({event_remap[c] for c in ev.pop("consequences_raw") if c in event_remap})
        ev["consequences"] = consequences
        # Remove source_event_ids from final output; keep as provenance instead
        ev["provenance"] = {"source_event_ids": sorted(set(ev.pop("source_event_ids")))}

    # Re-order keys for readability
    cleaned: list[dict] = []
    for ev in out:
        cleaned.append({
            "id": ev["id"],
            "name": ev["name"],
            "description": ev.get("description", ""),
            "date": ev.get("date"),
            "participants": ev.get("participants", []),
            "location": ev.get("location"),
            "consequences": ev.get("consequences", []),
            "context": ev.get("context", ""),
            "chunk_ids": ev["chunk_ids"],
            "provenance": ev["provenance"],
        })
    return cleaned, event_remap


def build_canonical_themes(
    ontos: list[dict],
    entity_remap: dict[str, str],
    event_remap: dict[str, str],
) -> list[dict]:
    """Deduplicate themes by normalized name."""
    bucket: dict[str, dict] = {}
    for onto in ontos:
        for t in onto["themes"]:
            name_norm = normalize(t.get("name", ""))
            related_entities = sorted({entity_remap[e] for e in (t.get("related_entities") or []) if e in entity_remap})
            related_events = sorted({event_remap[e] for e in (t.get("related_events") or []) if e in event_remap})
            existing = bucket.get(name_norm)
            if not existing:
                bucket[name_norm] = {
                    "name": t.get("name"),
                    "description": t.get("description", ""),
                    "related_entities": list(related_entities),
                    "related_events": list(related_events),
                    "chunk_ids": [onto["chunk_id"]],
                }
            else:
                if len(t.get("description", "")) > len(existing["description"]):
                    existing["description"] = t["description"]
                existing["related_entities"] = sorted(set(existing["related_entities"]) | set(related_entities))
                existing["related_events"] = sorted(set(existing["related_events"]) | set(related_events))
                existing["chunk_ids"].append(onto["chunk_id"])

    out = []
    for i, (_, t) in enumerate(sorted(bucket.items()), start=1):
        out.append({
            "id": f"thm_{i:05d}",
            "name": t["name"],
            "description": t.get("description", ""),
            "related_entities": t.get("related_entities", []),
            "related_events": t.get("related_events", []),
            "chunk_ids": sorted(set(t["chunk_ids"])),
        })
    return out


# ---------- main ----------

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--in-dir", type=Path, required=True, help="Directory of per-chunk ontology JSON files.")
    p.add_argument("--out", type=Path, required=True, help="Output path for merged ontology.")
    p.add_argument("--book-title", default="", help="Book title for the source block.")
    p.add_argument("--book-author", default="", help="Book author for the source block.")
    p.add_argument("--apply-decisions", type=Path, help="A disambiguation decisions JSON to apply.")
    p.add_argument("--emit-disambiguation-report", type=Path,
                   help="Write a report of ambiguous entity pairs to this path.")
    args = p.parse_args()

    if not args.in_dir.is_dir():
        p.error(f"--in-dir not a directory: {args.in_dir}")

    ontos = load_chunk_ontologies(args.in_dir)
    if not ontos:
        p.error(f"No chunk ontology files found in {args.in_dir}")

    decisions = Decisions.load(args.apply_decisions)
    uf, by_id = cluster_entities(ontos, decisions)
    entities, entity_remap = build_canonical_entities(ontos, by_id, uf)
    relations = build_canonical_relations(ontos, entity_remap)
    events, event_remap = build_canonical_events(ontos, entity_remap)
    themes = build_canonical_themes(ontos, entity_remap, event_remap)

    flags = find_ambiguous_clusters(by_id, uf, decisions) if args.emit_disambiguation_report or True else []

    merged = {
        "ontology_version": "1.0",
        "source": {
            "book_title": args.book_title,
            "book_author": args.book_author,
            "chunk_ids": sorted({o["chunk_id"] for o in ontos}),
            "total_chunks": len(ontos),
        },
        "entities": entities,
        "relations": relations,
        "events": events,
        "themes": themes,
        "merge_report": {
            "input_files": len(ontos),
            "raw_entities": len(by_id),
            "merged_entities": len(entities),
            "raw_relations": sum(len(o["relations"]) for o in ontos),
            "merged_relations": len(relations),
            "raw_events": sum(len(o["events"]) for o in ontos),
            "merged_events": len(events),
            "raw_themes": sum(len(o["themes"]) for o in ontos),
            "merged_themes": len(themes),
            "disambiguation_flags": len(flags),
        },
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    print(f"✓ Wrote merged ontology to {args.out}")
    for k, v in merged["merge_report"].items():
        print(f"  {k:24} {v}")

    if args.emit_disambiguation_report:
        with open(args.emit_disambiguation_report, "w", encoding="utf-8") as f:
            json.dump({"flags": flags}, f, ensure_ascii=False, indent=2)
        print(f"\n  ⓘ Disambiguation report → {args.emit_disambiguation_report} ({len(flags)} pairs)")
        if flags:
            print("    Review with an LLM and write a disambiguation_decisions.json, then rerun with --apply-decisions.")


if __name__ == "__main__":
    main()
