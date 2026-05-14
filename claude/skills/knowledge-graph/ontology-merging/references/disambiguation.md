# LLM-assisted disambiguation

When the deterministic merger isn't sure whether two entities refer to the same thing, it writes them to a `disambiguation_report.json` and stops. Your job (as Claude using this skill) is to read each flagged pair, decide based on their descriptions and the chunks they came from, and emit a `disambiguation_decisions.json` for the merger to re-consume.

## The report format

```json
{
  "flags": [
    {
      "entity_a": {
        "id": "chunk_0003_ent_007",
        "chunk_id": "chunk_0003",
        "type": "Person",
        "canonical_name": "John",
        "aliases": ["the gardener"],
        "description": "An elderly gardener at the manor."
      },
      "entity_b": {
        "id": "chunk_0017_ent_002",
        "chunk_id": "chunk_0017",
        "type": "Person",
        "canonical_name": "John Smith",
        "aliases": ["John", "Mr. Smith"],
        "description": "A solicitor visiting from London."
      }
    },
    ...
  ]
}
```

## How to make decisions

For each flagged pair, ask:

1. **Do the descriptions describe the same role?** Gardener vs solicitor — clearly different. Mark as `split`.
2. **Do they describe the same role but at different life stages?** "Young Pip" and "old Pip" — same entity, mark as `merge`.
3. **Is one a sub-character of the other?** "King George" mentioning "Prince George" — different entities, `split`.
4. **Is there explicit textual evidence in the chunks?** If unsure, fetch the chunks (`chunks/chunk_NNNN.json`) and re-read the relevant mentions before deciding.

If you genuinely cannot tell from the available evidence, default to `split` (forbid merging). False splits are recoverable; false merges aren't.

## Decisions file format

```json
{
  "merge": [
    ["chunk_0005_ent_003", "chunk_0019_ent_002"],
    ["chunk_0008_ent_001", "chunk_0022_ent_004"]
  ],
  "split": [
    ["chunk_0003_ent_007", "chunk_0017_ent_002"]
  ]
}
```

Pairs in `merge` get force-unioned (transitively — if A-B and B-C are both merged, A-C also).
Pairs in `split` are blocked from merging even if the deterministic algorithm would have unioned them.

Save as `<book-slug>/ontology/disambiguation_decisions.json` and re-run:

```bash
python scripts/merge_ontologies.py \
  --in-dir <book-slug>/ontology/per_chunk/ \
  --out <book-slug>/ontology/merged.json \
  --apply-decisions <book-slug>/ontology/disambiguation_decisions.json \
  --emit-disambiguation-report <book-slug>/ontology/disambiguation_report.json
```

You can iterate: the new report may surface fewer flags now that the previous decisions are applied. Repeat until the report is empty or the remaining flags are deliberate splits.

## Multi-volume merging

When folding a new volume into an existing book ontology:

1. Chunk and extract the new volume normally → per-chunk files in `volume2/per_chunk/`.
2. Copy the existing `merged.json` from volume 1 into a directory alongside the volume-2 chunk files. The merger ignores files with `source` blocks (merged files) by default; patch `load_chunk_ontologies` to accept both, or convert the merged file back to a single "synthetic chunk" first:

```bash
python scripts/merge_ontologies.py \
  --in-dir all_inputs/ \
  --out final/merged.json \
  ...
```

Practical advice: it's usually less error-prone to re-merge from scratch using all per-chunk files from both volumes. The merge is fast — minutes even for 200+ chunks — so re-running isn't a big cost.

## Limits

- The disambiguation report only flags pairs the deterministic algorithm wasn't sure about. It will never flag a pair the algorithm confidently merged or confidently kept apart. If you suspect the algorithm got confident cases wrong, inspect the merged output directly (search for the canonical name) and add entries to `split` to force-unmerge.
- For very large books, the flag list can run into hundreds. Tackle them in batches — sort by type, by chunk distance, or by name similarity — rather than trying to review all at once.
