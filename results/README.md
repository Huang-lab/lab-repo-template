# Results

Committed only when frozen. Frozen means a directory that is never overwritten.

```
results/
  results-2026-08-13/     # a complete run, never edited after it lands
  results-2026-09-02/     # a later run, its own directory
```

`src/analysis/results.py` (`results_dir`, `freeze`) and `R/utils.R` enforce this in code.

**Why:** a rerun that overwrites in place produces a diff reading as a code change. Two years later, when the figure is in a supplement, nobody can tell which numbers are in the paper.

**Commit:** small tables and figures backing a manuscript claim, plus run metadata.
**Don't commit:** anything large (5 MB check in `check_hygiene.sh`), regenerable intermediates, participant-level output.

## Provenance stub - one per results directory

```markdown
- Run by:       <name>
- Code version: <git rev-parse --short HEAD>
- Config:       config/<file>.yaml
- Inputs:       /sc/arion/projects/<project>/raw/<file> (md5 <...>)
- Command:      python steps/03_model.py --config config/<file>.yaml
- Notes:        <what changed since the previous run, and why>
```
