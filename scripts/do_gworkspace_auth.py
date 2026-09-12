#!/usr/bin/env python3
"""
Google Workspace OAuth 2.0 Interactive Handshake Helper.
Obtains refresh token and displays required env vars for Google Workspace MCP.
"""
import sys
import os
import json

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/do_gworkspace_auth.py <path_to_client_secret.json>")
        sys.exit(1)

    secret_file = sys.argv[1]
    if not os.path.exists(secret_file):
        print(f"Error: Secret file '{secret_file}' not found.")
        sys.exit(1)

    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
    except ImportError:
        print("Installing google-auth-oauthlib...")
        os.system("pip install google-auth-oauthlib")
        from google_auth_oauthlib.flow import InstalledAppFlow

    scopes = [
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/drive",
        "https://www.googleapis.com/auth/documents",
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/tasks",
        "https://www.googleapis.com/auth/contacts.readonly"
    ]

    flow = InstalledAppFlow.from_client_secrets_file(secret_file, scopes)
    print("\n--- Starting Google Workspace OAuth 2.0 Consent Flow ---")
    try:
        creds = flow.run_local_server(port=0)
    except Exception:
        print("Local server flow failed/unavailable, switching to console flow...")
        creds = flow.run_console()

    with open(secret_file, "r") as f:
        secret_data = json.load(f)

    client_info = secret_data.get("installed") or secret_data.get("web") or {}
    client_id = client_info.get("client_id", "")
    client_secret = client_info.get("client_secret", "")

    token_data = {
        "token": creds.token,
        "refresh_token": creds.refresh_token,
        "token_uri": creds.token_uri,
        "client_id": client_id,
        "client_secret": client_secret,
        "scopes": creds.scopes
    }

    token_out_path = "token.json"
    with open(token_out_path, "w") as f:
        json.dump(token_data, f, indent=2)

    print("\n============================================================")
    print(" ✓ OAuth Handshake Completed Successfully!")
    print(f" Saved token details to: {os.path.abspath(token_out_path)}")
    print("============================================================")
    print("\nAdd these environment variables to your environment / secrets:")
    print(f"GOOGLE_WORKSPACE_CLIENT_ID={client_id}")
    print(f"GOOGLE_WORKSPACE_CLIENT_SECRET={client_secret}")
    print(f"GOOGLE_WORKSPACE_REFRESH_TOKEN={creds.refresh_token}")
    print("============================================================\n")

if __name__ == "__main__":
    main()
