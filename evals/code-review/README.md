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
Added-line and context-line citations to `change.patch` are mapped to their
post-change source locations before matching. Patch headers, deleted lines,
out-of-range references, and lines belonging to another file do not create a
matching source reference. Semantic requirements and scoring thresholds are
unchanged.
The `detection` reporter calculates required-bug catch-in-any across
trials.

## Fixture integrity

Candidate source and tests must use valid language syntax and must not identify the
expected findings in comments. Intentional product defects belong in the
fixture; syntax errors and oracle annotations do not, unless those are the
behavior being evaluated. The model-free tests check for oracle annotations and
exercise the runnable pagination and cache cases.

The cache fixture's patch replaces a single-flight Promise cache with a
resolved-value cache. A gated concurrency test verifies one disk read before
the change and two after it. Both the cache and log-writer patches are
reverse-applied and reapplied against their proposed source snapshots.

Verdict floors follow the skill's verdict definitions, not the number of
required findings. The refund fixture requires Needs Changes because its
defects can be fixed incrementally. Both required findings are still mandatory;
LGTM and an incomplete review still fail.

Read-only pagination environments set `PYTHONDONTWRITEBYTECODE=1`, including
the defend-the-diff and validation-scenarios consumers of the same fixture.
Tests reproduce bytecode-induced snapshot changes, verify that Python execution
with bytecode disabled leaves an empty diff, and verify that source edits
still fail the read-only grader.

Results from revised fixtures are not directly comparable with historical
results that used leaked annotations, a pre-existing cache race, an invalid
Python header, or an incompatible verdict floor. Preserve those historical
records rather than retroactively treating them as measurements of the
repaired cases.

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
