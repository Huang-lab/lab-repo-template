# Pseudocode

How each step maps to code, written *before* the step exists. `TODO(schema)` markers in `steps/*.py` point here. Skip this file unless you're building a multi-step pipeline against data you don't have yet.

Layering: README = what to run, this = how, `DESIGN_DECISIONS.md` = why.

---

## Step 01 - cohort

**In:** `<extract>.tsv`, one row per person. **Out:** `results-YYYY-MM-DD/cohort.parquet`.

```
load extract          -> require_columns([person_id, index_date, ...])
apply inclusion       -> Tri per criterion (DD-01)
apply exclusion
resolve(unknown_as=?) -> state the policy explicitly, record it as a DD
label excluded rows   -> keep them with a reason column; never drop silently
write frozen output
```

**Traps to test:** no header row in the extract; units differing by row (ounces vs pounds); a category label containing the negation of its meaning (`"Never Assessed"` is not never).
