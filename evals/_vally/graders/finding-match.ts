import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type {
  Grader,
  GraderInput,
  GraderRegistry,
  GraderResult,
} from "@microsoft/vally";

type Verdict =
  | "review_incomplete"
  | "unknown"
  | "lgtm"
  | "needs_human_review"
  | "needs_changes"
  | "reject";

interface FileReference {
  file: string;
  line?: number;
}

interface Finding {
  severity: "error" | "warning" | "suggestion" | "unknown";
  title: string;
  body: string;
  fileRefs: FileReference[];
}

interface ExpectedBug {
  id: string;
  category: string;
  expectation: "required" | "optional";
  expected_severity: string;
  evidence_regions: Array<{ file: string; lines: [number, number] }>;
  semantic_keywords?: string[];
}

interface ExpectedDistractor {
  id: string;
  evidence_regions: Array<{ file: string; lines: [number, number] }>;
}

interface ExpectedCase {
  case_id: string;
  mature?: boolean;
  expected_verdict_at_least?: Verdict;
  bugs: ExpectedBug[];
  non_bug_distractors?: ExpectedDistractor[];
}

interface FindingMatchConfig {
  expected_path?: string;
  line_window?: number;
  semantic_threshold?: number;
  location_keyword_min?: number;
  distractor_penalty?: number;
}

const verdictRanks: Record<Verdict, number> = {
  review_incomplete: -1,
  unknown: -1,
  lgtm: 0,
  needs_human_review: 1,
  needs_changes: 2,
  reject: 3,
};

function normalizePath(path: string): string {
  return path.replaceAll("\\", "/").replace(/^\.\//, "").toLowerCase();
}

function pathsMatch(left: string, right: string): boolean {
  const a = normalizePath(left);
  const b = normalizePath(right);
  return a === b || a.endsWith(`/${b}`) || b.endsWith(`/${a}`);
}

function countKeywords(keywords: string[], text: string): number {
  return keywords.filter((keyword) => {
    const escaped = keyword.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    return new RegExp(`\\b${escaped}\\b`, "i").test(text);
  }).length;
}

function getVerdict(markdown: string): Verdict {
  const declared = markdown.match(
    /^(?:[-*+]\s*)?(?:\*\*)?(?:summary|verdict)(?:\*\*)?\s*[:\-]\s*(?:\*\*)?\s*(.+)$/im,
  )?.[1]?.toLowerCase();
  if (!declared) return "unknown";
  if (/review[\s-]?incomplete|incomplete[\s-]?review/.test(declared)) return "review_incomplete";
  if (/\breject(?:ed|ion)?\b/.test(declared)) return "reject";
  if (/needs[\s-]?human/.test(declared)) return "needs_human_review";
  if (/needs[\s-]?changes/.test(declared)) return "needs_changes";
  if (/\blgtm\b|looks good to me|\bapproved\b/.test(declared)) return "lgtm";
  return "unknown";
}

function getSeverity(heading: string): Finding["severity"] {
  if (/❌|:x:|\berror\b|\[error\]/i.test(heading)) return "error";
  if (/⚠|:warning:|\bwarning\b|\[warn(?:ing)?\]/i.test(heading)) return "warning";
  if (/💡|:bulb:|\bsuggestion\b|\bnote\b|\[suggest(?:ion)?\]/i.test(heading)) {
    return "suggestion";
  }
  return "unknown";
}

function getFileRefs(text: string): FileReference[] {
  const references = new Map<string, FileReference>();
  const patterns = [
    /(?<file>[\w./\\-]+\.[\w]+):(?<line>\d+)/g,
    /(?<file>[\w./\\-]+\.[\w]+)\s*\(?\blines?\s+(?<line>\d+)\)?/gi,
  ];
  for (const pattern of patterns) {
    for (const match of text.matchAll(pattern)) {
      const file = match.groups?.file;
      if (!file) continue;
      const line = Number(match.groups?.line);
      references.set(`${normalizePath(file)}:${line}`, { file, line });
    }
  }
  for (const match of text.matchAll(/(?<file>[\w./\\-]+\.[\w]+)/g)) {
    const file = match.groups?.file;
    if (!file) continue;
    if (![...references.values()].some((reference) => pathsMatch(reference.file, file))) {
      references.set(`${normalizePath(file)}:`, { file });
    }
  }
  return [...references.values()];
}

export function parseReview(markdown: string): { verdict: Verdict; findings: Finding[] } {
  const findings: Finding[] = [];
  const headingPattern = /^####\s+(.+)$/gm;
  const headings = [...markdown.matchAll(headingPattern)];
  for (let index = 0; index < headings.length; index += 1) {
    const heading = headings[index][1].trim();
    const start = (headings[index].index ?? 0) + headings[index][0].length;
    const end = headings[index + 1]?.index ?? markdown.length;
    const body = markdown.slice(start, end).trim();
    findings.push({
      severity: getSeverity(heading),
      title: heading,
      body,
      fileRefs: getFileRefs(`${heading}\n${body}`),
    });
  }
  return { verdict: getVerdict(markdown), findings };
}

function matchesRegion(
  reference: FileReference,
  region: { file: string; lines: [number, number] },
  lineWindow: number,
): boolean {
  return (
    pathsMatch(reference.file, region.file) &&
    reference.line !== undefined &&
    reference.line >= region.lines[0] - lineWindow &&
    reference.line <= region.lines[1] + lineWindow
  );
}

function matchesBug(
  finding: Finding,
  bug: ExpectedBug,
  config: Required<Pick<FindingMatchConfig, "line_window" | "semantic_threshold" | "location_keyword_min">>,
): boolean {
  const keywords = bug.semantic_keywords ?? [];
  const keywordHits = countKeywords(keywords, `${finding.title} ${finding.body}`);
  const locationMatch = bug.evidence_regions.some((region) =>
    finding.fileRefs.some((reference) => matchesRegion(reference, region, config.line_window)),
  );
  if (locationMatch && (keywords.length === 0 || keywordHits >= config.location_keyword_min)) {
    return true;
  }
  const fileMatch = bug.evidence_regions.some((region) =>
    finding.fileRefs.some((reference) => pathsMatch(reference.file, region.file)),
  );
  return fileMatch && keywords.length > 0 && keywordHits >= config.semantic_threshold;
}

function matchesDistractor(
  finding: Finding,
  distractor: ExpectedDistractor,
  lineWindow: number,
): boolean {
  return distractor.evidence_regions.some((region) =>
    finding.fileRefs.some((reference) => matchesRegion(reference, region, lineWindow)),
  );
}

export async function scoreReview(
  markdown: string,
  expected: ExpectedCase,
  config: FindingMatchConfig = {},
): Promise<GraderResult> {
  const parsed = parseReview(markdown);
  const lineWindow = config.line_window ?? 8;
  const semanticThreshold = config.semantic_threshold ?? 2;
  const locationKeywordMin = config.location_keyword_min ?? 1;
  const distractorPenalty = config.distractor_penalty ?? 0.25;

  const bugResults = expected.bugs.map((bug) => {
    const matchedFindings = parsed.findings
      .map((finding, index) =>
        matchesBug(finding, bug, {
          line_window: lineWindow,
          semantic_threshold: semanticThreshold,
          location_keyword_min: locationKeywordMin,
        })
          ? index
          : -1,
      )
      .filter((index) => index >= 0);
    return {
      id: bug.id,
      expectation: bug.expectation,
      caught: matchedFindings.length > 0,
      matched_findings: matchedFindings,
    };
  });
  const required = bugResults.filter((bug) => bug.expectation === "required");
  const caughtRequired = required.filter((bug) => bug.caught).length;
  const recall = required.length === 0 ? 1 : caughtRequired / required.length;
  const distractors = (expected.non_bug_distractors ?? []).map((distractor) => ({
    id: distractor.id,
    flagged: parsed.findings.some((finding) =>
      matchesDistractor(finding, distractor, lineWindow),
    ),
  }));
  const distractorCount = distractors.filter((distractor) => distractor.flagged).length;
  const verdictFloor = expected.expected_verdict_at_least;
  const verdictPassed =
    !verdictFloor || verdictRanks[parsed.verdict] >= verdictRanks[verdictFloor];
  const passed =
    caughtRequired === required.length && verdictPassed && distractorCount === 0;
  const score = verdictPassed
    ? Math.max(0, recall - distractorCount * distractorPenalty)
    : 0;

  return {
    name: "finding-match",
    graderType: "finding-match",
    kind: "code",
    passed,
    score,
    label: passed ? "correct" : "incorrect",
    evidence: `${caughtRequired}/${required.length} required bugs caught; ${distractorCount} distractors flagged; verdict ${parsed.verdict}`,
    metadata: {
      case_id: expected.case_id,
      verdict: parsed.verdict,
      expected_verdict_at_least: verdictFloor,
      verdict_passed: verdictPassed,
      required_recall: recall,
      bugs: bugResults,
      distractors,
      finding_count: parsed.findings.length,
    },
    details: bugResults.map((bug) => ({
      name: bug.id,
      kind: "code",
      passed: bug.caught,
      score: bug.caught ? 1 : 0,
      evidence: bug.caught
        ? `Matched finding indexes: ${bug.matched_findings.join(", ")}`
        : "No matching finding",
      metadata: {
        expectation: bug.expectation,
        matched_findings: bug.matched_findings,
      },
    })),
  };
}

class FindingMatchGrader implements Grader {
  metadata = {
    name: "finding-match",
    description: "Matches structured code-review findings to hidden expected bugs",
    behavior: { requiresWorkspace: true },
    determinism: "complex-static" as const,
    reference: "reference-based" as const,
    temporalScope: "trajectory-level" as const,
    costProfile: "low" as const,
  };

  defaultName(): string {
    return this.metadata.name;
  }

  async grade(input: GraderInput): Promise<GraderResult> {
    if (!input.trajectory) throw new Error("Missing trajectory");
    const config = (input.config ?? {}) as FindingMatchConfig;
    const expectedPath = config.expected_path ?? ".vally/expected.json";
    const expected = JSON.parse(
      await readFile(join(input.trajectory.workDir, expectedPath), "utf8"),
    ) as ExpectedCase;
    return scoreReview(input.trajectory.output, expected, config);
  }
}

export function registerGraders(registry: GraderRegistry): void {
  registry.register(new FindingMatchGrader());
}
