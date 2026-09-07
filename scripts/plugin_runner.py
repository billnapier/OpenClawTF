#!/usr/bin/env python3
"""
OpenClaw Dynamic Tool Plugin Sandbox & Runtime Engine.
Dynamically loads custom plugin extensions with 5.0s process timeout bounds.
"""

import os
import sys
import json
import time
import subprocess
import argparse

PLUGIN_DIR = os.environ.get("PLUGIN_DIR", "/tmp/openclaw_plugins")
TIMEOUT_SECONDS = 5.0

class PluginRunner:
    def __init__(self, plugin_dir=PLUGIN_DIR):
        self.plugin_dir = plugin_dir
        os.makedirs(self.plugin_dir, exist_ok=True)

    def list_plugins(self):
        plugins = []
        for fname in os.listdir(self.plugin_dir):
            if fname.endswith(".py"):
                name = fname[:-3]
                plugins.append({"name": name, "path": os.path.join(self.plugin_dir, fname), "status": "enabled"})
        return {"status": "success", "plugins": plugins}

    def execute_plugin(self, plugin_name, kwargs_json="{}"):
        plugin_path = os.path.join(self.plugin_dir, f"{plugin_name}.py")
        if not os.path.exists(plugin_path):
            return {"status": "error", "error": f"Plugin '{plugin_name}' not found."}

        runner_code = f"""
import sys, json
sys.path.insert(0, '{self.plugin_dir}')
import {plugin_name}
args = json.loads('''{kwargs_json}''')
res = {plugin_name}.run(**args)
print(json.dumps(res))
"""
        start_t = time.time()
        try:
            proc = subprocess.run(
                [sys.executable, "-c", runner_code],
                capture_output=True,
                text=True,
                timeout=TIMEOUT_SECONDS
            )
            if proc.returncode == 0:
                out = json.loads(proc.stdout.strip() or "{}")
                return {"status": "success", "output": out, "execution_time_ms": int((time.time() - start_t)*1000)}
            else:
                return {"status": "error", "error": proc.stderr[:500]}
        except subprocess.TimeoutExpired:
            return {"status": "timeout", "error": "Plugin execution exceeded 5s limit", "execution_time_ms": int((time.time() - start_t)*1000)}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Plugin Sandbox Runner")
    parser.add_argument("--dir", type=str, default=PLUGIN_DIR)
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--run", type=str, help="Plugin name to run")
    parser.add_argument("--args", type=str, default="{}")
    args = parser.parse_args()

    pr = PluginRunner(args.dir)
    if args.list:
        print(json.dumps(pr.list_plugins()))
    elif args.run:
        print(json.dumps(pr.execute_plugin(args.run, args.args)))
    else:
        print(json.dumps({"status": "ready", "plugin_dir": args.dir}))
