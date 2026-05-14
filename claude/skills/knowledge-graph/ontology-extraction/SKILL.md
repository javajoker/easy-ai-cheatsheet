---
name: ontology-extraction
description: Read a single chunk of a book and extract a structured ontology (entities, relations, events, themes) as a knowledge-graph JSON. Use this skill whenever a chunk of text needs to be converted into structured semantic data — extracting characters, places, organisations, concepts, and how they relate; tagging events with participants and dates; identifying themes. The output JSON follows a fixed schema so that many chunks can be merged later by the ontology-merging skill. This is the LLM-heavy stage of the book→knowledge-graph pipeline: one extraction pass per chunk.
---

# Ontology Extraction

Turn one chunk of text into one chunk-level ontology JSON. This is an LLM task — you, Claude, do the extracting yourself, then validate the output against the schema.

## Output contract

For input chunk `chunks/chunk_0001.json`, produce `ontology/per_chunk/chunk_0001.json` matching the schema in `references/ontology_schema.md`. In brief:

```json
{
  "chunk_id": "chunk_0001",
  "ontology_version": "1.0",
  "entities": [ { "id": "ent_...", "canonical_name": "...", "type": "...", ... } ],
  "relations": [ { "id": "rel_...", "subject": "ent_...", "predicate": "...", "object": "ent_...", ... } ],
  "events":   [ { "id": "evt_...", "name": "...", ... } ],
  "themes":   [ { "id": "thm_...", "name": "...", ... } ]
}
```

Read `references/ontology_schema.md` for the full field list. Read `references/extraction_prompt.md` for the prompt you should follow when extracting — it's the exact wording that yields consistent output across many chunks.

## How to run a single chunk

1. **Load the chunk**: read `chunks/chunk_NNNN.json` and extract its `text` and `chunk_id`.
2. **Read the schema** at `references/ontology_schema.md` if you haven't this session.
3. **Read the extraction prompt** at `references/extraction_prompt.md`.
4. **Extract**: do the analysis yourself. Stay strictly within what the chunk says — do not import outside knowledge about famous characters, real people, etc. The downstream pipeline trusts that this ontology reflects _the book_, not the world.
5. **Emit JSON only**: produce the ontology JSON in your response, then write it to `ontology/per_chunk/<chunk_id>.json`.
6. **Validate**: run `python scripts/validate_ontology.py ontology/per_chunk/<chunk_id>.json`. If it fails, fix and re-emit. Do not move on with an invalid file — the merge step will reject it.

## ID conventions (critical for merging)

Within a single chunk, give entities IDs in the form `<chunk_id>_ent_001`, `<chunk_id>_ent_002`, etc. Example: `chunk_0001_ent_001`. Do the same for relations (`_rel_`), events (`_evt_`), and themes (`_thm_`). This guarantees IDs are globally unique across all per-chunk files before merging — the merger remaps them to canonical IDs.

## How to run across many chunks

You have two options:

**Sequential (recommended for fidelity)** — extract one chunk per turn. After each, write the output, validate, and move to the next. Slow but you can spot drift early.

**Batched** — extract several chunks worth in one turn if they're short. Risky: easy to confuse which entity came from which chunk. Only do this if chunks are small (<10K tokens each) and the user wants to save time.

For >2M-token books (dozens of chunks), warn the user upfront that this will span many turns and offer to do 2-3 sample chunks first so they can sanity-check the schema before committing.

## Entity types — controlled vocabulary

Use exactly these `type` values, no others (the merger and exporter rely on this):

| Type | Examples |
|---|---|
| `Person` | Named individuals, narrators, gods treated as characters |
| `Place` | Cities, regions, buildings, fictional locations |
| `Organization` | Houses, companies, religions, governments, schools |
| `Object` | Significant artefacts, weapons, books-within-the-book |
| `Concept` | Abstract ideas with proper-noun-like recurrence ("the Force", "the Tao") |
| `Event` | Don't use — put events in the `events` array instead |
| `Work` | Songs, books, films, paintings referenced inside the text |
| `Other` | Anything that genuinely doesn't fit above (use sparingly) |

If an entity could plausibly be two types, pick the dominant role in this chunk and note the secondary in `attributes.also_type`.

## Predicate conventions

Relation predicates are snake_case verb phrases. Prefer short, reusable predicates that will collide across chunks (good — the merger consolidates them):

- Good: `knows`, `child_of`, `located_in`, `founded`, `kills`, `loves`, `works_at`, `member_of`, `created`, `mentions`, `successor_of`.
- Bad: `is_the_father_of_the_main_character` (too specific), `verb_ed_something` (verbose), `has_relationship_with` (too vague).

If you find yourself inventing a predicate that only fires once in the whole book, consider whether it could be expressed as two simpler relations.

## What to include vs leave out

**Include** anything that recurs in the book or is plot-load-bearing. If a name appears only once in passing ("...and they bought bread from a baker named Tom..."), it's probably not worth an entity — unless Tom comes back later. When in doubt, include — the merge step will drop entities that have no relations to anything else and only one mention.

**Leave out** the narrator's voice, generic phrases ("the man", "a soldier" without context), and pronouns (resolve them to entity IDs where confident, drop where not).

## Quality checks before saving

Before writing the file:

1. **Every relation's `subject` and `object` must be IDs that exist in your `entities` array**. If you reference an entity that's not declared, declare it.
2. **Every event's `participants` IDs must exist** as entities.
3. **The chunk_id in the JSON must match the input chunk's ID**.
4. **No duplicate IDs** within the file.

Run `scripts/validate_ontology.py` to catch all four automatically.

## Reference files

- `references/ontology_schema.md` — full field-level schema with types and required/optional
- `references/extraction_prompt.md` — the system-style prompt to follow when doing the actual extraction
- `scripts/validate_ontology.py` — JSON-schema-style validator
- `scripts/extraction_template.json` — empty starter to copy
