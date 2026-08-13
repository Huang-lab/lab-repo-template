"""Frozen, dated result directories (DD-02).

A rerun writes a NEW directory. Overwriting in place produces a diff that reads
as a code change, and later nobody can tell which numbers are in the paper.
"""

from __future__ import annotations

import datetime as dt
import os
from pathlib import Path

__all__ = ["NOT_GROUND_TRUTH", "freeze", "results_dir"]

#: Suffix for any column whose values are not authoritative (estimate standing in
#: for a reference implementation, placeholder, imputation). In the column name it
#: cannot be mistaken for truth in a downstream join; a comment can.
NOT_GROUND_TRUTH = "_NOT_GROUND_TRUTH"


def results_dir(root: str | os.PathLike[str] = "results", *, date: dt.date | None = None) -> Path:
    """Return ``<root>/results-YYYY-MM-DD``, creating it if needed.

    Uses today's date unless ``date`` is given. Pass an explicit date when
    re-materializing an old run so the directory name stays truthful.
    """
    day = date or dt.date.today()
    path = Path(root) / f"results-{day.isoformat()}"
    path.mkdir(parents=True, exist_ok=True)
    return path


def freeze(path: str | os.PathLike[str]) -> Path:
    """Refuse to return ``path`` if it already exists.

    Call this for the specific output file rather than checking by hand. The
    failure mode it prevents is a second run of the same script quietly
    replacing the outputs a figure or table was built from.
    """
    target = Path(path)
    if target.exists():
        raise FileExistsError(
            f"{target} exists and frozen results are never overwritten. "
            f"Write to a new results-YYYY-MM-DD directory, or delete it "
            f"deliberately if it was never used."
        )
    target.parent.mkdir(parents=True, exist_ok=True)
    return target
