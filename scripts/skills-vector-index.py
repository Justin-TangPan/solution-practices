#!/usr/bin/env python3
"""
SAC Skills Vector Index Builder
================================
Generate vector embeddings for all skills in skills-index.json.
Output: skills-embeddings.json (skill_id -> embedding vector)

Includes:
- Embedding hash fingerprint for staleness detection
- Zero-dependency keyword fallback matcher (pure Python)

Usage:
    python scripts/skills-vector-index.py [--model MODEL]
    python scripts/skills-vector-index.py --verify   # check if embeddings are stale

Two modes:
    1. Local: uses sentence-transformers (all-MiniLM-L6-v2)
    2. API: uses OpenAI text-embedding-3-small (requires OPENAI_API_KEY env var)

Default mode: Local (no external dependencies beyond sentence-transformers).
Embeddings are committed to repo; runtime never needs the model.
"""

import json
import os
import sys
import argparse
import hashlib
from pathlib import Path

# Project root
ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / "skills-index.json"
OUTPUT_PATH = ROOT / "skills-embeddings.json"


# ── Embedding hash ──────────────────────────────────────────────────────────

def compute_index_hash(index):
    """Compute a deterministic fingerprint of the index content (skill metadata
    used for embedding). Returns a short hex digest.

    Any change to skill names, descriptions, keywords, or categories will
    produce a different hash, signalling that embeddings should be regenerated.
    """
    payload = []
    for skill in index.get("skills", []):
        block = {
            "id": skill.get("id", ""),
            "name": skill.get("name", ""),
            "compressed_description": skill.get("compressed_description", ""),
            "keywords": skill.get("keywords", []),
            "category": skill.get("category", ""),
        }
        payload.append(block)
    raw = json.dumps(payload, sort_keys=True, ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()[:16]


def verify_embeddings_stale(index, embeddings_path):
    """Check whether the on-disk embeddings match the current index hash.

    Returns (is_stale: bool, current_hash: str, stored_hash: str | None).
    """
    current_hash = compute_index_hash(index)

    if not embeddings_path.exists():
        return True, current_hash, None

    try:
        with open(embeddings_path, "r", encoding="utf-8-sig") as f:
            stored = json.load(f)
    except (json.JSONDecodeError, IOError):
        return True, current_hash, None

    stored_hash = stored.get("_index_hash")
    is_stale = stored_hash != current_hash
    return is_stale, current_hash, stored_hash


# ── Zero-dependency keyword fallback matcher ────────────────────────────────

def keyword_match_skills(query: str, index: dict, top_n: int = 3) -> list:
    """Pure-Python keyword-based skill matcher with zero external dependencies.

    Scores each skill by counting how many of its keywords appear in the query.
    Handles Chinese and English queries. Returns list of (skill_id, score, skill_dict).
    """
    import re

    if not query or not query.strip():
        return []

    # Normalise query: lowercase for English, keep Chinese as-is
    query_lower = query.lower()

    scored = []
    for skill in index.get("skills", []):
        score = 0
        keywords = skill.get("keywords", [])
        name = skill.get("name", "")
        desc = skill.get("compressed_description", "")

        # Score 1: keyword hits
        for kw in keywords:
            kw_lower = kw.lower()
            if kw_lower in query_lower:
                score += 2  # direct keyword match
            # Also check individual characters in Chinese keywords
            # (e.g. "模板" matching "模板开发" even when query says "terraform模板")
            elif len(kw) >= 2 and any(c in query_lower for c in kw_lower):
                score += 1

        # Score 2: name/description word overlap
        name_words = set(re.findall(r"[\w一-鿿]+", name.lower()))
        desc_words = set(re.findall(r"[\w一-鿿]+", desc.lower()))
        query_words = set(re.findall(r"[\w一-鿿]+", query_lower))

        name_overlap = len(name_words & query_words)
        desc_overlap = len(desc_words & query_words)

        score += name_overlap * 3      # name match is strong signal
        score += desc_overlap * 1      # description match is weaker

        if score > 0:
            scored.append((score, skill["id"], skill))

    # Sort descending by score
    scored.sort(key=lambda x: -x[0])
    return scored[:top_n]


# ── Embedding builders ──────────────────────────────────────────────────────

def load_index():
    """Load skills-index.json."""
    with open(INDEX_PATH, "r", encoding="utf-8-sig") as f:
        return json.load(f)


def build_embedding_texts(index):
    """Build embedding text for each skill."""
    texts = []
    skill_ids = []

    for skill in index["skills"]:
        text_parts = [
            skill.get("name", ""),
            skill.get("compressed_description", ""),
        ]
        keywords = skill.get("keywords", [])
        if keywords:
            text_parts.append("Keywords: " + ", ".join(keywords))

        category = skill.get("category", "")
        if category:
            text_parts.append(f"Category: {category}")

        text = ". ".join(text_parts)
        texts.append(text)
        skill_ids.append(skill["id"])

    return skill_ids, texts


def build_local_embeddings(texts):
    """Build embeddings using sentence-transformers (local)."""
    try:
        from sentence_transformers import SentenceTransformer
    except ImportError:
        print("ERROR: sentence-transformers not installed.")
        print("Install: pip install sentence-transformers")
        print("Or use --model openai for API-based embeddings.")
        sys.exit(1)

    print(f"Loading model: all-MiniLM-L6-v2 ...")
    model = SentenceTransformer("all-MiniLM-L6-v2")
    print(f"Encoding {len(texts)} texts ...")
    embeddings = model.encode(texts, show_progress_bar=True)
    return embeddings


def build_openai_embeddings(texts):
    """Build embeddings using OpenAI API."""
    try:
        from openai import OpenAI
    except ImportError:
        print("ERROR: openai package not installed.")
        print("Install: pip install openai")
        sys.exit(1)

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY environment variable not set.")
        sys.exit(1)

    client = OpenAI(api_key=api_key)
    model = "text-embedding-3-small"

    print(f"Encoding {len(texts)} texts using OpenAI {model} ...")
    response = client.embeddings.create(input=texts, model=model)
    embeddings = [item.embedding for item in response.data]
    return embeddings


# ── Output ──────────────────────────────────────────────────────────────────

def save_embeddings(skill_ids, embeddings, index_hash):
    """Save embeddings to output file with hash fingerprint."""
    result = {"_index_hash": index_hash}
    for sid, emb in zip(skill_ids, embeddings):
        if hasattr(emb, "tolist"):
            emb = emb.tolist()
        result[sid] = emb

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False)

    print(f"\nSaved {len(skill_ids)} embeddings to {OUTPUT_PATH}")
    print(f"Index hash: {index_hash}")


# ── CLI ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Build SAC skills vector index")
    parser.add_argument(
        "--model",
        choices=["local", "openai"],
        default="local",
        help="Embedding model to use (default: local)",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Check if on-disk embeddings are stale (no generation)",
    )
    parser.add_argument(
        "--keyword-demo",
        type=str,
        metavar="QUERY",
        help="Run keyword fallback matcher demo with QUERY and exit",
    )
    args = parser.parse_args()

    print(f"Loading index from {INDEX_PATH}")
    index = load_index()
    print(f"Found {len(index['skills'])} skills")

    # ── Keyword demo mode ──
    if args.keyword_demo:
        print(f"\n--- Keyword fallback matcher demo ---")
        print(f"Query: {args.keyword_demo}")
        results = keyword_match_skills(args.keyword_demo, index)
        print(f"Top {len(results)} matches:")
        for score, sid, skill in results:
            print(f"  [{score:3d}] {sid} — {skill['name']}")
        return

    # ── Verify mode ──
    if args.verify:
        is_stale, current_hash, stored_hash = verify_embeddings_stale(index, OUTPUT_PATH)
        if stored_hash is None:
            print(f"\n!!  Embeddings file not found at {OUTPUT_PATH}")
            print("   Run without --verify to generate.")
            sys.exit(1)
        if is_stale:
            print(f"\n!!  Embeddings are STALE")
            print(f"   Stored hash: {stored_hash}")
            print(f"   Current hash: {current_hash}")
            print("   Run without --verify to regenerate.")
            sys.exit(1)
        else:
            print(f"\n++  Embeddings are up-to-date (hash: {current_hash})")
            return

    # ── Generate mode ──

    # Check staleness first
    is_stale, current_hash, stored_hash = verify_embeddings_stale(index, OUTPUT_PATH)
    if not is_stale and OUTPUT_PATH.exists():
        print(f"++  Embeddings already up-to-date (hash: {current_hash}) — nothing to do.")
        return

    if is_stale and stored_hash:
        print(f"!!  Embeddings stale (stored: {stored_hash}, index: {current_hash}) — regenerating...")
    elif stored_hash is None:
        print(f"ii  No existing embeddings found — generating fresh...")

    skill_ids, texts = build_embedding_texts(index)

    print(f"\nEmbedding texts:")
    for sid, text in zip(skill_ids, texts):
        print(f"  [{sid}] {text[:80]}...")

    if args.model == "local":
        embeddings = build_local_embeddings(texts)
    else:
        embeddings = build_openai_embeddings(texts)

    save_embeddings(skill_ids, embeddings, current_hash)

    # Summary
    print(f"\n--- Summary ---")
    print(f"Skills indexed: {len(skill_ids)}")
    print(f"Embedding dimension: {len(embeddings[0])}")
    print(f"Model: {args.model}")
    print(f"Index hash: {current_hash}")
    print("Done.")


if __name__ == "__main__":
    main()
