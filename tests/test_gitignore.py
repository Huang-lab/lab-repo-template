"""The .gitignore, tested the way git applies it.

This file's header says "ANCHORING MATTERS" and tells you to verify with
`git check-ignore -v`. Nothing verified it: `tests/` swallowed
`crates/*/tests/` in fastVEP for months, and the data rules were written for
VCF/BAM/FASTQ and never extended when the lab started producing AnnData,
Space Ranger and Visium HD output. A repo made from this template, with its
`.gitignore` unchanged, would have committed `analysis/adata.h5ad` without a
word.

Two lists, both asked of real `git check-ignore` in a scratch repository:

- IGNORED: paths that must never be staged by `git add -A`.
- NOT_IGNORED: paths that must stay visible. A rule that is too broad fails the
  other way - silently - when a collaborator's file never reaches the remote, so
  this list is as much the point as the first.

Each path is its own test case, so a failure names the exact path. Add a path
here when a pattern is added; add one to NOT_IGNORED when a new pattern could
plausibly swallow something that should be tracked.

Every `!` negation in .gitignore has a NOT_IGNORED case, because a negation
under an excluded parent directory does nothing and nothing says so: `.claude/`
and `.vscode/` did exactly that until this test existed.

Mutation-checked: deleting any one of the patterns added for these formats
fails that format's case, restoring `.claude/` or `.vscode/` fails the
negation cases, and adding `*.csv` or un-anchoring `/data/*` fails NOT_IGNORED.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).parent.parent

IGNORED = [
    # raw data under data/, whatever its extension
    "data/raw/anything.bin",
    "data/extract.xlsx",
    # genomics formats the original rules were written for
    "analysis/cohort.vcf.gz",
    "analysis/sample.bam",
    "analysis/reads.fastq.gz",
    "analysis/geno.pgen",
    "analysis/obj.rds",
    "analysis/obj.RData",
    "analysis/table.parquet",
    "outs/filtered_feature_bc_matrix.h5",
    # single-cell and spatial formats
    "analysis/adata.h5ad",
    "results/seurat.loom",
    "outs/cloupe.cloupe",
    "outs/matrix.mtx",
    "outs/matrix.mtx.gz",
    "outs/filtered_feature_bc_matrix/barcodes.tsv.gz",
    "outs/filtered_feature_bc_matrix/features.tsv.gz",
    "outs/filtered_feature_bc_matrix/genes.tsv",
    "outs/filtered_feature_bc_matrix/genes.tsv.gz",
    "outs/barcodes.tsv",
    "outs/features.tsv",
    "analysis/sdata.zarr/zarr.json",
    "analysis/obj.qs",
    "analysis/obj.rda",
    "analysis/obj.Rdata",
    # serialised Python objects (data, and code on load)
    "analysis/frame.pkl",
    "docs/_build/doctrees/environment.pickle",
    # raw imaging and whole-slide formats
    "outs/image.btf",
    "outs/slide.ome.tif",
    "outs/slide.ome.tiff",
    "slides/case1.svs",
    "slides/case1.ndpi",
    "slides/case1.czi",
    "slides/case1.nd2",
    # secrets, cluster output, scratch, OS and editor droppings
    ".env",
    ".claude/settings.local.json",
    ".claude/projects/session.jsonl",
    ".vscode/settings.json",
    "config/prod.key",
    "config/service-account-prod.json",
    "logs/job.out",
    "tmp.R",
    ".DS_Store",
    "notebooks/.ipynb_checkpoints/x-checkpoint.ipynb",
]

NOT_IGNORED = [
    # the two files data/ exists to carry
    "data/README.md",
    "data/.gitkeep",
    # code and docs, including at depths where an unanchored `data/` or `tests/`
    # pattern would swallow them (the fastVEP failure)
    "src/analysis/data/loaders.py",
    "crates/example/tests/integration.rs",
    "tests/test_criteria.py",
    "steps/01_cohort.py",
    "README.md",
    "docs/DESIGN_DECISIONS.md",
    # tabular text results and figures are meant to be committed
    "results/2026-10-01_run/summary.csv",
    "results/2026-10-01_run/summary.tsv",
    "docs/figures/fig1.png",
    "docs/figures/fig1.tif",
    "docs/figures/fig1.tiff",
    "docs/figures/fig1.pdf",
    # config that looks like a secret and is not
    ".env.example",
    ".claude/settings.json",
    ".vscode/extensions.json",
    "tests/testdata/dummy.key",
    "renv/activate.R",
    "renv.lock",
    "Cargo.lock",
    ".github/workflows/ci.yml",
]


@pytest.fixture(scope="module")
def scratch_repo(tmp_path_factory):
    """An empty repository carrying only this repository's .gitignore."""
    repo = tmp_path_factory.mktemp("gitignore-probe")
    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    # `git init` sets core.ignorecase on a case-insensitive filesystem (macOS),
    # which makes `*.RData` match `x.Rdata` there and not on Linux CI. Pin it
    # off so a laptop and the runner give the same answer.
    subprocess.run(["git", "-C", str(repo), "config", "core.ignorecase", "false"], check=True)
    shutil.copy(ROOT / ".gitignore", repo / ".gitignore")
    return repo


def _is_ignored(repo: Path, path: str) -> bool:
    # check-ignore exits 0 when ignored, 1 when not, 128 on a fatal error.
    result = subprocess.run(
        ["git", "-C", str(repo), "check-ignore", "-q", path],
        capture_output=True,
        text=True,
    )
    assert result.returncode in (0, 1), f"git check-ignore failed: {result.stderr.strip()}"
    return result.returncode == 0


@pytest.mark.parametrize("path", IGNORED)
def test_path_is_ignored(scratch_repo, path):
    assert _is_ignored(scratch_repo, path), (
        f"{path} is not ignored: `git add -A` would stage it. "
        f"Check with `git check-ignore -v {path}`, then add or fix a pattern."
    )


@pytest.mark.parametrize("path", NOT_IGNORED)
def test_path_is_not_ignored(scratch_repo, path):
    assert not _is_ignored(scratch_repo, path), (
        f"{path} is ignored, so it would silently never reach the remote. "
        f"Find the pattern with `git check-ignore -v {path}` and narrow or anchor it."
    )
