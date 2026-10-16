import { describe, expect, it } from "vitest";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
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
  it("accepts an incrementally fixable refund review without demanding rejection", async () => {
    const truth = JSON.parse(await readFile(resolve(
      process.cwd(), "..", "code-reviewer", "fixtures", "detection", "dev",
      "add-refund-event-handler", "expected.json",
    ), "utf8"));
    const review = [
      "**Summary:** Needs Changes",
      "#### Error Correctness - Acknowledgement contract is missing",
      "`src/events/RefundIssuedHandler.ts:17` never calls ack, so the broker redelivers and duplicates refunds.",
      "#### Error Correctness - Incorrect amount units",
      "`src/events/RefundIssuedHandler.ts:11` multiplies minor units by 100, refunding 100 times the amount.",
    ].join("\n");
    expect((await scoreReview(review, truth)).passed).toBe(true);
    expect((await scoreReview(review.replace("Needs Changes", "LGTM"), truth)).passed).toBe(false);
    expect((await scoreReview(review.split("#### Error Correctness - Incorrect")[0], truth)).passed).toBe(false);
  });

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

  it("maps patch-line citations to source locations without crediting unrelated lines", async () => {
    const patch = [
      "diff --git a/src/proxy.ts b/src/proxy.ts",
      "--- a/src/proxy.ts",
      "+++ b/src/proxy.ts",
      "@@ -20,2 +20,2 @@",
      " export function proxy(url: string) {",
      "-  return validatedFetch(url);",
      "+  return fetch(url);",
      "diff --git a/src/other.ts b/src/other.ts",
      "--- a/src/other.ts",
      "+++ b/src/other.ts",
      "@@ -1 +1 @@",
      "-export const enabled = false;",
      "+export const enabled = true;",
    ].join("\n");
    const review = (reference: string, finding = "SSRF allows internal hosts without an allowlist") => [
      "**Verdict:** Needs changes",
      `#### Error Security - ${finding}`,
      `See \`${reference}\`.`,
    ].join("\n");
    for (const reference of ["change.patch:7", "C:\\project\\change.patch:7"]) {
      expect((await scoreReview(review(reference), expected, {}, patch)).passed).toBe(true);
    }
    for (const line of [3, 6, 13, 99]) {
      expect((await scoreReview(review(`change.patch:${line}`), expected, {}, patch)).passed).toBe(false);
    }
    expect((await scoreReview(review("change.patch:7", "Rename this variable"), expected, {}, patch)).passed)
      .toBe(false);
    expect((await scoreReview(review("unrelated.patch:7"), expected, {}, patch)).passed).toBe(false);
    expect((await scoreReview(
      review("change.patch:13"), expected, {}, patch.replace("+20,2", "+20,8"),
    )).passed).toBe(false);
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
