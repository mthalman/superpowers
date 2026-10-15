import { dirname, resolve } from "node:path";
import { access, readFile, writeFile } from "node:fs/promises";
import { describe, expect, it } from "vitest";
import {
  applyGraderFiles, computeMetrics, createDefaultGraderRegistry, gradeInDisposableWorkspace,
  gradeTrajectory, hasGraderError, loadEvalWithParams, materializeWorkspace, resolveEnvironment,
  resolveExperiment, resolveGradePass, resolveStimulus, runEval,
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
    const lines = content.split(/\r?\n/);
    const middle = Math.floor(lines.length / 2);
    const firstHalf = lines.slice(0, middle).join("\n");
    const secondHalf = lines.slice(middle).join("\n");
    const path = "defend-the-diff/SKILL.md";
    const read = (
      text: string, args: Record<string, unknown> = { path }, toolName = "view",
      success = true, agentId?: string,
    ): Trajectory["events"] => [{
      type: "tool_call", agentId,
      data: { toolName, toolCallId: "read-skill", arguments: args },
    }, {
      type: "tool_result", agentId,
      data: { toolName, toolCallId: "read-skill", success, result: { content: text } },
    }];
    const samples = [
      { name: "whole relative view", events: read(content), passed: true },
      { name: "whole absolute view", events: read(content, { path: "C:\\project\\defend-the-diff\\SKILL.md" }), passed: true },
      { name: "PowerShell read", events: read(content, { command: `Get-Content -Raw -LiteralPath '${path}'` }, "powershell"), passed: true },
      { name: "PowerShell script block", events: read(content, { command: `& { Get-Content -Raw -LiteralPath '${path}' }` }, "powershell"), passed: true },
      { name: "PowerShell assignment", events: read(content, { command: `$text = Get-Content -Raw -LiteralPath '${path}'; $text` }, "powershell"), passed: true },
      { name: "PowerShell compact assignment", events: read(content, { command: `$text=Get-Content -Raw -LiteralPath '${path}';$text` }, "powershell"), passed: true },
      { name: "PowerShell grouped read", events: read(content, { command: `(Get-Content -Raw -LiteralPath '${path}') | Write-Output` }, "powershell"), passed: true },
      { name: "PowerShell quoted punctuation", events: read(content, { command: `& { Get-Content -LiteralPath 'project; (old)/${path}' }` }, "powershell"), passed: true },
      { name: "PowerShell wrapped partial reads", events: [
        ...read(firstHalf, { command: `& { Get-Content '${path}' | Select-Object -First ${middle} }` }, "powershell"),
        ...read(secondHalf, { command: `$text = Get-Content '${path}' | Select-Object -Skip ${middle}; $text` }, "powershell"),
      ], passed: true },
      { name: "Bash read", events: read(content, { command: `cat '${path}'` }, "bash"), passed: true },
      { name: "segmented view", events: [...read(firstHalf), ...read(secondHalf)], passed: true },
      { name: "reordered overlapping reads", events: [
        ...read(secondHalf), ...read(lines.slice(0, middle + 3).join("\r\n")),
      ], passed: true },
      { name: "mixed readers", events: [
        ...read(firstHalf),
        ...read(secondHalf, { command: `Get-Content '${path}' | Select-Object -Skip ${middle}` }, "powershell"),
      ], passed: true },
      { name: "numbered view", events: read(lines.map((line, index) => `L${index + 1}:${line}`).join("\n")), passed: true },
      { name: "missing file", events: read("Error: file not found"), passed: false },
      { name: "listing", events: read("SKILL.md\nreferences", { path: "defend-the-diff" }), passed: false },
      { name: "unrelated path", events: read(content, { path: "unrelated/SKILL.md" }), passed: false },
      { name: "unrelated command", events: read(content, { command: "Get-Content unrelated/SKILL.md" }, "powershell"), passed: false },
      { name: "echoed instructions", events: read(content, { command: `Write-Output "Get-Content ${path}"` }, "powershell"), passed: false },
      { name: "echoed script block", events: read(content, { command: `Write-Output '& { Get-Content ${path} }'` }, "powershell"), passed: false },
      { name: "echoed assignment", events: read(content, { command: `Write-Output '$text = Get-Content ${path}; $text'` }, "powershell"), passed: false },
      { name: "echoed command separator", events: read(content, { command: `Write-Output '; Get-Content ${path}'` }, "powershell"), passed: false },
      { name: "echoed here-string", events: read(content, { command: `Write-Output @'\nGet-Content ${path}\n'@` }, "powershell"), passed: false },
      { name: "echoed escaped quote", events: read(content, { command: 'Write-Output "Ignore `"; Get-Content ' + path + '"' }, "powershell"), passed: false },
      { name: "commented reader", events: read(content, { command: `# Get-Content ${path}\nWrite-Output 'not a read'` }, "powershell"), passed: false },
      { name: "block-commented reader", events: read(content, { command: `<#\nGet-Content ${path}\n#>\nWrite-Output 'not a read'` }, "powershell"), passed: false },
      { name: "unrelated wrapped read", events: read(content, { command: "& { $text = Get-Content unrelated/SKILL.md; $text }" }, "powershell"), passed: false },
      { name: "truncated instructions", events: read(firstHalf), passed: false },
      { name: "repeated partial read", events: [...read(firstHalf), ...read(firstHalf)], passed: false },
      { name: "missing middle", events: read([...lines.slice(0, middle), ...lines.slice(middle + 1)].join("\n")), passed: false },
      { name: "landmarks only", events: read("name: defend-the-diff\n## Workflow\n## Report\nrequest approval before editing."), passed: false },
      { name: "failed read", events: read(content, { path }, "view", false), passed: false },
      { name: "uncompleted read", events: read(content).slice(0, 1), passed: false },
      { name: "self-report", events: [], passed: false },
      { name: "separate agents", events: [...read(firstHalf), ...read(secondHalf, { path }, "view", true, "child")], passed: false },
      { name: "colliding call IDs", events: [
        read(content)[0], read(content, { path: "unrelated/SKILL.md" }, "view", true, "child")[0],
        read(content, { path: "unrelated/SKILL.md" }, "view", true, "child")[1], read(content)[1],
      ], passed: true },
    ];
    const names = spec.stimuli.flatMap((item) => item.graders?.map((grader) => grader.name).filter(Boolean) ?? []);
    expect(new Set(names).size).toBe(names.length);
    for (const raw of spec.stimuli) {
      const graders = raw.graders?.filter((grader) => grader.type !== "prompt" && grader.type !== "diff-empty") ?? [];
      expect(graders).toHaveLength(1);
      const directory = resolve(process.cwd(), "..", "defend-the-diff");
      const stimulus = resolveStimulus(
        raw, resolveEnvironment(spec.environment, {}), {}, spec.tags, directory, spec.grading_environment,
      );
      const workspace = await materializeWorkspace(stimulus.environment, directory);
      try {
        await expect(access(resolve(workspace.workDir, ".vally", "skill-read.mjs")))
          .rejects.toMatchObject({ code: "ENOENT" });
        await applyGraderFiles(stimulus.grading_environment?.files, workspace.workDir, directory);
        for (const sample of samples) {
          const trajectory: Trajectory = {
            id: "skill-read",
            stimulus: { name: raw.name, prompt: raw.prompt! },
            workDir: workspace.workDir,
            output: "I invoked defend-the-diff",
            metrics: computeMetrics([]),
            metadata: { model: "none", skillsLoaded: [], executor: "copilot-sdk", sessionID: "none" },
            events: sample.events,
          };
          const result = await gradeTrajectory(trajectory, graders, { stimulus: trajectory.stimulus });
          expect(result.passed, `${raw.name}: ${sample.name}: ${JSON.stringify(result.details)}`)
            .toBe(sample.passed);
        }
      } finally {
        await workspace.cleanup();
      }
    }
  }, 60_000);

  it("stages the reader grader only for grading in both uplift variants and preserves source-edit failures", async () => {
    const experiment = await resolveExperiment(
      resolve(process.cwd(), "..", "experiments", "skill-uplift.experiment.yaml"),
      { cliParams: { RUNS: "1" } },
    );
    const registry = createDefaultGraderRegistry();
    registry.register({
      metadata: {
        name: "prompt", description: "Perfect behavioral score control",
        behavior: {}, determinism: "static", reference: "reference-free",
        temporalScope: "trajectory-level", costProfile: "low",
      },
      defaultName: () => "prompt",
      grade: async () => ({
        name: "prompt", kind: "code", passed: true, score: 1,
        evidence: "Controlled perfect behavioral score; no model invoked",
      }),
    });
    for (const plan of experiment.plans.filter((item) => item.effectiveSpec.name === "defend-the-diff")) {
      const spec = plan.effectiveSpec;
      const directory = dirname(plan.evalFile);
      const stimulus = resolveStimulus(
        spec.stimuli[1], resolveEnvironment(spec.environment, {}), {}, spec.tags, directory, spec.grading_environment,
      );
      expect(stimulus.grading_environment?.files).toHaveLength(1);
      for (const editSource of [false, true]) {
        const run = await runEval({
          prompt: stimulus.prompt, stimulus, skills: [], baseDir: directory, workDir: directory,
          environment: stimulus.environment,
          executor: {
            name: "skill-read-check", supportsEnvVars: true,
            async execute(item, options) {
              await expect(access(resolve(options.workDir, ".vally", "skill-read.mjs")))
                .rejects.toMatchObject({ code: "ENOENT" });
              const events: Trajectory["events"] = [];
              if (plan.variant === "with-skill") {
                const path = resolve(options.workDir, "defend-the-diff", "SKILL.md");
                const lines = (await readFile(path, "utf8")).split(/\r?\n/);
                const middle = Math.floor(lines.length / 2);
                for (const [index, content] of [lines.slice(0, middle), lines.slice(middle)].entries()) {
                  events.push({
                    type: "tool_call",
                    data: { toolName: "view", toolCallId: String(index), arguments: { path } },
                  }, {
                    type: "tool_result",
                    data: { toolName: "view", toolCallId: String(index), success: true, result: { content: content.join("\n") } },
                  });
                }
              }
              if (editSource) await writeFile(resolve(options.workDir, "src", "format.ts"), "throw new Error('modified');\n");
              return {
                id: "skill-read-check", stimulus: item, events, workDir: options.workDir,
                metrics: computeMetrics([]), output: "Inspected the change",
                metadata: { model: "none", skillsLoaded: [], executor: "skill-read-check", sessionID: "none" },
              };
            },
            async shutdown() {},
          },
        });
        try {
          const result = await gradeInDisposableWorkspace({
            trajectory: run.trajectory, baseDir: directory,
            graderFiles: stimulus.grading_environment?.files,
            grade: (trajectory) => gradeTrajectory(trajectory, stimulus.graders!, { registry, stimulus }),
          });
          expect(hasGraderError(result)).toBe(false);
          expect(resolveGradePass(result, spec.scoring?.threshold))
            .toBe(plan.variant === "with-skill" && !editSource);
          expect(result.details?.find((grader) => grader.graderType === "program")?.passed)
            .toBe(plan.variant === "with-skill");
          expect(result.details?.find((grader) => grader.graderType === "diff-empty")?.passed).toBe(!editSource);
          await expect(access(resolve(run.trajectory.workDir, ".vally", "skill-read.mjs")))
            .rejects.toMatchObject({ code: "ENOENT" });
        } finally {
          await run.cleanup();
        }
      }
    }
  }, 60_000);

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
