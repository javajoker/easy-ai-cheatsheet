# Chunking strategies — deeper notes

This file is loaded only when the chunker's default behaviour isn't right for the input. Most books work fine with defaults; read this when the book has unusual structure.

## Overlap sizing — why 500 tokens by default

Overlap exists so that cross-chunk references survive. If "the king" is introduced at the end of chunk 7 and then named ("King Aerys") at the start of chunk 8, the extraction pass on chunk 8 still sees enough context to know that "the king" referred to Aerys.

- **500 tokens** is roughly 2-3 paragraphs — enough for short-range coreference.
- **Increase to 1000-1500** if the book has very long flashback structures or dense cross-references (e.g. legal/scriptural texts where verses reference each other across chapters).
- **Decrease to 200** if you're cost-constrained — most coreference resolution can be done at merge time.

The overlap is prepended to each chunk, not duplicated content — the merge step deduplicates entities and relations by canonical ID so seeing the same passage twice does not double-count.

## Handling poetry, lyrics, drama, and code

The default heading regex looks for prose-style structural markers. For verse-heavy texts:

- **Poetry collections** — stanzas are short; the 30K-token target may pack hundreds of poems together. Increase `target-tokens` to 50000 so each chunk holds a meaningful body of work, and pass `--no-respect-headings` if poem titles look heading-like but break too aggressively.
- **Plays** — Acts and Scenes are usually well-marked. The default regex catches "ACT I", "Scene 2", etc. If the script uses non-English conventions, edit `HEADING_PATTERNS` in `chunk_book.py`.
- **Source code** — chunk at function or class boundaries, not paragraph boundaries. This is out of scope for this skill; use a code-aware chunker (tree-sitter based).

## Multi-volume corpora

For a series like _A Song of Ice and Fire_ (≈1.7M words, ~2.3M tokens):

1. Concatenate the volumes into one `book.txt` with a clear separator:
   ```
   ## VOLUME 1 — A Game of Thrones

   ...

   ## VOLUME 2 — A Clash of Kings

   ...
   ```
2. Chunk normally. The volume markers act as the strongest structural anchors.
3. In `index.json` you'll see chunks tagged with `section_title` starting with "VOLUME N" — downstream skills use these to scope entity resolution.

## When chunks come out the wrong size

Symptom: `--verify` reports many small chunks.

- **Many chunks just below soft floor** — the heading detector is firing too eagerly. Look at a few flagged chunks' `section_title`; if they're spurious matches (e.g. numbered lists in the text), pass `--no-respect-headings`.
- **One small tail chunk** — normal, ignore.
- **Big variance in size** — the book has uneven chapter lengths. Acceptable; the extraction pass adapts per-chunk.

Symptom: `--verify` reports chunks over the hard cap.

- This means the chunker couldn't find a paragraph break within the cap window. Almost always indicates a pathological input: a 50K-token paragraph (e.g. a single long quotation), or missing newlines (the book was converted from PDF without preserving line breaks). Rerun the source conversion.

## Choosing an encoding

`cl100k_base` is OpenAI's GPT-4 tokenizer. Claude's tokenizer differs, but for chunk-size budgeting the difference is within ±10% — fine for our purposes. We use cl100k because tiktoken is fast and dependable; the actual extraction pass will count tokens internally for the LLM call.

If you have a more accurate tokenizer (e.g. an Anthropic token counter), swap it in by replacing the `enc.encode` calls. The structural-anchor logic doesn't depend on tokenizer choice.

## Edge cases

- **Empty input** — script exits with no chunks; `index.json` is still written so downstream can detect this.
- **Non-UTF-8 input** — `errors="replace"` substitutes `\ufffd` for bad bytes. Re-encode the source if this matters.
- **Single line, no newlines** — chunker falls back to pure token-count splits with no semantic preference. This usually means the source needed line-break repair before chunking.
