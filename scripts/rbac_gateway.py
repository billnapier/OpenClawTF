#!/usr/bin/env python3
"""
OpenClaw Multi-Tenant RBAC Authorization Gateway.
Manages user roles and permission enforcement.
"""

import os
import sys
import json
import argparse

CONFIG_PATH = os.environ.get("RBAC_CONFIG_PATH", "/tmp/openclaw_roles.json")

DEFAULT_PERMISSIONS = {
    "Admin": ["*"],
    "StandardUser": ["chat", "remember", "search", "model_status", "rbac_status"],
    "ReadOnly": ["model_status", "rbac_status"]
}

class RBACGateway:
    def __init__(self, config_path=CONFIG_PATH):
        self.config_path = config_path
        self.roles = {}
        self.permissions = DEFAULT_PERMISSIONS
        self.reload_config()

    def reload_config(self):
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, "r") as f:
                    data = json.load(f)
                    self.roles = data.get("roles", {})
                    self.permissions = data.get("permissions", DEFAULT_PERMISSIONS)
            return True
        except Exception:
            return False

    def save_role(self, user_id, role):
        self.roles[str(user_id)] = role
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        with open(self.config_path, "w") as f:
            json.dump({"roles": self.roles, "permissions": self.permissions}, f, indent=2)

    def get_user_role(self, user_id):
        return self.roles.get(str(user_id), "ReadOnly")

    def authorize(self, user_id, action):
        role = self.get_user_role(user_id)
        perms = self.permissions.get(role, [])
        if "*" in perms or action in perms:
            return True, role, f"Access granted for action '{action}' under role '{role}'."
        return False, role, f"Permission Denied: Action '{action}' requires Admin role (current role: '{role}')."

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RBAC Gateway CLI")
    parser.add_argument("--config", type=str, default=CONFIG_PATH)
    parser.add_argument("--user-id", type=str, required=True)
    parser.add_argument("--action", type=str, default="chat")
    parser.add_argument("--set-role", type=str, help="Set user role")
    parser.add_argument("--reload", action="store_true")
    args = parser.parse_args()

    rbac = RBACGateway(args.config)
    if args.set_role:
        rbac.save_role(args.user_id, args.set_role)
        print(json.dumps({"status": "success", "message": f"User {args.user_id} assigned role {args.set_role}."}))
    elif args.reload:
        res = rbac.reload_config()
        print(json.dumps({"status": "success" if res else "error", "message": "RBAC configuration reloaded."}))
    else:
        allowed, role, msg = rbac.authorize(args.user_id, args.action)
        print(json.dumps({"allowed": allowed, "role": role, "message": msg}))
