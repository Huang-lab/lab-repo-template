#!/usr/bin/env python3
"""Step 01: build the analysis cohort.

Run order lives in the filename. Drivers here are thin: they read config, call
tested primitives from ``src/analysis/``, and write to a dated results directory.
Anything with a branch worth testing belongs in ``src/``, not here.

Usage:
    python steps/01_cohort.py --config config/example.yaml [--inspect]
"""

from __future__ import annotations

import argparse
import logging
from pathlib import Path

from analysis.results import results_dir

# Initialize logging in every entry point, first thing. A warning that fires into
# a logger nobody installed is not a warning: fastVEP silently dropped variants
# with IUPAC alleles for exactly this reason.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
)
log = logging.getLogger(__name__)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--config", type=Path, required=True, help="YAML config for this run")
    p.add_argument(
        "--inspect",
        action="store_true",
        help="Report column names and row counts only. Never echoes cell values.",
    )
    p.add_argument("--results", type=Path, default=Path("results"))
    return p.parse_args()


def main() -> None:
    args = parse_args()
    out = results_dir(args.results)
    log.info("writing to %s", out)

    if args.inspect:
        # --inspect must never print cell values: an extract with no header row
        # will hand you the first data row as column names, and you will print a
        # real participant ID into a log. Report the schema, then stop.
        raise NotImplementedError(
            "TODO(schema): implement --inspect once the extract is available. "
            "Report column names and row counts only, and add a test that the "
            "output contains no value from the fixture. See docs/PSEUDOCODE.md#step-01."
        )

    # Deliberately raises rather than guessing at the schema. A driver that
    # invents column names returns plausible garbage months later; one that
    # refuses to run tells you exactly what is missing.
    raise NotImplementedError(
        "TODO(schema): waiting on the data extract. Recipe in docs/PSEUDOCODE.md#step-01."
    )


if __name__ == "__main__":
    main()
