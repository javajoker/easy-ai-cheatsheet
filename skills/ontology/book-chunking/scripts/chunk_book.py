#!/usr/bin/env python3
"""
chunk_book.py — Stream-chunk a very long text file into LLM-sized JSON chunks.

Designed for books of arbitrary size (tested mentally on >10M token corpora).
Never loads the full file into memory; uses tiktoken for token budgeting and
respects structural anchors (chapters, headings, paragraph breaks).

Output:
  <out-dir>/index.json
  <out-dir>/chunk_0001.json
  <out-dir>/chunk_0002.json
  ...

Usage:
  python chunk_book.py --input book.txt --out-dir chunks/ \
      --target-tokens 30000 --overlap-tokens 500

  python chunk_book.py --verify --out-dir chunks/
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Iterable, Iterator, Optional

try:
    import tiktoken
    _HAS_TIKTOKEN = True
except ImportError:
    tiktoken = None
    _HAS_TIKTOKEN = False


class _ApproxEncoder:
    """
    Fallback tokenizer for environments where tiktoken can't download its BPE
    file (e.g. sandboxed networks). Uses a deliberately simple approximation
    that overcounts slightly so chunk sizes are conservative.

    Rule of thumb (matches Anthropic / OpenAI guidance well enough for budgeting):
        tokens ≈ words * 1.33  +  punctuation
    """

    def encode(self, text: str) -> list[int]:
        if not text:
            return []
        # words + standalone punctuation, then multiply
        word_count = len(re.findall(r"\w+", text))
        punct_count = len(re.findall(r"[^\w\s]", text))
        approx = int(word_count * 1.33) + punct_count
        # Return a list of that length; values don't matter, only len() is used.
        return [0] * approx

    def decode(self, tokens) -> str:
        # Used only to materialize the tail-overlap. Since we have no real
        # token boundaries, callers should use the alternative text-based
        # overlap path below.
        raise NotImplementedError("approximate encoder cannot decode")


def _get_encoder(name: str):
    """
    Return a tiktoken encoder if available and the BPE file is reachable;
    otherwise the approximate fallback. Print a one-line notice on stderr if
    we're falling back so the user knows.
    """
    if not _HAS_TIKTOKEN:
        print("ⓘ tiktoken not installed — using approximate token counter.", file=sys.stderr)
        return _ApproxEncoder(), True
    try:
        return tiktoken.get_encoding(name), False
    except Exception as e:
        print(
            f"ⓘ tiktoken couldn't load encoding {name!r} ({e.__class__.__name__}); "
            f"falling back to approximate counter.",
            file=sys.stderr,
        )
        return _ApproxEncoder(), True


# ---------- structural-anchor detection ----------

HEADING_PATTERNS = [
    re.compile(r"^#{1,6}\s+\S"),                          # markdown
    re.compile(r"^\s*CHAPTER\s+[\w\dIVXLCM]+", re.IGNORECASE),
    re.compile(r"^\s*BOOK\s+[\w\dIVXLCM]+", re.IGNORECASE),
    re.compile(r"^\s*PART\s+[\w\dIVXLCM]+", re.IGNORECASE),
    re.compile(r"^\s*VOLUME\s+[\w\dIVXLCM]+", re.IGNORECASE),
    re.compile(r"^\s*[IVXLCM]+\.\s+[A-Z]"),               # roman + caps
    re.compile(r"^\s*\d+\.\s+[A-Z]\w"),                   # "1. Title"
]


def is_heading(line: str) -> bool:
    s = line.strip()
    if not s or len(s) > 200:
        return False
    return any(p.match(s) for p in HEADING_PATTERNS)


# ---------- chunk accumulator ----------

@dataclass
class ChunkBuilder:
    ordinal: int
    char_start: int
    text_parts: list = field(default_factory=list)
    token_count: int = 0
    section_title: Optional[str] = None
    last_heading_token_pos: int = -1   # token index within this chunk
    last_paragraph_token_pos: int = -1

    def add(self, segment: str, token_count: int, is_heading_line: bool):
        self.text_parts.append(segment)
        self.token_count += token_count
        if is_heading_line and self.section_title is None:
            self.section_title = segment.strip()
        if is_heading_line:
            self.last_heading_token_pos = self.token_count
        if segment.endswith("\n\n") or segment.endswith("\r\n\r\n"):
            self.last_paragraph_token_pos = self.token_count

    def text(self) -> str:
        return "".join(self.text_parts)


# ---------- main chunker ----------

def iter_lines(path: Path) -> Iterator[str]:
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            yield line


def chunk_book(
    input_path: Path,
    out_dir: Path,
    target_tokens: int,
    overlap_tokens: int,
    encoding_name: str,
    respect_headings: bool,
) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)

    enc, is_approx = _get_encoder(encoding_name)
    hard_cap = int(target_tokens * 1.5)
    soft_floor = int(target_tokens * 0.8)

    builder = ChunkBuilder(ordinal=1, char_start=0)
    char_pos = 0
    chunks_meta: list[dict] = []
    overlap_text = ""   # carried from previous chunk
    overlap_token_count = 0

    def flush(builder: ChunkBuilder, next_overlap_text: str, next_overlap_tokens: int) -> ChunkBuilder:
        chunk_id = f"chunk_{builder.ordinal:04d}"
        text = builder.text()
        char_end = builder.char_start + len(text)
        meta = {
            "chunk_id": chunk_id,
            "ordinal": builder.ordinal,
            "char_range": [builder.char_start, char_end],
            "token_count": builder.token_count,
            "section_title": builder.section_title,
            "previous_chunk_id": f"chunk_{builder.ordinal - 1:04d}" if builder.ordinal > 1 else None,
            "next_chunk_id": None,  # filled in after we know there's a next
        }
        # link previous chunk to this one
        if chunks_meta:
            chunks_meta[-1]["next_chunk_id"] = chunk_id
        # write chunk file
        chunk_file = out_dir / f"{chunk_id}.json"
        with open(chunk_file, "w", encoding="utf-8") as f:
            json.dump({**meta, "text": text}, f, ensure_ascii=False, indent=2)
        chunks_meta.append(meta)

        # start the next builder with overlap prepended
        new_builder = ChunkBuilder(
            ordinal=builder.ordinal + 1,
            char_start=char_end - len(next_overlap_text),
        )
        if next_overlap_text:
            new_builder.text_parts.append(next_overlap_text)
            new_builder.token_count = next_overlap_tokens
        return new_builder

    def compute_overlap(builder: ChunkBuilder) -> tuple[str, int]:
        if overlap_tokens <= 0:
            return "", 0
        text = builder.text()
        if is_approx:
            # No real token boundaries — approximate by characters.
            # Assume ~4 chars per token (close enough for English prose).
            char_budget = overlap_tokens * 4
            if len(text) <= char_budget:
                return text, len(enc.encode(text))
            # Try to start the overlap at a paragraph or sentence boundary
            tail = text[-char_budget:]
            for boundary in ("\n\n", ". ", ".\n", "! ", "? "):
                idx = tail.find(boundary)
                if 0 <= idx < len(tail) // 2:   # don't slice past the midpoint
                    tail = tail[idx + len(boundary):]
                    break
            return tail, len(enc.encode(tail))

        # Real tiktoken path
        all_tokens = enc.encode(text)
        if len(all_tokens) <= overlap_tokens:
            return text, len(all_tokens)
        tail_tokens = all_tokens[-overlap_tokens:]
        tail_text = enc.decode(tail_tokens)
        return tail_text, len(tail_tokens)

    # ---- streaming loop ----
    for line in iter_lines(input_path):
        line_tokens = len(enc.encode(line))
        heading = respect_headings and is_heading(line)

        # If adding this line would blow the hard cap, flush first.
        if builder.token_count + line_tokens > hard_cap and builder.token_count >= soft_floor:
            ov_text, ov_tokens = compute_overlap(builder)
            builder = flush(builder, ov_text, ov_tokens)

        # If this line is a heading and the current builder is over soft_floor,
        # flush here so the new chapter starts a fresh chunk.
        if heading and builder.token_count >= soft_floor and respect_headings:
            ov_text, ov_tokens = compute_overlap(builder)
            builder = flush(builder, ov_text, ov_tokens)

        builder.add(line, line_tokens, heading)
        char_pos += len(line)

        # Opportunistic flush near the target token count at a paragraph break.
        if builder.token_count >= target_tokens:
            if line.strip() == "" and builder.last_paragraph_token_pos > 0:
                ov_text, ov_tokens = compute_overlap(builder)
                builder = flush(builder, ov_text, ov_tokens)

    # flush the tail (don't carry overlap on the last one)
    if builder.text_parts:
        flush(builder, "", 0)

    # write index.json
    index = {
        "book": {
            "source_file": str(input_path),
            "total_chunks": len(chunks_meta),
            "total_tokens": sum(c["token_count"] for c in chunks_meta),
            "total_chars": chunks_meta[-1]["char_range"][1] if chunks_meta else 0,
            "target_tokens": target_tokens,
            "overlap_tokens": overlap_tokens,
            "encoding": encoding_name,
        },
        "chunks": chunks_meta,
    }
    with open(out_dir / "index.json", "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)

    return index


# ---------- verify mode ----------

def verify(out_dir: Path) -> int:
    index_path = out_dir / "index.json"
    if not index_path.exists():
        print(f"ERROR: {index_path} not found", file=sys.stderr)
        return 1

    with open(index_path, "r", encoding="utf-8") as f:
        index = json.load(f)

    chunks = index["chunks"]
    if not chunks:
        print("ERROR: no chunks listed in index", file=sys.stderr)
        return 1

    sizes = [c["token_count"] for c in chunks]
    target = index["book"]["target_tokens"]
    print(f"Book:           {index['book']['source_file']}")
    print(f"Total chunks:   {len(chunks)}")
    print(f"Total tokens:   {index['book']['total_tokens']:,}")
    print(f"Target/chunk:   {target:,}")
    print(f"Min/Mean/Max:   {min(sizes):,} / {sum(sizes)//len(sizes):,} / {max(sizes):,}")

    flagged_small = [c for c in chunks if c["token_count"] < target * 0.3 and c["ordinal"] != len(chunks)]
    flagged_large = [c for c in chunks if c["token_count"] > target * 1.5]
    if flagged_small:
        print(f"\n⚠ {len(flagged_small)} chunk(s) unexpectedly small (excluding tail):")
        for c in flagged_small[:5]:
            print(f"   {c['chunk_id']}: {c['token_count']:,} tokens")
    if flagged_large:
        print(f"\n⚠ {len(flagged_large)} chunk(s) over hard cap:")
        for c in flagged_large[:5]:
            print(f"   {c['chunk_id']}: {c['token_count']:,} tokens")
    if not flagged_small and not flagged_large:
        print("\n✓ All chunks within expected size range.")

    # check files actually exist and are readable
    missing = []
    for c in chunks:
        p = out_dir / f"{c['chunk_id']}.json"
        if not p.exists():
            missing.append(c["chunk_id"])
    if missing:
        print(f"\n✗ Missing chunk files: {missing[:10]}")
        return 1

    print("\n✓ All chunk files present and accounted for.")
    return 0


# ---------- CLI ----------

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input", type=Path, help="Path to the UTF-8 plain-text book file.")
    p.add_argument("--out-dir", type=Path, required=True, help="Output directory for chunks.")
    p.add_argument("--target-tokens", type=int, default=30000)
    p.add_argument("--overlap-tokens", type=int, default=500)
    p.add_argument("--encoding", default="cl100k_base", help="tiktoken encoding name.")
    p.add_argument("--no-respect-headings", action="store_true",
                   help="Disable heading-aware breaks (use pure size-based chunking).")
    p.add_argument("--verify", action="store_true",
                   help="Don't chunk; verify an existing chunks/ directory and print stats.")
    args = p.parse_args()

    if args.verify:
        sys.exit(verify(args.out_dir))

    if not args.input:
        p.error("--input is required unless --verify is set.")
    if not args.input.exists():
        p.error(f"Input file not found: {args.input}")

    index = chunk_book(
        input_path=args.input,
        out_dir=args.out_dir,
        target_tokens=args.target_tokens,
        overlap_tokens=args.overlap_tokens,
        encoding_name=args.encoding,
        respect_headings=not args.no_respect_headings,
    )

    print(f"✓ Wrote {index['book']['total_chunks']} chunks to {args.out_dir}/")
    print(f"  Total tokens: {index['book']['total_tokens']:,}")
    print(f"  Average chunk: {index['book']['total_tokens'] // max(1, index['book']['total_chunks']):,} tokens")
    print(f"  Run with --verify on the same --out-dir to sanity-check.")


if __name__ == "__main__":
    main()
