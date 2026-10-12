import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { hasGraderError, resolveGradePass } from "@microsoft/vally";
import type {
  GraderResult,
  PlanReporter,
  PlanRunStartContext,
  ReporterRegistry,
  RunArtifacts,
  RunSummary,
  TrialResult,
  TrialWorkItem,
} from "@microsoft/vally";

interface TrialSnapshot {
  evalName: string;
  stimulus: string;
  passed: boolean;
  score: number | null;
  durationMs: number;
  metrics: Record<string, number>;
  graders: Array<{
    name: string;
    passed: boolean;
    score: number;
    evidence: string;
  }>;
}

function outputDirectory(artifacts: RunArtifacts): string | undefined {
  if (artifacts.jsonl) return dirname(artifacts.jsonl);
  return artifacts.sessionLogsDir;
}

function finite(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function graderErrorMessages(result: GraderResult): string[] {
  const nested = (result.details ?? []).flatMap(graderErrorMessages);
  if (nested.length > 0) return nested;
  return result.status === "error"
    ? [`${result.configuredName ?? result.name}: ${result.evidence}`]
    : [];
}

async function appendJsonl(path: string, value: unknown): Promise<void> {
  let current = "";
  try {
    current = await readFile(path, "utf8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }
  const prefix = current.length > 0 && !current.endsWith("\n") ? `${current}\n` : current;
  await writeFile(path, `${prefix}${JSON.stringify(value)}\n`, "utf8");
}

export class PagesHistoryReporter implements PlanReporter {
  readonly name = "pages-history";
  private context?: PlanRunStartContext;
  private readonly trials: TrialSnapshot[] = [];
  private readonly graderErrors = new Map<string, Set<string>>();

  async onRunStart(context: PlanRunStartContext): Promise<void> {
    this.context = context;
  }

  async onTrialResult(event: {
    item: TrialWorkItem;
    result: TrialResult;
  }): Promise<void> {
    const trajectory = event.result.trajectory;
    const grade = event.result.grade;
    if (grade && hasGraderError(grade)) {
      const errors = this.graderErrors.get(event.item.evalName) ?? new Set<string>();
      for (const message of graderErrorMessages(grade)) {
        errors.add(`${event.item.stimulus.name}: ${message}`);
      }
      this.graderErrors.set(event.item.evalName, errors);
    }
    const threshold = this.context?.evals.find((evaluation) =>
      evaluation.evalName === event.item.evalName &&
      evaluation.evalFilePath === event.item.evalFilePath &&
      evaluation.variant === event.item.variant &&
      evaluation.model === event.item.model
    )?.threshold;
    this.trials.push({
      evalName: event.item.evalName,
      stimulus: event.item.stimulus.name,
      passed: event.result.status === "success" && grade !== null &&
        resolveGradePass(grade, threshold),
      score: grade?.score ?? null,
      durationMs: event.result.durationMs,
      metrics: {
        tokens: finite(trajectory?.metrics.tokenUsage.totalTokens),
        turns: finite(trajectory?.metrics.turnCount),
        tool_calls: finite(trajectory?.metrics.toolCallCount),
        wall_time_ms: event.result.durationMs,
      },
      graders: (grade?.details ?? []).map((result) => ({
        name: result.configuredName ?? result.name,
        passed: result.passed,
        score: result.score,
        evidence: result.evidence,
      })),
    });
  }

  async onRunComplete(
    summary: RunSummary,
    artifacts: RunArtifacts,
    status = "completed",
  ): Promise<void> {
    const pagesDir = process.env.VALLY_PAGES_DIR;
    if (!pagesDir) return;
    const explicitRunId = process.env.VALLY_RUN_ID;
    const runId =
      explicitRunId ??
      process.env.GITHUB_RUN_ID ??
      `${new Date().toISOString().replaceAll(":", "-")}-${process.pid}`;
    const commit = process.env.VALLY_COMMIT ?? process.env.GITHUB_SHA ?? "local";
    const runKind = process.env.VALLY_RUN_KIND ?? "main";
    const timestamp = new Date().toISOString();
    const repository =
      process.env.VALLY_REPOSITORY ??
      process.env.GITHUB_REPOSITORY ??
      String(this.context?.metadata?.repository ?? "");
    const workflowRunUrl =
      process.env.VALLY_WORKFLOW_RUN_URL ??
      (!explicitRunId && repository && process.env.GITHUB_RUN_ID
        ? `https://github.com/${repository}/actions/runs/${process.env.GITHUB_RUN_ID}`
        : null);

    for (const evalSummary of summary.evals) {
      const graderErrors = this.graderErrors.get(evalSummary.evalName);
      const failed = status !== "completed" || !!evalSummary.error ||
        !!evalSummary.hadExecutionErrors || (graderErrors?.size ?? 0) > 0;
      const errorMessages = [
        ...(evalSummary.error ? [String(evalSummary.error)] : []),
        ...(graderErrors ?? []),
      ];
      const evalTrials = this.trials.filter(
        (trial) => trial.evalName === evalSummary.evalName,
      );
      const passCount = evalTrials.filter((trial) => trial.passed).length;
      const scores = evalTrials
        .map((trial) => trial.score)
        .filter((score): score is number => score !== null);
      const stimulusScores = evalSummary.stimuli
        .map((stimulus) => stimulus.multiTrial.score)
        .filter((score) => score !== null);
      const passAtK = stimulusScores.length
        ? stimulusScores.reduce((sum, score) => sum + score.multiTrial.passAtK, 0) /
          stimulusScores.length
        : null;
      const passToK = stimulusScores.length
        ? stimulusScores.reduce((sum, score) => sum + score.multiTrial.passToTheK, 0) /
          stimulusScores.length
        : null;
      const flakyCount = stimulusScores.filter((score) => score.flaky).length;
      const metrics = {
        pass_rate: evalTrials.length ? passCount / evalTrials.length : 0,
        mean_score: scores.length
          ? scores.reduce((sum, score) => sum + score, 0) / scores.length
          : null,
        pass_at_k: passAtK,
        pass_to_k: passToK,
        flaky_count: flakyCount,
        tokens: evalTrials.reduce((sum, trial) => sum + trial.metrics.tokens, 0),
        turns: evalTrials.reduce((sum, trial) => sum + trial.metrics.turns, 0),
        tool_calls: evalTrials.reduce((sum, trial) => sum + trial.metrics.tool_calls, 0),
        wall_time_ms: evalTrials.reduce((sum, trial) => sum + trial.metrics.wall_time_ms, 0),
      };
      const skill = evalSummary.evalName;
      const skillDir = join(pagesDir, "data", skill);
      const runFile = join("runs", `${runId}.json`).replaceAll("\\", "/");
      await mkdir(join(skillDir, "runs"), { recursive: true });
      await writeFile(
        join(skillDir, runFile),
        `${JSON.stringify(
          {
            schema_version: 2,
            run_id: runId,
            run_kind: runKind,
            skill,
            status: failed && status === "completed" ? "error" : status,
            passed: evalSummary.passed,
            metrics,
            stimuli: evalSummary.stimuli.map((stimulus) => {
              const score = stimulus.multiTrial.score;
              return {
                name: stimulus.stimulusName,
                score: score ? {
                  aggregateScore: score.aggregateScore,
                  multiTrial: {
                    passAtK: score.multiTrial.passAtK,
                    passToTheK: score.multiTrial.passToTheK,
                  },
                  flaky: score.flaky,
                } : null,
              };
            }),
            trials: evalTrials,
          },
          null,
          2,
        )}\n`,
        "utf8",
      );
      await appendJsonl(join(skillDir, "history.jsonl"), {
        schema_version: 2,
        run_id: runId,
        run_kind: runKind,
        skill,
        commit,
        short_sha: commit.slice(0, 7),
        timestamp,
        status: failed ? "error" : "ok",
        passed: evalSummary.passed,
        metrics,
        model: evalSummary.model,
        vally_version: this.context?.source?.version,
        workflow_run_url: workflowRunUrl,
        detail_file: runFile,
        error_message: errorMessages.length > 0 ? errorMessages.join("\n") : null,
      });
    }

    const outputDir = outputDirectory(artifacts);
    if (outputDir) {
      await mkdir(outputDir, { recursive: true });
      await writeFile(
        join(outputDir, "pages-history-status.json"),
        `${JSON.stringify({ pages_dir: pagesDir, run_id: runId }, null, 2)}\n`,
        "utf8",
      );
    }
  }
}

export function registerReporters(registry: ReporterRegistry): void {
  registry.register(new PagesHistoryReporter());
}
