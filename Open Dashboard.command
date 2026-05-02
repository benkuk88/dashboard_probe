#!/bin/bash
#
# Double-click this file in Finder to open the dashboard in your browser.
#
# What it does:
#   1. Starts a tiny local web server (Python's built-in http.server) in
#      this folder, on a free port, bound to 127.0.0.1 (localhost only —
#      not visible to anyone else on the network).
#   2. Opens feature-probe-pipeline.html in your default browser. The page
#      then fetches data/dashboard_feature_probe_source.csv from the
#      server, parses it, and renders the dashboard.
#   3. Stays running so the page can keep loading the CSV. To stop the
#      server, press Ctrl+C in this Terminal window or just close it.
#
# Why a local server instead of opening the .html file directly?
#   Modern browsers block fetch() of local files when the page is opened
#   via a file:// URL (CORS / "same-origin" policy). A local server side-
#   steps that with a tiny http://127.0.0.1 URL.
#
# Requirements:
#   Python 3 (already on macOS by default).
#
# To hide the Terminal window after it runs:
#   Terminal -> Settings -> Profiles -> Shell -> "When the shell exits:
#   Close if the shell exited cleanly".

set -u

WORKSPACE="$(cd "$(dirname "$0")" && pwd)"
cd "$WORKSPACE" || { echo "ERROR: could not cd to $WORKSPACE"; exit 1; }

if [ ! -f "feature-probe-pipeline.html" ]; then
  echo "ERROR: feature-probe-pipeline.html not found in $WORKSPACE"
  echo "       Run this .command from the repo root."
  echo ""
  echo "Press any key to close..."; read -n 1 -s
  exit 1
fi

PYTHON_BIN="$(command -v python3 || true)"
if [ -z "$PYTHON_BIN" ]; then
  echo "ERROR: python3 not found on PATH."
  echo "       macOS ships with python3 at /usr/bin/python3 — try installing"
  echo "       Xcode Command Line Tools: xcode-select --install"
  echo ""
  echo "Press any key to close..."; read -n 1 -s
  exit 1
fi

# Pick a free TCP port (0 = OS chooses).
PORT="$("$PYTHON_BIN" -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')"
URL="http://127.0.0.1:${PORT}/feature-probe-pipeline.html"

cat <<EOF
================================================================
 Feature × Probe dashboard — local launcher
================================================================
 Workspace : $WORKSPACE
 Serving   : $URL
 Stop      : press Ctrl+C in this window, or just close it

 Tip: refresh the browser tab after you replace
      data/dashboard_feature_probe_source.csv
================================================================

EOF

# Open the browser shortly after the server boots.
( sleep 0.7 && open "$URL" ) &

# Foreground server. Closes when this terminal closes or Ctrl+C is hit.
exec "$PYTHON_BIN" -m http.server "$PORT" --bind 127.0.0.1
