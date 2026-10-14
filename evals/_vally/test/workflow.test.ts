import { dirname, resolve } from "node:path";
import { readFile } from "node:fs/promises";
import { describe, expect, it } from "vitest";
import {
  computeMetrics, gradeTrajectory, loadEvalWithParams, resolveEnvironment,
  resolveExperiment, resolveStimulus,
} from "@microsoft/vally";
import type { Trajectory } from "@microsoft/vally";

describe("nightly trial configuration", () => {
  it("explicitly invokes the explicit-only explainability skill", async () => {
    const { spec } = await loadEvalWithParams(
      resolve(process.cwd(), "..", "defend-the-diff", "eval.yaml"),
      { cliParams: { RUNS: "1" } },
    );
    for (const stimulus of spec.stimuli) {
      expect(stimulus.prompt).toMatch(/defend-the-diff/);
    }
  });

  it("grades complete explicit-only skill reads, not self-reported invocation", async () => {
    const { spec } = await loadEvalWithParams(
      resolve(process.cwd(), "..", "defend-the-diff", "eval.yaml"),
      { cliParams: { RUNS: "1" } },
    );
    const content = await readFile(resolve(
      process.cwd(), "..", "..", "skills", "defend-the-diff", "SKILL.md",
    ), "utf8");
    const names = spec.stimuli.flatMap((item) => item.graders?.map((grader) => grader.name).filter(Boolean) ?? []);
    expect(new Set(names).size).toBe(names.length);
    for (const raw of spec.stimuli) {
      const graders = raw.graders?.filter((grader) => grader.type !== "prompt" && grader.type !== "diff-empty") ?? [];
      expect(graders).toHaveLength(1);
      for (const sample of [
        { path: "defend-the-diff/SKILL.md", content, passed: true },
        { path: "C:\\project\\defend-the-diff\\SKILL.md", content, passed: true },
        { path: "defend-the-diff/SKILL.md", content: "Error: file not found", passed: false },
        { path: "defend-the-diff", content: "SKILL.md\nreferences", passed: false },
        { path: "unrelated/SKILL.md", content, passed: false },
        { path: "defend-the-diff/SKILL.md", content: content.slice(0, 200), passed: false },
        { path: undefined, content: "I invoked defend-the-diff", passed: false },
      ]) {
        const timestamp = new Date();
        const trajectory: Trajectory = {
          id: "skill-read",
          stimulus: { name: raw.name, prompt: raw.prompt! },
          workDir: process.cwd(),
          output: "I invoked defend-the-diff",
          metrics: computeMetrics([]),
          metadata: { model: "none", skillsLoaded: [], executor: "copilot-sdk", sessionID: "none" },
          events: sample.path ? [{
            type: "tool_call", timestamp,
            data: { toolName: "view", toolCallId: "read-skill", arguments: { path: sample.path } },
          }, {
            type: "tool_result", timestamp,
            data: { toolName: "view", toolCallId: "read-skill", success: true, result: { content: sample.content } },
          }] : [],
        };
        expect((await gradeTrajectory(trajectory, graders, { stimulus: trajectory.stimulus })).passed)
          .toBe(sample.passed);
      }
    }
  });

  it("preserves TDD routing dependencies in both uplift variants", async () => {
    const experiment = await resolveExperiment(
      resolve(process.cwd(), "..", "experiments", "skill-uplift.experiment.yaml"),
      { cliParams: { RUNS: "1" } },
    );
    for (const plan of experiment.plans.filter((item) => item.effectiveSpec.name === "tdd")) {
      const directory = dirname(plan.evalFile);
      const spec = plan.effectiveSpec;
      const raw = spec.stimuli.find((item) => /unresolved-rate-limiter/.test(item.name))!;
      const stimulus = resolveStimulus(
        raw, resolveEnvironment(spec.environment, {}), {}, spec.tags, directory,
      );
      const skills = stimulus.environment?.skills?.map((path) => resolve(directory, path)) ?? [];
      for (const name of ["arena", "dispatching-parallel-agents"]) {
        expect(skills).toContain(resolve(directory, "..", "..", "skills", name));
      }
      expect(skills.includes(resolve(directory, "..", "..", "skills", "tdd")))
        .toBe(plan.variant === "with-skill");
    }
  });

  it("requires arena routing and design approval before unresolved TDD scaffolding", async () => {
    const { spec } = await loadEvalWithParams(
      resolve(process.cwd(), "..", "tdd", "eval.yaml"), { cliParams: { RUNS: "1" } },
    );
    const raw = spec.stimuli.find((item) => /unresolved-rate-limiter/.test(item.name))!;
    expect(raw.prompt).toMatch(/until I approve/);
    expect(raw.prompt).toMatch(/Do not edit the repository/);
    expect(raw.graders?.find((grader) => grader.type === "skill-invocation")?.config?.required)
      .toEqual(["arena"]);
    expect(raw.graders?.some((grader) => grader.type === "diff-empty")).toBe(true);
  });

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
