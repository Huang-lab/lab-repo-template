# Design decisions

Numbered so code and commits can cite them (`# see DD-03`). Worth keeping only if the reasoning matters more than the code - for a design-doc-driven pipeline it does, for a small tool it doesn't.

Format: decision, alternative rejected, consequence if wrong. Delete the examples below.

---

**DD-01 - Missing values use three-valued logic, not booleans.** `src/analysis/criteria.py`. A missing diagnosis is not a negative one; collapsing UNKNOWN to False yields a cohort that looks clean and is wrong.
*Rejected:* `fillna(False)` - silent and unauditable. *If wrong:* `resolve()` raises rather than guessing, so it fails loudly.

**DD-02 - Results freeze in dated directories.** `src/analysis/results.py`.
*Rejected:* overwrite in place - the diff then misrepresents a rerun as a code change. *If wrong:* extra disk, which is free.

**DD-03 - <next>**
