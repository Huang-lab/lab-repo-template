# Conventions

**Keep the sections that apply to your repo and delete the rest.** A convention nobody follows is worse than none. Each rule carries its reason so you can judge whether it's worth keeping.

## Repository names

Default **kebab-case**, no underscores or dates: `cancer-risk-msm`.
Exception: the repo *is* a published tool, then it keeps the tool's own name and casing (`fastVEP`, `RastQC`, `TRACE-Kin`) - for a tool the repo name is public identity; for a project nothing external depends on it.
Unsure? It's a project. Don't rename existing repos.

## File names

- No spaces or shell metacharacters. A directory named `SingleCell|-Arshiya/` breaks unquoted scripts; some tools won't create it.
- Spell-check directory names - `SubcellularExpressionPatern/` propagates into every path and figure caption.
- Numbered steps: `01_cohort.py`. `snake_case` everywhere.
- Never commit `tmp.*`, `scratch.*`, `Untitled*`.

## Commits

Subject imperative and specific (`Run` is not a message for 1,065 lines).
**Body like a methods section** - name the real-data observation:

```
Encode real MSM vocabularies; fix four silent-wrong-answer traps

Vitals has no BMI measure_type, and weight is often in ounces (median
~2700). Treating ounces as pounds drops every BMI via the plausibility
filter - 100% missing rather than visibly failing.
```

One commit per module plus tests, or per pipeline stage. A monster commit throws away `git blame` as a design record.

## Agent authorship

An agent is never the primary `Author:`; humans author, agents get `Co-Authored-By:`. Mechanics in [AGENTS.md](./AGENTS.md). Check your `user.email` is registered to your GitHub account, or your work goes uncredited.

## Data and results

Raw data and cluster output (`*.stdout`, `logs/`) never enter git; `.gitignore` doesn't remove what's already committed. See [data/README.md](./data/README.md).
Commit results only when frozen: `results-YYYY-MM-DD/`, never overwritten - otherwise a rerun's diff reads as a code change. See [results/README.md](./results/README.md).

## Tests

- **Mutation-check:** break the code, confirm the test fails, restore, commit. A test that passes against its own bug is worse than none.
- Test where a silent bug corrupts a result (unit conversions, eligibility, fold assignment), not the plumbing.
- Check what CI executes: `cargo test --workspace --lib` skips every integration test. Use `--all-targets`.
- Initialize a logger in `main` - fastVEP dropped IUPAC-allele variants because `log::warn!` fired into a logger nobody installed.

## Review

Any repo backing a manuscript needs a second reader on the decisions that set published numbers - one hour, three riskiest defaults.
