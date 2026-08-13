# Pseudocode

How each step maps to code, in enough detail that someone else could implement it.
Written *before* the step exists; `TODO(schema)` markers in `steps/*.py` point here.

The layering: `README` = what to run, this file = how, `DESIGN_DECISIONS.md` = why.

---

## Step 01 - cohort

**Input:** `<extract>.tsv` - one row per person.
**Output:** `results-YYYY-MM-DD/cohort.parquet`.

```
load extract          -> require_columns([person_id, index_date, ...])
apply inclusion       -> Tri per criterion (DD-01)
apply exclusion
resolve(unknown_as=?) -> state the policy explicitly, record it in DD
label excluded rows   -> keep them, with a reason column; never drop silently
write frozen output
```

**Traps to test:** no header row in the extract; units differing by row (weight in ounces vs pounds); a category whose label contains the negation of its meaning (`"Never Assessed"` is not never).

## Step 02 - <next>
