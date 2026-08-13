# Conventions

Each rule has its reason, because a rule without one gets dropped when inconvenient.

## Repository names

**Default: kebab-case**, lowercase, no underscores, no dates: `cancer-risk-msm`.

**Exception: the repo *is* a published tool** - then match the tool's canonical name exactly, casing included: `fastVEP`, `RastQC`, `TRACE-Kin`.
For a tool the repo name is public identity (installs, recipes, citations); for a project nothing external depends on it, so consistency wins.

**Tie-breaker:** unsure means it's a project - use kebab-case.
**Don't rename existing repos** to conform; every slide and clone URL would depend on a redirect.
**Never:** spaces, `|`, `:`, uppercase for projects, dates.

## File and directory names

- No shell metacharacters or spaces. A directory named `SingleCell|-Arshiya/` breaks any unquoted script; some tools won't create it. Checked by `scripts/check_hygiene.sh`.
- Spell-check directory names before creating them. `SubcellularExpressionPatern/` propagates into every path reference and figure caption.
- Numbered pipeline steps: `01_cohort.py`, `02_features.py`.
- `snake_case` for Python, R, and Rust. Tests: `tests/test_*.py`, `tests/testthat/test-*.R`.
- Never commit `tmp.*`, `test.*`, `scratch.*`, `Untitled*`. If it's worth committing, name it.

## Commits

- **Subject:** imperative, specific. `Run` is not a message for a 1,065-line addition.
- **Body: write it like a methods section.** Name the real-data observation that surfaced the problem:

  ```
  Encode real MSM vocabularies; fix four silent-wrong-answer traps

  Vitals has no BMI measure_type, and weight is often in ounces (cohort
  median ~2700). Treating ounces as pounds drops every BMI via the
  plausibility filter - 100% missing rather than visibly failing.

  "Never Assessed" (96,717 rows) means NOT ASKED but contains "never",
  so substring matching scored it as never-smoker.
  ```

  Six months later this is the only record of why a threshold is what it is.
- **Granularity:** one commit per module plus its tests, or per pipeline stage. A single monster commit throws away `git blame` as a design record - which for an analysis repo is most of its value.

## Branches and PRs

`main` is always runnable. Work on `<initials>/<topic>`.
Open a PR even in solo repos: CI needs somewhere to run.
**A human merges, always** - including agent-drafted PRs. That's what makes the human responsible.

## Agent authorship

**An agent is never the primary `Author:` of a commit.** Humans author, agents get `Co-Authored-By:`.
Mechanics in [AGENTS.md](./AGENTS.md).
`git log` is what a reviewer or an institutional inquiry reads; downstream tools can remap a name for headcount but cannot reconstruct responsibility.
The failure runs both ways - check `user.email` is registered to your GitHub account, or your work goes uncredited.

## Data

Raw data never enters git. Cluster output (`*.stdout`, `*.out`, `logs/`) never enters git.
A `.gitignore` addition does not remove what is already committed - run `scripts/scan_history.sh`, then `git filter-repo`, before the repo has forks.
See [data/README.md](./data/README.md).

## Results

Committed only when frozen: `results-YYYY-MM-DD/`, never overwritten.
A rerun that overwrites in place produces a diff reading as a code change, and later nobody can tell which numbers are in the paper.
See [results/README.md](./results/README.md).

## Tests

- **Mutation-check every test:** break the code, confirm the test fails, restore, commit. A test that passes against its own bug is worse than none.
- **Test where a silent bug corrupts a result** - unit conversions, eligibility logic, fold assignment - not the plumbing.
- **Blocking gates** for human-entered ground truth: a test that fails by design, with the pipeline step refusing to run while it's red.
- **Check what CI executes.** `cargo test --workspace --lib` skips every integration test in `tests/`. Use `--all-targets`.

## Logging

Initialize a logger in `main`, first thing: `env_logger::init()`, `logging.basicConfig()`.
fastVEP silently dropped IUPAC-allele variants because `log::warn!` fired into a logger that was never installed.

## Review

Any repo backing a manuscript needs a second reader on the decisions that determine published numbers - one hour, three riskiest defaults.
Nine of eleven active repos have one human contributor; nothing currently forces a second pair of eyes.
