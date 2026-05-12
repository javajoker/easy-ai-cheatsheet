# Query patterns

Reference for handling common question shapes. The point of this file isn't to enumerate everything a user might ask, but to give you (Claude) a stable mental model so you don't reinvent retrieval each time.

## "Who is X?" / "Tell me about X"

→ `mode=entity --name X`

Synthesis pattern: lead with the entity's `type` and `description`. Then summarize its outgoing relations grouped by predicate ("Friends: A, B, C. Enemies: D."). Then the most notable events it's in. Then themes it embodies.

If the user gives a name that doesn't match exactly, the retrieval helper falls back to substring match. If it returns nothing, run `mode=search` and present the top hits so the user can pick.

## "How does X relate to Y?"

→ `mode=relationship --a X --b Y`

If `direct_relations` is non-empty, lead with those. If only `shortest_path` is non-empty, the relationship is indirect — frame it as "they're connected through ..." and walk the path.

If neither direct nor path-based relations exist, say so plainly: "The ontology has no direct or indirect relationship between X and Y within four hops."

## "What happens in [event]?"

→ `mode=event --name "..."`

Lead with the date if known, then the description, then the participants (resolved to names) and location, then the context snippet quoting the book.

## "What does the book say about [topic]?"

Try two retrievals:

1. `mode=theme --name "..."` first — themes are the curated answer to thematic questions.
2. If no theme matches, `mode=search --query "..."` to pull entities/events/themes that mention it.

Synthesize what the book seems to be saying based on the evidence, but don't editorialize beyond what the descriptions and contexts assert. If the topic is barely mentioned, say "the book touches on this in [N places] but doesn't develop it as a central theme."

## "Who knows [character]?" / "Who fights [character]?"

→ `mode=entity --name X`, then filter the relations by predicate.

Or for general "show me everyone connected to X": just present `mode=entity` and let the user pick.

## "What's this book about?" / "Summarize"

→ `mode=summary`

Synthesize a 2-3 paragraph summary using:
- the principal characters (by degree)
- the major themes
- the top-frequency events
- the most-connected places

Don't try to retell the plot — the ontology isn't plot-structured. It's a relational summary, which is honest about what the data supports.

## "Find me passages where X happens"

→ Mostly out of scope for the ontology. The ontology has `context` snippets attached to relations/events, which work for short-form lookups. For "find every passage where Anna cries", the contexts will catch some but not all. Fall back to `grep_chunks.py` with a regex.

## "List all [characters/places/events] in the book"

→ `mode=summary` returns counts and the top-N. For a full list:

```bash
jq '.entities[] | select(.type=="Person") | .canonical_name' merged.json
```

(Or load the JSON in Python and filter — easier to read in conversation.)

## Aggregation questions

"How many characters die?" "How many battles?" "What's the most-mentioned place?"

These are programmatic. Load the JSON, write a one-liner. Example:

```python
import json, collections
o = json.load(open("merged.json"))
deaths = [r for r in o["relations"] if r["predicate"] in {"kills", "killed", "dies"}]
victims = collections.Counter(r["object"] for r in deaths if r["predicate"] == "kills")
print("Top victims by mention:", victims.most_common(10))
```

For the user, summarize the answer and offer to show the code if they want to verify.

## Adversarial / out-of-ontology questions

"What is [character]'s favourite colour?" — almost certainly not in the ontology unless it's plot-relevant. Search, then say honestly: "The ontology doesn't have an attribute for that, and a substring search of the descriptions doesn't return anything either."

"What does [character] think about [character]?" — partly in relations (predicates like `loves`, `respects`, `mistrusts`), partly in description text. Retrieve and report what you find; flag what you don't.

## Refusal templates

When retrieval is genuinely empty:

> "I queried the ontology of *<book>* for <topic>, and there are no matching entities, events, or themes. This either means the book doesn't substantially address this, or the extraction pass missed it. I can run a full-text search of the source chunks if you'd like — that'll find any mention even if it wasn't extracted as a structured concept."

When the answer is uncertain because evidence is thin:

> "The ontology has one mention of this, from chunk X: '<context>'. That's the only evidence I can find. Take this with a grain of salt — single-chunk extractions are sometimes incidental rather than authoritative."

These templates are honest about what the ontology supports and what it doesn't, which is the whole point of grounding the QA in the graph.
