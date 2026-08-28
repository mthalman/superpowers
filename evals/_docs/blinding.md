# Blinding real-model skill evaluations

Real-model evaluations can measure test awareness instead of normal task
behavior when the candidate sees the rubric, expected findings, model labels,
or experiment-shaped paths. Apply blinding whenever an adapter invokes a model
whose behavior can change in response to those clues.

Deterministic smoke adapters do not require behavioral blinding.

## Separate information by audience

### Candidate-visible

Give the candidate:

- an organic user request;
- a plausible project name and directory structure;
- only the files and skills a normal task would expose;
- no information about other candidates or variants.

### Harness-only

Keep these outside the candidate-visible workspace:

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

Separate judge calls can drift in calibration. If separate calls are
unavoidable, report that limitation.

## Verify execution evidence

If the host exposes transcripts or tool-call records, verify which files,
skills, and commands the candidate actually used. Reading a skill does not
prove that the candidate applied it, and citing a skill does not prove that it
was read.

Execution evidence is adapter-dependent. Adapters should declare which evidence
they can provide. Do not hard-code a host's private transcript path into the
cross-skill contract.

## Report limitations

Record:

- information visible to candidates;
- information visible to judges;
- whether output labels were randomized;
- whether comparisons shared one judge pass;
- which execution evidence was available;
- known sources of leakage or calibration drift.

An evaluation with material leakage is not a clean comparison. Preserve its
artifacts, but label the result accordingly.
