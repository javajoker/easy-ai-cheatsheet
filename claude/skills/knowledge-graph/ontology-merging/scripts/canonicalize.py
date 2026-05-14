"""
canonicalize.py — Name-normalization helpers for entity matching.

Importable by merge_ontologies.py. Kept as a tiny separate module so it can
also be reused by ontology-qa for query-side name matching.
"""

from __future__ import annotations

import re
import unicodedata

# Common honorifics / titles we strip to get to the "core" of a name.
# Conservative list — we don't want to strip meaningful name parts.
HONORIFICS = {
    "mr", "mrs", "ms", "miss", "mx",
    "dr", "doctor", "prof", "professor",
    "sir", "lady", "lord", "dame",
    "king", "queen", "prince", "princess",
    "duke", "duchess", "earl", "count", "countess", "baron", "baroness",
    "saint", "st",
    "father", "mother", "brother", "sister",
    "captain", "lieutenant", "colonel", "general", "major", "sergeant", "private",
    "rev", "reverend",
}

# Articles / particles we don't strip but normalize for comparison.
PARTICLES = {"de", "la", "le", "du", "des", "von", "van", "der", "den", "the", "of", "and", "&"}

_WS = re.compile(r"\s+")
_PUNCT = re.compile(r"[^\w\s'-]")    # keep apostrophes and hyphens, drop other punctuation


def fold(s: str) -> str:
    """Unicode NFKD-fold and lowercase — handles accents, full-width chars, etc."""
    s = unicodedata.normalize("NFKD", s)
    s = s.encode("ascii", "ignore").decode("ascii")
    return s.lower()


def normalize(name: str) -> str:
    """Aggressive normalization for comparison: fold, strip punct, collapse ws."""
    if not name:
        return ""
    s = fold(name)
    s = _PUNCT.sub(" ", s)
    s = _WS.sub(" ", s).strip()
    return s


def strip_honorifics(name: str) -> str:
    """Remove leading/trailing honorifics. 'Dr. John Smith' -> 'John Smith'."""
    n = normalize(name)
    if not n:
        return ""
    toks = n.split()
    # strip leading honorifics
    while toks and toks[0] in HONORIFICS:
        toks.pop(0)
    # strip trailing suffixes that act like honorifics ("Jr", "Sr", "PhD")
    suffix = {"jr", "sr", "ii", "iii", "iv", "phd", "md", "esq"}
    while toks and toks[-1] in suffix:
        toks.pop()
    return " ".join(toks)


def core_tokens(name: str) -> frozenset[str]:
    """
    The 'core' content tokens of a name — for fuzzy partial matching.
    Strips honorifics and particles.

    'Mr. John H. Smith' -> {'john', 'h', 'smith'}
    'Lord John of York'  -> {'john', 'york'}    (note: 'of' dropped)
    """
    n = strip_honorifics(name)
    toks = [t for t in n.split() if t and t not in PARTICLES]
    return frozenset(toks)


def all_normalized_forms(canonical_name: str, aliases: list[str] | None) -> set[str]:
    """All the normalized strings an entity can be matched on."""
    forms: set[str] = set()
    if canonical_name:
        forms.add(normalize(canonical_name))
        sh = strip_honorifics(canonical_name)
        if sh:
            forms.add(sh)
    for a in aliases or []:
        if not a:
            continue
        forms.add(normalize(a))
        sh = strip_honorifics(a)
        if sh:
            forms.add(sh)
    forms.discard("")
    return forms


def confident_match(
    name_a: str, aliases_a: list[str],
    name_b: str, aliases_b: list[str],
) -> bool:
    """
    True if these two entities should be merged automatically.
    Caller is responsible for checking type equality first.
    """
    forms_a = all_normalized_forms(name_a, aliases_a)
    forms_b = all_normalized_forms(name_b, aliases_b)
    return bool(forms_a & forms_b)


def ambiguous_match(
    name_a: str, aliases_a: list[str],
    name_b: str, aliases_b: list[str],
) -> bool:
    """
    True if there's a partial token overlap but not a confident match.
    Caller can use this to flag for LLM disambiguation.
    """
    if confident_match(name_a, aliases_a, name_b, aliases_b):
        return False
    core_a: set[str] = set()
    core_b: set[str] = set()
    for n in [name_a, *(aliases_a or [])]:
        core_a |= core_tokens(n)
    for n in [name_b, *(aliases_b or [])]:
        core_b |= core_tokens(n)
    if not core_a or not core_b:
        return False
    overlap = core_a & core_b
    if not overlap:
        return False
    # Require the overlap to be at least one non-trivial token
    nontrivial = {t for t in overlap if len(t) >= 3}
    return bool(nontrivial)
