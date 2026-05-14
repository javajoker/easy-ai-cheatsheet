#!/usr/bin/env python3
"""
export_ontology.py — Export a merged ontology JSON to multiple formats.

Supported formats:
  - json    : canonical re-export, pretty-printed, key-sorted
  - jsonld  : JSON-LD with schema.org / custom vocabulary
  - ttl     : RDF Turtle
  - graphml : GraphML for Gephi/Cytoscape/yEd
  - md      : human-readable Markdown summary

Usage:
  python export_ontology.py \
      --in ontology/merged.json \
      --out-dir exports/ \
      --formats json,jsonld,ttl,graphml,md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any
from xml.sax.saxutils import escape as xml_escape


SCHEMA_VERSION = "1.0"


# ---------- helpers ----------

def load_ontology(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if data.get("ontology_version") != SCHEMA_VERSION:
        print(f"⚠ ontology_version {data.get('ontology_version')!r} != expected {SCHEMA_VERSION!r}", file=sys.stderr)
    return data


def _safe_iri(s: str) -> str:
    """Make a string safe to embed in an IRI fragment."""
    return re.sub(r"[^A-Za-z0-9_\-.]", "_", s)


def _ttl_literal(s: str) -> str:
    """Escape a string for use as a Turtle literal."""
    if s is None:
        return '""'
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
    return f'"{s}"'


# ---------- JSON (canonical re-export) ----------

def export_json(onto: dict, out_path: Path, lean: bool) -> None:
    out = json.loads(json.dumps(onto))  # deep copy
    if lean:
        for e in out.get("entities", []):
            e.pop("mentions", None)
            e.pop("provenance", None)
        for r in out.get("relations", []):
            r.pop("chunk_ids", None)
        for ev in out.get("events", []):
            ev.pop("chunk_ids", None)
            ev.pop("provenance", None)
        for t in out.get("themes", []):
            t.pop("chunk_ids", None)
        out.pop("merge_report", None)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2, sort_keys=True)


# ---------- JSON-LD ----------

JSONLD_CONTEXT = {
    "@vocab": "https://example.org/book/vocab#",
    "schema": "https://schema.org/",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "name": "schema:name",
    "description": "schema:description",
    "alternateName": "schema:alternateName",
    "Person": "schema:Person",
    "Place": "schema:Place",
    "Organization": "schema:Organization",
    "Work": "schema:CreativeWork",
    "Event": "schema:Event",
    "Concept": "schema:DefinedTerm",
    "Object": "schema:Product",
    "Other": "schema:Thing",
    "participants": {"@type": "@id"},
    "location": {"@type": "@id"},
    "relatedEntities": {"@id": "schema:about", "@type": "@id"},
    "relatedEvents": {"@id": "schema:about", "@type": "@id"},
}


def export_jsonld(onto: dict, out_path: Path, base_iri: str) -> None:
    base = base_iri.rstrip("/") + "/"
    nodes: list[dict] = []

    # entities
    for e in onto.get("entities", []):
        node = {
            "@id": f"{base}{e['id']}",
            "@type": e["type"],
            "name": e["canonical_name"],
        }
        if e.get("description"):
            node["description"] = e["description"]
        if e.get("aliases"):
            node["alternateName"] = e["aliases"]
        if e.get("attributes"):
            for k, v in e["attributes"].items():
                node[k] = v
        nodes.append(node)

    # events
    for ev in onto.get("events", []):
        node = {
            "@id": f"{base}{ev['id']}",
            "@type": "Event",
            "name": ev["name"],
        }
        if ev.get("description"):
            node["description"] = ev["description"]
        if ev.get("date"):
            node["startDate"] = ev["date"]
        if ev.get("participants"):
            node["participants"] = [f"{base}{p}" for p in ev["participants"]]
        if ev.get("location"):
            node["location"] = f"{base}{ev['location']}"
        nodes.append(node)

    # themes
    for t in onto.get("themes", []):
        node = {
            "@id": f"{base}{t['id']}",
            "@type": "schema:DefinedTerm",
            "name": t["name"],
        }
        if t.get("description"):
            node["description"] = t["description"]
        if t.get("related_entities"):
            node["relatedEntities"] = [f"{base}{x}" for x in t["related_entities"]]
        if t.get("related_events"):
            node["relatedEvents"] = [f"{base}{x}" for x in t["related_events"]]
        nodes.append(node)

    # relations as separate nodes (RDF-style — could also fold into subject)
    for r in onto.get("relations", []):
        # represent inline on the subject for cleaner output
        subj_iri = f"{base}{r['subject']}"
        obj_iri = f"{base}{r['object']}"
        # find subject node and tack on
        for n in nodes:
            if n["@id"] == subj_iri:
                pred = r["predicate"]
                # tuck under "@vocab:predicate"
                if pred not in n:
                    n[pred] = {"@id": obj_iri}
                elif isinstance(n[pred], list):
                    n[pred].append({"@id": obj_iri})
                else:
                    n[pred] = [n[pred], {"@id": obj_iri}]
                break

    doc = {
        "@context": JSONLD_CONTEXT,
        "@graph": nodes,
    }
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)


# ---------- Turtle / RDF ----------

TTL_TYPE_MAP = {
    "Person": "schema:Person",
    "Place": "schema:Place",
    "Organization": "schema:Organization",
    "Work": "schema:CreativeWork",
    "Concept": "schema:DefinedTerm",
    "Object": "schema:Product",
    "Other": "schema:Thing",
}


def export_ttl(onto: dict, out_path: Path, base_iri: str) -> None:
    base = base_iri.rstrip("/") + "/"
    lines: list[str] = []
    lines.append("@prefix schema: <https://schema.org/> .")
    lines.append("@prefix rdfs:   <http://www.w3.org/2000/01/rdf-schema#> .")
    lines.append("@prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .")
    lines.append("@prefix book:   <https://example.org/book/vocab#> .")
    lines.append(f"@prefix ex:     <{base}> .")
    lines.append("")

    # entities
    for e in onto.get("entities", []):
        subj = f"ex:{e['id']}"
        type_ = TTL_TYPE_MAP.get(e["type"], "schema:Thing")
        lines.append(f"{subj} a {type_} ;")
        lines.append(f"    schema:name {_ttl_literal(e['canonical_name'])} ;")
        if e.get("description"):
            lines.append(f"    schema:description {_ttl_literal(e['description'])} ;")
        for a in e.get("aliases", []) or []:
            lines.append(f"    schema:alternateName {_ttl_literal(a)} ;")
        # close
        if lines[-1].endswith(" ;"):
            lines[-1] = lines[-1][:-2] + " ."
        lines.append("")

    # events
    for ev in onto.get("events", []):
        subj = f"ex:{ev['id']}"
        lines.append(f"{subj} a schema:Event ;")
        lines.append(f"    schema:name {_ttl_literal(ev['name'])} ;")
        if ev.get("description"):
            lines.append(f"    schema:description {_ttl_literal(ev['description'])} ;")
        if ev.get("date"):
            lines.append(f"    schema:startDate {_ttl_literal(ev['date'])} ;")
        if ev.get("location"):
            lines.append(f"    schema:location ex:{ev['location']} ;")
        for p in ev.get("participants", []) or []:
            lines.append(f"    book:participant ex:{p} ;")
        if lines[-1].endswith(" ;"):
            lines[-1] = lines[-1][:-2] + " ."
        lines.append("")

    # themes
    for t in onto.get("themes", []):
        subj = f"ex:{t['id']}"
        lines.append(f"{subj} a schema:DefinedTerm ;")
        lines.append(f"    schema:name {_ttl_literal(t['name'])} ;")
        if t.get("description"):
            lines.append(f"    schema:description {_ttl_literal(t['description'])} ;")
        for x in t.get("related_entities", []) or []:
            lines.append(f"    schema:about ex:{x} ;")
        for x in t.get("related_events", []) or []:
            lines.append(f"    schema:about ex:{x} ;")
        if lines[-1].endswith(" ;"):
            lines[-1] = lines[-1][:-2] + " ."
        lines.append("")

    # relations
    for r in onto.get("relations", []):
        subj = f"ex:{r['subject']}"
        pred = f"book:{r['predicate']}"
        obj = f"ex:{r['object']}"
        lines.append(f"{subj} {pred} {obj} .")
    lines.append("")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


# ---------- GraphML ----------

GRAPHML_KEYS = [
    ("nlabel",   "node",  "label",       "string"),
    ("ntype",    "node",  "type",        "string"),
    ("ndesc",    "node",  "description", "string"),
    ("nsal",     "node",  "salience",    "double"),
    ("naliases", "node",  "aliases",     "string"),
    ("elabel",   "edge",  "predicate",   "string"),
    ("econf",    "edge",  "confidence",  "double"),
    ("eclass",   "edge",  "kind",        "string"),
]


def export_graphml(onto: dict, out_path: Path) -> None:
    lines: list[str] = []
    lines.append('<?xml version="1.0" encoding="UTF-8"?>')
    lines.append('<graphml xmlns="http://graphml.graphdrawing.org/xmlns"')
    lines.append('         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"')
    lines.append('         xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns')
    lines.append('             http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">')
    for kid, ktype, name, typ in GRAPHML_KEYS:
        lines.append(f'  <key id="{kid}" for="{ktype}" attr.name="{name}" attr.type="{typ}"/>')
    lines.append('  <graph id="G" edgedefault="directed">')

    # entity nodes
    for e in onto.get("entities", []):
        nid = e["id"]
        lines.append(f'    <node id="{nid}">')
        lines.append(f'      <data key="nlabel">{xml_escape(e["canonical_name"])}</data>')
        lines.append(f'      <data key="ntype">{xml_escape(e["type"])}</data>')
        if e.get("description"):
            lines.append(f'      <data key="ndesc">{xml_escape(e["description"])}</data>')
        sal = e.get("salience")
        if isinstance(sal, (int, float)):
            lines.append(f'      <data key="nsal">{sal}</data>')
        if e.get("aliases"):
            lines.append(f'      <data key="naliases">{xml_escape("; ".join(e["aliases"]))}</data>')
        lines.append('    </node>')

    # event nodes
    for ev in onto.get("events", []):
        nid = ev["id"]
        lines.append(f'    <node id="{nid}">')
        lines.append(f'      <data key="nlabel">{xml_escape(ev["name"])}</data>')
        lines.append(f'      <data key="ntype">Event</data>')
        if ev.get("description"):
            lines.append(f'      <data key="ndesc">{xml_escape(ev["description"])}</data>')
        lines.append('    </node>')

    # theme nodes (optional — keep them for community-detection)
    for t in onto.get("themes", []):
        nid = t["id"]
        lines.append(f'    <node id="{nid}">')
        lines.append(f'      <data key="nlabel">{xml_escape(t["name"])}</data>')
        lines.append(f'      <data key="ntype">Theme</data>')
        if t.get("description"):
            lines.append(f'      <data key="ndesc">{xml_escape(t["description"])}</data>')
        lines.append('    </node>')

    # relation edges
    eid_counter = 0
    for r in onto.get("relations", []):
        eid_counter += 1
        lines.append(f'    <edge id="e{eid_counter}" source="{r["subject"]}" target="{r["object"]}">')
        lines.append(f'      <data key="elabel">{xml_escape(r["predicate"])}</data>')
        lines.append(f'      <data key="eclass">relation</data>')
        if isinstance(r.get("confidence"), (int, float)):
            lines.append(f'      <data key="econf">{r["confidence"]}</data>')
        lines.append('    </edge>')

    # event-participant edges
    for ev in onto.get("events", []):
        for p in ev.get("participants", []) or []:
            eid_counter += 1
            lines.append(f'    <edge id="e{eid_counter}" source="{p}" target="{ev["id"]}">')
            lines.append('      <data key="elabel">participated_in</data>')
            lines.append('      <data key="eclass">participation</data>')
            lines.append('    </edge>')
        if ev.get("location"):
            eid_counter += 1
            lines.append(f'    <edge id="e{eid_counter}" source="{ev["id"]}" target="{ev["location"]}">')
            lines.append('      <data key="elabel">located_at</data>')
            lines.append('      <data key="eclass">location</data>')
            lines.append('    </edge>')

    # theme-membership edges
    for t in onto.get("themes", []):
        for x in t.get("related_entities", []) or []:
            eid_counter += 1
            lines.append(f'    <edge id="e{eid_counter}" source="{t["id"]}" target="{x}">')
            lines.append('      <data key="elabel">theme_includes</data>')
            lines.append('      <data key="eclass">theme</data>')
            lines.append('    </edge>')
        for x in t.get("related_events", []) or []:
            eid_counter += 1
            lines.append(f'    <edge id="e{eid_counter}" source="{t["id"]}" target="{x}">')
            lines.append('      <data key="elabel">theme_includes</data>')
            lines.append('      <data key="eclass">theme</data>')
            lines.append('    </edge>')

    lines.append('  </graph>')
    lines.append('</graphml>')

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


# ---------- Markdown ----------

def export_md(onto: dict, out_path: Path, top_n: int) -> None:
    src = onto.get("source", {})
    title = src.get("book_title") or "(untitled)"
    author = src.get("book_author") or "(unknown)"
    entities = onto.get("entities", [])
    relations = onto.get("relations", [])
    events = onto.get("events", [])
    themes = onto.get("themes", [])

    # group entities by type
    by_type: dict[str, list[dict]] = {}
    for e in entities:
        by_type.setdefault(e["type"], []).append(e)

    def by_salience_desc(es: list[dict]) -> list[dict]:
        return sorted(es, key=lambda e: -(e.get("salience") or 0))

    lines: list[str] = []
    lines.append(f"# Ontology of *{title}*")
    lines.append("")
    lines.append(f"**Author:** {author}  ")
    lines.append(f"**Entities:** {len(entities)}  ")
    lines.append(f"**Relations:** {len(relations)}  ")
    lines.append(f"**Events:** {len(events)}  ")
    lines.append(f"**Themes:** {len(themes)}  ")
    lines.append(f"**Source chunks:** {src.get('total_chunks', '?')}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # principal characters
    people = by_salience_desc(by_type.get("Person", []))
    if people:
        lines.append("## Principal characters")
        lines.append("")
        for e in people[:top_n]:
            aliases = e.get("aliases") or []
            alias_str = f" *({', '.join(aliases)})*" if aliases else ""
            desc = e.get("description") or ""
            lines.append(f"- **{e['canonical_name']}**{alias_str} — {desc}")
        lines.append("")

    # places
    places = by_salience_desc(by_type.get("Place", []))
    if places:
        lines.append("## Places")
        lines.append("")
        for e in places[:top_n]:
            desc = e.get("description") or ""
            lines.append(f"- **{e['canonical_name']}** — {desc}")
        lines.append("")

    # organizations
    orgs = by_salience_desc(by_type.get("Organization", []))
    if orgs:
        lines.append("## Organizations")
        lines.append("")
        for e in orgs[:top_n]:
            desc = e.get("description") or ""
            lines.append(f"- **{e['canonical_name']}** — {desc}")
        lines.append("")

    # objects / concepts / works
    for category, label in [("Object", "Notable objects"), ("Concept", "Concepts"), ("Work", "Works referenced")]:
        items = by_salience_desc(by_type.get(category, []))
        if items:
            lines.append(f"## {label}")
            lines.append("")
            for e in items[:top_n]:
                desc = e.get("description") or ""
                lines.append(f"- **{e['canonical_name']}** — {desc}")
            lines.append("")

    # events
    if events:
        lines.append("## Events")
        lines.append("")
        # sort by date when available, otherwise by name
        def ev_sort_key(ev):
            d = ev.get("date") or ""
            return (d == "", d, ev.get("name", ""))
        for ev in sorted(events, key=ev_sort_key):
            date_str = f" *({ev['date']})*" if ev.get("date") else ""
            desc = ev.get("description") or ""
            lines.append(f"- **{ev['name']}**{date_str} — {desc}")
        lines.append("")

    # themes
    if themes:
        lines.append("## Themes")
        lines.append("")
        # entity name lookup
        ename = {e["id"]: e["canonical_name"] for e in entities}
        evname = {ev["id"]: ev["name"] for ev in events}
        for t in themes:
            lines.append(f"### {t['name']}")
            lines.append("")
            if t.get("description"):
                lines.append(t["description"])
                lines.append("")
            re_ids = t.get("related_entities") or []
            rv_ids = t.get("related_events") or []
            if re_ids:
                names = [ename.get(x, x) for x in re_ids]
                lines.append(f"_Entities:_ {', '.join(names)}")
            if rv_ids:
                names = [evname.get(x, x) for x in rv_ids]
                lines.append(f"_Events:_ {', '.join(names)}")
            lines.append("")

    # relationship index
    if relations:
        lines.append("## Relationship index")
        lines.append("")
        ename = {e["id"]: e["canonical_name"] for e in entities}
        lines.append("| Subject | Predicate | Object |")
        lines.append("|---|---|---|")
        for r in sorted(relations, key=lambda x: (ename.get(x["subject"], ""), x["predicate"], ename.get(x["object"], ""))):
            s = ename.get(r["subject"], r["subject"]).replace("|", "\\|")
            o = ename.get(r["object"], r["object"]).replace("|", "\\|")
            p = r["predicate"].replace("|", "\\|")
            lines.append(f"| {s} | {p} | {o} |")
        lines.append("")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


# ---------- main ----------

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--in", dest="in_path", type=Path, required=True)
    p.add_argument("--out-dir", type=Path, required=True)
    p.add_argument("--formats", default="json,md",
                   help="Comma-separated subset of json,jsonld,ttl,graphml,md")
    p.add_argument("--lean", action="store_true", help="Strip provenance/mentions from JSON export.")
    p.add_argument("--top-n", type=int, default=50)
    p.add_argument("--prefix", default="ontology")
    p.add_argument("--base-iri", default="https://example.org/book/")
    args = p.parse_args()

    if not args.in_path.exists():
        p.error(f"Input not found: {args.in_path}")

    onto = load_ontology(args.in_path)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    formats = {f.strip() for f in args.formats.split(",") if f.strip()}
    valid = {"json", "jsonld", "ttl", "graphml", "md"}
    bad = formats - valid
    if bad:
        p.error(f"Unknown formats: {bad}. Choose from {valid}.")

    written: list[Path] = []
    if "json" in formats:
        out = args.out_dir / f"{args.prefix}.json"
        export_json(onto, out, lean=args.lean); written.append(out)
    if "jsonld" in formats:
        out = args.out_dir / f"{args.prefix}.jsonld"
        export_jsonld(onto, out, base_iri=args.base_iri); written.append(out)
    if "ttl" in formats:
        out = args.out_dir / f"{args.prefix}.ttl"
        export_ttl(onto, out, base_iri=args.base_iri); written.append(out)
    if "graphml" in formats:
        out = args.out_dir / f"{args.prefix}.graphml"
        export_graphml(onto, out); written.append(out)
    if "md" in formats:
        out = args.out_dir / f"{args.prefix}.md"
        export_md(onto, out, top_n=args.top_n); written.append(out)

    print(f"✓ Exported {len(written)} file(s) to {args.out_dir}/")
    for w in written:
        size = w.stat().st_size
        print(f"  {w.name:30}  {size:>10,} bytes")


if __name__ == "__main__":
    main()
