import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { GraderInput, GraderResult, Trajectory } from "@microsoft/vally";

type ToolCallEvent = Extract<Trajectory["events"][number], { type: "tool_call" }>;

function isSkillPath(path: string): boolean {
  const parts = path.replaceAll("\\", "/").toLowerCase().split("/");
  return !parts.includes("..") && parts.slice(-2).join("/") === "defend-the-diff/skill.md";
}

function readsPowerShellSkill(command: string): boolean {
  const tokens = command.match(/<#[\s\S]*?#>|#[^\r\n]*|@'\r?\n[\s\S]*?^'@|@"\r?\n[\s\S]*?^"@|'(?:''|[^'])*'|"(?:`[\s\S]|""|[^"`])*"|`[\s\S]|[;|&{}()=\r\n]|[^\s"'`;|&{}()=]+/gm) ?? [];
  let segment: string[] = [];
  for (const token of [...tokens, ";"]) {
    if (token.startsWith("#") || token.startsWith("<#")) continue;
    if (!/^[;|&{}()\r\n]$/.test(token)) {
      segment.push(token);
      continue;
    }
    let index = 0;
    while (/^\$[\w:]+$/.test(segment[index] ?? "") && segment[index + 1] === "=") index += 2;
    if (["get-content", "gc", "cat", "type"].includes(segment[index]?.toLowerCase())) {
      for (const argument of segment.slice(index + 1)) {
        const path = argument.startsWith("'") ? argument.slice(1, -1).replaceAll("''", "'")
          : argument.startsWith('"') ? argument.slice(1, -1).replace(/`(.)|""/gs, (_, escaped: string | undefined) => escaped ?? '"')
          : argument;
        if (isSkillPath(path)) return true;
      }
    }
    segment = [];
  }
  return false;
}

function readsSkill(call: ToolCallEvent): boolean {
  const args = call.data.arguments;
  if (!args || typeof args !== "object" || Array.isArray(args)) return false;
  const tool = call.data.toolName.split(".").at(-1);
  if (tool === "view") return typeof args.path === "string" && isSkillPath(args.path);
  if (typeof args.command !== "string") return false;
  if (tool === "powershell") return readsPowerShellSkill(args.command);
  if (tool !== "bash") return false;
  const commands = /(?:^|[;\n|]|&&)\s*(?:&\s*)?(?:cat|head|tail|sed)\s+([^;\n|&]+)/gi;
  for (const command of args.command.matchAll(commands)) {
    for (const token of command[1].matchAll(/"([^"]*)"|'([^']*)'|([^\s"']+)/g)) {
      if (isSkillPath(token[1] ?? token[2] ?? token[3])) return true;
    }
  }
  return false;
}

function resultText(result: unknown): string[] {
  if (typeof result === "string") return [result];
  if (Array.isArray(result)) return result.flatMap(resultText);
  if (!result || typeof result !== "object") return [];
  return Object.entries(result)
    .filter(([key]) => ["content", "text", "stdout", "output"].includes(key))
    .flatMap(([, value]) => resultText(value));
}

export function gradeSkillRead(trajectory: Trajectory, instructions: string): GraderResult {
  const required = new Set(instructions.split(/\r?\n/).map((line) => line.trim()).filter(Boolean));
  if (required.size === 0) throw new Error("Skill instructions are empty");
  const pending = new Map<string, ToolCallEvent>();
  const coverage = new Map<string | undefined, Set<string>>();
  for (const event of trajectory.events) {
    if (event.type !== "tool_call" && event.type !== "tool_result") continue;
    const key = JSON.stringify([event.agentId ?? null, event.data.toolCallId]);
    if (event.type === "tool_call") {
      pending.set(key, event);
      continue;
    }
    const call = pending.get(key);
    pending.delete(key);
    if (!call || call.data.toolName !== event.data.toolName || !event.data.success || !readsSkill(call)) continue;
    const seen = coverage.get(event.agentId) ?? new Set<string>();
    for (const text of resultText(event.data.result)) {
      for (const line of text.split(/\r?\n/)) {
        const plain = line.trim();
        const numbered = plain.replace(/^(?:L\d+:|\d+[:\t]\s?)/, "").trim();
        if (required.has(plain)) seen.add(plain);
        else if (required.has(numbered)) seen.add(numbered);
      }
    }
    coverage.set(event.agentId, seen);
  }
  const read = Math.max(0, ...[...coverage.values()].map((seen) => seen.size));
  const passed = read === required.size;
  return {
    name: "skill-read",
    kind: "code",
    passed,
    score: passed ? 1 : 0,
    evidence: `${read}/${required.size} distinct instruction lines exposed to one agent by completed skill reads`,
  };
}

async function main(): Promise<GraderResult> {
  const inputPath = process.env.EVALUATE_GRADER_INPUT;
  if (!inputPath) throw new Error("EVALUATE_GRADER_INPUT is required");
  const input: GraderInput = JSON.parse(await readFile(inputPath, "utf8"));
  if (!input.trajectory) throw new Error("Missing trajectory");
  const path = join(input.trajectory.workDir, "defend-the-diff", "SKILL.md");
  if (!existsSync(path)) {
    return {
      name: "skill-read", kind: "code", passed: false, score: 0,
      evidence: "The evaluated workspace does not contain the defend-the-diff skill",
    };
  }
  return gradeSkillRead(input.trajectory, await readFile(path, "utf8"));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    console.log(JSON.stringify(await main()));
  } catch (error) {
    console.log(JSON.stringify({
      name: "skill-read", kind: "code", status: "error", passed: false, score: 0,
      evidence: `Skill-read grading failed: ${error instanceof Error ? error.message : String(error)}`,
    }));
  }
}
