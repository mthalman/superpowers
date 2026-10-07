import { execFile } from "node:child_process";
import { access, readFile, readdir } from "node:fs/promises";
import { join, relative, resolve } from "node:path";
import { promisify } from "node:util";
import { loadEvalSpec, materializeWorkspace, resolveEnvironment, resolveStimulus } from "@microsoft/vally";
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
        expect(await readFile(join(workspace.workDir, relative(contextDir, source))))
          .toEqual(await readFile(source));
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
});
