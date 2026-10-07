import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { createRequire } from "node:module";
import type { ErrorObject, Options as AjvOptions, ValidateFunction } from "ajv";

type JsonObject = Record<string, any>;

interface AjvInstance {
  compile(schema: object): ValidateFunction;
  errorsText(
    errors?: ErrorObject[] | null,
    options?: { separator?: string },
  ): string;
}

const require = createRequire(import.meta.url);
const Ajv = require("ajv") as new (options?: AjvOptions) => AjvInstance;

interface Options {
  pagesDir: string;
  comparisonFile: string;
  runId: string;
  sourceSha: string;
  publicationBranch: string;
  runs: number;
  repository: string;
  repoRoot: string;
  outputRelative: string;
  automationSessionUrl: string | null;
}

interface ComparisonSummary {
  trial_count: number;
  mean_score: number;
  ci_low: number;
  ci_high: number;
  wins: number;
  ties: number;
  losses: number;
  win_rate: number;
  verdict: "improvement" | "inconclusive" | "regression";
}

const expectedSkills = [
  "code-review",
  "defend-the-diff",
  "over-engineering-review",
  "tdd",
  "validation-scenarios",
];

const upliftSkills = expectedSkills.filter((skill) => skill !== "code-review");
const t95 = [
  0, 12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262,
  2.228, 2.201, 2.179, 2.16, 2.145, 2.131, 2.12, 2.11, 2.101, 2.093,
  2.086,
];

function parseArgs(argv: string[]): Options {
  const values = new Map<string, string>();
  for (let index = 0; index < argv.length; index += 2) {
    const key = argv[index];
    const value = argv[index + 1];
    if (!key?.startsWith("--") || value === undefined) {
      throw new Error(`Invalid argument near '${key ?? ""}'.`);
    }
    values.set(key.slice(2), value);
  }
  const required = (name: string): string => {
    const value = values.get(name);
    if (!value) throw new Error(`Missing --${name}.`);
    return value;
  };
  return {
    pagesDir: required("pages-dir"),
    comparisonFile: required("comparison-file"),
    runId: required("run-id"),
    sourceSha: required("source-sha"),
    publicationBranch: required("publication-branch"),
    runs: Number(required("runs")),
    repository: required("repository"),
    repoRoot: required("repo-root"),
    outputRelative: required("output-relative"),
    automationSessionUrl: values.get("automation-session-url") ?? null,
  };
}

async function readJson(path: string): Promise<JsonObject> {
  return JSON.parse(await readFile(path, "utf8")) as JsonObject;
}

async function readJsonl(path: string): Promise<JsonObject[]> {
  return (await readFile(path, "utf8"))
    .split(/\r?\n/)
    .filter((line) => line.trim())
    .map((line) => JSON.parse(line) as JsonObject);
}

async function appendJsonl(path: string, value: JsonObject): Promise<void> {
  let current = "";
  try {
    current = await readFile(path, "utf8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }
  const prefix = current && !current.endsWith("\n") ? `${current}\n` : current;
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, `${prefix}${JSON.stringify(value)}\n`, "utf8");
}

function summarize(scores: number[]): ComparisonSummary {
  if (!scores.length) throw new Error("Cannot summarize an empty comparison.");
  const mean = scores.reduce((sum, score) => sum + score, 0) / scores.length;
  const variance =
    scores.length > 1
      ? scores.reduce((sum, score) => sum + (score - mean) ** 2, 0) /
        (scores.length - 1)
      : 0;
  const degreesOfFreedom = scores.length - 1;
  const z = 1.959963984540054;
  const z2 = z * z;
  const critical =
    t95[degreesOfFreedom] ??
    z +
      (z * (z2 + 1)) / (4 * degreesOfFreedom) +
      (z * (5 * z2 * z2 + 16 * z2 + 3)) /
        (96 * degreesOfFreedom ** 2) +
      (z * (3 * z2 ** 3 + 19 * z2 ** 2 + 17 * z2 - 15)) /
        (384 * degreesOfFreedom ** 3);
  const margin =
    scores.length > 1 ? critical * Math.sqrt(variance / scores.length) : 0;
  const ciLow = mean - margin;
  const ciHigh = mean + margin;
  return {
    trial_count: scores.length,
    mean_score: mean,
    ci_low: ciLow,
    ci_high: ciHigh,
    wins: scores.filter((score) => score > 0).length,
    ties: scores.filter((score) => score === 0).length,
    losses: scores.filter((score) => score < 0).length,
    win_rate: scores.filter((score) => score > 0).length / scores.length,
    verdict:
      ciHigh < 0
        ? "regression"
        : ciLow > 0
          ? "improvement"
          : "inconclusive",
  };
}

async function createValidators(repoRoot: string) {
  const ajv = new Ajv({ allErrors: true, strict: true });
  const names = [
    "history-row",
    "run-detail",
    "uplift-comparison",
    "uplift-history",
    "nightly-run",
    "nightly-index",
  ];
  const validators = new Map<string, ReturnType<typeof ajv.compile>>();
  for (const name of names) {
    const schema = await readJson(
      join(repoRoot, "evals", "_vally", "schemas", `${name}.schema.json`),
    );
    validators.set(name, ajv.compile(schema));
  }
  return (name: string, value: unknown): void => {
    const validate = validators.get(name);
    if (!validate) throw new Error(`Unknown schema '${name}'.`);
    if (!validate(value)) {
      throw new Error(
        `${name} validation failed:\n${ajv.errorsText(validate.errors, {
          separator: "\n",
        })}`,
      );
    }
  };
}

async function declaredModel(repoRoot: string, skill: string): Promise<string | null> {
  const text = await readFile(join(repoRoot, "evals", skill, "eval.yaml"), "utf8");
  const match = text.match(/^\s{2}model:\s*(\S+)\s*$/m);
  return match?.[1] ?? null;
}

async function main(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  const validate = await createValidators(options.repoRoot);
  const timestamp = new Date().toISOString();
  const skillRows: JsonObject[] = [];

  for (const skill of expectedSkills) {
    const historyPath = join(options.pagesDir, "data", skill, "history.jsonl");
    const rows = await readJsonl(historyPath);
    const row = rows.find((candidate) => candidate.run_id === options.runId);
    if (!row) throw new Error(`Missing nightly history row for '${skill}'.`);
    validate("history-row", row);
    if (row.run_kind !== "nightly" || row.status !== "ok") {
      throw new Error(`Nightly result for '${skill}' is incomplete.`);
    }
    const detailPath = join(options.pagesDir, "data", skill, row.detail_file);
    const detail = await readJson(detailPath);
    validate("run-detail", detail);
    skillRows.push({ ...row, detail });
  }

  const comparisonRecords = await readJsonl(options.comparisonFile);
  if (!comparisonRecords.length) throw new Error("Uplift comparison produced no records.");
  for (const record of comparisonRecords) validate("uplift-comparison", record);

  const skillScores = new Map<string, number[]>(
    upliftSkills.map((skill) => [skill, []]),
  );
  for (const record of comparisonRecords) {
    for (const stimulus of record.stimuli) {
      const separator = String(stimulus.stimulusName).indexOf("--");
      const skill = String(stimulus.stimulusName).slice(0, separator);
      const scores = skillScores.get(skill);
      if (!scores) {
        throw new Error(`Cannot map uplift stimulus '${stimulus.stimulusName}' to a skill.`);
      }
      for (const trial of stimulus.trials) {
        if (trial.errored === true) {
          throw new Error(`Uplift trial '${stimulus.stimulusName}' is incomplete.`);
        }
        scores.push(Number(trial.score));
      }
    }
  }

  const upliftBySkill = [];
  for (const skill of upliftSkills) {
    upliftBySkill.push({
      skill,
      baseline_model: await declaredModel(options.repoRoot, skill),
      treatment_model: await declaredModel(options.repoRoot, skill),
      ...summarize(skillScores.get(skill) ?? []),
    });
  }
  const overall = summarize([...skillScores.values()].flat());
  const comparisonRelative = `data/uplift/runs/${options.runId}.jsonl`;
  const comparisonDestination = join(options.pagesDir, comparisonRelative);
  await mkdir(dirname(comparisonDestination), { recursive: true });
  await writeFile(
    comparisonDestination,
    comparisonRecords.map((record) => JSON.stringify(record)).join("\n") + "\n",
    "utf8",
  );

  const upliftHistory = {
    schema_version: 1,
    run_id: options.runId,
    timestamp,
    commit: options.sourceSha,
    overall,
    skills: upliftBySkill,
    comparison_file: comparisonRelative,
  };
  validate("uplift-history", upliftHistory);
  await appendJsonl(
    join(options.pagesDir, "data", "uplift", "history.jsonl"),
    upliftHistory,
  );

  const nightlyDir = join(options.pagesDir, "data", "nightly-runs");
  const indexPath = join(nightlyDir, "index.json");
  let existingIndex: JsonObject = { schema_version: 1, runs: [] };
  try {
    existingIndex = await readJson(indexPath);
    validate("nightly-index", existingIndex);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }

  const previousSummary = existingIndex.runs[0]
    ? await readJson(join(options.pagesDir, existingIndex.runs[0].summary_file))
    : null;
  if (previousSummary) validate("nightly-run", previousSummary);

  const skills = skillRows.map((row) => {
    const previous = previousSummary?.skills.find(
      (candidate: JsonObject) => candidate.skill === row.skill,
    );
    return {
      skill: row.skill,
      passed: row.passed,
      model: row.model ?? null,
      metrics: row.metrics,
      detail_file: `data/${row.skill}/${row.detail_file}`,
      delta_from_previous_nightly:
        previous && typeof previous.metrics?.pass_rate === "number"
          ? row.metrics.pass_rate - previous.metrics.pass_rate
          : null,
    };
  });

  const hasSkillRegression = skills.some((skill) => !skill.passed);
  const hasUpliftRegression =
    overall.verdict === "regression" ||
    upliftBySkill.some((skill) => skill.verdict === "regression");
  const hasInconclusive =
    overall.verdict === "inconclusive" ||
    upliftBySkill.some((skill) => skill.verdict === "inconclusive");
  const status =
    hasSkillRegression || hasUpliftRegression
      ? "regression"
      : hasInconclusive
        ? "inconclusive"
        : "clean";
  const flakyCount = skills.reduce(
    (sum, skill) => sum + Number(skill.metrics.flaky_count ?? 0),
    0,
  );
  const summaryRelative = `data/nightly-runs/${options.runId}.json`;
  const summary = {
    schema_version: 1,
    run_id: options.runId,
    run_kind: "nightly",
    timestamp,
    source: {
      commit: options.sourceSha,
      short_sha: options.sourceSha.slice(0, 7),
    },
    publication: {
      branch: options.publicationBranch,
      automation_session_url: options.automationSessionUrl,
    },
    toolchain: {
      vally_version: "0.17.0",
      schema_version: 1,
    },
    runs_per_stimulus: options.runs,
    status,
    flaky_count: flakyCount,
    skills,
    uplift: {
      history_file: "data/uplift/history.jsonl",
      comparison_file: comparisonRelative,
      overall,
      skills: upliftBySkill,
    },
  };
  validate("nightly-run", summary);
  await mkdir(nightlyDir, { recursive: true });
  await writeFile(
    join(options.pagesDir, summaryRelative),
    `${JSON.stringify(summary, null, 2)}\n`,
    "utf8",
  );

  const index = {
    schema_version: 1,
    runs: [
      {
        run_id: options.runId,
        timestamp,
        status,
        commit: options.sourceSha,
        short_sha: options.sourceSha.slice(0, 7),
        flaky_count: flakyCount,
        summary_file: summaryRelative,
      },
      ...existingIndex.runs,
    ],
  };
  validate("nightly-index", index);
  await writeFile(indexPath, `${JSON.stringify(index, null, 2)}\n`, "utf8");

  const prLines = [
    "## Nightly Vally evaluation",
    "",
    `- **Run:** \`${options.runId}\``,
    `- **Source:** \`${options.sourceSha}\``,
    `- **Status:** **${status}**`,
    `- **Runs per stimulus:** ${options.runs}`,
    `- **Flaky stimuli:** ${flakyCount}`,
    `- **Local results:** \`${options.outputRelative}\``,
    ...(options.automationSessionUrl
      ? [`- **Automation session:** ${options.automationSessionUrl}`]
      : []),
    "",
    "### Skills",
    "",
    "| Skill | Passed | Pass rate | Delta from previous nightly | Flaky | Model |",
    "|---|---:|---:|---:|---:|---|",
    ...skills.map(
      (skill) =>
        `| ${skill.skill} | ${skill.passed ? "yes" : "no"} | ${(skill.metrics.pass_rate * 100).toFixed(1)}% | ${
          skill.delta_from_previous_nightly === null
            ? "baseline not established"
            : `${(skill.delta_from_previous_nightly * 100).toFixed(1)} pp`
        } | ${skill.metrics.flaky_count} | ${skill.model ?? "default"} |`,
    ),
    "",
    "### Uplift",
    "",
    `Overall mean signed score: **${overall.mean_score.toFixed(3)}** (95% CI ${overall.ci_low.toFixed(3)} to ${overall.ci_high.toFixed(3)}), **${overall.verdict}**.`,
    "",
    "| Skill | Mean signed score | 95% CI | Verdict |",
    "|---|---:|---:|---|",
    ...upliftBySkill.map(
      (skill) =>
        `| ${skill.skill} | ${skill.mean_score.toFixed(3)} | ${skill.ci_low.toFixed(3)} to ${skill.ci_high.toFixed(3)} | ${skill.verdict} |`,
    ),
    "",
    "### Validation",
    "",
    `- \`./scripts/Invoke-VallyNightly.ps1 -Runs ${options.runs} -Publish\` completed.`,
    "- Generated history rows, run details, uplift comparisons, nightly summary, and index passed JSON Schema validation.",
    "- Raw trajectories and the SQLite database remain local and are not committed.",
  ];
  await writeFile(
    join(dirname(options.comparisonFile), "nightly-pr-body.md"),
    `${prLines.join("\n")}\n`,
    "utf8",
  );
  console.log(JSON.stringify({ status, summary_file: summaryRelative }));
}

await main();
