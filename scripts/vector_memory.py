#!/usr/bin/env python3
"""
OpenClaw Vector Memory & Semantic Search Engine.
Stores memories and embeddings in SQLite on persistent disk.
"""

import os
import sys
import json
import sqlite3
import math
import argparse

DB_PATH = os.environ.get("VECTOR_DB_PATH", "/tmp/openclaw_vector_memory.db")

def init_db(db_path=DB_PATH):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS memories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            text TEXT NOT NULL,
            embedding TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            role TEXT DEFAULT 'user'
        )
    """)
    # Additive migration: existing DBs created before the `role` column existed
    # won't have it yet — add it if missing (backward compatible, no data loss).
    cur.execute("PRAGMA table_info(memories)")
    existing_cols = {row[1] for row in cur.fetchall()}
    if "role" not in existing_cols:
        try:
            cur.execute("ALTER TABLE memories ADD COLUMN role TEXT DEFAULT 'user'")
        except sqlite3.OperationalError:
            # Two concurrent callers (e.g. two `openclaw chat` processes) can both
            # see "role" missing and both attempt the ALTER TABLE; the loser hits
            # "duplicate column name" once the winner's DDL has committed. That's
            # fine — the column already exists, so there's nothing left to do.
            pass
    conn.commit()
    return conn

def simple_embed(text):
    """Generates a deterministic 16-dim pseudo embedding for testing/offline usage."""
    words = text.lower().split()
    vec = [0.0] * 16
    for i, word in enumerate(words):
        h = hash(word) % 16
        vec[h] += 1.0
    norm = math.sqrt(sum(x*x for x in vec)) or 1.0
    return [x / norm for x in vec]

def cosine_similarity(v1, v2):
    dot = sum(a*b for a, b in zip(v1, v2))
    n1 = math.sqrt(sum(a*a for a in v1)) or 1.0
    n2 = math.sqrt(sum(b*b for b in v2)) or 1.0
    return dot / (n1 * n2)

class VectorMemoryEngine:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        self.conn = init_db(db_path)

    def add_memory(self, text, session_id="default", role="user"):
        vec = simple_embed(text)
        cur = self.conn.cursor()
        cur.execute(
            "INSERT INTO memories (session_id, text, embedding, role) VALUES (?, ?, ?, ?)",
            (session_id, text, json.dumps(vec), role)
        )
        self.conn.commit()
        return cur.lastrowid

    def get_recent(self, session_id="default", limit=20):
        """Return the last `limit` turns for session_id in chronological order
        (oldest first), for linear conversation context — complements
        search_memory()'s similarity-ranked retrieval, which is not sufficient
        on its own for 'recall the last few turns' recall behavior."""
        cur = self.conn.cursor()
        cur.execute(
            "SELECT id, text, role, created_at FROM memories WHERE session_id = ? "
            "ORDER BY created_at DESC, id DESC LIMIT ?",
            (session_id, limit)
        )
        rows = cur.fetchall()
        rows.reverse()  # chronological oldest-first
        return [
            {"id": row_id, "text": text, "role": role, "created_at": created_at}
            for row_id, text, role, created_at in rows
        ]

    def search_memory(self, query, session_id="default", top_k=3):
        q_vec = simple_embed(query)
        cur = self.conn.cursor()
        cur.execute("SELECT id, text, embedding FROM memories WHERE session_id = ?", (session_id,))
        rows = cur.fetchall()

        results = []
        for row_id, text, vec_json in rows:
            vec = json.loads(vec_json)
            sim = cosine_similarity(q_vec, vec)
            results.append({"id": row_id, "text": text, "similarity": round(sim, 4)})

        results.sort(key=lambda x: x["similarity"], reverse=True)
        return results[:top_k]

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Vector Memory Engine CLI")
    parser.add_argument("--db", type=str, default=DB_PATH)
    parser.add_argument("--remember", type=str, help="Text to remember")
    parser.add_argument("--search", type=str, help="Query text")
    parser.add_argument("--session", type=str, default="default")
    args = parser.parse_args()

    engine = VectorMemoryEngine(args.db)
    if args.remember:
        mem_id = engine.add_memory(args.remember, session_id=args.session)
        print(json.dumps({"status": "success", "id": mem_id, "message": "Memory stored successfully."}))
    elif args.search:
        results = engine.search_memory(args.search, session_id=args.session)
        print(json.dumps({"status": "success", "results": results}))
    else:
        print(json.dumps({"status": "ready", "db": args.db}))
