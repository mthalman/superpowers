# Threat Model Quality Rubric

This reference covers final quality checks before handing off a threat model document.

## Output Quality Checklist

Before finalizing document:

- [ ] Every component mentioned has at least one threat analyzed.
- [ ] Every data flow has trust boundaries identified.
- [ ] Every threat has a mitigation or explicit TODO.
- [ ] No assumptions are made without flagging them in the Assumptions section.
- [ ] Open questions from the interview are documented.
- [ ] Action items are numbered and actionable.

## Risk and Mitigation Quality

A strong risk statement:

- names the specific component, actor, or data flow;
- explains what could go wrong;
- maps to a STRIDE category when useful;
- avoids generic threats that could apply to any system.

A strong mitigation:

- describes the actual control or planned control;
- states whether the control exists today;
- identifies owner or follow-up when incomplete;
- does not hide uncertainty.

## TODO Quality

Use a TODO when mitigation is incomplete, unknown, or accepted for later work.
Every TODO should be actionable and traceable to a risk.

Prefer:

```markdown
**TODO**: Confirm whether service-to-service calls enforce mTLS and document the owner.
```

Avoid:

```markdown
**TODO**: Security.
```
