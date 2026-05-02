# dashboard_probe

A self-contained HTML dashboard for the **feature × probe** ultrasound data
collection pipeline. Drop today's CSV into `data/`, double-click `Open
Dashboard.command`, and a fresh dashboard pops up in your browser. No
build step, no regeneration script.

## Layout

```
dashboard_probe/
├── data/
│   └── dashboard_feature_probe_source.csv      # The CSV the dashboard reads
├── feature-probe-pipeline.html                 # The dashboard (parses CSV in the browser)
├── Open Dashboard.command                      # Double-click launcher (starts local server + opens browser)
├── README.md
└── AGENTS.md                                   # Notes for AI agents editing this repo
```

## Daily workflow

1. **Drop today's CSV** into `data/dashboard_feature_probe_source.csv`,
   overwriting yesterday's file.

   Drag the file from Downloads into the `data/` folder in Finder, or run:

   ```bash
   cp ~/Downloads/today.csv data/dashboard_feature_probe_source.csv
   ```

2. **Double-click `Open Dashboard.command`** in Finder.

   A Terminal window opens, prints a status line, and your default browser
   pops up showing the dashboard with the latest data. The CSV is parsed
   client-side every page load — no caching, no manual regeneration.

3. **Refresh** the browser tab (`Cmd+R`) any time you replace the CSV
   while the dashboard is open.

4. **When you're done**, close the Terminal window. That stops the local
   server. The browser tab can stay open but will go blank on refresh.

### Loading a different CSV (history view)

Inside the dashboard there are two buttons:

- **Reload from disk** — re-fetches `data/dashboard_feature_probe_source.csv`.
- **Load other CSV...** — opens a file picker so you can point at any CSV
  on disk (e.g. an archived `data/dashboard_2026-04-15.csv`).

You can also **drag-and-drop** any CSV file directly onto the dashboard
page — same effect as the file picker.

## What the dashboard shows

Everything is computed in-browser from the CSV. The dashboard auto-adapts
to whatever the data contains:

- **Top stats** — patients required, collected, passed curation, gap to
  target.
- **Hero progress bar** — overall collection vs target, with passed
  curation overlaid.
- **Per-feature table** — sorted by patients collected, status pill
  (On track / In progress / Lagging / Not started) per feature.
- **Two charts** — stacked horizontal bar of collection-vs-gap per
  feature (sorted by % complete), and a donut for curation outcomes.
- **Patient pipeline funnel** — Required → Collected → Pending curation →
  Passed → Failed.
- **Phase 3 & 4 sections** — render only if the CSV has any non-zero
  values in the annotation / review columns. Otherwise a single warning
  callout says those phases aren't active yet.
- **Source-group split** — internal-only / external-only /
  internal+external feature lists, with a danger callout if every
  external-coverage feature has zero collection.
- **Probe-models row** — every probe model that appears in the CSV.
- **Key findings** — auto-generated callouts for on-track, lagging,
  not-started features, plus the curation pass rate.

## CSV schema

Two header rows, then detail rows. Subtotal rows (where source_group and
probe_group are empty) are skipped — totals are recomputed from detail
rows.

| Column | Index | Meaning |
| --- | --- | --- |
| `feature` | 0 | Clinical feature (e.g. `bladder`, `vti`) |
| `source_group` | 1 | `internal` or `external` |
| `probe_group` | 2 | Transducer model (e.g. `15C`, `L420t`) |
| `system` | 3 | Imaging system (currently always `Chameleon`) |
| `required_count` | 4 | Target patient count |
| `patients_collected` | 5 | Phase 1 — collected |
| (gap formula) | 6 | Skipped (recomputed) |
| `patients_pending_multiframe` | 7 | Phase 1 |
| `patients_pending_multiframe_not_collected` | 8 | Skipped (subset) |
| `patients_pending_curation` | 9 | Phase 2 |
| `patients_pass_curation` | 10 | Phase 2 |
| `patients_failed_curation` | 11 | Phase 2 |
| (curated total) | 12 | Skipped (formula) |
| `pending_annotations` | 13 | Phase 3 |
| `Complete_annotations` | 14 | Phase 3 |
| `Pending Review` | 15 | Phase 4 |
| `Frames_pass_Review` | 16 | Phase 4 |
| `Frames_failed_Review` | 17 | Phase 4 |
| `Total Frames was Reviewed` | 18 | Skipped (formula) |

Extra columns added at the end of the schema do not break the parser.

If the schema changes (new columns, renamed columns), update the `COL_*`
constants at the top of the `<script>` block in
`feature-probe-pipeline.html`, and extend the aggregation in
`aggregateFromCSV`.

## How the launcher works

`Open Dashboard.command` is a tiny bash script that:

1. Asks Python for a free TCP port.
2. Starts `python3 -m http.server <port> --bind 127.0.0.1` in this
   folder. Bound to localhost, so nothing on the network can see it.
3. Opens `http://127.0.0.1:<port>/feature-probe-pipeline.html` in your
   default browser.

The HTML then runs `fetch('data/dashboard_feature_probe_source.csv')` —
which works because the page is served over `http://`. Trying to open
the `.html` directly via `file://` would fail at the fetch step
(browsers block local file access for security); the dashboard detects
this and shows a friendly fallback with a "Choose a CSV file..." button.

## Requirements

- macOS with Python 3 (already preinstalled — verify with `python3 --version`).
- A modern browser (Chrome, Safari, Firefox, Edge — all fine).

## Troubleshooting

- **The launcher Terminal window says "address already in use"** — close
  any leftover Terminal windows from a previous launch and try again.
  Each launch picks a free port, so this should be rare.
- **Browser shows the error card "Could not load CSV"** — most likely
  you opened `feature-probe-pipeline.html` directly via Finder
  (file:// URL) instead of via `Open Dashboard.command`. Use the
  launcher, or click "Choose a CSV file..." in the error card to pick
  one manually.
- **"No feature rows found" after loading a CSV** — the parser skips
  rows with empty `source_group` or `probe_group`. Double-check that the
  detail rows in your CSV have those columns filled in.
