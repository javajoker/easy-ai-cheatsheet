#!/usr/bin/env python3
"""
grep_chunks.py — Fallback chunk-level text search for ontology-qa.

Use when the ontology doesn't contain something the user is asking about but
the book might. Streams through each chunk's text and returns matching
snippets with their chunk IDs.

Usage:
  python grep_chunks.py --chunks-dir <book>/chunks/ --query "phrase to find" \
      --context 200 --limit 20
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path


def fold(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    return s.encode("ascii", "ignore").decode("ascii").lower()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--chunks-dir", type=Path, required=True)
    p.add_argument("--query", required=True, help="Substring to search for (case-insensitive, accent-folded).")
    p.add_argument("--context", type=int, default=200, help="Chars of context around each hit.")
    p.add_argument("--limit", type=int, default=20, help="Max hits to return.")
    p.add_argument("--regex", action="store_true", help="Treat --query as a Python regex.")
    p.add_argument("--out", type=Path, help="Write JSON to this path; otherwise stdout.")
    args = p.parse_args()

    if not args.chunks_dir.is_dir():
        p.error(f"--chunks-dir not a directory: {args.chunks_dir}")

    pattern: re.Pattern
    if args.regex:
        pattern = re.compile(args.query, re.IGNORECASE)
    else:
        # We'll match against folded text and recover positions in the original
        # by using the same lowercase-cased original (accents kept). For simple
        # English queries this is fine; for non-ASCII, the regex mode is safer.
        pattern = re.compile(re.escape(args.query), re.IGNORECASE)

    hits: list[dict] = []
    chunk_files = sorted(args.chunks_dir.glob("chunk_*.json"))
    for cf in chunk_files:
        with open(cf, "r", encoding="utf-8") as f:
            data = json.load(f)
        text = data.get("text", "")
        if not text:
            continue
        haystack = text if args.regex else fold(text)
        needle = args.query if args.regex else fold(args.query)
        if not args.regex:
            # use the folded-text indices on the original text — works for ASCII queries
            for m in re.finditer(re.escape(needle), haystack):
                start = max(0, m.start() - args.context)
                end = min(len(text), m.end() + args.context)
                hits.append({
                    "chunk_id": data["chunk_id"],
                    "char_offset": m.start(),
                    "snippet": text[start:end].replace("\n", " "),
                })
                if len(hits) >= args.limit:
                    break
        else:
            for m in pattern.finditer(text):
                start = max(0, m.start() - args.context)
                end = min(len(text), m.end() + args.context)
                hits.append({
                    "chunk_id": data["chunk_id"],
                    "char_offset": m.start(),
                    "snippet": text[start:end].replace("\n", " "),
                })
                if len(hits) >= args.limit:
                    break
        if len(hits) >= args.limit:
            break

    result = {
        "query": args.query,
        "regex": args.regex,
        "hits": hits,
        "truncated": len(hits) >= args.limit,
    }
    text = json.dumps(result, ensure_ascii=False, indent=2)
    if args.out:
        args.out.write_text(text, encoding="utf-8")
        print(f"✓ wrote {len(hits)} hit(s) to {args.out}")
    else:
        print(text)


if __name__ == "__main__":
    main()
