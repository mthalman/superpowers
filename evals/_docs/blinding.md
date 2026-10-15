# Blinding real-model skill evaluations

Real-model evaluations can measure test awareness instead of normal task
behavior when the candidate sees the rubric, expected findings, model labels,
or experiment-shaped paths. Apply blinding whenever Vally invokes a model
whose behavior can change in response to those clues.

## Separate information by audience

### Candidate-visible

Give the candidate:

- an organic user request;
- a plausible project name and directory structure;
- only the files and skills a normal task would expose;
- no information about other candidates or variants.

### Harness-only

Keep these outside the candidate-visible workspace. Use Vally's
`grading_environment` for hidden fixture truth:

- expected results;
- fixture metadata;
- scoring code;
- variant identity;
- adapter and model identity;
- experiment notes.

### Judge-visible

Give the judge:

- the private rubric;
- outputs labeled with randomized neutral identifiers;
- all compared outputs in one scoring pass when calibration must be shared.

Do not disclose candidate model or variant identity to the judge.

## Author an organic prompt

State the user's goal, not the behavior being measured.

Weak:

> Demonstrate that you follow the code-review skill and list every principle
> you applied.

Strong:

> Review this change for merge-blocking defects.

Do not ask candidates to report which skills, rules, or files they consulted.
Measure instruction use from observable behavior and available execution
records, not self-report.

An explicit-only skill may be named in an ordinary user request. This is not
an instruction to report activation or repeat the evaluation rubric. With the
pinned Copilot SDK executor, a named request can cause the skill to be read
without producing a native activation event. The defend-the-diff evaluation
therefore requires complete instruction exposure, verified by
`evals/_vally/graders/skill-read.ts`. It accepts `view`, PowerShell `Get-Content`
(including `gc`, `cat`, and `type` aliases), and Bash `cat`, `head`, `tail`,
and `sed` reads. PowerShell readers may appear in script blocks, grouped
expressions, or variable assignments. Quoted command text and comments do not
count as reads. Multiple successful, completed calls may collectively expose
the instructions to one agent.
The grader checks every distinct nonblank line of the workspace's staged
`defend-the-diff/SKILL.md`, allowing whitespace and line-number metadata.
It does not combine partial reads from different agents.

The compiled helper is staged only through `grading_environment` and runs
through Vally's built-in `program` grader, so direct evals and uplift variants
use the same check without a custom plugin. Missing-file responses, directory
listings, unrelated paths, failed or incomplete calls, truncated instructions,
landmark-only excerpts, and self-report do not satisfy the prerequisite. The
separate behavioral rubric still verifies the panel workflow, and `diff-empty`
still detects repository edits. A read alone is not evidence of compliance.

## Sanitize the environment

Do not expose experiment terms through candidate-visible paths, filenames,
prompts, environment variables, or seeded documentation. Terms such as
`candidate`, `expected`, `rubric`, `score`, `benchmark`, and `eval` can reveal
the setup.

Use project-shaped names. Keep fixture truth and scoring artifacts in a
separate harness directory that the candidate cannot read.

The meaningful boundary is candidate visibility. The repository and harness
may use evaluation terminology outside that boundary.

## Compare variants consistently

When comparing variants:

1. Use the same organic prompt and equivalent project state.
2. Randomize neutral output labels.
3. Score all outputs in one judge pass when possible.
4. Keep the judge blind to model and variant identity.
5. Record the random label mapping in harness-only artifacts.
6. Reuse the same rubric and scoring scale.

Keep supporting skills needed for routing in the stimulus environment so both
variants retain them. The unresolved TDD API case exposes `arena` and
`dispatching-parallel-agents` in both variants; only the evaluated root skill
differs. Its activation prerequisite checks the intended destination, `arena`,
not the deliberately inapplicable `tdd` workflow. The request explicitly
withholds approval for all repository edits, including scaffolding or tests,
matching its read-only grader.

Separate judge calls can drift in calibration. If separate calls are
unavoidable, report that limitation.

## Verify execution evidence

If the host exposes transcripts or tool-call records, verify which files,
skills, and commands the candidate actually used. Reading a skill does not
prove that the candidate applied it, and citing a skill does not prove that it
was read.

Vally trajectories are the execution evidence contract. Graders may request
`trajectory`, `diff`, `golden_patch`, or `repo` evidence. Do not depend on a
host-private transcript path.

## Report limitations

Record:

- information visible to candidates;
- information visible to judges;
- whether output labels were randomized;
- whether comparisons shared one judge pass;
- which execution evidence was available;
- known sources of leakage or calibration drift.

Vally's experiment comparison judge randomizes neutral A/B labels. Preserve
the experiment output and comparison JSONL so that this provenance is
auditable.

An evaluation with material leakage is not a clean comparison. Preserve its
artifacts, but label the result accordingly.
