import { readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { resolveExperiment } from "@microsoft/vally";
import { parse } from "yaml";

describe("nightly trial configuration", () => {
  it.each([1, 5])("applies %i trials to every uplift plan", async (runs) => {
    const experiment = await resolveExperiment(
      resolve(process.cwd(), "..", "experiments", "skill-uplift.experiment.yaml"),
      { cliParams: { RUNS: String(runs) } },
    );
    expect(experiment.plans).toHaveLength(8);
    for (const plan of experiment.plans) {
      expect(plan.effectiveSpec.defaults?.runs).toBe(runs);
      expect(plan.effectiveSpec.stimuli).toHaveLength(3);
    }
  });
});

describe("changed-skill CI preservation", () => {
  it("preserves outputs before failing the quality gate", async () => {
    const workflow = parse(await readFile(
      join(process.cwd(), "..", "..", ".github", "workflows", "skill-eval.yml"),
      "utf8",
    ));
    const steps = workflow.jobs.evaluate.steps;
    const evaluation = steps.find((step: { name: string }) =>
      step.name === "Evaluate changed skills");
    expect(evaluation.id).toBe("evaluations");
    expect(evaluation["continue-on-error"]).toBe(true);
    const uploadIndex = steps.findIndex((step: { name: string }) =>
      step.name === "Upload detailed results");
    const publishIndex = steps.findIndex((step: { name: string }) =>
      step.name === "Publish Pages data");
    const gateIndex = steps.findIndex((step: { name: string }) =>
      step.name === "Report evaluation failure");
    expect(steps[uploadIndex].if).toContain("!cancelled()");
    expect(gateIndex).toBeGreaterThan(uploadIndex);
    expect(gateIndex).toBeGreaterThan(publishIndex);
    expect(steps[gateIndex].if).toContain("steps.evaluations.outcome == 'failure'");
    expect(steps[gateIndex].run).toContain("exit 1");
  });
});
