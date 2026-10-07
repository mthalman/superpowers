# Superpowers eval dashboard

Static GitHub Pages dashboard for Vally skill-eval trends. It shows pass rate,
mean score, pass@k, pass^k, flakiness, skill uplift when available, and
trajectory cost. Full trajectories stay in the workflow artifact and can be
opened with `scripts/Start-EvalDashboard.ps1`.

## Files

| Path                          | Purpose                                                 |
|-------------------------------|---------------------------------------------------------|
| `index.html`                  | Landing page — grid of all skills + regression callout. |
| `skill.html`                  | Drill-down for one skill (`?name=<skill>`).             |
| `nightly.html`                | Canonical nightly status and uplift history.            |
| `assets/app.js`               | Shared JS — manifest loader, sparkline, chart, tables.  |
| `assets/styles.css`           | Styling (light + dark mode).                            |
| `assets/chart.umd.js`         | Vendored Chart.js v4.5.1 (MIT). Used on trend pages.    |
| `assets/LICENSE.chartjs.md`   | Chart.js license, preserved alongside the bundle.       |

## Chart.js vendoring

| Field    | Value                                                         |
|----------|---------------------------------------------------------------|
| Version  | 4.5.1                                                         |
| Source   | <https://cdn.jsdelivr.net/npm/chart.js@4.5.1/dist/chart.umd.js> |
| License  | MIT (see `assets/LICENSE.chartjs.md`)                         |
| SHA-256  | `ECC3CD1EEB8C34D2178E3F59FD63EC5A3D84358C11730AF0B9958DC886D7652A` |

To upgrade, re-download from the pinned URL pattern, refresh the hash, and
update this README.

## Data sources

The dashboard fetches files **relative** to its own URL — no absolute paths
and no `window.location` parsing — so it works at any GitHub Pages base
path. It reads:

- `data/manifest.json` — produced by `scripts/Build-VallyDashboardManifest.ps1`
- `data/<skill>/history.jsonl` — appended by the `pages-history` Vally reporter
- `data/<skill>/runs/<…>.json` — emitted by the `pages-history` Vally reporter

The manifest carries per-skill sparklines, latest metrics, recent regression
data, and repository identity. The skill page links to the workflow artifact
and prints the exact local dashboard command for the selected run.

The full three-trial suite and uplift experiment are intentionally local rather
than scheduled in GitHub Actions:

```powershell
./scripts/Invoke-VallyNightly.ps1 -Publish
```

`-Publish` appends the locally generated per-skill history and run detail,
commits the uplift comparison and canonical nightly summary, rebuilds the
manifest, and opens a pull request from `vally-history/<run-id>` into
`gh-pages`. Raw trajectories and the local SQLite database remain on the
evaluation machine; only compact schema-validated dashboard records are
committed. The PR remains open for manual review and merge even when the valid
run records a regression.

Canonical nightly data lives under:

- `data/nightly-runs/index.json`
- `data/nightly-runs/<run-id>.json`
- `data/uplift/history.jsonl`
- `data/uplift/runs/<run-id>.jsonl`

The dashboard treats canonical nightly runs as the regression baseline.
Changed-skill `main` runs remain visible on skill charts but do not drive
nightly deltas or the largest-regression callout.

`-Runs` sets the trial count for both skill evaluations and the uplift
experiment; the nightly wrapper defaults to three. Direct Vally experiment
runs default to one trial; pass `--param RUNS=3` for three.

Pass rates follow Vally's effective scoring threshold, or the grader's binary
verdict when no threshold is configured. Execution and grader infrastructure
errors are recorded as errors, with grader diagnostics preserved in
`error_message`; valid failing grades remain measurements. Legacy history
remains visible without requiring Vally-specific
metrics. Failed changed-skill Actions runs still attempt to upload detailed
results and publish available history before reporting failure.

`Start-EvalDashboard.ps1` recursively ingests nested `results.jsonl` files
before starting `vally serve`. This supports both local nightly output and
downloaded Actions artifacts. Missing results or ingestion failures stop the
launcher instead of opening an empty dashboard.

The landing page uses `manifest.repository` (e.g. `mthalman/superpowers`)
to build GitHub commit URLs. This avoids guessing the repo from
`location.host` / `location.pathname`, which breaks for forks, user-pages
sites, renamed repos, and custom domains.

## Security

All data is rendered with `textContent` and DOM APIs — never raw HTML
interpolation. `commit_message`, `error`, `metrics`, and adapter strings
are all untrusted.

## Local smoke testing

```powershell
# Stage a fake gh-pages tree.
$pages = New-TemporaryFile | Select-Object -ExpandProperty FullName
Remove-Item $pages; New-Item -ItemType Directory -Path $pages | Out-Null
Copy-Item dashboard/* $pages -Recurse

# Seed minimal data.
New-Item -ItemType Directory -Path "$pages/data/code-review/runs" -Force | Out-Null
Set-Content "$pages/data/code-review/history.jsonl" `
  '{"schema_version":2,"run_id":"123","skill":"code-review","commit":"abc1234abc","short_sha":"abc1234","timestamp":"2026-10-07T10:00:00Z","status":"ok","passed":true,"metrics":{"pass_rate":0.75,"mean_score":0.8,"pass_at_k":0.9,"pass_to_k":0.5,"flaky_count":1,"tokens":1000,"turns":5,"tool_calls":8,"wall_time_ms":12000},"detail_file":"runs/123.json"}'
Set-Content "$pages/data/code-review/runs/123.json" `
  '{"schema_version":2,"metrics":{"pass_rate":0.75},"stimuli":[]}'
pwsh -File scripts/Build-VallyDashboardManifest.ps1 -PagesDir $pages -Repository owner/repo

# Serve.
python -m http.server -d $pages 8080
# Open http://localhost:8080/
```

`file://` browsing won't work — most browsers block `fetch()` against
local files for security. Use a real static server (anything: `python -m
http.server`, `npx http-server`, `caddy file-server`, ...).

## How it ships

Files in this directory are committed on `main`. The Vally skill-eval workflow
copies them onto `gh-pages` alongside the reporter-owned `data/` directory.
