# Agent instructions

Claude Code, Copilot, Cursor, any coding agent. Edit this file to fit the repo; delete what doesn't apply.

## Authorship

**Never be the primary `Author:` of a commit.** The human authors; you get `Co-Authored-By:`.

```sh
git config user.name "Your Name" && git config user.email "your-github-email@mssm.edu"
git log -1 --format='%an <%ae> / committer %cn'   # verify the commit, not the config
```

If either name reads `Claude`, `Copilot`, or a bot, fix and amend before pushing.
`git log` is what a reviewer or institutional inquiry reads. Two lab repos have `Claude` as author, committer, *and* co-author of every substantive commit, so no human is named anywhere.

## Never commit

Raw data. Cluster output (`*.stdout`, `logs/`). Session logs. `tmp.*`, `scratch.*`. Absolute paths from your machine - parameterize them.
Run `scripts/check_hygiene.sh` first.

## Tests

Mutation-check what you write (break the code, confirm failure, restore) and say so in the PR.
Never weaken, skip, or delete a failing test to make CI green - leave it failing and say so. Some lab tests fail *by design* until a human enters ground-truth values.

## Commits and merging

Body like a methods section; one commit per module or stage.
Open the PR, say what you verified vs. assumed, and stop. A human merges.
