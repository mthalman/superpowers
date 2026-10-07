import { describe, expect, it } from "vitest";
import { createGraderRegistry, gradeTrajectory, resolveGradePass } from "@microsoft/vally";
import { parseReview, scoreReview } from "../graders/finding-match.js";

const expected = {
  case_id: "ssrf",
  expected_verdict_at_least: "needs_changes" as const,
  bugs: [
    {
      id: "missing-allowlist",
      category: "security",
      expectation: "required" as const,
      expected_severity: "error",
      evidence_regions: [{ file: "src/proxy.ts", lines: [18, 30] as [number, number] }],
      semantic_keywords: ["ssrf", "allowlist", "internal"],
    },
  ],
};

describe("finding-match", () => {
  it("parses verdicts, findings, and file references", () => {
    const review = [
      "## Code Review",
      "**Verdict:** Needs changes",
      "### Detailed Findings",
      "#### Error Security - SSRF without allowlist",
      "`src/proxy.ts:22` accepts internal hosts.",
    ].join("\n");
    const parsed = parseReview(review);
    expect(parsed.verdict).toBe("needs_changes");
    expect(parsed.findings[0].fileRefs[0]).toEqual({
      file: "src/proxy.ts",
      line: 22,
    });
  });

  it("credits a location and semantic match", async () => {
    const result = await scoreReview(
      [
        "**Verdict:** Needs changes",
        "### Detailed Findings",
        "#### Error Security - SSRF is possible",
        "`src/proxy.ts:22` needs a host allowlist to block internal services.",
      ].join("\n"),
      expected,
    );
    expect(result.passed).toBe(true);
    expect(result.score).toBe(1);
  });

  it("does not credit location alone when semantic evidence is absent", async () => {
    const result = await scoreReview(
      [
        "**Verdict:** Needs changes",
        "### Detailed Findings",
        "#### Warning Style - Rename this variable",
        "`src/proxy.ts:22` could use a clearer name.",
      ].join("\n"),
      expected,
    );
    expect(result.passed).toBe(false);
    expect(result.score).toBe(0);
  });

  it("enforces the verdict floor", async () => {
    const result = await scoreReview(
      [
        "**Verdict:** LGTM",
        "### Detailed Findings",
        "#### Error Security - SSRF is possible",
        "`src/proxy.ts:22` needs a host allowlist for internal services.",
      ].join("\n"),
      expected,
    );
    expect(result.passed).toBe(false);
    expect(result.metadata?.verdict_passed).toBe(false);
  });

  it("enforces the verdict floor through Vally threshold scoring", async () => {
    const result = await scoreReview(
      [
        "**Verdict:** LGTM",
        "#### Error Security - SSRF is possible",
        "`src/proxy.ts:22` needs a host allowlist for internal services.",
      ].join("\n"),
      expected,
    );
    const registry = createGraderRegistry();
    for (const type of ["finding-match", "skill-invocation", "diff-empty"]) {
      registry.register({
        metadata: {
          name: type,
          description: "Fixture grader",
          behavior: { requiresWorkspace: false },
          determinism: "complex-static",
          reference: "reference-based",
          temporalScope: "trajectory-level",
          costProfile: "low",
        },
        defaultName: () => type,
        grade: async () => type === "finding-match" ? result : {
          name: type,
          kind: "code",
          passed: true,
          score: 1,
          evidence: "",
        },
      });
    }
    const stimulus = { name: "ssrf", prompt: "Review this change" };
    const aggregate = await gradeTrajectory({
      id: "fixture",
      workDir: process.cwd(),
      output: "",
      stimulus,
      events: [],
      metadata: { completedAt: new Date() },
    } as never, [
      { type: "finding-match" },
      { type: "skill-invocation" },
      { type: "diff-empty" },
    ], { registry, stimulus });
    expect(aggregate.passed).toBe(false);
    expect(resolveGradePass(aggregate, 1)).toBe(false);
    expect(result.metadata?.required_recall).toBe(1);
  });
});
