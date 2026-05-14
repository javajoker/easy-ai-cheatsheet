# Extraction prompt

This is the prompt-style instruction you (Claude) should mentally apply when extracting one chunk's ontology. Following it consistently across all chunks is what makes the merge step succeed — every chunk should be extracted by the same "internal extractor", not by ad-hoc improvisation per chunk.

---

## Your task

You are extracting a knowledge graph from one chunk of a book. The output is one JSON object per chunk, following the schema in `ontology_schema.md`. Many such chunks will later be merged into a single book-level ontology, so consistency across chunks matters more than cleverness on any one chunk.

## The five passes

Make five focused passes over the chunk text. Don't try to do everything in one read.

### Pass 1 — Inventory entities

Read the chunk through. List every:

- **Person** named by a proper noun (full name, or recurring nickname)
- **Place** named by a proper noun
- **Organization** (house, faction, institution, religion, company, ship, etc.)
- **Object** with a name (Excalibur, the One Ring, the Necronomicon)
- **Concept** with proper-noun-like recurrence (the Force, dharma, the unconscious)
- **Work** referenced inside the text (a book, song, painting)

For each, capture:
- The most complete name form you've seen → `canonical_name`
- Every other name form → `aliases` (titles, nicknames, partial names)
- A one-sentence description grounded in the chunk

Skip one-off mentions of generic nouns ("a soldier", "the old woman") unless they're plot-load-bearing and unnamed-but-tracked (e.g. "the Stranger" in Camus).

### Pass 2 — Inventory relations

For each pair of entities you've listed, ask: does the chunk assert a relationship between them? Use snake_case verb predicates. Common predicates to consider:

- Family: `parent_of`, `child_of`, `sibling_of`, `spouse_of`, `ancestor_of`
- Social: `knows`, `loves`, `hates`, `married_to`, `friend_of`, `enemy_of`, `mentor_of`
- Action: `kills`, `saves`, `betrays`, `meets`, `helps`, `serves`, `commands`
- Affiliation: `member_of`, `leader_of`, `founded`, `joined`, `expelled_from`
- Spatial: `located_in`, `traveled_to`, `born_in`, `died_in`, `ruled`
- Creative: `wrote`, `created`, `composed`, `performed`
- Causal: `caused`, `prevented`, `enabled`

Always include a `context` snippet (≤ 280 chars) quoting or paraphrasing the evidence. This is what lets the QA stage cite back to the book.

### Pass 3 — Inventory events

Anything with a distinct happening — a meeting, battle, journey, birth, death, ceremony, discovery, decision. For each:

- A short noun-phrase `name` ("Battle of the Blackwater", "Anna's confession")
- A `date` if the chunk gives one (year, month, ISO date, or relative — "the morning after" is OK as `description` but don't put it in `date`)
- `participants` as entity IDs
- `location` as a single place entity ID if known

Don't double-record actions as both relations and events. Rule of thumb: if it's an _action_ between two entities ("Brutus killed Caesar"), use a relation; if it's a _scene_ involving multiple entities at a time and place ("Caesar's assassination on the Ides of March"), use an event.

### Pass 4 — Inventory themes

After the entities, relations, and events are listed, step back: what 3-7 abstract themes does this chunk develop? Examples:

- "Loyalty vs. ambition" (in a political drama)
- "The corrupting nature of power"
- "Grief and memory"
- "Industrialization and the loss of nature"

For each theme, link the entities and events that exemplify it. Themes are how downstream QA finds thematic answers ("what does this book say about ___?").

Don't invent themes that aren't actually developed in this chunk — if a chunk is a battle scene, "the horror of war" might be apt, but "the bureaucracy of empire" probably isn't.

### Pass 5 — Validate before emitting

- Every relation's `subject` and `object` ID exists in `entities`.
- Every event's `participants` IDs exist in `entities`.
- Every theme's `related_entities` and `related_events` IDs exist.
- No duplicate IDs.
- IDs follow `<chunk_id>_<kind>_<NNN>` format.
- `chunk_id` field at top matches the input.

## Tone and style

- **Be conservative.** Better to under-extract than to invent. If you're unsure whether two names refer to the same person, list them as one entity with the second as an alias only if the chunk confirms it; otherwise list two entities and let the merger reconcile.
- **Stick to the text.** Don't import outside knowledge. If the chunk says Einstein is a baker, your ontology says Einstein is a baker.
- **Don't editorialize.** No "interestingly," no "perhaps the author means…". Descriptions are flat statements grounded in what the chunk asserts.
- **English snake_case for predicates regardless of source language.** The merger is language-aware for entity names but predicates are normalized to English snake_case so cross-chunk relations match.

## Output format

A single JSON object — no surrounding prose, no Markdown code fence, no commentary. The exact shape is in `ontology_schema.md`. The validator will reject anything else.

If you find yourself wanting to explain something, put it in a `description` or `context` field — those are what the QA stage uses to ground answers.
