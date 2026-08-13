# Agent instructions

Applies to Claude Code, Copilot, Cursor, and any other coding agent.

## Authorship

**An agent is never the primary `Author:` of a commit.** The human running the session authors; the agent gets `Co-Authored-By:`.

```sh
git config user.name  "Your Name"
git config user.email "the-address-on-your-github-account@example.org"
git log -1 --format='%an <%ae> / committer %cn'   # verify the commit, not the config
```

If either name reads `Claude`, `Copilot`, or a bot, fix and amend before pushing.

Why: `git log` is what a reviewer, collaborating lab, or institutional inquiry reads. Two lab repos currently have `Claude` as author, committer, *and* co-author of every substantive commit, so no human is named anywhere in the commit object. Downstream tools can remap a name for headcount; they cannot reconstruct responsibility.

Also check `user.email` is registered to your GitHub account - a `.local` or hostname address means the work goes uncredited entirely.

## Never commit

Raw data. Cluster output (`*.stdout`, `*.out`, `logs/`). Session logs or transcripts. `tmp.*`, `scratch.*`, `Untitled*`. Absolute paths from your machine - parameterize them.

Run `scripts/check_hygiene.sh` before committing.

## Tests

Mutation-check every test you write (revert the fix, confirm failure, restore) and say so in the PR.
Never weaken, skip, or delete a failing test to make CI green - if a test blocks you, leave it failing and say so. Some lab tests fail *by design* until a human enters ground-truth values.

## Commits and merging

Body like a methods section; one commit per module or pipeline stage ([examples](./CONVENTIONS.md#commits)).
Open the PR, summarize what you changed and verified, and stop. A human merges.
