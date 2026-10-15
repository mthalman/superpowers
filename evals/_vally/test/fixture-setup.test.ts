import { execFile } from "node:child_process";
import { access, readFile, readdir, writeFile } from "node:fs/promises";
import { join, relative, resolve } from "node:path";
import { promisify } from "node:util";
import { runInNewContext } from "node:vm";
import ts from "typescript";
import {
  computeMetrics, DiffEmptyGrader, loadEvalSpec, loadEvalWithParams, materializeWorkspace,
  resolveEnvironment, resolveStimulus, runEval,
} from "@microsoft/vally";
import { describe, expect, it } from "vitest";

const execFileAsync = promisify(execFile);
const baseDir = resolve(process.cwd(), "..", "code-review");
const spec = await loadEvalSpec(join(baseDir, "eval.yaml"));
const rootEnvironment = resolveEnvironment(spec.environment, {});

describe("code-review fixture setup", () => {
  it.each(spec.stimuli)("materializes $name without a model", async (raw) => {
    const stimulus = resolveStimulus(raw, rootEnvironment, {}, spec.tags, baseDir);
    const workspace = await materializeWorkspace(stimulus.environment, baseDir);
    try {
      const caseDir = join(baseDir, "fixtures", "detection", "dev", raw.name);
      expect(await readFile(join(workspace.workDir, "change.patch"), "utf8"))
        .toBe(await readFile(join(caseDir, "diff.patch"), "utf8"));
      const contextDir = join(caseDir, "context");
      for (const entry of await readdir(contextDir, { recursive: true, withFileTypes: true })) {
        if (!entry.isFile()) continue;
        const source = join(entry.parentPath, entry.name);
        const content = await readFile(join(workspace.workDir, relative(contextDir, source)), "utf8");
        expect(content).toBe(await readFile(source, "utf8"));
        expect(content).not.toMatch(/BUG INTRODUCED IN PR|REVIEW NOTE|NO test that asserts|even with the bug/i);
      }
      const gitStatus = await execFileAsync(
        "git", ["status", "--porcelain"], { cwd: workspace.workDir },
      );
      expect(gitStatus.stdout).toBe("");
      expect(stimulus.prompt).toContain("Review change.patch");
      expect(stimulus.prompt).toContain("do not apply it");
      await expect(access(join(workspace.workDir, ".vally", "expected.json")))
        .rejects.toMatchObject({ code: "ENOENT" });
    } finally {
      await workspace.cleanup();
    }
  }, 60_000);

  it.each(["race-double-checked-cache", "leak-file-handle-on-error"])(
    "round-trips the rewritten %s patch against its proposed source",
    async (name) => {
      const raw = spec.stimuli.find((item) => item.name === name)!;
      const stimulus = resolveStimulus(raw, rootEnvironment, {}, spec.tags, baseDir);
      const workspace = await materializeWorkspace(stimulus.environment, baseDir);
      try {
        const file = name === "race-double-checked-cache" ? "cache.ts" : "log_writer.go";
        const path = join(workspace.workDir, "src", file);
        const proposed = (await readFile(path, "utf8")).replaceAll("\r\n", "\n");
        await writeFile(path, proposed);
        const patch = join(workspace.workDir, "change.patch");
        await writeFile(patch, (await readFile(patch, "utf8")).replaceAll("\r\n", "\n"));
        await execFileAsync("git", ["apply", "--reverse", "change.patch"], { cwd: workspace.workDir });
        const original = await readFile(path, "utf8");
        await execFileAsync("git", ["apply", "change.patch"], { cwd: workspace.workDir });
        expect((await readFile(path, "utf8")).replaceAll("\r\n", "\n")).toBe(proposed);
        if (name === "race-double-checked-cache") {
          expect(await concurrentDiskReads(original)).toBe(1);
          expect(await concurrentDiskReads(proposed)).toBe(2);
        }
      } finally {
        await workspace.cleanup();
      }
    }, 60_000,
  );
});

async function concurrentDiskReads(source: string): Promise<number> {
  let release!: () => void;
  const gate = new Promise<void>((resolve) => { release = resolve; });
  let calls = 0;
  const exports: Record<string, unknown> = {};
  runInNewContext(ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText, {
    exports,
    readSettingsFromDisk: async () => {
      calls += 1;
      await gate;
      return { apiKey: "local", region: "local" };
    },
  });
  const loader = exports.SettingsLoader;
  if (typeof loader !== "function" || !("load" in loader) || typeof loader.load !== "function") {
    throw new Error("Cache fixture does not expose SettingsLoader.load");
  }
  const pending = [loader.load(), loader.load()];
  release();
  await Promise.all(pending);
  return calls;
}

describe("read-only pagination workspaces", () => {
  it.each(["code-review", "defend-the-diff", "validation-scenarios"])(
    "%s runs Python without changes, but source edits still fail",
    async (skill) => {
      const directory = resolve(process.cwd(), "..", skill);
      const { spec: evaluation } = await loadEvalWithParams(
        join(directory, "eval.yaml"), { cliParams: { RUNS: "1" } },
      );
      const raw = evaluation.stimuli.find((item) => /pagination/.test(item.name))!;
      const stimulus = resolveStimulus(
        raw, resolveEnvironment(evaluation.environment, {}), {}, evaluation.tags, directory,
      );
      for (const mode of ["bytecode", "read-only", "source-edit"]) {
        const environment = mode === "bytecode"
          ? {
            ...stimulus.environment,
            env: { ...stimulus.environment?.env, PYTHONDONTWRITEBYTECODE: "0" },
          }
          : stimulus.environment;
        const run = await runEval({
          prompt: stimulus.prompt,
          stimulus,
          skills: [],
          workDir: directory,
          baseDir: directory,
          environment,
          executor: {
            name: "python-fixture-check",
            supportsEnvVars: true,
            async execute(item, options) {
              await execFileAsync("python", ["-m", "pytest", "-q", join("tests", "test_pagination.py")], {
                cwd: options.workDir,
                env: { ...process.env, ...options.env, PYTHONUTF8: "1" },
              });
              if (mode === "source-edit") {
                await writeFile(join(options.workDir, "src", "pagination.py"), "raise RuntimeError('modified')\n");
              }
              return {
                id: "python-check",
                stimulus: item,
                events: [],
                metrics: computeMetrics([]),
                output: "Inspected pagination",
                workDir: options.workDir,
                metadata: { model: "none", skillsLoaded: [], executor: "python-fixture-check", sessionID: "none" },
              };
            },
            async shutdown() {},
          },
        });
        try {
          const grade = await new DiffEmptyGrader().grade({ trajectory: run.trajectory, stimulus });
          expect(grade.passed, run.trajectory.diff).toBe(mode === "read-only");
          if (mode === "bytecode") {
            expect(run.trajectory.diff).toContain("__pycache__");
          } else {
            expect(run.trajectory.diff).not.toContain("__pycache__");
            expect(run.trajectory.diff).not.toContain(".pytest_cache");
          }
          if (mode === "source-edit") {
            expect(run.trajectory.diff).toContain("src/pagination.py");
          }
        } finally {
          await run.cleanup();
        }
      }
    },
    60_000,
  );
});
