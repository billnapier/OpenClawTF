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

    def list_mcp_tools(self):
        try:
            bridge_script = os.path.join(os.path.dirname(os.path.realpath(__file__)), "gworkspace_mcp_bridge.py")
            res = subprocess.run(
                [sys.executable, bridge_script, "--list"],
                capture_output=True,
                text=True,
                timeout=TIMEOUT_SECONDS
            )
            if res.returncode == 0:
                return json.loads(res.stdout)
            return {"status": "error", "error": res.stderr[:500]}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def call_mcp_tool(self, tool_name, args_json="{}"):
        start_t = time.time()
        try:
            bridge_script = os.path.join(os.path.dirname(os.path.realpath(__file__)), "gworkspace_mcp_bridge.py")
            rpc_payload = json.dumps({
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {"name": tool_name, "arguments": json.loads(args_json or "{}")}
            }) + "\n"

            res = subprocess.run(
                [sys.executable, bridge_script, "--stdio"],
                input=rpc_payload,
                capture_output=True,
                text=True,
                timeout=TIMEOUT_SECONDS
            )

            if res.returncode == 0 and res.stdout.strip():
                rpc_res = json.loads(res.stdout.strip())
                content_items = rpc_res.get("result", {}).get("content", [])
                if content_items:
                    output_text = content_items[0].get("text", "{}")
                    return {
                        "status": "success",
                        "tool": tool_name,
                        "output": json.loads(output_text),
                        "execution_time_ms": int((time.time() - start_t) * 1000)
                    }
                return {"status": "success", "result": rpc_res, "execution_time_ms": int((time.time() - start_t) * 1000)}
            return {"status": "error", "error": res.stderr[:500]}
        except subprocess.TimeoutExpired:
            return {"status": "timeout", "error": "MCP tool execution timed out (10s limit)"}
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
    parser.add_argument("--tool", type=str, required=True, choices=["execute_python", "write_file", "read_file", "get_system_status", "list_mcp_tools", "call_mcp_tool"])
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
    elif args.tool == "list_mcp_tools":
        print(json.dumps(gw.list_mcp_tools()))
    elif args.tool == "call_mcp_tool":
        print(json.dumps(gw.call_mcp_tool(args.arg1, args.arg2)))

