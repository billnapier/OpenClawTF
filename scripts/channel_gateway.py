#!/usr/bin/env python3
"""
OpenClaw Multi-Channel Transport Gateway.
Provides abstract ChannelAdapter with Telegram and Discord implementations.
"""

import os
import sys
import json
import argparse
from abc import ABC, abstractmethod

class ChannelAdapter(ABC):
    def __init__(self, channel_name, allowed_user_ids_env):
        self.channel_name = channel_name
        self.allowed_user_ids = self._parse_allowed_ids(os.environ.get(allowed_user_ids_env, ""))

    def _parse_allowed_ids(self, raw_str):
        if not raw_str:
            return set()
        return set(x.strip() for x in raw_str.split(",") if x.strip())

    def is_authorized(self, user_id):
        if not self.allowed_user_ids:
            return True # Open if empty or unrestricted, but strict if set
        return str(user_id) in self.allowed_user_ids

    def process_message(self, user_id, chat_id, text):
        authorized = self.is_authorized(user_id)
        if not authorized:
            return {
                "channel": self.channel_name,
                "user_id": str(user_id),
                "chat_id": str(chat_id),
                "status": "unauthorized",
                "response": f"Access Denied: User ID {user_id} is not authorized for channel {self.channel_name}."
            }

        return {
            "channel": self.channel_name,
            "user_id": str(user_id),
            "chat_id": str(chat_id),
            "status": "success",
            "normalized_message": text,
            "response": f"[{self.channel_name.upper()}] Processed: {text}"
        }

class TelegramAdapter(ChannelAdapter):
    def __init__(self):
        super().__init__("telegram", "TELEGRAM_ALLOWED_USER_IDS")

class DiscordAdapter(ChannelAdapter):
    def __init__(self):
        super().__init__("discord", "DISCORD_ALLOWED_USER_IDS")

class CLIAdapter(ChannelAdapter):
    """Channel adapter for the local `openclaw chat` CLI.

    Unlike Telegram/Discord, the CLI channel has no separate per-platform
    credential or whitelist — its sole authorization boundary is having an
    already-authenticated SSH session on the host (FR-003/FR-009). We
    deliberately do NOT call `ChannelAdapter.__init__` with an
    `allowed_user_ids_env`, since that would imply reading and honoring a
    CLI-specific allowlist env var that does not exist for this channel.
    """
    def __init__(self):
        self.channel_name = "cli"
        self.allowed_user_ids = set()

    def is_authorized(self, user_id):
        # SSH-boundary model: always authorized. The OS user is never
        # consulted here — it is used only as an audit label elsewhere
        # (FR-006), never as part of this authorization decision (FR-009).
        return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Multi-Channel Gateway CLI")
    parser.add_argument("--channel", type=str, required=True, choices=["telegram", "discord", "cli"])
    parser.add_argument("--user-id", type=str, required=True)
    parser.add_argument("--chat-id", type=str, default="1001")
    parser.add_argument("--text", type=str, default="Hello")
    args = parser.parse_args()

    if args.channel == "telegram":
        adapter = TelegramAdapter()
    elif args.channel == "discord":
        adapter = DiscordAdapter()
    else:
        adapter = CLIAdapter()
    res = adapter.process_message(args.user_id, args.chat_id, args.text)
    print(json.dumps(res))
