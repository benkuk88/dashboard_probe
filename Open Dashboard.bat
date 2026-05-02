@echo off
rem ============================================================
rem  Double-click this file in File Explorer to open the
rem  dashboard in your default browser (Windows version).
rem
rem  What it does:
rem    1. Starts a tiny local web server (Python's built-in
rem       http.server) in this folder, on a free port, bound to
rem       127.0.0.1 (localhost only -- not visible to anyone else
rem       on the network).
rem    2. Opens feature-probe-pipeline.html in your default
rem       browser. The page then fetches
rem       data/dashboard_feature_probe_source.csv from the server,
rem       parses it, and renders the dashboard.
rem    3. Stays running so the page can keep loading the CSV. To
rem       stop the server, press Ctrl+C in this window or just
rem       close it.
rem
rem  Why a local server instead of opening the .html file directly?
rem    Modern browsers block fetch() of local files when the page
rem    is opened via a file:// URL (CORS / "same-origin" policy).
rem    A local server side-steps that with a tiny http://127.0.0.1
rem    URL.
rem
rem  Requirements:
rem    Python 3. Install from https://www.python.org/downloads/
rem    (make sure to tick "Add Python to PATH" during install) or
rem    from the Microsoft Store.
rem ============================================================

setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

if not exist "feature-probe-pipeline.html" (
  echo ERROR: feature-probe-pipeline.html not found in:
  echo        %CD%
  echo        Run this .bat from the repo root.
  echo.
  pause
  exit /b 1
)

set "PYTHON_BIN="
where py  >nul 2>&1 && set "PYTHON_BIN=py -3"
if not defined PYTHON_BIN (
  where python >nul 2>&1 && set "PYTHON_BIN=python"
)
if not defined PYTHON_BIN (
  echo ERROR: Python 3 not found on PATH.
  echo        Install it from https://www.python.org/downloads/
  echo        (tick "Add Python to PATH" during install) or from
  echo        the Microsoft Store, then run this file again.
  echo.
  pause
  exit /b 1
)

for /f %%P in ('%PYTHON_BIN% -c "import socket; s=socket.socket(); s.bind((chr(49)+chr(50)+chr(55)+chr(46)+chr(48)+chr(46)+chr(48)+chr(46)+chr(49),0)); print(s.getsockname()[1]); s.close()"') do set "PORT=%%P"

if not defined PORT (
  echo ERROR: failed to pick a free TCP port via Python.
  echo.
  pause
  exit /b 1
)

set "URL=http://127.0.0.1:%PORT%/feature-probe-pipeline.html"

echo ================================================================
echo  Feature x Probe dashboard -- local launcher
echo ================================================================
echo  Workspace : %CD%
echo  Serving   : %URL%
echo  Stop      : press Ctrl+C in this window, or just close it
echo.
echo  Tip: refresh the browser tab after you replace
echo       data\dashboard_feature_probe_source.csv
echo ================================================================
echo.

start "" "%URL%"

%PYTHON_BIN% -m http.server %PORT% --bind 127.0.0.1

endlocal
