#!/usr/bin/env python3
"""
validate_ontology.py — Validate a per-chunk or merged ontology JSON file.

Catches the four most common failure modes that break the merge step:
  1. Schema violations (missing required fields, wrong types).
  2. Dangling references (relation.subject / relation.object / event.participants
     pointing at IDs that aren't declared).
  3. Duplicate IDs within one file.
  4. ID prefix mismatch with the declared chunk_id.

Exit codes:
  0 — valid
  1 — invalid (errors printed to stderr)
  2 — usage error

Usage:
  python validate_ontology.py path/to/chunk_0001.json
  python validate_ontology.py --merged path/to/merged.json
  python validate_ontology.py --dir path/to/per_chunk/   # validate every file
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ENTITY_TYPES = {"Person", "Place", "Organization", "Object", "Concept", "Work", "Other"}
SCHEMA_VERSION = "1.0"


def fail(errors: list[str], path: Path) -> bool:
    if errors:
        print(f"✗ {path}", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return False
    return True


def validate_file(path: Path, merged: bool = False) -> bool:
    errors: list[str] = []

    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        return fail([f"invalid JSON: {e}"], path)
    except OSError as e:
        return fail([f"cannot read file: {e}"], path)

    if not isinstance(data, dict):
        return fail(["top level must be a JSON object"], path)

    # version
    if data.get("ontology_version") != SCHEMA_VERSION:
        errors.append(f"ontology_version must be {SCHEMA_VERSION!r}, got {data.get('ontology_version')!r}")

    # chunk_id XOR source
    has_chunk_id = "chunk_id" in data
    has_source = "source" in data
    if merged:
        if not has_source:
            errors.append("merged file must contain 'source' object")
        if has_chunk_id:
            errors.append("merged file must not contain 'chunk_id'")
    else:
        if not has_chunk_id:
            errors.append("per-chunk file must contain 'chunk_id'")
        if has_source:
            errors.append("per-chunk file must not contain 'source'")

    chunk_id = data.get("chunk_id")
    if chunk_id and not isinstance(chunk_id, str):
        errors.append("chunk_id must be a string")

    # required arrays
    for key in ("entities", "relations", "events", "themes"):
        if key not in data:
            errors.append(f"missing required array: {key!r}")
        elif not isinstance(data[key], list):
            errors.append(f"{key!r} must be an array")

    if errors:
        return fail(errors, path)

    entities = data["entities"]
    relations = data["relations"]
    events = data["events"]
    themes = data["themes"]

    # collect IDs, check duplicates and prefixes
    seen_ids: set[str] = set()
    entity_ids: set[str] = set()
    event_ids: set[str] = set()

    def check_id(item: dict, kind: str, expected_infix: str):
        iid = item.get("id")
        if not isinstance(iid, str) or not iid:
            errors.append(f"{kind}: missing or non-string 'id': {item!r:.120}")
            return None
        if iid in seen_ids:
            errors.append(f"{kind}: duplicate id {iid!r}")
            return None
        seen_ids.add(iid)
        if chunk_id and not merged:
            expected_prefix = f"{chunk_id}_{expected_infix}_"
            if not iid.startswith(expected_prefix):
                errors.append(f"{kind} id {iid!r} should start with {expected_prefix!r}")
        return iid

    # entities
    for e in entities:
        eid = check_id(e, "entity", "ent")
        if eid:
            entity_ids.add(eid)
        if e.get("type") not in ENTITY_TYPES:
            errors.append(f"entity {e.get('id')!r}: type must be one of {sorted(ENTITY_TYPES)}, got {e.get('type')!r}")
        if not isinstance(e.get("canonical_name"), str) or not e["canonical_name"].strip():
            errors.append(f"entity {e.get('id')!r}: canonical_name missing or empty")
        sal = e.get("salience")
        if sal is not None and not (isinstance(sal, (int, float)) and 0.0 <= sal <= 1.0):
            errors.append(f"entity {e.get('id')!r}: salience must be float in [0,1], got {sal!r}")

    # events (before relations because relations may reference event ids indirectly... actually no, relations don't reference events. But check events here.)
    for ev in events:
        evid = check_id(ev, "event", "evt")
        if evid:
            event_ids.add(evid)
        if not isinstance(ev.get("name"), str) or not ev["name"].strip():
            errors.append(f"event {ev.get('id')!r}: name missing or empty")
        participants = ev.get("participants") or []
        if not isinstance(participants, list):
            errors.append(f"event {ev.get('id')!r}: participants must be an array")
        else:
            for pid in participants:
                if pid not in entity_ids:
                    errors.append(f"event {ev.get('id')!r}: participant {pid!r} not declared as entity")
        loc = ev.get("location")
        if loc is not None and loc not in entity_ids:
            errors.append(f"event {ev.get('id')!r}: location {loc!r} not declared as entity")

    # relations
    for r in relations:
        rid = check_id(r, "relation", "rel")
        subj = r.get("subject")
        obj = r.get("object")
        pred = r.get("predicate")
        if not isinstance(pred, str) or not pred.strip():
            errors.append(f"relation {rid!r}: predicate missing or empty")
        elif " " in pred or pred != pred.lower():
            errors.append(f"relation {rid!r}: predicate {pred!r} should be snake_case lowercase")
        if subj not in entity_ids:
            errors.append(f"relation {rid!r}: subject {subj!r} not declared as entity")
        if obj not in entity_ids:
            errors.append(f"relation {rid!r}: object {obj!r} not declared as entity")
        conf = r.get("confidence")
        if conf is not None and not (isinstance(conf, (int, float)) and 0.0 <= conf <= 1.0):
            errors.append(f"relation {rid!r}: confidence must be float in [0,1], got {conf!r}")

    # themes
    for t in themes:
        tid = check_id(t, "theme", "thm")
        if not isinstance(t.get("name"), str) or not t["name"].strip():
            errors.append(f"theme {tid!r}: name missing or empty")
        for ent_id in t.get("related_entities") or []:
            if ent_id not in entity_ids:
                errors.append(f"theme {tid!r}: related entity {ent_id!r} not declared")
        for ev_id in t.get("related_events") or []:
            if ev_id not in event_ids:
                errors.append(f"theme {tid!r}: related event {ev_id!r} not declared")

    return fail(errors, path)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("path", nargs="?", help="Path to an ontology JSON file.")
    p.add_argument("--merged", action="store_true", help="Treat as a merged ontology (has 'source' instead of 'chunk_id').")
    p.add_argument("--dir", type=Path, help="Validate every *.json file in this directory.")
    args = p.parse_args()

    if args.dir:
        files = sorted(args.dir.glob("*.json"))
        if not files:
            print(f"no JSON files in {args.dir}", file=sys.stderr)
            sys.exit(2)
        ok = 0
        for f in files:
            if validate_file(f, merged=args.merged):
                ok += 1
        print(f"\n{ok}/{len(files)} files valid.")
        sys.exit(0 if ok == len(files) else 1)

    if not args.path:
        p.error("provide a file path or --dir")
    path = Path(args.path)
    if not path.exists():
        print(f"file not found: {path}", file=sys.stderr)
        sys.exit(2)

    ok = validate_file(path, merged=args.merged)
    if ok:
        print(f"✓ {path}")
        sys.exit(0)
    sys.exit(1)


if __name__ == "__main__":
    main()
