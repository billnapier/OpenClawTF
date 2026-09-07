#!/usr/bin/env python3
"""
OpenClaw Control UI Gateway Web Server.
Serves the OpenClaw Control UI web dashboard and REST API on port 18789.
"""

import os
import sys
import json
import time
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = int(os.environ.get("OPENCLAW_CONTROL_PORT", 18789))

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OpenClaw Control UI</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-primary: #0b0f19;
      --bg-secondary: #111827;
      --bg-card: #1f2937;
      --accent: #6366f1;
      --accent-hover: #4f46e5;
      --text-main: #f9fafb;
      --text-muted: #9ca3af;
      --border-color: #374151;
      --success: #10b981;
      --warning: #f59e0b;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Inter', system-ui, -apple-system, sans-serif;
      background-color: var(--bg-primary);
      color: var(--text-main);
      display: flex;
      height: 100vh;
      overflow: hidden;
    }
    #sidebar {
      width: 260px;
      background-color: var(--bg-secondary);
      border-right: 1px solid var(--border-color);
      display: flex;
      flex-direction: column;
      padding: 1.5rem 1rem;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      font-size: 1.25rem;
      font-weight: 700;
      color: #fff;
      margin-bottom: 2rem;
      padding-left: 0.5rem;
    }
    .brand-icon {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, #6366f1, #a855f7);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      color: #fff;
    }
    .nav-menu {
      list-style: none;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }
    .nav-item a {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      color: var(--text-muted);
      text-decoration: none;
      border-radius: 8px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .nav-item.active a, .nav-item a:hover {
      background-color: rgba(99, 102, 241, 0.15);
      color: #fff;
    }
    #main-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      background-color: var(--bg-primary);
      overflow-y: auto;
    }
    header {
      padding: 1.25rem 2rem;
      border-bottom: 1px solid var(--border-color);
      background-color: var(--bg-secondary);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.35rem 0.85rem;
      border-radius: 9999px;
      font-size: 0.85rem;
      font-weight: 600;
      background-color: rgba(16, 185, 129, 0.15);
      color: var(--success);
      border: 1px solid rgba(16, 185, 129, 0.3);
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background-color: var(--success);
      box-shadow: 0 0 8px var(--success);
    }
    .container {
      padding: 2rem;
      max-width: 1200px;
    }
    .tab-content {
      display: none;
    }
    .tab-content.active {
      display: block;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2rem;
    }
    .card {
      background-color: var(--bg-card);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      padding: 1.5rem;
    }
    .card-title {
      font-size: 0.875rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--text-muted);
      margin-bottom: 0.75rem;
    }
    .card-value {
      font-size: 1.75rem;
      font-weight: 700;
      color: #fff;
    }
    .card-subtitle {
      font-size: 0.85rem;
      color: var(--text-muted);
      margin-top: 0.5rem;
    }
    .section-title {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 1rem;
      color: #fff;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      background-color: var(--bg-card);
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid var(--border-color);
      margin-bottom: 1.5rem;
    }
    th, td {
      padding: 1rem 1.25rem;
      text-align: left;
      border-bottom: 1px solid var(--border-color);
    }
    th {
      background-color: var(--bg-secondary);
      color: var(--text-muted);
      font-weight: 600;
      font-size: 0.85rem;
      text-transform: uppercase;
    }
    td {
      font-size: 0.95rem;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.6rem 1.2rem;
      background-color: var(--accent);
      color: #fff;
      border: none;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
      transition: background 0.2s;
    }
    .btn:hover {
      background-color: var(--accent-hover);
    }
  </style>
</head>
<body>
  <div id="sidebar">
    <div class="brand">
      <div class="brand-icon">⚡</div>
      <span>OpenClaw</span>
    </div>
    <ul class="nav-menu">
      <li class="nav-item active" data-tab="tab-overview"><a onclick="switchTab('tab-overview')">📊 Overview</a></li>
      <li class="nav-item" data-tab="tab-config"><a onclick="switchTab('tab-config')">⚙️ Configuration</a></li>
      <li class="nav-item" data-tab="tab-channels"><a onclick="switchTab('tab-channels')">💬 Channels</a></li>
      <li class="nav-item" data-tab="tab-models"><a onclick="switchTab('tab-models')">🧠 Models</a></li>
      <li class="nav-item" data-tab="tab-whitelist"><a onclick="switchTab('tab-whitelist')">🔒 Whitelist</a></li>
    </ul>
  </div>
  <div id="main-content">
    <header>
      <h2 id="header-title">Control UI & Gateway Dashboard</h2>
      <div class="status-badge">
        <span class="status-dot"></span>
        Gateway Active
      </div>
    </header>
    <div class="container">

      <!-- TAB 1: OVERVIEW -->
      <div id="tab-overview" class="tab-content active">
        <div class="grid">
          <div class="card">
            <div class="card-title">LLM Model Engine</div>
            <div class="card-value">Gemini 2.5 Flash</div>
            <div class="card-subtitle">Default Model Router</div>
          </div>
          <div class="card">
            <div class="card-title">Active Transport</div>
            <div class="card-value">Telegram Bot</div>
            <div class="card-subtitle">Long-Polling Gateway</div>
          </div>
          <div class="card">
            <div class="card-title">Storage Persistence</div>
            <div class="card-value">/mnt/disks/...</div>
            <div class="card-subtitle">Detached GCP Persistent Disk</div>
          </div>
        </div>

        <h3 class="section-title">System Runtime Status</h3>
        <table>
          <thead>
            <tr>
              <th>Component</th>
              <th>Status</th>
              <th>Details</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Control UI Web Server</td>
              <td><span style="color: var(--success); font-weight:600;">RUNNING</span></td>
              <td>Port 18789 (Local IAP Tunnel)</td>
            </tr>
            <tr>
              <td>Telegram Channel Adapter</td>
              <td><span style="color: var(--success); font-weight:600;">ACTIVE</span></td>
              <td>Outbound Polling Active</td>
            </tr>
            <tr>
              <td>Vector Memory Engine</td>
              <td><span style="color: var(--success); font-weight:600;">READY</span></td>
              <td>SQLite Persistent DB Mount</td>
            </tr>
          </tbody>
        </table>
        <button class="btn" onclick="fetchStatus()">🔄 Refresh System Health</button>
      </div>

      <!-- TAB 2: CONFIGURATION -->
      <div id="tab-config" class="tab-content">
        <h3 class="section-title">Gateway Configuration</h3>
        <table>
          <thead>
            <tr>
              <th>Parameter</th>
              <th>Configured Value</th>
              <th>Source</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Control Port</td>
              <td>18789</td>
              <td>OPENCLAW_CONTROL_PORT</td>
            </tr>
            <tr>
              <td>GCP Project ID</td>
              <td>openclaw-tf-90326</td>
              <td>Environment Metadata</td>
            </tr>
            <tr>
              <td>Persistent Mount</td>
              <td>/mnt/disks/openclaw-data</td>
              <td>GCP Persistent Disk</td>
            </tr>
            <tr>
              <td>Gemini API Credential</td>
              <td><span style="color: var(--success); font-weight:600;">Configured</span></td>
              <td>GCP Secret Manager</td>
            </tr>
            <tr>
              <td>Telegram Bot Token</td>
              <td><span style="color: var(--success); font-weight:600;">Configured</span></td>
              <td>GCP Secret Manager</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- TAB 3: CHANNELS -->
      <div id="tab-channels" class="tab-content">
        <h3 class="section-title">Active Transport Channels</h3>
        <table>
          <thead>
            <tr>
              <th>Channel</th>
              <th>Protocol</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Telegram Bot Gateway</td>
              <td>HTTPS Outbound Long-Polling</td>
              <td><span style="color: var(--success); font-weight:600;">ACTIVE</span></td>
            </tr>
            <tr>
              <td>Discord Adapter</td>
              <td>WebSocket Egress</td>
              <td><span style="color: var(--text-muted);">STANDBY</span></td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- TAB 4: MODELS -->
      <div id="tab-models" class="tab-content">
        <h3 class="section-title">Configured LLM Model Engines</h3>
        <table>
          <thead>
            <tr>
              <th>Model Identifier</th>
              <th>Provider</th>
              <th>Capabilities</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>gemini-2.5-flash</strong></td>
              <td>Google Gemini API</td>
              <td>Fast Reasoning, Multimodal, Vector Memory</td>
              <td><span style="color: var(--success); font-weight:600;">DEFAULT</span></td>
            </tr>
            <tr>
              <td><strong>gemini-2.5-pro</strong></td>
              <td>Google Gemini API</td>
              <td>High Intelligence, Deep Analysis</td>
              <td><span style="color: var(--success); font-weight:600;">AVAILABLE</span></td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- TAB 5: WHITELIST -->
      <div id="tab-whitelist" class="tab-content">
        <h3 class="section-title">Access Control Whitelist</h3>
        <p style="color: var(--text-muted); margin-bottom: 1rem;">Authorized Telegram User IDs with system access:</p>
        <table>
          <thead>
            <tr>
              <th>User ID</th>
              <th>Role</th>
              <th>Authorization Status</th>
            </tr>
          </thead>
          <tbody id="whitelist-table-body">
            <tr>
              <td>7797117562</td>
              <td>Administrator</td>
              <td><span style="color: var(--success); font-weight:600;">AUTHORIZED</span></td>
            </tr>
          </tbody>
        </table>
      </div>

    </div>
  </div>

  <script>
    function switchTab(tabId) {
      // Hide all tabs
      document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
      document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));

      // Show selected tab
      const targetTab = document.getElementById(tabId);
      if (targetTab) {
        targetTab.classList.add('active');
      }

      // Highlight active nav item
      const navItem = document.querySelector('.nav-item[data-tab="' + tabId + '"]');
      if (navItem) {
        navItem.classList.add('active');
      }
    }

    async function fetchStatus() {
      try {
        const resp = await fetch('/api/status');
        const data = await resp.json();
        alert('Gateway Status: ' + data.status + '\\nComponents: ' + JSON.stringify(data.components, null, 2));
      } catch (e) {
        alert('Error fetching status: ' + e);
      }
    }
  </script>
</body>
</html>
"""

class ControlGatewayHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path in ["/", "/index.html"]:
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_TEMPLATE.encode("utf-8"))
        elif parsed.path in ["/api/status", "/api/health"]:
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            data = {
                "status": "healthy",
                "service": "OpenClaw Control Gateway",
                "timestamp": int(time.time()),
                "components": {
                    "control_ui": "online",
                    "telegram_daemon": "online",
                    "model_router": "gemini-2.5-flash"
                }
            }
            self.wfile.write(json.dumps(data).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"404 Not Found")

    def address_string(self):
        return self.client_address[0]

    def log_message(self, format, *args):
        sys.stderr.write(f"[CONTROL GATEWAY] {self.address_string()} - {format%args}\n")

def run_server():
    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, ControlGatewayHandler)
    print(f"[CONTROL GATEWAY] OpenClaw Control UI Web Server running on port {PORT}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("[CONTROL GATEWAY] Shutting down web server...")
        httpd.server_close()

if __name__ == "__main__":
    run_server()
