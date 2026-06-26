#!/usr/bin/env python3
"""
SAC Skills Vector Index Builder
================================
Generate vector embeddings for all skills in skills-index.json.
Output: skills-embeddings.json (skill_id -> embedding vector)

Usage:
    python scripts/skills-vector-index.py [--model MODEL]

Two modes:
    1. Local: uses sentence-transformers (all-MiniLM-L6-v2)
    2. API: uses OpenAI text-embedding-3-small (requires OPENAI_API_KEY env var)

Default mode: Local (no external dependencies beyond sentence-transformers).
"""

import json
import os
import sys
import argparse
from pathlib import Path

# Project root
ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / "skills-index.json"
OUTPUT_PATH = ROOT / "skills-embeddings.json"


def load_index():
    """Load skills-index.json."""
    with open(INDEX_PATH, "r", encoding="utf-8") as f:
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


def save_embeddings(skill_ids, embeddings):
    """Save embeddings to output file."""
    result = {}
    for sid, emb in zip(skill_ids, embeddings):
        if hasattr(emb, "tolist"):
            emb = emb.tolist()
        result[sid] = emb

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False)

    print(f"\nSaved {len(result)} embeddings to {OUTPUT_PATH}")


def main():
    parser = argparse.ArgumentParser(description="Build SAC skills vector index")
    parser.add_argument(
        "--model",
        choices=["local", "openai"],
        default="local",
        help="Embedding model to use (default: local)",
    )
    args = parser.parse_args()

    print(f"Loading index from {INDEX_PATH}")
    index = load_index()
    print(f"Found {len(index['skills'])} skills")

    skill_ids, texts = build_embedding_texts(index)

    print(f"\nEmbedding texts:")
    for sid, text in zip(skill_ids, texts):
        print(f"  [{sid}] {text[:80]}...")

    if args.model == "local":
        embeddings = build_local_embeddings(texts)
    else:
        embeddings = build_openai_embeddings(texts)

    save_embeddings(skill_ids, embeddings)

    # Summary
    total_tokens = sum(s.get("tokens", 0) for s in index["skills"])
    print(f"\n--- Summary ---")
    print(f"Skills indexed: {len(skill_ids)}")
    print(f"Total skill tokens (approx): {total_tokens}")
    print(f"Embedding dimension: {len(embeddings[0])}")
    print(f"Model: {args.model}")
    print("Done.")


if __name__ == "__main__":
    main()
