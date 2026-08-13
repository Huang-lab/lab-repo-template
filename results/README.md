# Results

Commit outputs only when frozen - a directory that is never overwritten.

```
results/
  results-2026-08-13/
  results-2026-09-02/     # a rerun writes a new directory
```

`src/analysis/results.py` (`results_dir`, `freeze`) and `R/utils.R` enforce this in code. Delete them if you'd rather not.

**Why:** overwriting in place produces a diff that reads as a code change. Two years later, when the figure is in a supplement, nobody can tell which numbers are in the paper.

**Commit:** small tables and figures backing a claim, plus run metadata.
**Don't:** anything large, regenerable intermediates, participant-level output.

## Provenance stub - one per results directory

```markdown
- Run by:       <name>
- Code version: <git rev-parse --short HEAD>
- Config:       config/<file>.yaml
- Inputs:       <path> (md5 <...>)
- Command:      python steps/03_model.py --config config/<file>.yaml
- Notes:        <what changed since the previous run, and why>
```
