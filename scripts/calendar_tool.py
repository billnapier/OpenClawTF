#!/usr/bin/env python3
"""
OpenClaw Google Calendar Tool Module.
Fetches google-calendar-credentials from GCP Secret Manager and queries Google Calendar API.
"""

import os
import sys
import json
import time
import subprocess
import datetime
import urllib.request
import urllib.error

PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "openclaw-tf-90326")
SECRET_NAME = "google-calendar-credentials"

def fetch_calendar_secret():
    """Fetches credentials JSON from GCP Secret Manager via gcloud CLI."""
    try:
        res = subprocess.run(
            ["gcloud", "secrets", "versions", "access", "latest", "--secret", SECRET_NAME, "--project", PROJECT_ID],
            capture_output=True,
            text=True,
            timeout=10
        )
        if res.returncode == 0 and res.stdout.strip():
            return json.loads(res.stdout.strip())
    except Exception as e:
        print(f"[CALENDAR TOOL] Error fetching secret: {e}", file=sys.stderr)
    return None

def get_calendar_events(max_results=10):
    """
    Fetches upcoming calendar events using Google Calendar REST API.
    Supports Service Account & OAuth Access Tokens.
    """
    creds = fetch_calendar_secret()
    if not creds:
        return {"status": "error", "message": "No google-calendar-credentials secret found in GCP Secret Manager. Upload credentials.json to enable calendar access."}

    # If creds is a raw access token string or contains access_token
    token = creds.get("access_token") if isinstance(creds, dict) else None
    
    # If creds is Service Account JSON, we can fetch token via ADC or oauth token endpoint
    if not token and isinstance(creds, dict) and creds.get("type") == "service_account":
        # Check ADC / gcloud auth print-access-token
        try:
            res = subprocess.run(["gcloud", "auth", "print-access-token"], capture_output=True, text=True, timeout=5)
            if res.returncode == 0 and res.stdout.strip():
                token = res.stdout.strip()
        except Exception:
            pass

    if not token:
        # Fallback: Check gcloud access token
        try:
            res = subprocess.run(["gcloud", "auth", "print-access-token"], capture_output=True, text=True, timeout=5)
            if res.returncode == 0 and res.stdout.strip():
                token = res.stdout.strip()
        except Exception:
            pass

    if not token:
        return {"status": "error", "message": "google-calendar-credentials secret exists, but no valid OAuth token or Service Account key version payload was uploaded yet."}

    # Call Google Calendar API
    now = datetime.datetime.utcnow().isoformat() + "Z"
    url = f"https://www.googleapis.com/calendar/v3/calendars/primary/events?timeMin={now}&maxResults={max_results}&singleEvents=true&orderBy=startTime"
    
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/json"
    })

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            items = data.get("items", [])
            events = []
            for item in items:
                start = item.get("start", {}).get("dateTime") or item.get("start", {}).get("date")
                summary = item.get("summary", "No Title")
                events.append({"summary": summary, "start": start, "status": item.get("status")})
            return {"status": "success", "count": len(events), "events": events}
    except urllib.error.HTTPError as e:
        return {"status": "error", "message": f"Google Calendar API HTTP {e.code}: {e.reason}"}
    except Exception as e:
        return {"status": "error", "message": f"Google Calendar API Error: {e}"}

if __name__ == "__main__":
    res = get_calendar_events()
    print(json.dumps(res, indent=2))
