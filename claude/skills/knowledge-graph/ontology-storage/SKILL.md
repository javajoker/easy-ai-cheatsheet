---
name: ontology-storage
description: Export a merged book ontology to well-formatted, portable files — JSON, JSON-LD, Turtle (RDF), GraphML (for Gephi/Cytoscape), and a human-readable Markdown summary. Use this skill whenever a merged ontology needs to be saved in a form people or downstream tools can consume: sharing with the user, loading into a graph database, visualizing in Gephi, archiving, or feeding into Neo4j / RDF stores. Produces one file per requested format in an exports/ directory, with consistent naming. Round-trips through JSON (re-importing the exported JSON yields the same ontology).
---

# Ontology Storage / Export

Take a merged ontology JSON and write it out in multiple well-formatted forms suitable for humans and tools.

## When to run

After `ontology-merging` has produced `<book-slug>/ontology/merged.json`. The exporter is read-only on the merged ontology — it never modifies the source.

## How to run

```bash
python scripts/export_ontology.py \
  --in <book-slug>/ontology/merged.json \
  --out-dir <book-slug>/exports/ \
  --formats json,jsonld,ttl,graphml,md
```

Output:
```
exports/
├── ontology.json        # canonical re-export, schema-valid
├── ontology.jsonld      # JSON-LD with schema.org-ish vocabulary
├── ontology.ttl         # RDF Turtle
├── ontology.graphml     # GraphML for Gephi / Cytoscape / yEd
└── ontology.md          # human-readable book summary
```

Then present the files to the user with the `present_files` tool.

## Format catalogue

### `ontology.json` — canonical re-export

A pretty-printed, key-sorted, schema-valid copy of the merged ontology. Strip provenance and chunk_ids if `--lean` is passed, otherwise include them. Useful as the authoritative artefact to archive.

### `ontology.jsonld` — JSON-LD

JSON-LD with a `@context` mapping to schema.org and FOAF where reasonable, custom IRIs for everything else. Entities become typed `@id`s (`#ent_00001`). Relations become RDF triples expressed through schema.org-like predicates (`schema:knows`, `schema:parent`, etc.) or our custom predicates under `book:`.

Use when the user wants to load the ontology into an RDF tool that understands JSON-LD (most modern triple stores, Apache Jena, Stardog).

### `ontology.ttl` — Turtle / RDF

Same content as the JSON-LD, expressed in Turtle syntax. Some tools prefer this. Imports cleanly into Apache Jena, Blazegraph, Virtuoso, Stardog. Use this for serious knowledge-graph work — it's the most portable RDF format.

### `ontology.graphml` — GraphML

XML graph format. Drag-and-drop into:
- **Gephi** — interactive graph layouts, community detection
- **Cytoscape** — biological-style network analysis
- **yEd** — diagram-style layouts
- **igraph / networkx** — programmatic analysis

Entities become nodes (with `type`, `name`, `salience` as node attributes). Relations become directed edges (with `predicate`, `confidence` as edge attributes). Events get nodes too (with `type=Event`), connected to their participants by edges with `predicate=participated_in`.

### `ontology.md` — human-readable summary

A Markdown document that reads like a book summary:

- Frontispiece — book title, author, stats (entities, relations, events, themes).
- "Principal characters" — top-N entities by salience, with descriptions.
- "Places" — geography section.
- "Organizations" — institutional section.
- "Events" — chronologically sorted, with participant links.
- "Themes" — each theme with the entities/events that exemplify it.
- "Relationship index" — a table of canonical relations, suitable for skimming.

This is the file most users actually want to read.

## Flags

| Flag | Default | Meaning |
|---|---|---|
| `--in` | required | Path to merged ontology JSON. |
| `--out-dir` | required | Output directory; created if missing. |
| `--formats` | `json,md` | Comma-separated subset of `json,jsonld,ttl,graphml,md`. |
| `--lean` | false | Strip provenance, chunk_ids, mentions from the JSON re-export. |
| `--top-n` | 50 | Number of top-salience entities to highlight in the Markdown summary. |
| `--prefix` | `ontology` | Output filename prefix (e.g. `--prefix book1` → `book1.json`). |
| `--base-iri` | `https://example.org/book/` | Base IRI for JSON-LD / Turtle. Set this to your own domain if publishing. |

## What "well-formatted" means here

- **JSON** is pretty-printed with 2-space indent, keys sorted at each level, UTF-8 with no BOM.
- **JSON-LD** uses a stable `@context` and resolves all internal IDs to relative IRIs (`#ent_00001`) so a single file is self-contained.
- **Turtle** uses prefix declarations at the top (`@prefix book: <...> .`), one triple per line where possible, with proper escaping of literal strings.
- **GraphML** validates against the GraphML XML schema (you can confirm with `xmllint --schema graphml.xsd ontology.graphml`).
- **Markdown** uses ATX headers, escaped pipe characters in tables, no emoji, no hard line breaks within paragraphs.

## Round-trip guarantee

The `json` export round-trips: re-importing `ontology.json` into the merger (or just re-validating it) yields the same canonical content. The other formats are lossy — JSON-LD/Turtle drop the `merge_report` block; GraphML drops `attributes` that aren't representable as flat strings; Markdown is for humans, not re-parsing.

If you need a single authoritative file, use `ontology.json`. The others are derivative.

## Reference files

- `references/format_specs.md` — details of the JSON-LD context, Turtle prefixes, GraphML attribute keys.
- `scripts/export_ontology.py` — the exporter.
