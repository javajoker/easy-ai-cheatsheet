# Book → Knowledge Graph skillset

A pipeline of six skills that turn very long books (typically >2 million tokens)
into a queryable knowledge graph and then answer questions against it.

> Naming note — this directory was previously called `ontology/`. It was
> renamed to disambiguate from the `share/memory-ontology/` skill, which
> maintains a different kind of ontology (user / project knowledge for the
> Claude Code MEMORY system). Both produce ontologies in the formal sense;
> they serve different purposes.

## The six skills

| Skill | Role |
|---|---|
| `book-to-knowledge-graph` | Orchestrator. Read first. Decides which stages to run. |
| `book-chunking` | Split a long text into semantically coherent, size-bounded chunks. |
| `ontology-extraction` | LLM-driven: extract entities/relations/events/themes from one chunk. |
| `ontology-merging` | Merge per-chunk ontologies into one canonical book-level ontology. |
| `ontology-storage` | Export the merged ontology to JSON, JSON-LD, Turtle, GraphML, Markdown. |
| `ontology-qa` | Answer questions about the book by querying the ontology. |

## How they fit together

```
book.txt → book-chunking      → chunks/
           ontology-extraction → ontology/per_chunk/
           ontology-merging    → ontology/merged.json
           ontology-storage    → exports/{json,jsonld,ttl,graphml,md}
           ontology-qa         → answers grounded in the ontology
```

## Installation

Each skill is a self-contained folder with a `SKILL.md`, scripts, and reference
docs. Install however your environment installs skills (drop into the skills
directory, package as a `.skill` file, etc.).

Python dependencies:

```bash
pip install --break-system-packages tiktoken
```

Everything else is the Python standard library.

## Quick start

```bash
# 1. Chunk
python book-chunking/scripts/chunk_book.py \
    --input book.txt --out-dir work/chunks/ --target-tokens 30000

# 2. Extract (Claude does this per chunk — see ontology-extraction/SKILL.md)

# 3. Merge
python ontology-merging/scripts/merge_ontologies.py \
    --in-dir work/ontology/per_chunk/ \
    --out work/ontology/merged.json \
    --book-title "..." --book-author "..."

# 4. Export
python ontology-storage/scripts/export_ontology.py \
    --in work/ontology/merged.json \
    --out-dir work/exports/ \
    --formats json,jsonld,ttl,graphml,md

# 5. Ask questions
python ontology-qa/scripts/query_ontology.py \
    --ontology work/ontology/merged.json \
    --mode entity --name "Hermione Granger"
```

## Design notes

- **Streaming everywhere** — chunking streams the input file rather than
  loading it all into memory; books of arbitrary size work.
- **Deterministic merge** — entity disambiguation is alias-based and
  reproducible. LLM disambiguation is opt-in for ambiguous cases.
- **Grounded QA** — every answer cites the entities/relations/events/themes
  it drew from. No hallucinated answers; refuses cleanly when retrieval is
  empty.
- **Round-trippable JSON** — the canonical export re-imports cleanly. Other
  formats (Turtle, GraphML, Markdown) are derivative.

## When NOT to use this

- **Short documents** (< 200K tokens) — overkill. Just put the text in
  context and ask.
- **Highly structured data** (CSVs, databases) — already structured; use a
  query engine.
- **Books you want to read** — the ontology summarizes *relationships*, not
  *experience*. The Markdown export is a reference, not a replacement.
- **The MEMORY ontology** — that is the `share/memory-ontology/` skill, not
  this pipeline. They share the word but not the use case.

## Related

- `share/memory-ontology/` — user / project ontology for Claude Code's
  session-spanning memory.
- `share/skill-orchestrator/` — picks this skillset when a user asks to
  "analyze a whole book" or "build a knowledge graph from a long text".
