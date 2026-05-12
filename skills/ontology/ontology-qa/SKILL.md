---
name: ontology-qa
description: Answer questions about a book using its merged ontology / knowledge graph. Use whenever a user asks a question about a book they previously had processed by the book-to-knowledge-graph pipeline — character relationships ("who is X?", "how does X know Y?"), plot events ("what happens at the battle of Z?"), thematic analysis ("what does the book say about loyalty?"), or comparative questions ("which characters appear most often with X?"). Combines deterministic graph queries (via the bundled retrieval helper) with grounded synthesis so every answer cites the entities/relations/events/themes it drew from. Avoids hallucination by refusing to answer when the ontology lacks supporting evidence.
---

# Ontology Q&A

Answer questions about a book by querying its ontology and synthesizing grounded answers.

## When to run

Whenever the user asks a question and there is a merged ontology JSON available (typically `<book-slug>/ontology/merged.json` or any of the JSON exports from the storage skill). If the user uploads a freshly-exported ontology and asks "what does this book say about X?", that's this skill.

## Workflow per question

1. **Locate the ontology** — accept either a path the user gave you or scan `<book-slug>/ontology/merged.json` and `<book-slug>/exports/ontology.json`.
2. **Classify the question** — is it about a specific entity, a relationship between two entities, an event, a theme, or a global summary? The retrieval helper has a mode for each.
3. **Retrieve** with `scripts/query_ontology.py`. This returns a small JSON of relevant entities/relations/events with their context snippets.
4. **Synthesize** the answer in prose, citing the retrieved IDs and quoting their `context` fields where appropriate.
5. **Refuse to invent** — if retrieval comes back empty, say so. Don't fall back to general knowledge about the topic.

## Retrieval modes

```bash
python scripts/query_ontology.py --ontology <merged.json> --mode <mode> [args]
```

| Mode | Args | Use for |
|---|---|---|
| `entity` | `--name "..."` or `--id ent_NNNNN` | "Who is X?" — returns the entity record plus all relations involving it and all events it participates in. |
| `relationship` | `--a "..." --b "..."` | "How does X relate to Y?" — finds direct relations, shared events, shared themes, and (if no direct link) the shortest path through the graph up to 4 hops. |
| `event` | `--name "..."` or `--id evt_NNNNN` | "What happens at X?" — returns the event with all participants and location resolved. |
| `theme` | `--name "..."` or `--id thm_NNNNN` | "What does the book say about X?" — returns the theme with all linked entities and events. |
| `search` | `--query "..."` | Fuzzy text search across all canonical_names, aliases, and descriptions. Useful when you're not sure which entity the user means. |
| `summary` | (none) | Global summary: top-N entities by degree, count by type, theme list. Useful for "what is this book about?". |

The output is always JSON, suitable for you to read in one turn and synthesize from.

## Examples

### "Who is Hermione Granger?"

```bash
python scripts/query_ontology.py --ontology merged.json --mode entity --name "Hermione Granger"
```

Returns:
```json
{
  "entity": { "id": "ent_00012", "canonical_name": "Hermione Granger", "type": "Person", "description": "...", "aliases": ["Hermione"], ... },
  "relations_out": [ { "predicate": "friend_of", "object": "Harry Potter", "context": "..." }, ... ],
  "relations_in": [ ... ],
  "events": [ { "name": "Troll in the dungeon", "context": "..." } ],
  "themes": [ "Friendship", "Bravery" ]
}
```

Then synthesize: "Hermione Granger is described in the book as ... She is friends with Harry Potter (from chunk 3: '...'). She participates in the troll incident in chunk 2..."

### "What happens between Cassio and Iago?"

```bash
python scripts/query_ontology.py --ontology merged.json --mode relationship --a "Cassio" --b "Iago"
```

Returns all direct relations, shared events, shared themes. Synthesize the dynamic between them, quoting context where it helps the user.

### "What does this book say about death?"

```bash
python scripts/query_ontology.py --ontology merged.json --mode theme --name "death"
```

Returns the theme record, linked entities, linked events. Synthesize.

If the theme isn't extracted as a named theme but is implicit, fall back to:

```bash
python scripts/query_ontology.py --ontology merged.json --mode search --query "death"
```

This pulls everything mentioning death — events with "death" in the name, entities described with mortality language, themes adjacent to death.

## Answer style

Ground every claim in the retrieval output. The user is paying you (in tokens) to be specific:

- **Cite entity / event IDs in your reasoning** even if you don't show them to the user — it forces you to stay anchored.
- **Quote `context` snippets** when the user asks "where does it say that?" or for any claim that might be doubted.
- **Mark uncertainty** — if a relation's `confidence` is low, or if it was extracted from only one chunk, say so ("In one passage..."). High-confidence claims with many supporting chunks can be stated plainly ("Throughout the book...").
- **Refuse cleanly** when retrieval is empty: "The ontology I have for this book doesn't contain anything about [topic]. This could mean the topic isn't in the book, or that it wasn't picked up during extraction. Would you like me to search the raw chunks?"

## Falling back to raw chunks

If the ontology lacks the answer but the user is confident the book covers it, you can re-read the source chunks (`<book-slug>/chunks/chunk_NNNN.json`) and search them with grep/Python. This is much slower and burns more tokens, but it's the right thing to do for genuinely missing extractions.

```bash
python scripts/grep_chunks.py --chunks-dir <book-slug>/chunks/ --query "..."
```

This returns matching chunk IDs and snippets. Read the relevant chunks yourself and answer from them. Then suggest the user re-run extraction on those chunks if the gap is systematic.

## Limits

- **Comparative / aggregate questions** ("how many characters die?") may need to query the graph programmatically. The retrieval helper has limited aggregation; for complex queries, fall back to loading the ontology in Python and writing a one-liner.
- **Counterfactual / opinion questions** ("would X have survived if...?") aren't graph queries. Either treat them as creative-writing requests separate from the ontology, or decline if the user wanted a factual answer.
- **Cross-book questions** require a single ontology spanning both books. Re-run the pipeline with both books concatenated, or merge the two ontologies as described in `ontology-merging/references/disambiguation.md`.

## Reference files

- `references/query_patterns.md` — common question shapes and how to handle them.
- `scripts/query_ontology.py` — the retrieval helper.
- `scripts/grep_chunks.py` — chunk-level fallback search.
