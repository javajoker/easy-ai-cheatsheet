---
name: book-to-knowledge-graph
description: End-to-end pipeline that turns a very long book (>2M tokens, e.g. multi-volume works, dense academic texts, full novels, scripture, encyclopaedias) into a queryable ontology / knowledge graph and then answers questions against it. Use this skill whenever the user wants to "analyze a whole book", "build a knowledge graph from a book", "extract characters/concepts/events from a long text", "make sense of a book too big to read in one pass", or asks questions about a book they have uploaded as a file. Coordinates five sub-skills (book-chunking, ontology-extraction, ontology-merging, ontology-storage, ontology-qa) — read this skill first to decide which stages to run, then follow the linked skill for each stage.
---

# Book → Knowledge Graph Pipeline

A coordinator skill for turning very long books into structured ontologies and answering questions against them. Useful when the book is so large that it cannot fit into the model context in one pass (>200K tokens, and definitely >2M tokens).

## The pipeline at a glance

```
[ book.txt / book.pdf / book.epub ]
            │
            ▼
   ┌────────────────────┐
   │ 1. book-chunking   │  → chunks/chunk_0001.json … chunk_NNNN.json + index.json
   └────────────────────┘
            │
            ▼  (for each chunk, one LLM pass)
   ┌────────────────────┐
   │ 2. ontology-       │  → ontology/per_chunk/chunk_0001.json …
   │    extraction      │
   └────────────────────┘
            │
            ▼
   ┌────────────────────┐
   │ 3. ontology-       │  → ontology/merged.json (canonical)
   │    merging         │
   └────────────────────┘
            │
            ▼
   ┌────────────────────┐
   │ 4. ontology-       │  → ontology.{json,jsonld,ttl,graphml,md}
   │    storage         │
   └────────────────────┘
            │
            ▼
   ┌────────────────────┐
   │ 5. ontology-qa     │  ← user questions → grounded answers
   └────────────────────┘
```

Each stage is a standalone skill — you do not have to run them in one shot. A user may already have chunks, or already have an ontology, and only want the later stages.

## When to invoke which stage

Look at what the user has given you and what they want:

- **Raw book file, "summarize this 1200-page text"** → run all five stages.
- **Raw book file, "what does this book say about X?"** → run all five stages, then answer X from the ontology.
- **They already uploaded an `ontology.json`** → skip to stage 5 (ontology-qa).
- **They already have chunked files** → skip to stage 2.
- **They want to add a new volume to an existing ontology** → chunk + extract the new volume, then re-run stage 3 (merge) feeding in both the old ontology and the new per-chunk ontologies.

## Working directory layout

Always set up a working directory in `/home/claude/<book-slug>/`. The five skills assume this layout:

```
<book-slug>/
├── source/
│   └── book.txt                    # the raw text (after any PDF→txt conversion)
├── chunks/
│   ├── index.json                  # list of all chunks with metadata
│   ├── chunk_0001.json
│   ├── chunk_0002.json
│   └── ...
├── ontology/
│   ├── per_chunk/
│   │   ├── chunk_0001.json         # ontology extracted from one chunk
│   │   └── ...
│   └── merged.json                 # canonical merged ontology
└── exports/
    ├── ontology.json               # canonical re-export
    ├── ontology.jsonld
    ├── ontology.ttl
    ├── ontology.graphml
    └── ontology.md                 # human-readable summary
```

Pass this working directory to every script — the skills agree on these relative paths so they can chain.

## Running the pipeline

### Step 1 — Chunk the book

Read `/path/to/book-chunking/SKILL.md`. Run:

```bash
python book-chunking/scripts/chunk_book.py \
  --input <book-slug>/source/book.txt \
  --out-dir <book-slug>/chunks/ \
  --target-tokens 30000 \
  --overlap-tokens 500
```

30K tokens per chunk leaves plenty of headroom for the extraction prompt and the JSON output. For a 2M-token book this gives ~70 chunks.

### Step 2 — Extract per-chunk ontology

Read `/path/to/ontology-extraction/SKILL.md`. This stage is LLM-driven — for **each** chunk you, Claude, read the chunk and emit a JSON ontology following the schema in that skill. The skill provides the prompt template and an output validator. Save each as `<book-slug>/ontology/per_chunk/chunk_NNNN.json`.

For >2M token books this means dozens of extraction passes. Tell the user upfront: this will take many turns and many tokens. Offer to do a sample of 2-3 chunks first so they can sanity-check the schema before committing to the whole run.

### Step 3 — Merge per-chunk ontologies

Read `/path/to/ontology-merging/SKILL.md`. Run:

```bash
python ontology-merging/scripts/merge_ontologies.py \
  --in-dir <book-slug>/ontology/per_chunk/ \
  --out <book-slug>/ontology/merged.json
```

The merge script does deterministic alias-based canonicalization. For tricky cases (e.g. "the doctor" vs "Dr. Watson") the skill explains how to do an LLM-assisted disambiguation pass afterwards.

### Step 4 — Export to well-formatted files

Read `/path/to/ontology-storage/SKILL.md`. Run:

```bash
python ontology-storage/scripts/export_ontology.py \
  --in <book-slug>/ontology/merged.json \
  --out-dir <book-slug>/exports/ \
  --formats json,jsonld,ttl,graphml,md
```

Present the resulting files to the user with `present_files`.

### Step 5 — Answer questions

Read `/path/to/ontology-qa/SKILL.md`. For each question, run the retrieval helper and then answer grounded in what it returns.

## Cost / time expectations to set with the user

A 2M-token book ≈ 70 chunks × one extraction pass each ≈ 70 LLM calls just for stage 2, plus 1-3 calls for stage 3 disambiguation. Tell the user this honestly before kicking off — they may want a sample first, or a smaller chunk count (larger chunks = fewer calls but lower fidelity).

## Common failure modes

- **PDF text extraction is dirty** — running stage 1 on a PDF with broken hyphenation produces bad chunks. Use the `pdf-reading` skill to convert cleanly to text first.
- **The book has no clear chapter markers** — chunking falls back to paragraph-aware token splits; quality is still fine but section titles won't be populated.
- **Schema drift across chunks** — if you run extraction over many turns and start adding fields, the merge step will silently drop them. Stick to the schema in `ontology-extraction/references/ontology_schema.md`.
- **Entity over-splitting** — "John", "John Smith", and "Mr. Smith" become three entities. The merge step's alias rules fix most of this; remaining cases need the optional LLM disambiguation pass.

## Bigger than 2M tokens?

For 5M+ token corpora (multi-volume series, complete works of an author), run stages 1-3 per volume, then run stage 3 again with the volume-level merged ontologies as input. The merge script accepts both per-chunk and already-merged ontologies as input.
