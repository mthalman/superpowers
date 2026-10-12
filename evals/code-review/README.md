# Code-review evaluation

`eval.yaml` runs the worked detection fixtures through Vally. Fixture context
and patches are staged into project-shaped workspaces. Hidden expected findings
are staged through Vally's `grading_environment`, outside the candidate
workspace.

Setup keeps the proposed diff at `change.patch` and commits the supplied
context as the initial workspace. The source trees are contextual snapshots,
not uniformly pre-change files, and some diffs are illustrative excerpts.
Reviewers read the diff alongside the source; setup does not apply it.
The model-free fixture tests materialize all seven cases, verify that the
diff and source files are unchanged, and check that expected findings remain
outside the candidate workspace.

The TypeScript `finding-match` grader parses the review's structured findings
and grants credit only when semantic keywords and the expected file region
match. It also enforces the fixture's verdict floor and penalizes distractor
findings. A verdict below the fixture's floor forces the numeric score to zero,
so Vally's threshold-based pass rule cannot override that failure.
The `detection` reporter calculates required-bug catch-in-any across
trials.

Run the evaluation from the repository root after building the plugins:

```powershell
npm ci --prefix evals/_vally
npm run build --prefix evals/_vally
$env:VALLY_TELEMETRY_OPTOUT = '1'
node evals/_vally/node_modules/@microsoft/vally-cli/dist/index.js eval `
  --eval-spec evals/code-review/eval.yaml `
  --grader-plugin evals/_vally/dist/graders/finding-match.js `
  --reporter-plugin evals/_vally/dist/reporters/detection.js
```
