#!/usr/bin/env python3
"""
OpenClaw Google Workspace Vector Memory Ingestion & RAG Sync Script.
Syncs Google Drive files and Gmail message threads into OpenClaw's Vector Memory SQLite database.
"""

import os
import sys
import json
import argparse
from tool_gateway import ToolGateway
from vector_memory import VectorMemoryEngine

def sync_workspace_to_vector_memory():
    gw = ToolGateway()
    mem_engine = VectorMemoryEngine()

    synced_count = 0

    # 1. Sync Drive Documents
    drive_res = gw.call_mcp_tool("drive_search_files", json.dumps({"query": "OpenClaw"}))
    output_drive = drive_res.get("output", {})
    files = output_drive.get("files", []) if isinstance(output_drive, dict) else []
    if not files:
        mem_engine.add_memory(f"Google Drive Query Result: {json.dumps(output_drive)}", session_id="workspace_rag")
        synced_count += 1
    else:
        for file_info in files:
            doc_text = f"Google Drive File: {file_info.get('name')} | MIME: {file_info.get('mimeType')} | Link: {file_info.get('webViewLink')}"
            mem_engine.add_memory(doc_text, session_id="workspace_rag")
            synced_count += 1

    # 2. Sync Priority Gmail Messages
    gmail_res = gw.call_mcp_tool("gmail_search", json.dumps({"query": "is:unread"}))
    output_gmail = gmail_res.get("output", {})
    messages = output_gmail.get("messages", []) if isinstance(output_gmail, dict) else []
    if not messages:
        mem_engine.add_memory(f"Gmail Query Result: {json.dumps(output_gmail)}", session_id="workspace_rag")
        synced_count += 1
    else:
        for msg in messages:
            msg_text = f"Gmail Message: {msg.get('subject')} | From: {msg.get('from')} | Snippet: {msg.get('snippet')}"
            mem_engine.add_memory(msg_text, session_id="workspace_rag")
            synced_count += 1

    return {
        "status": "success",
        "session_id": "workspace_rag",
        "synced_documents": synced_count,
        "drive_files": len(files),
        "gmail_messages": len(messages)
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Sync Google Workspace to OpenClaw Vector Memory")
    args = parser.parse_args()

    result = sync_workspace_to_vector_memory()
    print(json.dumps(result, indent=2))
