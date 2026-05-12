# Merging strategies — deeper notes

## Why deterministic-first, LLM-second

The merger is deliberately conservative. It only auto-merges when names match exactly after normalization, because false merges are nearly impossible to detect after the fact: once "Lord Tywin" and "Lord Robert" both become `ent_00042` because they were both aliased "the Lord", the relations they carry get smeared together and the rest of the pipeline silently corrupts.

False splits, by contrast, are easy to see: an obvious character shows up as two entities in the exported graph, and the user notices in seconds. So the merger errs heavily toward splitting and flags the ambiguous cases for review.

## Tuning the normalization

`canonicalize.py` strips honorifics ("Dr.", "Sir", "Captain", etc.) and ignores particles ("of", "the", "von", "de") during fuzzy comparison. If your book uses honorifics not in the default list (medieval titles, fictional ranks, religious titles in non-English traditions), edit the `HONORIFICS` set at the top of that file.

Don't widen `HONORIFICS` casually — every word you add becomes a word the merger ignores when comparing names. Adding "the" would merge "the Doctor" and "the Patient" because they share zero core tokens after stripping.

## Same-name-different-entity cases

Some books deliberately reuse names:

- _One Hundred Years of Solitude_ — five generations of José Arcadios.
- _The Brothers Karamazov_ — multiple Fyodors.
- Genealogical texts — many Johns/Marys/Williams.

For these, the merger will over-merge by default. You have two options:

1. **Extraction-side fix**: have the extraction prompt include a generational marker in `canonical_name`, e.g. "José Arcadio (I)", "José Arcadio (II)". The merger sees them as different strings and won't merge them.
2. **Disambiguation-side fix**: let the merger over-merge, then use the LLM disambiguation pass (see `disambiguation.md`) to split them apart with `forbid_merge` decisions.

Option 1 is cleaner if you know upfront that the book has this pattern.

## Cross-language books

If the book mixes languages (e.g. a Russian novel with French dialogue, or translated texts where names appear in two scripts), the same character may appear as "Pierre" and "Пьер" in different chunks. The deterministic merger won't catch this — the strings don't normalize the same way.

Fix: extraction should always list both forms in `aliases`. If you see this pattern emerging, instruct the extraction pass explicitly: "for characters with names in multiple scripts, list all forms as aliases of the most canonical Latin-alphabet form."

## Performance ceiling

Quadratic ambiguity scan caps at 2000 entities per type. For a book with >2000 named persons (rare — usually means over-extraction), the scan is skipped with a warning, and you should:

1. Re-run extraction with more aggressive filtering (drop entities with `salience < 0.1`).
2. Or accept that ambiguity detection is incomplete and run the LLM pass on the merged ontology directly.

## When to skip the merger

If you have only one chunk (a small book), the merger is technically still needed — it remaps `chunk_0001_ent_001` to `ent_00001`, which downstream skills expect. Run it; it'll finish in milliseconds and produce a valid merged file.

If you have already-merged ontologies (e.g. you're folding two volumes' ontologies together), just put them in `--in-dir` alongside the per-chunk files. They have different top-level keys (`source` vs `chunk_id`) so the merger has to be patched to accept both — see the "Multi-volume merging" section in `disambiguation.md` for the workflow.
