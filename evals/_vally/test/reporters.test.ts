import { mkdtemp, readFile, rm } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { afterEach, describe, expect, it } from "vitest";
import {
  computeStimulusScore,
  createGraderRegistry,
  gradeTrajectory,
  hasGraderError,
  resolveGradePass,
} from "@microsoft/vally";
import { createRequire } from "node:module";
import { DetectionReporter } from "../reporters/detection.js";
import { PagesHistoryReporter } from "../reporters/pages-history.js";

const originalEnvironment = { ...process.env };
const require = createRequire(import.meta.url);
const Ajv = require("ajv");
const roots: string[] = [];

afterEach(async () => {
  process.env = { ...originalEnvironment };
  await Promise.all(roots.splice(0).map((root) => rm(root, { recursive: true, force: true })));
});

describe("PagesHistoryReporter", () => {
  it("writes uniform history and run detail records", async () => {
    const root = await mkdtemp(join(tmpdir(), "vally-pages-"));
    roots.push(root);
    const pagesDir = join(root, "pages");
    const resultsDir = join(root, "results");
    process.env.VALLY_PAGES_DIR = pagesDir;
    process.env.GITHUB_RUN_ID = "123";
    process.env.GITHUB_SHA = "abcdef0123456789";
    process.env.GITHUB_REPOSITORY = "owner/repo";

    const reporter = new PagesHistoryReporter();
    await reporter.onRunStart({ evals: [], source: { version: "0.17.0" } } as never);
    await reporter.onTrialResult({
      item: {
        evalName: "tdd",
        stimulus: { name: "adds-tests-first" },
      },
      result: {
        status: "success",
        durationMs: 2500,
        trajectory: {
          metrics: {
            tokenUsage: { totalTokens: 400 },
            turnCount: 3,
            toolCallCount: 2,
          },
        },
        grade: {
          passed: true,
          score: 0.8,
          details: [],
        },
      },
    } as never);

    await reporter.onRunComplete(
      {
        evals: [
          {
            evalName: "tdd",
            model: "test-model",
            passed: true,
            stimuli: [
              {
                stimulusName: "adds-tests-first",
                multiTrial: {
                  score: computeStimulusScore(
                    "adds-tests-first",
                    [{
                      passed: true,
                      grade: {
                        name: "fixture",
                        kind: "code",
                        passed: true,
                        score: 0.8,
                        evidence: "",
                        details: [],
                      },
                    }],
                    true,
                  ),
                },
              },
            ],
          },
        ],
      } as never,
      { jsonl: join(resultsDir, "results.jsonl") } as never,
    );

    const history = JSON.parse(
      (await readFile(join(pagesDir, "data", "tdd", "history.jsonl"), "utf8")).trim(),
    );
    expect(history.run_id).toBe("123");
    expect(history.run_kind).toBe("main");
    expect(history.metrics).toMatchObject({
      pass_rate: 1,
      mean_score: 0.8,
      pass_at_k: 1,
      pass_to_k: 1,
      tokens: 400,
    });

    const detail = JSON.parse(
      await readFile(join(pagesDir, "data", "tdd", "runs", "123.json"), "utf8"),
    );
    expect(detail.stimuli[0].score.aggregateScore).toBe(0.8);
    expect(detail.trials[0].metrics.tool_calls).toBe(2);
    const schema = JSON.parse(
      await readFile(join(process.cwd(), "schemas", "run-detail.schema.json"), "utf8"),
    );
    const validate = new Ajv({ allErrors: true }).compile(schema);
    expect(validate(detail), JSON.stringify(validate.errors)).toBe(true);
    expect(detail.stimuli[0].score).not.toHaveProperty("trialResults");
  });

  it.each([
    { threshold: 0.8, binaryPassed: false, score: 0.9, passed: true },
    { threshold: 1, binaryPassed: true, score: 0.9, passed: false },
    { threshold: undefined, binaryPassed: false, score: 1, passed: false },
  ])("uses Vally's pass rule for $threshold and $binaryPassed", async ({
    threshold, binaryPassed, score, passed,
  }) => {
    const root = await mkdtemp(join(tmpdir(), "vally-threshold-"));
    roots.push(root);
    process.env.VALLY_PAGES_DIR = root;
    process.env.VALLY_RUN_ID = "threshold";
    const grade = {
      name: "fixture",
      kind: "code" as const,
      passed: binaryPassed,
      score,
      evidence: "",
      details: [],
    };
    expect(resolveGradePass(grade, threshold)).toBe(passed);
    const reporter = new PagesHistoryReporter();
    await reporter.onRunStart({
      evals: [{ evalName: "tdd", threshold }],
    } as never);
    await reporter.onTrialResult({
      item: { evalName: "tdd", stimulus: { name: "fixture" } },
      result: { status: "success", durationMs: 10, trajectory: null, grade },
    } as never);
    await reporter.onRunComplete({
      evals: [{
        evalName: "tdd",
        passed,
        stimuli: [{
          stimulusName: "fixture",
          multiTrial: {
            score: computeStimulusScore("fixture", [{ grade, passed }], true),
          },
        }],
      }],
    } as never, {});
    const detail = JSON.parse(
      await readFile(join(root, "data", "tdd", "runs", "threshold.json"), "utf8"),
    );
    expect(detail.trials[0].passed).toBe(passed);
    expect(detail.metrics.pass_rate).toBe(passed ? 1 : 0);
    expect(detail.metrics.pass_at_k).toBe(passed ? 1 : 0);
  });

  it("marks operational trial errors as errors rather than valid regressions", async () => {
    const root = await mkdtemp(join(tmpdir(), "vally-error-"));
    roots.push(root);
    process.env.VALLY_PAGES_DIR = root;
    process.env.VALLY_RUN_ID = "error";
    const reporter = new PagesHistoryReporter();
    await reporter.onRunComplete({
      evals: [{
        evalName: "tdd",
        passed: false,
        hadExecutionErrors: true,
        stimuli: [],
      }],
    } as never, {});
    const history = JSON.parse(
      await readFile(join(root, "data", "tdd", "history.jsonl"), "utf8"),
    );
    expect(history.status).toBe("error");
  });

  it.each(["main", "nightly"])("preserves grader failures as errors in %s history", async (runKind) => {
    const root = await mkdtemp(join(tmpdir(), "vally-grader-error-"));
    roots.push(root);
    process.env.VALLY_PAGES_DIR = root;
    process.env.VALLY_RUN_ID = "grader-error";
    process.env.VALLY_RUN_KIND = runKind;
    const registry = createGraderRegistry();
    registry.register({
      metadata: {
        name: "broken-judge",
        description: "Failing fixture judge",
        behavior: { requiresWorkspace: false },
        determinism: "complex-static",
        reference: "reference-free",
        temporalScope: "trajectory-level",
        costProfile: "low",
      },
      defaultName: () => "broken-judge",
      grade: async () => { throw new Error("Judge infrastructure unavailable"); },
    });
    const stimulus = { name: "fixture", prompt: "Review this change" };
    const grade = await gradeTrajectory({
      id: "fixture",
      workDir: process.cwd(),
      output: "",
      stimulus,
      events: [],
      metadata: { completedAt: new Date() },
    } as never, [{ type: "broken-judge" }], { registry, stimulus });
    expect(hasGraderError(grade)).toBe(true);
    const reporter = new PagesHistoryReporter();
    await reporter.onRunStart({
      evals: [{ evalName: "tdd", threshold: 0.8 }],
    } as never);
    await reporter.onTrialResult({
      item: { evalName: "tdd", stimulus },
      result: { status: "success", durationMs: 10, trajectory: null, grade },
    } as never);
    await reporter.onRunComplete({
      evals: [{
        evalName: "tdd",
        passed: false,
        hadExecutionErrors: false,
        stimuli: [{
          stimulusName: stimulus.name,
          multiTrial: {
            score: computeStimulusScore(stimulus.name, [{ grade, passed: false }], true),
          },
        }],
      }],
    } as never, {});
    const history = JSON.parse(
      await readFile(join(root, "data", "tdd", "history.jsonl"), "utf8"),
    );
    expect(history.status).toBe("error");
    expect(history.error_message).toContain("Judge infrastructure unavailable");
    const detail = JSON.parse(
      await readFile(join(root, "data", "tdd", "runs", "grader-error.json"), "utf8"),
    );
    expect(detail.status).toBe("error");
    const validate = new Ajv({ allErrors: true }).compile(JSON.parse(
      await readFile(join(process.cwd(), "schemas", "run-detail.schema.json"), "utf8"),
    ));
    expect(validate(detail), JSON.stringify(validate.errors)).toBe(true);
  });

  it("keeps valid failing grades as measurements", async () => {
    const root = await mkdtemp(join(tmpdir(), "vally-valid-regression-"));
    roots.push(root);
    process.env.VALLY_PAGES_DIR = root;
    process.env.VALLY_RUN_ID = "valid-failure";
    const grade = {
      name: "fixture",
      kind: "code" as const,
      passed: false,
      score: 0,
      evidence: "The required behavior was not implemented",
    };
    const reporter = new PagesHistoryReporter();
    await reporter.onTrialResult({
      item: { evalName: "tdd", stimulus: { name: "fixture" } },
      result: { status: "success", durationMs: 10, trajectory: null, grade },
    } as never);
    await reporter.onRunComplete({
      evals: [{ evalName: "tdd", passed: false, stimuli: [] }],
    } as never, {});
    const history = JSON.parse(
      await readFile(join(root, "data", "tdd", "history.jsonl"), "utf8"),
    );
    expect(history.status).toBe("ok");
    expect(history.passed).toBe(false);
    expect(history.error_message).toBeNull();
  });

  it("uses local run identifiers without inventing a workflow URL", async () => {
    const root = await mkdtemp(join(tmpdir(), "vally-local-pages-"));
    roots.push(root);
    process.env.VALLY_PAGES_DIR = join(root, "pages");
    process.env.VALLY_RUN_ID = "local-20261007";
    process.env.VALLY_COMMIT = "abc123";
    process.env.VALLY_REPOSITORY = "owner/repo";
    process.env.GITHUB_RUN_ID = "999";

    const reporter = new PagesHistoryReporter();
    await reporter.onRunComplete(
      {
        evals: [
          {
            evalName: "tdd",
            passed: true,
            stimuli: [],
          },
        ],
      } as never,
      { jsonl: join(root, "results", "results.jsonl") } as never,
    );

    const history = JSON.parse(
      (
        await readFile(
          join(root, "pages", "data", "tdd", "history.jsonl"),
          "utf8",
        )
      ).trim(),
    );
    expect(history.run_id).toBe("local-20261007");
    expect(history.workflow_run_url).toBeNull();
  });
});

describe("DetectionReporter", () => {
  it("calculates required-bug catch-in-any across trials", async () => {
    const root = await mkdtemp(join(tmpdir(), "vally-detection-"));
    roots.push(root);
    const reporter = new DetectionReporter();
    const makeResult = (caught: boolean) =>
      ({
        item: {
          stimulus: { name: "case-one" },
          trialIndex: caught ? 1 : 0,
        },
        result: {
          grade: {
            name: "finding-match",
            graderType: "finding-match",
            metadata: {
              case_id: "case-one",
              bugs: [
                {
                  id: "bug-one",
                  expectation: "required",
                  caught,
                },
              ],
            },
          },
        },
      }) as never;

    await reporter.onTrialResult(makeResult(false));
    await reporter.onTrialResult(makeResult(true));
    await reporter.onRunComplete(
      {} as never,
      { jsonl: join(root, "results.jsonl") } as never,
    );

    const summary = JSON.parse(
      await readFile(join(root, "detection-summary.json"), "utf8"),
    );
    expect(summary.required_bug_count).toBe(1);
    expect(summary.caught_in_any).toBe(1);
    expect(summary.detection_recall).toBe(1);
  });
});
