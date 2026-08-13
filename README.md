# lab-repo-template

Best-practice backbone for Huang Lab repos.
**Use this template**, then work through [SETUP.md](./SETUP.md) (10 min).

Each piece exists because a repo in the lab needed it patched in by hand later.
Source: the [2026-08-13 code review](https://github.com/Huang-lab/HuangLabCodeReview).

| Area | Files |
|---|---|
| Conventions | [CONVENTIONS.md](./CONVENTIONS.md) - naming, commits, data, results, tests |
| Agent policy | [AGENTS.md](./AGENTS.md) - agents are never the primary commit author |
| Ignore rules | [.gitignore](./.gitignore) - macOS, Python, R, Rust, notebooks, cluster logs, agent logs, data, secrets |
| CI | [.github/workflows/ci.yml](./.github/workflows/ci.yml) - detects Python/R/Rust, runs only what's present |
| Hygiene | [scripts/check_hygiene.sh](./scripts/check_hygiene.sh) - large files, `tmp.*`, metacharacters in paths, keys, hardcoded home paths |
| History scan | [scripts/scan_history.sh](./scripts/scan_history.sh) - run before going public or submitting |
| Layered docs | [docs/](./docs) - `DESIGN_DECISIONS.md`, `PSEUDOCODE.md`, README skeleton |
| Scaffolds | `src/` `steps/` `tests/` (Python), `R/` (R), `crates/` (Rust) - one passing test each; delete what you don't need |
| Data / results | [data/README.md](./data/README.md), [results/README.md](./results/README.md) |
| Furniture | PR + issue templates, dependabot, pre-commit, `.editorconfig`, `.gitattributes`, `CITATION.cff` |

## Naming

Repos are **kebab-case** (`cancer-risk-msm`) unless the repo *is* a published tool, which matches the tool's own name exactly (`fastVEP`, `RastQC`, `TRACE-Kin`).
Details: [CONVENTIONS.md](./CONVENTIONS.md#repository-names).

## Three practices worth more than any file here

1. **Mutation-check tests** - revert the fix, confirm the test fails, then commit. (fastVEP #80)
2. **Commit bodies like methods sections** - name the real-data observation, not just the change. (Cancer-risk-MSM)
3. **`_NOT_GROUND_TRUTH` in column names** - impossible to mistake for authoritative downstream. (Proteomic-CKD-prediction)

Issues and PRs welcome - this should change as the lab learns things.
