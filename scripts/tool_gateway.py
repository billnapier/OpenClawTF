#!/usr/bin/env python3
"""
OpenClaw Structured Tool Call & Sandboxed Execution Gateway.
Includes timeout enforcement, path containment, and output size caps.
"""

import os
import sys
import json
import time
import subprocess
import argparse

ALLOWED_DIRS = ["/mnt/disks/openclaw-data", "/tmp"]
TIMEOUT_SECONDS = 10
MAX_OUTPUT_BYTES = 2048

def is_path_safe(path):
    resolved = os.path.realpath(path)
    return any(resolved.startswith(allowed) for allowed in ALLOWED_DIRS)

class ToolGateway:
    def execute_python(self, code):
        start_t = time.time()
        try:
            res = subprocess.run(
                [sys.executable, "-c", code],
                capture_output=True,
                text=True,
                timeout=TIMEOUT_SECONDS
            )
            stdout = res.stdout[:MAX_OUTPUT_BYTES]
            stderr = res.stderr[:MAX_OUTPUT_BYTES]
            return {
                "status": "success" if res.returncode == 0 else "error",
                "returncode": res.returncode,
                "stdout": stdout,
                "stderr": stderr,
                "execution_time_ms": int((time.time() - start_t) * 1000)
            }
        except subprocess.TimeoutExpired:
            return {
                "status": "timeout",
                "error": "Tool execution timed out (10s limit)",
                "execution_time_ms": int((time.time() - start_t) * 1000)
            }

    def write_file(self, path, content):
        if not is_path_safe(path):
            return {"status": "error", "error": f"Path '{path}' outside allowed directories."}
        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(content)
            return {"status": "success", "bytes_written": len(content)}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def read_file(self, path):
        if not is_path_safe(path):
            return {"status": "error", "error": f"Path '{path}' outside allowed directories."}
        try:
            with open(path, "r") as f:
                content = f.read(MAX_OUTPUT_BYTES)
            return {"status": "success", "content": content}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def get_system_status(self):
        return {
            "status": "success",
            "uptime": "online",
            "pid": os.getpid(),
            "allowed_dirs": ALLOWED_DIRS
        }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Tool Execution Gateway")
    parser.add_argument("--tool", type=str, required=True, choices=["execute_python", "write_file", "read_file", "get_system_status"])
    parser.add_argument("--arg1", type=str, default="")
    parser.add_argument("--arg2", type=str, default="")
    args = parser.parse_args()

    gw = ToolGateway()
    if args.tool == "execute_python":
        print(json.dumps(gw.execute_python(args.arg1)))
    elif args.tool == "write_file":
        print(json.dumps(gw.write_file(args.arg1, args.arg2)))
    elif args.tool == "read_file":
        print(json.dumps(gw.read_file(args.arg1)))
    elif args.tool == "get_system_status":
        print(json.dumps(gw.get_system_status()))
