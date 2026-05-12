#!/usr/bin/env python3
"""
query_ontology.py — Retrieve relevant slices of a merged ontology for Q&A.

Modes:
  entity        — find an entity by name or id and return its neighborhood
  relationship  — find how two entities relate (direct + shortest path up to 4 hops)
  event         — find an event by name or id with participants/location resolved
  theme         — find a theme and its linked entities/events
  search        — fuzzy text search across names/aliases/descriptions
  summary       — global overview: top-N entities, counts by type, theme list

Output is always JSON on stdout (or to --out file).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict, deque
from pathlib import Path

# Reuse normalization from the merger
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "ontology-merging" / "scripts"))
try:
    from canonicalize import normalize  # type: ignore
except ImportError:
    # Fall back to a minimal local normalizer if the merger isn't on the path
    import unicodedata

    def normalize(s: str) -> str:
        if not s:
            return ""
        s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode("ascii").lower()
        s = re.sub(r"[^\w\s'-]", " ", s)
        return re.sub(r"\s+", " ", s).strip()


# ---------- index ----------

class OntologyIndex:
    def __init__(self, onto: dict):
        self.onto = onto
        self.entities: dict[str, dict] = {e["id"]: e for e in onto.get("entities", [])}
        self.events: dict[str, dict] = {ev["id"]: ev for ev in onto.get("events", [])}
        self.themes: dict[str, dict] = {t["id"]: t for t in onto.get("themes", [])}
        self.relations: list[dict] = onto.get("relations", [])

        # name lookup (entity)
        self.entity_by_norm: dict[str, list[str]] = defaultdict(list)
        for eid, e in self.entities.items():
            for n in [e.get("canonical_name", "")] + (e.get("aliases") or []):
                if n:
                    self.entity_by_norm[normalize(n)].append(eid)

        self.event_by_norm: dict[str, list[str]] = defaultdict(list)
        for evid, ev in self.events.items():
            n = normalize(ev.get("name", ""))
            if n:
                self.event_by_norm[n].append(evid)

        self.theme_by_norm: dict[str, list[str]] = defaultdict(list)
        for tid, t in self.themes.items():
            n = normalize(t.get("name", ""))
            if n:
                self.theme_by_norm[n].append(tid)

        # adjacency for relationship paths
        self.adj: dict[str, list[tuple[str, str, dict]]] = defaultdict(list)
        for r in self.relations:
            self.adj[r["subject"]].append((r["object"], r["predicate"], r))
            self.adj[r["object"]].append((r["subject"], f"~{r['predicate']}", r))   # reverse

    def find_entity(self, name: str | None, id_: str | None) -> dict | None:
        if id_:
            return self.entities.get(id_)
        if not name:
            return None
        norm = normalize(name)
        ids = self.entity_by_norm.get(norm)
        if ids:
            return self.entities[ids[0]]
        # fall back to substring match on normalized canonical names / aliases
        candidates: list[tuple[int, str]] = []
        for key, ids in self.entity_by_norm.items():
            if norm in key:
                # rank by how close the lengths are
                candidates.append((abs(len(key) - len(norm)), ids[0]))
        if candidates:
            candidates.sort()
            return self.entities[candidates[0][1]]
        return None

    def find_event(self, name: str | None, id_: str | None) -> dict | None:
        if id_:
            return self.events.get(id_)
        if not name:
            return None
        norm = normalize(name)
        ids = self.event_by_norm.get(norm)
        if ids:
            return self.events[ids[0]]
        for key, ids in self.event_by_norm.items():
            if norm in key:
                return self.events[ids[0]]
        return None

    def find_theme(self, name: str | None, id_: str | None) -> dict | None:
        if id_:
            return self.themes.get(id_)
        if not name:
            return None
        norm = normalize(name)
        ids = self.theme_by_norm.get(norm)
        if ids:
            return self.themes[ids[0]]
        for key, ids in self.theme_by_norm.items():
            if norm in key:
                return self.themes[ids[0]]
        return None


# ---------- modes ----------

def mode_entity(idx: OntologyIndex, name: str | None, id_: str | None) -> dict:
    e = idx.find_entity(name, id_)
    if not e:
        return {"error": f"entity not found: name={name!r} id={id_!r}"}

    eid = e["id"]
    out: list[dict] = []
    inc: list[dict] = []
    for r in idx.relations:
        if r["subject"] == eid:
            obj = idx.entities.get(r["object"])
            out.append({
                "predicate": r["predicate"],
                "object_id": r["object"],
                "object_name": obj["canonical_name"] if obj else r["object"],
                "context": r.get("context", ""),
                "confidence": r.get("confidence"),
                "chunk_ids": r.get("chunk_ids", []),
            })
        if r["object"] == eid:
            subj = idx.entities.get(r["subject"])
            inc.append({
                "predicate": r["predicate"],
                "subject_id": r["subject"],
                "subject_name": subj["canonical_name"] if subj else r["subject"],
                "context": r.get("context", ""),
                "confidence": r.get("confidence"),
                "chunk_ids": r.get("chunk_ids", []),
            })

    events_in = []
    for ev in idx.events.values():
        if eid in (ev.get("participants") or []) or ev.get("location") == eid:
            events_in.append({
                "id": ev["id"],
                "name": ev["name"],
                "date": ev.get("date"),
                "description": ev.get("description", ""),
                "context": ev.get("context", ""),
                "role": "location" if ev.get("location") == eid else "participant",
            })

    themes_in = []
    for t in idx.themes.values():
        if eid in (t.get("related_entities") or []):
            themes_in.append({"id": t["id"], "name": t["name"]})

    return {
        "entity": e,
        "relations_out": out,
        "relations_in": inc,
        "events": events_in,
        "themes": themes_in,
        "degree": len(out) + len(inc),
    }


def shortest_path(idx: OntologyIndex, src: str, dst: str, max_hops: int = 4) -> list[dict] | None:
    if src == dst:
        return []
    visited = {src}
    # BFS where each node stores its predecessor and the edge dict
    q = deque([(src, [])])
    while q:
        node, path = q.popleft()
        if len(path) >= max_hops:
            continue
        for nb, pred, rel in idx.adj.get(node, []):
            if nb in visited:
                continue
            new_path = path + [{
                "from": node,
                "to": nb,
                "predicate": pred,
                "context": rel.get("context", ""),
            }]
            if nb == dst:
                return new_path
            visited.add(nb)
            q.append((nb, new_path))
    return None


def mode_relationship(idx: OntologyIndex, a: str, b: str) -> dict:
    ea = idx.find_entity(a, None)
    eb = idx.find_entity(b, None)
    if not ea:
        return {"error": f"entity not found: {a!r}"}
    if not eb:
        return {"error": f"entity not found: {b!r}"}

    aid, bid = ea["id"], eb["id"]
    direct: list[dict] = []
    for r in idx.relations:
        if (r["subject"] == aid and r["object"] == bid) or (r["subject"] == bid and r["object"] == aid):
            direct.append({
                "subject": r["subject"],
                "predicate": r["predicate"],
                "object": r["object"],
                "context": r.get("context", ""),
                "confidence": r.get("confidence"),
                "chunk_ids": r.get("chunk_ids", []),
            })

    shared_events = []
    for ev in idx.events.values():
        parts = set(ev.get("participants") or [])
        if aid in parts and bid in parts:
            shared_events.append({
                "id": ev["id"], "name": ev["name"], "date": ev.get("date"),
                "description": ev.get("description", ""), "context": ev.get("context", ""),
            })

    shared_themes = []
    for t in idx.themes.values():
        re_set = set(t.get("related_entities") or [])
        if aid in re_set and bid in re_set:
            shared_themes.append({"id": t["id"], "name": t["name"]})

    out: dict = {
        "entity_a": {"id": aid, "name": ea["canonical_name"]},
        "entity_b": {"id": bid, "name": eb["canonical_name"]},
        "direct_relations": direct,
        "shared_events": shared_events,
        "shared_themes": shared_themes,
    }
    if not direct and not shared_events:
        path = shortest_path(idx, aid, bid, max_hops=4)
        out["shortest_path"] = path  # may be None
    return out


def mode_event(idx: OntologyIndex, name: str | None, id_: str | None) -> dict:
    ev = idx.find_event(name, id_)
    if not ev:
        return {"error": f"event not found: name={name!r} id={id_!r}"}
    out = {**ev}
    out["participants"] = [
        {"id": pid, "name": idx.entities[pid]["canonical_name"]}
        for pid in (ev.get("participants") or []) if pid in idx.entities
    ]
    if ev.get("location") and ev["location"] in idx.entities:
        loc = idx.entities[ev["location"]]
        out["location"] = {"id": loc["id"], "name": loc["canonical_name"]}
    return out


def mode_theme(idx: OntologyIndex, name: str | None, id_: str | None) -> dict:
    t = idx.find_theme(name, id_)
    if not t:
        return {"error": f"theme not found: name={name!r} id={id_!r}"}
    out = {**t}
    out["related_entities"] = [
        {"id": eid, "name": idx.entities[eid]["canonical_name"], "type": idx.entities[eid]["type"]}
        for eid in (t.get("related_entities") or []) if eid in idx.entities
    ]
    out["related_events"] = [
        {"id": evid, "name": idx.events[evid]["name"], "date": idx.events[evid].get("date")}
        for evid in (t.get("related_events") or []) if evid in idx.events
    ]
    return out


def mode_search(idx: OntologyIndex, query: str, limit: int = 25) -> dict:
    norm = normalize(query)
    if not norm:
        return {"error": "empty query"}
    hits: list[dict] = []

    for e in idx.entities.values():
        score = 0
        haystacks = [normalize(e.get("canonical_name", ""))]
        haystacks += [normalize(a) for a in (e.get("aliases") or [])]
        haystacks.append(normalize(e.get("description", "")))
        for h in haystacks:
            if not h:
                continue
            if h == norm:
                score = max(score, 100)
            elif h.startswith(norm):
                score = max(score, 60)
            elif norm in h:
                score = max(score, 30)
        if score:
            hits.append({"kind": "entity", "id": e["id"], "name": e["canonical_name"],
                         "type": e["type"], "score": score, "description": e.get("description", "")})

    for ev in idx.events.values():
        hay = " ".join([normalize(ev.get("name", "")), normalize(ev.get("description", ""))])
        if norm in hay:
            score = 80 if normalize(ev.get("name", "")) == norm else 30
            hits.append({"kind": "event", "id": ev["id"], "name": ev["name"],
                         "date": ev.get("date"), "score": score, "description": ev.get("description", "")})

    for t in idx.themes.values():
        hay = " ".join([normalize(t.get("name", "")), normalize(t.get("description", ""))])
        if norm in hay:
            score = 90 if normalize(t.get("name", "")) == norm else 40
            hits.append({"kind": "theme", "id": t["id"], "name": t["name"],
                         "score": score, "description": t.get("description", "")})

    hits.sort(key=lambda h: -h["score"])
    return {"query": query, "hits": hits[:limit], "total": len(hits)}


def mode_summary(idx: OntologyIndex, top_n: int = 25) -> dict:
    by_type: dict[str, int] = defaultdict(int)
    for e in idx.entities.values():
        by_type[e["type"]] += 1

    # degree from relations
    deg: dict[str, int] = defaultdict(int)
    for r in idx.relations:
        deg[r["subject"]] += 1
        deg[r["object"]] += 1

    top = sorted(idx.entities.values(), key=lambda e: (-deg[e["id"]], -(e.get("salience") or 0)))[:top_n]
    return {
        "source": idx.onto.get("source", {}),
        "counts": {
            "entities": len(idx.entities),
            "by_type": dict(by_type),
            "relations": len(idx.relations),
            "events": len(idx.events),
            "themes": len(idx.themes),
        },
        "top_entities_by_degree": [
            {"id": e["id"], "name": e["canonical_name"], "type": e["type"],
             "degree": deg[e["id"]], "salience": e.get("salience"),
             "description": e.get("description", "")}
            for e in top
        ],
        "themes": [{"id": t["id"], "name": t["name"], "description": t.get("description", "")}
                   for t in idx.themes.values()],
    }


# ---------- main ----------

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--ontology", type=Path, required=True)
    p.add_argument("--mode", required=True, choices=["entity", "relationship", "event", "theme", "search", "summary"])
    p.add_argument("--name")
    p.add_argument("--id", dest="id_")
    p.add_argument("--a")
    p.add_argument("--b")
    p.add_argument("--query")
    p.add_argument("--top-n", type=int, default=25)
    p.add_argument("--limit", type=int, default=25)
    p.add_argument("--out", type=Path, help="Write JSON to this path instead of stdout.")
    args = p.parse_args()

    if not args.ontology.exists():
        p.error(f"ontology not found: {args.ontology}")

    with open(args.ontology, "r", encoding="utf-8") as f:
        onto = json.load(f)
    idx = OntologyIndex(onto)

    if args.mode == "entity":
        if not (args.name or args.id_):
            p.error("--name or --id required for mode=entity")
        result = mode_entity(idx, args.name, args.id_)
    elif args.mode == "relationship":
        if not (args.a and args.b):
            p.error("--a and --b required for mode=relationship")
        result = mode_relationship(idx, args.a, args.b)
    elif args.mode == "event":
        if not (args.name or args.id_):
            p.error("--name or --id required for mode=event")
        result = mode_event(idx, args.name, args.id_)
    elif args.mode == "theme":
        if not (args.name or args.id_):
            p.error("--name or --id required for mode=theme")
        result = mode_theme(idx, args.name, args.id_)
    elif args.mode == "search":
        if not args.query:
            p.error("--query required for mode=search")
        result = mode_search(idx, args.query, limit=args.limit)
    elif args.mode == "summary":
        result = mode_summary(idx, top_n=args.top_n)
    else:
        p.error(f"unknown mode {args.mode}")

    text = json.dumps(result, ensure_ascii=False, indent=2)
    if args.out:
        args.out.write_text(text, encoding="utf-8")
        print(f"✓ wrote result to {args.out}")
    else:
        print(text)


if __name__ == "__main__":
    main()
