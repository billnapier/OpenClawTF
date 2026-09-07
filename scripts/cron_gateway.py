#!/usr/bin/env python3
"""
OpenClaw Autonomous Cron Gateway & Task Scheduler Engine.
Persists job definitions and execution locks in SQLite.
"""

import os
import sys
import json
import sqlite3
import argparse

DB_PATH = os.environ.get("CRON_DB_PATH", "/tmp/openclaw_cron.db")

def init_db(db_path=DB_PATH):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS cron_jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            schedule TEXT NOT NULL,
            prompt TEXT NOT NULL,
            channel TEXT DEFAULT 'telegram',
            status TEXT DEFAULT 'active'
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS cron_locks (
            job_id INTEGER PRIMARY KEY,
            locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    return conn

class CronGateway:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        self.conn = init_db(db_path)

    def add_job(self, schedule, prompt, channel="telegram"):
        cur = self.conn.cursor()
        cur.execute(
            "INSERT INTO cron_jobs (schedule, prompt, channel) VALUES (?, ?, ?)",
            (schedule, prompt, channel)
        )
        self.conn.commit()
        job_id = cur.lastrowid
        return {"status": "success", "job_id": job_id, "message": f"Cron job #{job_id} scheduled ({schedule})."}

    def list_jobs(self):
        cur = self.conn.cursor()
        cur.execute("SELECT id, schedule, prompt, channel, status FROM cron_jobs WHERE status = 'active'")
        rows = cur.fetchall()
        jobs = [{"id": r[0], "schedule": r[1], "prompt": r[2], "channel": r[3], "status": r[4]} for r in rows]
        return {"status": "success", "jobs": jobs}

    def remove_job(self, job_id):
        cur = self.conn.cursor()
        cur.execute("UPDATE cron_jobs SET status = 'cancelled' WHERE id = ?", (job_id,))
        self.conn.commit()
        return {"status": "success", "message": f"Cron job #{job_id} removed."}

    def trigger_tick(self, job_id):
        cur = self.conn.cursor()
        # Acquire atomic execution lock
        try:
            cur.execute("INSERT INTO cron_locks (job_id) VALUES (?)", (job_id,))
            self.conn.commit()
        except sqlite3.IntegrityError:
            return {"status": "locked", "message": f"Job #{job_id} is already locked by another process."}

        cur.execute("SELECT prompt, channel FROM cron_jobs WHERE id = ?", (job_id,))
        row = cur.fetchone()
        if not row:
            return {"status": "error", "message": "Job not found"}

        prompt, channel = row
        return {
            "status": "executed",
            "job_id": job_id,
            "channel": channel,
            "dispatch_text": f"[CRON DISPATCH] Executed background job: {prompt}"
        }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Cron Gateway Engine CLI")
    parser.add_argument("--db", type=str, default=DB_PATH)
    parser.add_argument("--add", action="store_true")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--remove", type=int, help="Job ID to remove")
    parser.add_argument("--trigger", type=int, help="Job ID to trigger tick")
    parser.add_argument("--schedule", type=str, default="0 8 * * *")
    parser.add_argument("--prompt", type=str, default="Daily Summary")
    args = parser.parse_args()

    gw = CronGateway(args.db)
    if args.add:
        print(json.dumps(gw.add_job(args.schedule, args.prompt)))
    elif args.list:
        print(json.dumps(gw.list_jobs()))
    elif args.remove is not None:
        print(json.dumps(gw.remove_job(args.remove)))
    elif args.trigger is not None:
        print(json.dumps(gw.trigger_tick(args.trigger)))
    else:
        print(json.dumps({"status": "ready"}))
