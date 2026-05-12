---
name: book-chunking
description: Split a very long book (>200K tokens, especially >2M tokens) into semantically coherent, size-bounded chunks that downstream LLM stages can process one at a time. Use this skill whenever a text is too large to fit in a single model context — full-length novels, multi-volume works, dense academic books, scripture, encyclopaedias, legal codes, transcripts of long conversations. Produces a `chunks/` directory of JSON files plus an `index.json` describing the chunking. Streams the input file rather than loading it all into memory, so it works on books of arbitrary size.
---

# Book Chunking

Split a very long text into chunks that are (a) small enough for an LLM to process in one pass, (b) semantically coherent (don't cut mid-paragraph if avoidable), and (c) carry enough metadata that downstream skills can stitch results back together.

## Output contract

After running, `<out-dir>/` contains:

```
chunks/
├── index.json              # array of chunk metadata
├── chunk_0001.json
├── chunk_0002.json
└── ...
```

Each `chunk_NNNN.json`:
```json
{
  "chunk_id": "chunk_0001",
  "ordinal": 1,
  "char_range": [0, 124583],
  "token_count": 29874,
  "section_title": "Chapter 1: A Long-Expected Party",
  "previous_chunk_id": null,
  "next_chunk_id": "chunk_0002",
  "text": "..."
}
```

`index.json` is an array of the metadata blocks above (without the `text` field) plus a top-level `book` block with totals.

## How to run

```bash
python scripts/chunk_book.py \
  --input <book-slug>/source/book.txt \
  --out-dir <book-slug>/chunks/ \
  --target-tokens 30000 \
  --overlap-tokens 500
```

| Flag | Default | Meaning |
|---|---|---|
| `--input` | required | Path to the raw text file (UTF-8). For PDF/EPUB, convert first using the `pdf-reading` skill or `pandoc`. |
| `--out-dir` | required | Output directory; created if missing. |
| `--target-tokens` | 30000 | Aim for this many tokens per chunk. Hard cap is 1.5× this. |
| `--overlap-tokens` | 500 | Each chunk repeats this many tokens from the end of the previous chunk, so cross-chunk references survive. |
| `--respect-headings` | true | If structural headings are detected (Markdown `#`, "Chapter N", roman numerals), prefer to break there. |
| `--encoding` | cl100k | Tiktoken encoding name. cl100k matches Claude well enough for budgeting. |

## Choosing chunk size

Bigger chunks = fewer extraction passes but more entities packed into each LLM output (and a higher chance of truncation). Smaller chunks = more passes but cleaner extractions.

| Book size | Recommended `--target-tokens` | Resulting chunk count |
|---|---|---|
| 200K – 500K tokens | 20000 | 10 – 25 |
| 500K – 2M tokens | 30000 | 17 – 70 |
| 2M – 10M tokens | 40000 | 50 – 250 |

Tell the user the count before running — they may want fewer larger chunks to save on LLM calls, or smaller chunks for fidelity.

## Chunking algorithm (what the script does)

1. **Stream the file** line by line — never load the whole book into memory. Books >2M tokens routinely exceed available RAM if loaded naively.
2. **Detect structural anchors** during streaming: lines matching `^(#+\s|CHAPTER\s+\w+|Chapter\s+\w+|BOOK\s+\w+|Part\s+\w+|\d+\.\s+[A-Z])` are tagged.
3. **Accumulate text** into a buffer, counting tokens via `tiktoken`.
4. **When the buffer hits `target_tokens`**, look backwards within a 20% window for the most recent structural anchor or, failing that, paragraph break (`\n\n`), and cut there. This keeps chunks coherent.
5. **Hard cap**: if no good break is found within 1.5× target, force-cut at the next paragraph boundary.
6. **Carry overlap forward**: the last `overlap_tokens` tokens of the previous chunk are prepended to the next chunk (clearly marked in metadata so extraction can ignore it for entity counting but use it for context).
7. **Emit** `chunk_NNNN.json` and append to `index.json`.

## Verifying the output

After chunking, sanity-check with:

```bash
python scripts/chunk_book.py --verify --out-dir <book-slug>/chunks/
```

This prints total tokens, chunk count, chunk size distribution, and flags any chunks that are unexpectedly small (often a sign of a bad break near EOF) or unexpectedly large (a sign the hard cap kicked in).

## What to do if input isn't `.txt`

This skill expects UTF-8 plain text. For other formats:

- **PDF** — use the `pdf-reading` skill, or `pdftotext -layout book.pdf book.txt`. Inspect a sample to make sure column order and hyphenation came through correctly; broken hyphenation in particular will fragment entity names downstream.
- **EPUB** — `pandoc -f epub -t plain book.epub -o book.txt`.
- **Multiple files** (volumes split across files) — concatenate them with clear `## Volume N` markers between, then chunk normally. The structural anchor detection will respect these.

## Reference

See `references/chunking_strategies.md` for deeper notes on overlap sizing, handling tables / poetry / code blocks, and when to prefer semantic chunking over fixed-size.
