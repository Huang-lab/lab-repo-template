# lab-repo-template

Backbone for Huang Lab repos. **Use this template**, then [SETUP.md](./SETUP.md).

> **This is a menu, not a mandate.** Take the parts that fit your project and delete the rest - an unused scaffold or a convention nobody follows is worse than nothing. Only two things are lab-wide: the git identity in SETUP step 3, and never committing raw data.

Each piece exists because a repo needed it patched in by hand later ([2026-08-13 review](https://github.com/Huang-lab/HuangLabCodeReview)).

| Keep if... | Files |
|---|---|
| always | [.gitignore](./.gitignore), [LICENSE](./LICENSE) |
| an agent touches this repo | [AGENTS.md](./AGENTS.md), [CLAUDE.md](./CLAUDE.md) |
| you have tests | [.github/workflows/ci.yml](./.github/workflows/ci.yml) - detects Python/R/Rust, runs only what's present |
| the repo will go public or back a manuscript | [scripts/scan_history.sh](./scripts/scan_history.sh), [scripts/check_hygiene.sh](./scripts/check_hygiene.sh) |
| it's a pipeline | `src/` `steps/` `tests/` (Python), `R/`, `crates/` (Rust) - one passing test each |
| it touches participant data | [data/README.md](./data/README.md) |
| it produces committed outputs | [results/README.md](./results/README.md) |
| the reasoning matters more than the code | [docs/](./docs) - DD-numbered decisions, pseudocode |
| you want them | [CONVENTIONS.md](./CONVENTIONS.md), PR/issue templates, dependabot, pre-commit, `CITATION.cff` |

## Naming

Repos are **kebab-case** (`cancer-risk-msm`) unless the repo *is* a published tool, which keeps its own name (`fastVEP`, `RastQC`). [Details](./CONVENTIONS.md#repository-names).

## Three practices worth more than any file here

1. **Mutation-check tests** - break the code, confirm the test fails, then commit. (fastVEP #80)
2. **Commit bodies like methods sections** - name the real-data observation. (Cancer-risk-MSM)
3. **`_NOT_GROUND_TRUTH` in column names** - can't be mistaken for truth downstream. (Proteomic-CKD)
