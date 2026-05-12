# Ontology schema (v1.0)

All per-chunk and merged ontology files conform to this schema. Validator: `scripts/validate_ontology.py`.

## Top level

```json
{
  "ontology_version": "1.0",                   // required, string, exactly "1.0"
  "chunk_id": "chunk_0001",                    // required for per-chunk; omitted in merged
  "source": {                                  // required for merged; omitted in per-chunk
    "book_title": "...",
    "book_author": "...",
    "chunk_ids": ["chunk_0001", "chunk_0002", ...]
  },
  "entities":  [ /* Entity */ ],               // required, may be empty
  "relations": [ /* Relation */ ],             // required, may be empty
  "events":    [ /* Event */ ],                // required, may be empty
  "themes":    [ /* Theme */ ]                 // required, may be empty
}
```

Exactly one of `chunk_id` (per-chunk file) or `source` (merged file) is present.

## Entity

```json
{
  "id": "chunk_0001_ent_001",                  // required, unique within file
  "canonical_name": "Albert Einstein",         // required, the most complete form seen
  "type": "Person",                            // required, one of the controlled vocab
  "aliases": ["Einstein", "Albert"],           // optional, all other names seen for this entity
  "description": "German-born physicist who developed relativity.",  // optional, ≤ 280 chars
  "attributes": {                              // optional, open-ended key-value
    "birth_year": "1879",
    "nationality": "German"
  },
  "salience": 0.95,                            // optional float 0..1, importance within this chunk
  "mentions": [                                // optional, where the entity appears in the chunk
    { "snippet": "Einstein walked into the room", "char_offset": 12345 }
  ]
}
```

### `type` — controlled vocabulary

`Person | Place | Organization | Object | Concept | Work | Other`

(Note: there is no `Event` type — events go in the `events` array.)

### `attributes` — conventions

Open-ended, but prefer consistent keys across chunks for the same entity type:

- Person: `birth_year`, `death_year`, `nationality`, `occupation`, `gender`, `role`
- Place: `country`, `region`, `coordinates`, `population`
- Organization: `founded`, `dissolved`, `headquarters`, `type` (e.g. "religious order")
- Work: `year`, `author`, `medium`

If you add a free-form key, use snake_case and keep values as strings (numbers and dates as ISO strings).

## Relation

```json
{
  "id": "chunk_0001_rel_001",
  "subject": "chunk_0001_ent_001",             // required, must be an entity ID in the same file
  "predicate": "developed",                    // required, snake_case verb phrase
  "object": "chunk_0001_ent_042",              // required, must be an entity ID in the same file
  "context": "Einstein developed the theory of relativity in 1905",  // optional, short evidence snippet ≤ 280 chars
  "attributes": {                              // optional, e.g. time-qualifying the relation
    "year": "1905",
    "location": "chunk_0001_ent_017"
  },
  "confidence": 0.95                           // optional float 0..1, your confidence in the extraction
}
```

**Both `subject` and `object` MUST point to entities declared in the same file.** This is the most common validation failure — fix by declaring the missing entity, not by deleting the relation.

## Event

```json
{
  "id": "chunk_0001_evt_001",
  "name": "Publication of Relativity Paper",   // required, short noun phrase
  "description": "Einstein's first paper on special relativity is published in Annalen der Physik.",  // optional ≤ 500 chars
  "date": "1905",                              // optional, ISO-like string ("1905", "1905-06", "1905-06-30")
  "participants": [ "chunk_0001_ent_001" ],    // optional, entity IDs
  "location": "chunk_0001_ent_017",            // optional, single entity ID
  "consequences": [ "chunk_0001_evt_002" ],    // optional, other event IDs
  "context": "..."                             // optional, evidence snippet
}
```

## Theme

```json
{
  "id": "chunk_0001_thm_001",
  "name": "Theory of Relativity",
  "description": "...",                        // optional ≤ 500 chars
  "related_entities": [ "chunk_0001_ent_001", "chunk_0001_ent_042" ],
  "related_events":   [ "chunk_0001_evt_001" ]
}
```

Themes are higher-level than entities — they group entities/events around an abstract idea. Use sparingly: 3-7 themes per chunk is typical, 20+ is over-extraction.

## ID rules

- Per-chunk file: every ID starts with the chunk_id prefix (e.g. `chunk_0001_ent_001`).
- Merged file: IDs are remapped to canonical form by the merger (e.g. `ent_00042`). Don't try to predict canonical IDs at extraction time.
- IDs are case-sensitive. Stick to lowercase with underscores.

## Numeric ranges

- `salience` and `confidence` are floats in `[0.0, 1.0]`.
- Coordinates (if used in attributes) as `"lat,lon"` string, e.g. `"48.8566,2.3522"`.

## What MUST NOT appear

- Markdown formatting in any string field (the data will be re-rendered as Markdown by the storage skill, so embedded Markdown round-trips badly).
- HTML tags.
- Newlines in `canonical_name` or `predicate` or `name`.
- Pronouns ("he", "they") as canonical names — resolve to the entity or drop.
- The narrator as an entity unless they're a named character.
