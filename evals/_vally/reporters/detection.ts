import { mkdir, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import type {
  GraderResult,
  PlanReporter,
  ReporterRegistry,
  RunArtifacts,
  RunSummary,
  TrialResult,
  TrialWorkItem,
} from "@microsoft/vally";

interface DetectionTrial {
  caseId: string;
  trial: number;
  bugs: Array<{ id: string; expectation: string; caught: boolean }>;
}

function findResult(result: GraderResult | null, type: string): GraderResult | undefined {
  if (!result) return undefined;
  if (result.graderType === type || result.name === type) return result;
  for (const detail of result.details ?? []) {
    const found = findResult(detail, type);
    if (found) return found;
  }
  return undefined;
}

function outputDirectory(artifacts: RunArtifacts): string | undefined {
  if (artifacts.jsonl) return dirname(artifacts.jsonl);
  return artifacts.sessionLogsDir;
}

export class DetectionReporter implements PlanReporter {
  readonly name = "detection";
  private readonly trials: DetectionTrial[] = [];

  async onTrialResult(event: {
    item: TrialWorkItem;
    result: TrialResult;
  }): Promise<void> {
    const grade = findResult(event.result.grade, "finding-match");
    if (!grade) return;
    const metadata = grade.metadata ?? {};
    const bugs = Array.isArray(metadata.bugs) ? metadata.bugs : [];
    this.trials.push({
      caseId: String(metadata.case_id ?? event.item.stimulus.name),
      trial: event.item.trialIndex ?? 0,
      bugs: bugs
        .filter((bug): bug is Record<string, unknown> => typeof bug === "object" && bug !== null)
        .map((bug) => ({
          id: String(bug.id ?? ""),
          expectation: String(bug.expectation ?? ""),
          caught: bug.caught === true,
        })),
    });
  }

  async onRunComplete(
    _summary: RunSummary,
    artifacts: RunArtifacts,
  ): Promise<void> {
    const directory = outputDirectory(artifacts);
    if (!directory || this.trials.length === 0) return;
    const required = new Map<string, boolean>();
    for (const trial of this.trials) {
      for (const bug of trial.bugs.filter((item) => item.expectation === "required")) {
        const key = `${trial.caseId}/${bug.id}`;
        required.set(key, (required.get(key) ?? false) || bug.caught);
      }
    }
    const caught = [...required.values()].filter(Boolean).length;
    const detail = {
      schema_version: 1,
      required_bug_count: required.size,
      caught_in_any: caught,
      detection_recall: required.size === 0 ? null : caught / required.size,
      bugs: [...required].map(([key, wasCaught]) => ({ key, caught: wasCaught })),
      trials: this.trials,
    };
    await mkdir(directory, { recursive: true });
    await writeFile(
      join(directory, "detection-summary.json"),
      `${JSON.stringify(detail, null, 2)}\n`,
      "utf8",
    );
  }
}

export function registerReporters(registry: ReporterRegistry): void {
  registry.register(new DetectionReporter());
}
