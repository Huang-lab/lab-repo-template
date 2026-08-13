# Design decisions

Numbered so code and commit messages can cite them (`# see DD-03`).
Record the decision when you make it - reconstructing it later is the expensive part.
This pattern is why `Proteomic-CKD-prediction` was the best-documented new repo in the lab.

Format: decision, alternatives rejected, consequence if wrong.

---

**DD-01 - Missing values use three-valued logic, not booleans.**
`src/analysis/criteria.py`. A missing diagnosis is not a negative diagnosis; collapsing UNKNOWN to False yields a cohort that looks clean and is wrong.
*Rejected:* boolean with `fillna(False)` - silent, unauditable.
*If wrong:* eligibility counts shift; `resolve()` raises rather than guessing, so the failure is loud.

**DD-02 - Results are frozen in dated directories.**
`src/analysis/results.py`. A rerun writes a new directory.
*Rejected:* overwrite in place - the diff then misrepresents a rerun as a code change.
*If wrong:* extra disk, which is free.

**DD-03 - <next decision>**

---

Cite these in code where the reasoning isn't local:

```python
# DD-01: UNKNOWN is not False here - see docs/DESIGN_DECISIONS.md
```
