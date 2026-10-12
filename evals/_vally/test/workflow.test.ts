import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { resolveExperiment } from "@microsoft/vally";

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
