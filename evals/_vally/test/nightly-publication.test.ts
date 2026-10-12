import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { afterEach, describe, expect, it } from "vitest";
import { computeStimulusScore } from "@microsoft/vally";
import { PagesHistoryReporter } from "../reporters/pages-history.js";

const execFileAsync = promisify(execFile);
const originalEnvironment = { ...process.env };
const roots: string[] = [];
afterEach(async () => {
  process.env = { ...originalEnvironment };
  await Promise.all(roots.splice(0).map((root) => rm(root, { recursive: true, force: true })));
});
const skills = [
  "code-review",
  "defend-the-diff",
  "over-engineering-review",
  "tdd",
  "validation-scenarios",
];

describe("nightly publication builder", () => {
  it("writes validated canonical summaries and uplift history", async () => {
    const root = await mkdtemp(join(tmpdir(), "vally-nightly-"));
    roots.push(root);
    const pagesDir = join(root, "pages");
    const runId = "20261007-120000123-abcdef0";
    process.env.VALLY_PAGES_DIR = pagesDir;
    process.env.VALLY_RUN_ID = runId;
    process.env.VALLY_RUN_KIND = "nightly";
    process.env.VALLY_COMMIT = "abcdef0123456789";
    process.env.VALLY_REPOSITORY = "owner/repo";
    for (const skill of skills) {
      const reporter = new PagesHistoryReporter();
      const grade = {
        name: "fixture",
        kind: "code" as const,
        passed: true,
        score: 0.9,
        evidence: "",
        details: [],
      };
      const stimulusName = `${skill}--fixture`;
      await reporter.onRunStart({
        evals: [{ evalName: skill, threshold: 0.8 }],
        source: { version: "0.17.0" },
      } as never);
      for (let index = 0; index < 3; index++) {
        await reporter.onTrialResult({
          item: { evalName: skill, stimulus: { name: stimulusName } },
          result: { status: "success", durationMs: 100, grade, trajectory: null },
        } as never);
      }
      await reporter.onRunComplete({
        evals: [{
          evalName: skill,
          passed: true,
          model: "test-model",
          stimuli: [{
            stimulusName,
            multiTrial: {
              score: computeStimulusScore(
                stimulusName,
                Array.from({ length: 3 }, () => ({ grade, passed: true })),
                true,
              ),
            },
          }],
        }],
      } as never, {});
    }

    const comparisonFile = join(root, "uplift-comparisons.jsonl");
    const upliftStimuli = skills
      .filter((skill) => skill !== "code-review")
      .map((skill) => ({
        stimulusName: `${skill}--fixture`,
        trials: Array.from({ length: 3 }, () => ({
          score: 0.4, winner: "treatment", magnitude: "moderate",
        })),
        meanScore: 0.4,
      }));
    await writeFile(
      comparisonFile,
      `${JSON.stringify({
        type: "comparison",
        baseline: "without-skill",
        treatment: "with-skill",
        summary: {
          trialCount: 12,
          erroredCount: 0,
          meanScore: 0.4,
          ciLow: 0.4,
          ciHigh: 0.4,
          wins: 12,
          ties: 0,
          losses: 0,
          winRate: 1,
        },
        stimuli: upliftStimuli,
        unmatchedBaseline: [],
        unmatchedTreatment: [],
      })}\n`,
    );

    await execFileAsync(process.execPath, [
      join(process.cwd(), "dist", "tools", "build-nightly-publication.js"),
      "--pages-dir",
      pagesDir,
      "--comparison-file",
      comparisonFile,
      "--run-id",
      runId,
      "--source-sha",
      "abcdef0123456789",
      "--publication-branch",
      `vally-history/${runId}`,
      "--runs",
      "3",
      "--repository",
      "owner/repo",
      "--repo-root",
      join(process.cwd(), "..", ".."),
      "--output-relative",
      `vally-results/nightly-${runId}`,
    ]);

    const summary = JSON.parse(
      await readFile(
        join(pagesDir, "data", "nightly-runs", `${runId}.json`),
        "utf8",
      ),
    );
    expect(summary.status).toBe("clean");
    expect(summary.skills).toHaveLength(5);
    expect(summary.uplift.skills).toHaveLength(4);
    expect(summary.uplift.overall.verdict).toBe("improvement");

    const index = JSON.parse(
      await readFile(join(pagesDir, "data", "nightly-runs", "index.json"), "utf8"),
    );
    expect(index.runs[0].run_id).toBe(runId);
    await execFileAsync("pwsh", [
      "-NoProfile",
      "-File",
      join(process.cwd(), "..", "..", "scripts", "Build-VallyDashboardManifest.ps1"),
      "-PagesDir",
      pagesDir,
      "-Repository",
      "owner/repo",
    ]);
    const manifest = JSON.parse(
      await readFile(join(pagesDir, "data", "manifest.json"), "utf8"),
    );
    expect(manifest.skills.map((skill: { name: string }) => skill.name).sort())
      .toEqual([...skills].sort());
    expect(manifest.uplift_history).toBe("data/uplift/history.jsonl");
  }, 30_000);

  it("rejects raw trajectory data in compact publication records", async () => {
    const root = await mkdtemp(join(tmpdir(), "vally-nightly-invalid-"));
    roots.push(root);
    const pagesDir = join(root, "pages");
    const runId = "20261007-120000123-abcdef0";
    for (const skill of skills) {
      const skillDir = join(pagesDir, "data", skill);
      await mkdir(join(skillDir, "runs"), { recursive: true });
      const metrics = {
        pass_rate: 1,
        mean_score: 0.9,
        pass_at_k: 1,
        pass_to_k: 1,
        flaky_count: 0,
        tokens: 10,
        turns: 2,
        tool_calls: 1,
        wall_time_ms: 100,
      };
      await writeFile(
        join(skillDir, "history.jsonl"),
        `${JSON.stringify({
          schema_version: 2,
          run_id: runId,
          run_kind: "nightly",
          skill,
          commit: "abcdef0123456789",
          short_sha: "abcdef0",
          timestamp: "2026-10-07T12:00:00.000Z",
          status: "ok",
          passed: true,
          metrics,
          model: "test-model",
          detail_file: `runs/${runId}.json`,
        })}\n`,
      );
      await writeFile(
        join(skillDir, "runs", `${runId}.json`),
        JSON.stringify({
          schema_version: 2,
          run_id: runId,
          run_kind: "nightly",
          skill,
          status: "completed",
          passed: true,
          metrics,
          stimuli: [],
          trials:
            skill === "code-review"
              ? [{ trajectory: { raw: "must not publish" } }]
              : [],
        }),
      );
    }

    const comparisonFile = join(root, "uplift-comparisons.jsonl");
    await writeFile(
      comparisonFile,
      `${JSON.stringify({
        type: "comparison",
        baseline: "without-skill",
        treatment: "with-skill",
        summary: {
          trialCount: 4,
          erroredCount: 0,
          meanScore: 0.4,
          ciLow: 0.4,
          ciHigh: 0.4,
          wins: 4,
          ties: 0,
          losses: 0,
          winRate: 1,
        },
        stimuli: skills
          .filter((skill) => skill !== "code-review")
          .map((skill) => ({
            stimulusName: `${skill}--fixture`,
            trials: [{ score: 0.4 }],
          })),
        unmatchedBaseline: [],
        unmatchedTreatment: [],
      })}\n`,
    );

    await expect(
      execFileAsync(process.execPath, [
        join(process.cwd(), "dist", "tools", "build-nightly-publication.js"),
        "--pages-dir",
        pagesDir,
        "--comparison-file",
        comparisonFile,
        "--run-id",
        runId,
        "--source-sha",
        "abcdef0123456789",
        "--publication-branch",
        `vally-history/${runId}`,
        "--runs",
        "3",
        "--repository",
        "owner/repo",
        "--repo-root",
        join(process.cwd(), "..", ".."),
        "--output-relative",
        `vally-results/nightly-${runId}`,
      ]),
    ).rejects.toThrow(/run-detail validation failed/);
  });
});
