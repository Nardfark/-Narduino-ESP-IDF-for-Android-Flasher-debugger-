#!/bin/bash

# ==================================================================================
# 🎄 Jennifer's Upgraded Christmas Coupon Server 🎄
# ==================================================================================
# This script installs a standalone Python web server and CLI for managing coupons.
# It sets up a systemd service to keep it running in the background.
#
# USAGE: Just run this script!
# ==================================================================================

APP_DIR="$HOME/christmas_coupons"
PORT=6969
USER=$(whoami)

echo "🎅 Ho Ho Ho! Starting installation..."

# --- 1. PRE-FLIGHT CHECKS ---
if ss -tuln | grep -q ":$PORT "; then
    echo "⚠️  WARNING: Port $PORT seems to be in use."
    read -p "Do you want to try and kill the process on port $PORT? (y/N) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        PID=$(lsof -t -i:$PORT)
        if [ -n "$PID" ]; then
            kill -9 $PID
            echo "✅ Process killed."
        else
            echo "❌ Could not find process. Exiting."
            exit 1
        fi
    else
        echo "❌ Exiting. Please free port $PORT."
        exit 1
    fi
fi

# Backup existing installation
if [ -d "$APP_DIR" ]; then
    BACKUP="${APP_DIR}_backup_$(date +%s)"
    echo "📦 Backing up existing directory to $BACKUP..."
    mv "$APP_DIR" "$BACKUP"
fi

mkdir -p "$APP_DIR"
cd "$APP_DIR"

echo "📂 Created directory at $APP_DIR"

# --- 2. GENERATE FILES ---

# 2.1 DATABASE (coupons.json)
cat <<EOF > coupons.json
{
  "definitions": {
    "JEN-XMAS-001": "Back Scratching (5m)",
    "JEN-XMAS-002": "Back Scratching (5m)",
    "JEN-XMAS-003": "Foot Rub (15m)",
    "JEN-XMAS-004": "Foot Rub (15m)",
    "JEN-XMAS-005": "Tech Free Hour",
    "JEN-XMAS-006": "Watch Movie (No Work)",
    "JEN-XMAS-007": "Do Dishes (All Day)",
    "JEN-XMAS-008": "Vacuum & Mop",
    "JEN-XMAS-009": "Do Laundry (All Day)",
    "JEN-XMAS-010": "Grocery Shopping",
    "JEN-XMAS-011": "Organize A Room",
    "JEN-XMAS-012": "Pay For Gas (Tank)",
    "JEN-XMAS-013": "Spa Day (Baby Watch)",
    "JEN-XMAS-014": "Diaper Duty (All Day)",
    "JEN-XMAS-015": "24hr Mom Break",
    "JEN-XMAS-016": "Sleep In",
    "JEN-XMAS-017": "Personal Chauffeur",
    "JEN-XMAS-018": "One 'Yes' Day",
    "JEN-XMAS-019": "Back Massage (30m)",
    "JEN-XMAS-020": "Back Scratching (10m)",
    "JEN-XMAS-021": "Trip to Lake",
    "JEN-XMAS-022": "Go on a Hike",
    "JEN-XMAS-023": "Wildcard #1",
    "JEN-XMAS-024": "Wildcard #2"
  },
  "redeemed": {}
}
EOF

# 2.2 SERVER (server.py)
cat <<EOF > server.py
import http.server
import socketserver
import json
import os
import urllib.parse
from datetime import datetime

PORT = $PORT
DB_FILE = 'coupons.json'

class ThreadingSimpleServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    pass

class CouponHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Serve API Data
        if self.path == '/api/data':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            try:
                with open(DB_FILE, 'r') as f:
                    self.wfile.write(f.read().encode())
            except Exception as e:
                self.wfile.write(json.dumps({"error": str(e)}).encode())
            return

        # Rewrite root to redeem.html
        if self.path == '/' or self.path.startswith('/?'):
            self.path = '/redeem.html'

        return http.server.SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self):
        # API: Redeem Coupon
        if self.path == '/api/redeem':
            try:
                length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(length)
                data = json.loads(post_data.decode())
                code = data.get('code')

                with open(DB_FILE, 'r+') as f:
                    db = json.load(f)

                    if code in db['definitions']:
                        if code in db['redeemed']:
                            self.send_response(409) # Conflict
                            self.end_headers()
                            response = {
                                "status": "error",
                                "message": "Already redeemed",
                                "date": db['redeemed'][code],
                                "item": db['definitions'][code]
                            }
                        else:
                            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                            db['redeemed'][code] = timestamp
                            f.seek(0)
                            json.dump(db, f, indent=2)
                            f.truncate()

                            self.send_response(200)
                            self.end_headers()
                            response = {
                                "status": "success",
                                "message": "Redeemed successfully",
                                "date": timestamp,
                                "item": db['definitions'][code]
                            }
                    else:
                        self.send_response(404)
                        self.end_headers()
                        response = {"status": "error", "message": "Invalid Code"}

                self.wfile.write(json.dumps(response).encode())
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "message": str(e)}).encode())
            return

print(f"Starting Christmas Coupon Server on port {PORT}...")
socketserver.TCPServer.allow_reuse_address = True
with ThreadingSimpleServer(("", PORT), CouponHandler) as httpd:
    httpd.serve_forever()
EOF

# 2.3 FRONTEND (redeem.html)
cat <<EOF > redeem.html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Jennifer's Christmas Coupons</title>
<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700&family=Lato:wght@300;400;700&display=swap" rel="stylesheet">
<style>
  :root {
    --primary: #c0392b; /* Christmas Red */
    --secondary: #27ae60; /* Christmas Green */
    --gold: #f1c40f;
    --dark: #2c3e50;
    --light: #fdfbf7;
    --card-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: 'Lato', sans-serif;
    background-color: var(--primary);
    background-image: radial-gradient(circle at 20% 20%, rgba(255,255,255,0.1) 1%, transparent 1%),
                      radial-gradient(circle at 80% 80%, rgba(255,255,255,0.1) 1%, transparent 1%);
    background-size: 50px 50px;
    color: var(--dark);
    min-height: 100vh;
    padding: 20px;
    position: relative;
    overflow-x: hidden;
  }

  .snow-container {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      z-index: 0;
  }

  .container {
    max-width: 800px;
    margin: 0 auto;
    position: relative;
    z-index: 1;
  }

  header {
    text-align: center;
    color: #fff;
    margin-bottom: 30px;
    text-shadow: 0 2px 4px rgba(0,0,0,0.2);
  }

  h1 {
    font-family: 'Cinzel', serif;
    font-size: 2.5rem;
    margin-bottom: 10px;
    border-bottom: 2px solid rgba(255,255,255,0.3);
    display: inline-block;
    padding-bottom: 10px;
  }

  .stats-bar {
    background: rgba(255,255,255,0.9);
    border-radius: 50px;
    padding: 10px 20px;
    margin-bottom: 30px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: var(--card-shadow);
    font-weight: bold;
    color: var(--dark);
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 20px;
  }

  .card {
    background: #fff;
    border-radius: 8px;
    overflow: hidden;
    position: relative;
    box-shadow: var(--card-shadow);
    transition: transform 0.2s;
    border: 1px solid #eee;
  }

  .card:hover {
    transform: translateY(-3px);
  }

  .card.redeemed {
    opacity: 0.7;
    background: #f8f9fa;
  }

  .card-header {
    background: var(--dark);
    color: #fff;
    padding: 10px 15px;
    font-size: 0.8rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .card-body {
    padding: 20px;
    text-align: center;
    border-bottom: 2px dashed #ddd; /* Perforation look */
    position: relative;
  }

  .card-body::before, .card-body::after {
      content: '';
      position: absolute;
      bottom: -10px;
      width: 20px;
      height: 20px;
      background: var(--primary); /* Match bg */
      border-radius: 50%;
  }
  .card-body::before { left: -10px; }
  .card-body::after { right: -10px; }

  .card-title {
    font-size: 1.2rem;
    font-weight: 700;
    margin-bottom: 5px;
    font-family: 'Cinzel', serif;
    color: var(--primary);
  }

  .card-footer {
    padding: 15px;
    text-align: center;
  }

  .btn {
    display: inline-block;
    background: var(--secondary);
    color: white;
    padding: 8px 20px;
    border-radius: 20px;
    text-decoration: none;
    font-weight: bold;
    font-size: 0.9rem;
    cursor: pointer;
    border: none;
    transition: background 0.2s;
  }

  .btn:hover { background: #219150; }

  .btn.disabled {
    background: #ccc;
    cursor: default;
  }

  .stamp {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) rotate(-15deg);
    border: 3px solid var(--primary);
    color: var(--primary);
    font-size: 1.5rem;
    font-weight: bold;
    padding: 5px 10px;
    text-transform: uppercase;
    border-radius: 5px;
    opacity: 0.3;
    pointer-events: none;
  }

  /* Modal */
  .modal-overlay {
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      background: rgba(0,0,0,0.8);
      z-index: 100;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 20px;
  }
  .modal {
      background: white;
      padding: 30px;
      border-radius: 10px;
      max-width: 400px;
      width: 100%;
      text-align: center;
      position: relative;
  }
  .modal h2 { margin-bottom: 15px; color: var(--primary); font-family: 'Cinzel', serif; }
  .modal-icon { font-size: 3rem; margin-bottom: 15px; display: block; }
  .modal-close { margin-top: 20px; background: var(--dark); }

  /* Loading */
  .loading { color: white; text-align: center; font-style: italic; margin-top: 50px; }

  @media (max-width: 600px) {
      h1 { font-size: 1.8rem; }
      .grid { grid-template-columns: 1fr; }
  }
</style>
</head>
<body>

<div id="snow" class="snow-container"></div>

<div class="container">
  <header>
    <h1>Christmas Coupons</h1>
    <p>Use them wisely!</p>
  </header>

  <div class="stats-bar">
    <span>Available: <span id="count-avail">0</span></span>
    <span>Redeemed: <span id="count-used">0</span></span>
  </div>

  <div id="grid" class="grid">
    <div class="loading">Loading festive goodies...</div>
  </div>
</div>

<!-- Modal -->
<div id="modal" class="modal-overlay">
    <div class="modal">
        <span id="modal-icon" class="modal-icon">🎁</span>
        <h2 id="modal-title">Redeemed!</h2>
        <p id="modal-msg">Enjoy your gift.</p>
        <div id="modal-date" style="font-size:0.8rem; color:#666; margin-top:5px;"></div>
        <button class="btn modal-close" onclick="closeModal()">Close</button>
    </div>
</div>

<script>
    let definitions = {};
    let redeemed = {};

    // --- Snow Effect ---
    function createSnow() {
        const container = document.getElementById('snow');
        const count = 50;
        for (let i = 0; i < count; i++) {
            const flake = document.createElement('div');
            flake.style.position = 'absolute';
            flake.style.width = Math.random() * 5 + 2 + 'px';
            flake.style.height = flake.style.width;
            flake.style.background = 'rgba(255,255,255,0.7)';
            flake.style.borderRadius = '50%';
            flake.style.left = Math.random() * 100 + '%';
            flake.style.top = -10 + 'px';
            flake.style.animation = \`fall \${Math.random() * 5 + 3}s linear infinite\`;
            flake.style.animationDelay = Math.random() * 5 + 's';
            container.appendChild(flake);
        }

        const style = document.createElement('style');
        style.innerHTML = \`
            @keyframes fall {
                to { transform: translateY(100vh) rotate(360deg); }
            }
        \`;
        document.head.appendChild(style);
    }
    createSnow();

    // --- Data Loading ---
    async function loadData() {
        try {
            const res = await fetch('/api/data');
            const data = await res.json();
            definitions = data.definitions;
            redeemed = data.redeemed;
            render();
            updateStats();
        } catch (e) {
            console.error(e);
            document.getElementById('grid').innerHTML = '<div class="loading">Error loading coupons :(</div>';
        }
    }

    function updateStats() {
        const total = Object.keys(definitions).length;
        const used = Object.keys(redeemed).length;
        document.getElementById('count-avail').innerText = total - used;
        document.getElementById('count-used').innerText = used;
    }

    function render() {
        const grid = document.getElementById('grid');
        grid.innerHTML = '';

        const items = Object.entries(definitions).map(([id, name]) => {
            return { id, name, date: redeemed[id] };
        });

        // Sort: Available first
        items.sort((a, b) => {
            if (a.date && !b.date) return 1;
            if (!a.date && b.date) return -1;
            return 0;
        });

        items.forEach(item => {
            const isRedeemed = !!item.date;
            const card = document.createElement('div');
            card.className = \`card \${isRedeemed ? 'redeemed' : ''}\`;

            const btnHtml = isRedeemed
                ? \`<div class="btn disabled">REDEEMED</div>\`
                : \`<button class="btn" onclick="confirmRedeem('\${item.id}')">REDEEM</button>\`;

            const stampHtml = isRedeemed
                ? \`<div class="stamp">USED</div>\`
                : '';

            card.innerHTML = \`
                <div class="card-header">
                    <span>\${item.id}</span>
                    <span>\${isRedeemed ? item.date.split(' ')[0] : 'VALID'}</span>
                </div>
                <div class="card-body">
                    <div class="card-title">\${item.name}</div>
                    \${stampHtml}
                </div>
                <div class="card-footer">
                    \${btnHtml}
                </div>
            \`;
            grid.appendChild(card);
        });
    }

    // --- Redemption Logic ---
    async function confirmRedeem(code) {
        if(!confirm("Are you sure you want to redeem '" + definitions[code] + "'?")) return;
        doRedeem(code);
    }

    async function doRedeem(code) {
        try {
            const res = await fetch('/api/redeem', {
                method: 'POST',
                body: JSON.stringify({ code })
            });
            const result = await res.json();

            if (res.status === 200) {
                showModal('success', 'Success!', \`You redeemed: \${result.item}\`, result.date);
            } else if (res.status === 409) {
                showModal('error', 'Already Used', \`\${result.item} was used on:\`, result.date);
            } else {
                showModal('error', 'Error', result.message);
            }
            loadData(); // Refresh UI
        } catch (e) {
            showModal('error', 'Connection Error', 'Could not reach server.');
        }
    }

    // --- URL Logic for QR Codes ---
    async function checkUrl() {
        const params = new URLSearchParams(window.location.search);
        const code = params.get('code');
        if (code && definitions[code]) {
            // Remove code from URL so refresh doesn't re-trigger
            window.history.replaceState({}, document.title, window.location.pathname);
            // Attempt redeem immediately
            await doRedeem(code);
        }
    }

    // --- Modal ---
    function showModal(type, title, msg, date='') {
        const modal = document.getElementById('modal');
        const icon = document.getElementById('modal-icon');
        const h2 = document.getElementById('modal-title');
        const p = document.getElementById('modal-msg');
        const d = document.getElementById('modal-date');

        icon.innerText = type === 'success' ? '🎄' : '⚠️';
        h2.innerText = title;
        h2.style.color = type === 'success' ? 'var(--secondary)' : 'var(--primary)';
        p.innerText = msg;
        d.innerText = date;

        modal.style.display = 'flex';
    }

    function closeModal() {
        document.getElementById('modal').style.display = 'none';
    }

    // --- Init ---
    window.addEventListener('DOMContentLoaded', async () => {
        await loadData();
        checkUrl();
    });
</script>
</body>
</html>
EOF

# 2.4 CLI TOOL (coupons)
cat <<EOF > coupons
#!/usr/bin/env python3
import json
import sys
import os
import argparse
from datetime import datetime

# Assuming the script is run from the app directory or relative to it
APP_DIR = "$APP_DIR"
DB_FILE = os.path.join(APP_DIR, "coupons.json")

# Colors
RED = '\033[91m'
GREEN = '\033[92m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
BOLD = '\033[1m'
RESET = '\033[0m'

def load_db():
    if not os.path.exists(DB_FILE):
        print(f"{RED}Error: Database not found at {DB_FILE}{RESET}")
        sys.exit(1)
    with open(DB_FILE, 'r') as f:
        return json.load(f)

def save_db(data):
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def print_header():
    print(f"\n{BOLD}{RED}🎄 CHRISTMAS COUPON MANAGER 🎄{RESET}")
    print(f"{YELLOW}{'-'*60}{RESET}")

def cmd_list(args):
    data = load_db()
    defs = data['definitions']
    redeemed = data['redeemed']

    print(f"{BOLD}{'CODE':<15} | {'STATUS':<10} | {'OFFER'}{RESET}")
    print("-" * 60)

    for code, name in defs.items():
        if code in redeemed:
            status = f"{RED}USED{RESET}"
            line_color = "\033[90m" # Dark Gray
        else:
            status = f"{GREEN}OPEN{RESET}"
            line_color = RESET

        print(f"{line_color}{code:<15}{RESET} | {status}       | {line_color}{name}{RESET}")
    print("-" * 60)
    print(f"Total: {len(defs)} | Available: {len(defs) - len(redeemed)} | Redeemed: {len(redeemed)}")

def cmd_details(args):
    data = load_db()
    redeemed = data['redeemed']

    if not redeemed:
        print("No coupons have been redeemed yet.")
        return

    print(f"{BOLD}{'CODE':<15} | {'DATE':<20} | {'OFFER'}{RESET}")
    print("-" * 60)
    for code, date in redeemed.items():
        name = data['definitions'].get(code, "Unknown")
        print(f"{code:<15} | {date:<20} | {name}")

def cmd_redeem(args):
    data = load_db()
    code = args.code

    if code not in data['definitions']:
        print(f"{RED}Error: Invalid coupon code '{code}'{RESET}")
        return

    if code in data['redeemed']:
        print(f"{YELLOW}Coupon '{code}' was already redeemed on {data['redeemed'][code]}{RESET}")
        return

    # Redeem
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data['redeemed'][code] = timestamp
    save_db(data)
    print(f"{GREEN}Success! Redeemed: {data['definitions'][code]}{RESET}")
    print(f"Timestamp: {timestamp}")

def cmd_reset(args):
    if input(f"{RED}Are you sure you want to RESET all coupons? (y/N): {RESET}").lower() != 'y':
        print("Aborted.")
        return

    data = load_db()
    data['redeemed'] = {}
    save_db(data)
    print(f"{GREEN}All coupons have been reset to AVAILABLE.{RESET}")

def main():
    parser = argparse.ArgumentParser(description="Manage Christmas Coupons")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    subparsers.add_parser("list", help="List all coupons and status")
    subparsers.add_parser("details", help="Show details of redeemed coupons")

    p_redeem = subparsers.add_parser("redeem", help="Manually redeem a coupon")
    p_redeem.add_argument("code", help="Coupon Code (e.g., JEN-XMAS-001)")

    subparsers.add_parser("reset", help="Reset all coupons to available")

    args = parser.parse_args()

    print_header()
    if args.command == "list":
        cmd_list(args)
    elif args.command == "details":
        cmd_details(args)
    elif args.command == "redeem":
        cmd_redeem(args)
    elif args.command == "reset":
        cmd_reset(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
EOF
chmod +x coupons

# --- 3. CREATE SYSTEMD SERVICE ---
echo "⚙️  Configuring Systemd..."
sudo cat <<EOF > /etc/systemd/system/coupon_server.service
[Unit]
Description=Christmas Coupon Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 $APP_DIR/server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# --- 4. FINALIZE ---
echo "🔄 Reloading Systemd..."
sudo systemctl daemon-reload
echo "🚀 Starting Service..."
sudo systemctl enable coupon_server
sudo systemctl restart coupon_server

# Bash Alias
if ! grep -q "alias coupons=" "$HOME/.bashrc"; then
    echo "alias coupons='$APP_DIR/coupons'" >> "$HOME/.bashrc"
    echo "✨ Added alias 'coupons' to .bashrc"
fi

# Get IP
IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=================================================================================="
echo "🎁 INSTALLATION COMPLETE!"
echo "=================================================================================="
echo ""
echo "🌐 Access the App here:"
echo "   http://$IP:$PORT"
echo ""
echo "📱 CLI Commands (Type 'coupons'):"
echo "   coupons list      -> Show all coupons"
echo "   coupons redeem ID -> Redeem manually"
echo "   coupons reset     -> Reset all"
echo ""
echo "Merry Christmas! 🎄"
