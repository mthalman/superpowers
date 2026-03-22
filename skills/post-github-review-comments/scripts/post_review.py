#!/usr/bin/env python3
"""Post pending review comments to a GitHub pull request via the GitHub CLI."""

import argparse
import json
import os
import subprocess
import sys
import tempfile


def get_pr_head_sha(owner, repo, pr_number):
    """Get the HEAD commit SHA for a pull request."""
    result = subprocess.run(
        ["gh", "api", f"repos/{owner}/{repo}/pulls/{pr_number}", "--jq", ".head.sha"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Error fetching PR info: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return result.stdout.strip()


def build_review_payload(comments, body=None, commit_id=None):
    """Build the JSON payload for the review API."""
    payload = {}

    if body:
        payload["body"] = body

    if commit_id:
        payload["commit_id"] = commit_id

    # No "event" field = PENDING review
    review_comments = []
    for comment in comments:
        c = {
            "path": comment["path"],
            "body": comment["body"],
            "line": comment["line"],
            "side": comment.get("side", "RIGHT"),
        }
        # Multi-line support
        start_line = comment.get("start_line")
        if start_line is not None and start_line != comment["line"]:
            c["start_line"] = start_line
            c["start_side"] = comment.get("start_side", c["side"])

        review_comments.append(c)

    payload["comments"] = review_comments
    return payload


def post_review(owner, repo, pr_number, payload):
    """Post the review via gh api and return the response."""
    tmp = None
    try:
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        )
        json.dump(payload, tmp)
        tmp.close()

        endpoint = f"repos/{owner}/{repo}/pulls/{pr_number}/reviews"
        result = subprocess.run(
            ["gh", "api", endpoint, "-X", "POST", "--input", tmp.name],
            capture_output=True, text=True,
        )

        if result.returncode != 0:
            print(f"Error posting review: {result.stderr}", file=sys.stderr)
            sys.exit(1)

        return json.loads(result.stdout)
    finally:
        if tmp and os.path.exists(tmp.name):
            os.unlink(tmp.name)


def main():
    parser = argparse.ArgumentParser(
        description="Post pending review comments to a GitHub PR"
    )
    parser.add_argument("--owner", required=True, help="Repository owner")
    parser.add_argument("--repo", required=True, help="Repository name")
    parser.add_argument("--pr", required=True, type=int, help="Pull request number")
    parser.add_argument(
        "--input", required=True,
        help='JSON file with comments array. Each comment: {"path", "body", "line", optional "start_line", optional "side"}',
    )
    parser.add_argument(
        "--body", default="", help="Overall review body text (optional)"
    )
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        data = json.load(f)

    comments = data if isinstance(data, list) else data.get("comments", [])

    if not comments:
        print("No comments to post.")
        return

    commit_id = get_pr_head_sha(args.owner, args.repo, args.pr)
    payload = build_review_payload(comments, body=args.body or None, commit_id=commit_id)

    print(f"Posting {len(comments)} comment(s) as a pending review...")
    response = post_review(args.owner, args.repo, args.pr, payload)

    review_id = response.get("id", "unknown")
    html_url = response.get("html_url", "")
    print(f"Created pending review (id: {review_id}) with {len(comments)} comment(s).")
    if html_url:
        print(f"URL: {html_url}")
    print("The review is PENDING. Visit the PR on GitHub to submit it.")


if __name__ == "__main__":
    main()
