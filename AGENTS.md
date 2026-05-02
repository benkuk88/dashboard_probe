# Agent guide

This repo is intentionally tiny: one self-contained HTML dashboard plus a
double-click launcher. There is no build step, no regeneration script,
no canvas. The dashboard fetches and parses the CSV at page-load time.

## Files

- `feature-probe-pipeline.html` — the dashboard. Inline CSS, vanilla JS,
  SVG charts. Reads `data/dashboard_feature_probe_source.csv` via
  `fetch()` and parses it client-side. Also accepts drag-and-drop or a
  file picker for ad-hoc CSV files.
- `Open Dashboard.command` — bash launcher. Starts
  `python3 -m http.server` on a free port bound to `127.0.0.1`, opens
  the dashboard URL in the default browser, stays running until Ctrl+C
  or window close.
- `data/dashboard_feature_probe_source.csv` — the canonical CSV the
  dashboard auto-loads. Overwritten daily by the user.

## Default workflow when a new CSV arrives

1. Save the new CSV to `data/dashboard_feature_probe_source.csv`
   (overwrite by default; ISO-date-suffixed archives are fine but the
   dashboard auto-loads only the canonical filename).
2. The user re-opens the dashboard via `Open Dashboard.command` (or
   refreshes the existing tab). No script needs to run on the agent
   side.
3. If you want to sanity-check totals before responding, parse the CSV
   yourself (e.g. with Python's `csv` module) and confirm the numbers
   match what the dashboard would show. Aggregation rules:
   - Skip the first two header rows.
   - Skip detail rows where `source_group` or `probe_group` is empty
     (these are subtotal rows).
   - Sum the remaining rows per feature on the columns indexed by the
     `COL_*` constants at the top of the `<script>` in the HTML.

## Editing the dashboard

The HTML file is structured as:

1. `<style>` — design tokens (CSS variables) + component classes.
2. State containers in `<body>`: `#loader`, `#error`, `#app`.
3. `<script>` sections in this order:
   - `CONSTANTS` — `DEFAULT_CSV_PATH`, `COL_*` indices.
   - `CSV PARSER` — `parseCSV(text)`, RFC 4180-ish.
   - `AGGREGATOR` — `aggregateFromCSV(rows)`, port of the old Python.
   - `HELPERS` — `el`, `escapeXml`, `pillHTML`, `statCard`, `callout`,
     `statusFor`, `sourcePill`.
   - `CHARTS` — `horizontalBarChart`, `donutChart` (pure SVG).
   - `MAIN RENDER` — `renderDashboard({ features, probes, sourceLabel,
     loadedAt })` builds and injects the whole UI into `#app`.
   - `LOADING + UI STATES` — `showLoading`, `showError`, `showApp`,
     `loadFromURL`, `loadFromFile`, `processText`, `tryLoadDefault`.
   - `WIRE UP` — file-input listener, drag-and-drop, error buttons,
     `tryLoadDefault()` on init.

Layout, copy, callout text — edit freely. Just make sure
`renderDashboard` keeps starting with `app.innerHTML = ""` so reloading a
different CSV redraws cleanly.

## Schema changes

If the CSV schema changes (new columns, renamed columns):

1. Update the `COL_*` index constants at the top of the `<script>`.
2. Extend the per-row aggregation in `aggregateFromCSV` (add the new
   field on the `agg` object and accumulate it).
3. Use the new field in `renderDashboard` wherever it should appear.
4. Update the schema table in `README.md`.

## Do not

- Do **not** add external `<script src="...">`, `<link rel=stylesheet>`,
  or any CDN dependency. The dashboard must remain a single
  self-contained file that opens fine over `http://127.0.0.1` from the
  launcher and degrades gracefully (with the file-picker fallback)
  when opened over `file://`.
- Do **not** add `npm`, `tsc`, build steps, or regeneration scripts.
  The whole point of this repo is "drop CSV, double-click, see
  dashboard". Keep that surface area tiny.
- Do **not** edit `data/*.csv` programmatically — those are
  user-supplied source-of-truth files.
- Do **not** bind the launcher's HTTP server to anything other than
  `127.0.0.1`. The dashboard contains internal patient-pipeline numbers;
  it must not be reachable from the LAN.
