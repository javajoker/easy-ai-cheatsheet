# Format specifications

## JSON-LD `@context`

The exported JSON-LD uses this context (defined in `export_ontology.py`):

```json
{
  "@vocab": "https://example.org/book/vocab#",
  "schema": "https://schema.org/",
  "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
  "name": "schema:name",
  "description": "schema:description",
  "alternateName": "schema:alternateName",
  "Person": "schema:Person",
  "Place": "schema:Place",
  "Organization": "schema:Organization",
  "Work": "schema:CreativeWork",
  "Event": "schema:Event",
  "Concept": "schema:DefinedTerm",
  "Object": "schema:Product",
  "Other": "schema:Thing",
  "participants": { "@type": "@id" },
  "location": { "@type": "@id" }
}
```

Custom predicates (anything from the relations array) live under the default vocab IRI — e.g. `knows`, `child_of`, `located_in` become `https://example.org/book/vocab#knows`, etc. Set `--base-iri` to your own domain if you're publishing the graph.

## Turtle prefix declarations

```turtle
@prefix schema: <https://schema.org/> .
@prefix rdfs:   <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix book:   <https://example.org/book/vocab#> .
@prefix ex:     <https://example.org/book/> .
```

Entity IRIs are `ex:ent_00001`, etc. Relations use `book:<predicate>`.

## GraphML key catalogue

| Key id | For | Attribute name | Type | Description |
|---|---|---|---|---|
| `nlabel` | node | `label` | string | Display name (canonical_name for entities, name for events/themes) |
| `ntype` | node | `type` | string | `Person`, `Place`, ..., `Event`, `Theme` |
| `ndesc` | node | `description` | string | Description text |
| `nsal` | node | `salience` | double | 0..1 importance, optional |
| `naliases` | node | `aliases` | string | Semicolon-separated alias list |
| `elabel` | edge | `predicate` | string | Relation predicate or `participated_in`, `located_at`, `theme_includes` |
| `econf` | edge | `confidence` | double | 0..1 confidence, optional |
| `eclass` | edge | `kind` | string | `relation`, `participation`, `location`, or `theme` |

In Gephi, set node colour by `type` and node size by `salience` for a quick informative visualization.

## Markdown structure

```
# Ontology of *Title*

**Author:** ...
**Entities:** N
**Relations:** N
**Events:** N
**Themes:** N
**Source chunks:** N

---

## Principal characters
- ...

## Places
- ...

## Organizations
- ...

## Notable objects / Concepts / Works referenced
- ...

## Events
- (chronologically sorted)

## Themes
### Theme name
description...
_Entities:_ A, B, C
_Events:_ X, Y

## Relationship index
| Subject | Predicate | Object |
```

Pipe characters in entity names are escaped (`|` → `\|`) so they don't break tables.

## Round-trip semantics

- **JSON** is the only fully round-trippable format. `--lean` strips provenance/mentions, which the merger doesn't need for re-import but which the QA stage uses for citations — so don't use `--lean` if you'll be running QA against the exported file.
- **JSON-LD** can be re-loaded by RDF tools but loses the `merge_report` block and the chunk-id provenance arrays (chunk_ids on relations and themes). Re-importing into our merger from JSON-LD is not supported.
- **Turtle** same as JSON-LD.
- **GraphML** loses `attributes` (the open-ended key-value map on entities). Only canonical_name, type, description, salience, aliases survive. Events lose their `consequences` field (no easy GraphML representation as edges between events without ambiguity with relations).
- **Markdown** is for humans. Don't try to re-parse it.

## Validating exports

```bash
# JSON: re-validate against schema
python ../ontology-extraction/scripts/validate_ontology.py --merged ontology.json

# JSON-LD: try json-ld processor
pyld-format ontology.jsonld  # if pyld installed

# Turtle: parse with rdflib
python -c "import rdflib; g=rdflib.Graph(); g.parse('ontology.ttl', format='turtle'); print(len(g), 'triples')"

# GraphML: load with networkx
python -c "import networkx as nx; g=nx.read_graphml('ontology.graphml'); print(len(g.nodes), 'nodes', len(g.edges), 'edges')"
```
