---
name: ontology-merging
description: Merge many per-chunk ontology JSON files into a single canonical book-level ontology. Use whenever per-chunk ontology files (produced by the ontology-extraction skill) need to be consolidated — deduplicating entities across chunks (e.g. "John", "John Smith", "Mr. Smith" → one entity), unifying relations, stitching event sequences, and remapping all chunk-local IDs to global canonical IDs. The merger is deterministic by default (alias-based canonicalization) with an optional LLM-assisted disambiguation pass for ambiguous cases. Required step between ontology-extraction and ontology-storage / ontology-qa.
---

# Ontology Merging

Many per-chunk ontology JSON files in, one canonical book-level ontology JSON out. The merger consolidates entities that refer to the same thing, deduplicates relations, sequences events, and remaps IDs.

## When to run

- After `ontology-extraction` has produced one JSON per chunk in `ontology/per_chunk/`.
- Before `ontology-storage` (exporting) or `ontology-qa` (answering questions).
- Re-run whenever new chunks are added, or to fold a new volume's ontology into an existing book ontology.

## How to run — basic case

```bash
python scripts/merge_ontologies.py \
  --in-dir <book-slug>/ontology/per_chunk/ \
  --out <book-slug>/ontology/merged.json \
  --book-title "The Title of the Book" \
  --book-author "The Author"
```

The script:
1. Loads every `*.json` in `--in-dir` (skipping `index.json` if present).
2. Validates each one against the per-chunk schema.
3. Builds a canonical entity map by clustering entities whose `canonical_name` or any `alias` matches (case-insensitive, punctuation-stripped) within the same `type`.
4. Remaps every entity ID to a canonical `ent_NNNNN` form, propagating through relations / events / themes.
5. Deduplicates relations on the `(subject, predicate, object)` triple — keeps the highest-confidence context and accumulates `chunk_ids`.
6. Merges events by `(name, date)` similarity; participants accumulate.
7. Writes the merged ontology and prints a summary.

## How to run — with LLM-assisted disambiguation

The deterministic merge handles most aliasing, but ambiguous cases ("the king" across chunks where multiple kings appear; "John" where there are five Johns) need human or LLM judgement.

After the deterministic merge, the script can produce a `disambiguation_report.json` listing the uncertain clusters:

```bash
python scripts/merge_ontologies.py \
  --in-dir <book-slug>/ontology/per_chunk/ \
  --out <book-slug>/ontology/merged.json \
  --emit-disambiguation-report <book-slug>/ontology/disambiguation_report.json
```

Then you, Claude, read the report and make merge/split decisions chunk by chunk. Apply them with:

```bash
python scripts/merge_ontologies.py \
  --apply-decisions <book-slug>/ontology/disambiguation_decisions.json \
  --in-dir <book-slug>/ontology/per_chunk/ \
  --out <book-slug>/ontology/merged.json
```

The decisions file shape and the LLM-assisted workflow are documented in `references/disambiguation.md`.

## Canonicalization rules (what counts as "the same entity")

Two entities are merged automatically when **all** of these hold:

1. Same `type`.
2. After normalization (lowercase, strip punctuation, collapse whitespace), one of these matches:
   - One entity's `canonical_name` appears in the other's `aliases`.
   - Both entities share any `alias` in common.
   - The normalized canonical names are identical.
3. They are not on the disambiguation block-list (see `--block-list` flag).

Two entities are **not** merged automatically, but flagged for review, when:

- They share a partial token match but not a full alias match (e.g. "John" vs "John Smith" — could be the same, could not).
- They share an alias but are of different types (e.g. a person "Rome" and a place "Rome").

The default policy is conservative: when in doubt, don't merge — the LLM disambiguation pass catches the rest.

## Output

The merged file follows the schema in `ontology-extraction/references/ontology_schema.md` but with:

- `source` block instead of `chunk_id`.
- Canonical IDs in the form `ent_00001`, `rel_00001`, `evt_00001`, `thm_00001`.
- Each entity carries a `provenance` field listing the original per-chunk IDs that contributed to it and the chunk_ids where it appeared.
- Each relation carries a `chunk_ids` array showing every chunk that asserts the same triple.

```json
{
  "ontology_version": "1.0",
  "source": {
    "book_title": "The Title",
    "book_author": "The Author",
    "chunk_ids": ["chunk_0001", "chunk_0002", ...],
    "total_chunks": 70
  },
  "entities":  [ ... ],
  "relations": [ ... ],
  "events":    [ ... ],
  "themes":    [ ... ],
  "merge_report": {
    "input_files": 70,
    "raw_entities": 4823,
    "merged_entities": 1247,
    "raw_relations": 8912,
    "merged_relations": 6104,
    "disambiguation_flags": 18
  }
}
```

## Performance notes

- The merge is fast: clustering uses a Union-Find over normalized name strings, so even 50K raw entities finish in seconds.
- Memory: the script holds all per-chunk files in memory simultaneously. For 100+ chunks of 30K tokens each, peak is ~500MB JSON; budget accordingly.
- Determinism: same inputs → byte-identical output (entities and relations are sorted before writing).

## Re-merging when chunks change

If you re-extract a chunk (because the schema changed or you noticed bad extraction), just rerun the merge — it consumes the whole `per_chunk/` directory each time. There's no incremental mode; the deterministic algorithm is fast enough that incremental isn't worth the complexity.

## Reference files

- `references/merging_strategies.md` — deeper notes on canonicalization, threshold tuning, and handling tricky cases.
- `references/disambiguation.md` — the LLM-assisted disambiguation workflow and decisions-file format.
- `scripts/merge_ontologies.py` — the merger.
- `scripts/canonicalize.py` — name normalization helpers (importable).
