# <repo-name>

<One sentence: what question this answers or what the tool does.>

- **Status:** in development | frozen for manuscript | maintained
- **Contact:** <name> (<email>)
- **Data:** see [data/README.md](./data/README.md)

## Run order

| Step | Script | Input | Output |
|---|---|---|---|
| 01 | `steps/01_cohort.py` | raw extract | cohort table |
| 02 | | | |

```sh
pip install -e '.[dev]'
python steps/01_cohort.py --config config/example.yaml
```

## Layout

```
src/        tested primitives
steps/      numbered drivers (run order = filename)
tests/      unit tests
docs/       DESIGN_DECISIONS.md (why), PSEUDOCODE.md (how)
results/    frozen, dated outputs only
```

## Known gaps

<Be honest here. A documented gap is a collaborator's saved afternoon.>

## Conventions

[CONVENTIONS.md](./CONVENTIONS.md), [AGENTS.md](./AGENTS.md).
