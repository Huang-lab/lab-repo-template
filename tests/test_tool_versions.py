"""One version of every tool that gates CI.

A gate a developer cannot reproduce is a gate that wastes their afternoon. This
repository had two ruffs: `.pre-commit-config.yaml` pinned
`astral-sh/ruff-pre-commit` at `v0.6.9`, and CI installed `ruff>=0.5` from
`[project.optional-dependencies].dev` and therefore resolved to whatever was
newest. Ordinary code passed the hook and failed the build:

    $ cat demo.py
    def parse_ids(text: str) -> list[str]:
        head, tail = text.split(",", 1)
        return PATTERN.findall(tail)

    $ ruff-0.6.9  check demo.py      # what `pre-commit run` used
    All checks passed!

    $ ruff-0.16.5 check demo.py      # what CI installed
    RUF059 Unpacked variable `head` is never used
    Found 1 error.

Sixty rules in the selected families (E, F, W, I, B, UP, SIM, PTH, RUF) exist in
0.16.5 and not in 0.6.9, and `ruff format`'s output has changed across that
range too, so `ruff format --check` can fail on code the hook just formatted.

These tests are deliberately dumb string checks rather than a YAML parse: they
run with no dependency beyond pytest, in a repository whose whole point is to be
copied into projects that may not want one.

Mutation-checked: restoring either half of the split fails the matching test.
"""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).parent.parent
PRE_COMMIT = ROOT / ".pre-commit-config.yaml"
PYPROJECT = ROOT / "pyproject.toml"
CI = ROOT / ".github" / "workflows" / "ci.yml"

# Tools that gate CI and also run in a pre-commit hook, so a version split
# between the two is invisible until the build goes red. Add to this when a
# tool acquires both roles.
GATING_TOOLS = ["ruff"]


def _dev_dependencies() -> list:
    """The `dev` extra's requirement strings, read without tomllib.

    `tomllib` is 3.11+ and this template supports 3.10, so the block is sliced
    out by hand. It is four lines of a file this repository owns.
    """
    text = PYPROJECT.read_text()
    match = re.search(r"^dev\s*=\s*\[(.*?)^\]", text, re.MULTILINE | re.DOTALL)
    assert match, "pyproject.toml has no `dev = [...]` block"
    reqs = []
    for line in match.group(1).splitlines():
        line = line.split("#", 1)[0].strip().rstrip(",").strip()
        if line.startswith(('"', "'")):
            reqs.append(line.strip("\"'"))
    return reqs


@pytest.mark.parametrize("tool", GATING_TOOLS)
def test_gating_tool_is_pinned_exactly(tool):
    """`tool==X.Y.Z`, not `tool>=X.Y`.

    A floor is not a version. Two people installing on different days get
    different linters, and so does CI.
    """
    reqs = [r for r in _dev_dependencies() if re.match(rf"^{tool}\b", r)]
    assert reqs, f"{tool} is not in the dev extra of pyproject.toml"
    for req in reqs:
        assert "==" in req, (
            f"{req!r} is a floor, not a pin. CI resolves it to whatever is "
            f"newest that day; a developer resolves it to whatever they "
            f"installed. Pin it and let dependabot propose the bump."
        )


@pytest.mark.parametrize("tool", GATING_TOOLS)
def test_gating_tool_has_no_second_version_in_pre_commit(tool):
    """No remote pre-commit hook supplies a tool the dev extra already pins.

    A `rev:` in `.pre-commit-config.yaml` is a second, independent version of
    the same binary, and nothing keeps the two in step -- dependabot does not
    read pre-commit configs at all. A `repo: local` hook running the tool from
    the project environment has one version by construction.
    """
    text = PRE_COMMIT.read_text()
    offenders = [
        line.strip()
        for line in text.splitlines()
        if line.strip().startswith("- repo:") and tool in line
    ]
    assert not offenders, (
        f"{offenders} pins its own {tool}, while pyproject.toml pins another. "
        f"Use a `repo: local` hook with `entry: {tool} ...` and "
        f"`language: system` so the hook and CI are the same binary."
    )


@pytest.mark.parametrize("tool", GATING_TOOLS)
def test_pre_commit_actually_runs_the_tool(tool):
    """The split is not fixed by deleting the hook.

    Removing `ruff-pre-commit` and putting nothing back would pass the test
    above and quietly stop linting before commit, which is worse than the
    version skew it was meant to fix.
    """
    text = PRE_COMMIT.read_text()
    assert re.search(rf"^\s*entry:\s*{tool}\b", text, re.MULTILINE), (
        f".pre-commit-config.yaml has no local hook running {tool}"
    )


def _versions_named(tool: str, path: Path) -> set:
    """Every `tool==X.Y.Z` version string appearing in `path`."""
    return set(re.findall(rf"{tool}\s*==\s*([0-9][0-9A-Za-z.\-]*)", path.read_text()))


@pytest.mark.parametrize("tool", GATING_TOOLS)
def test_ci_does_not_install_the_tool_unpinned(tool):
    """No bare `pip install ... ruff` anywhere in CI.

    `pip install ruff` resolves to the newest release regardless of what
    pyproject.toml pins, which reintroduces the split one line below the fix.
    The `requirements.txt` branch is the one that had it: a repo built from
    this template without a pyproject.toml still linted against whatever was
    newest that morning.
    """
    for line in CI.read_text().splitlines():
        stripped = line.split("#", 1)[0].strip()
        if not stripped.startswith("pip install"):
            continue
        for token in stripped.split():
            token = token.strip("'\"")
            if token == tool:
                pytest.fail(f"CI installs an unpinned {tool}: {stripped!r}")


@pytest.mark.parametrize("tool", GATING_TOOLS)
def test_every_named_version_of_the_tool_agrees(tool):
    """One version string, however many files have to name it.

    A repository with no pyproject.toml has nowhere else to pin a dev tool, so
    ci.yml names the version too. Two mentions are fine; two *versions* are the
    bug. This is the assertion that keeps them honest.
    """
    named = {}
    for path in (PYPROJECT, CI, PRE_COMMIT):
        versions = _versions_named(tool, path)
        if versions:
            named[path.name] = versions
    assert named, f"nothing pins {tool}"
    distinct = set().union(*named.values())
    assert len(distinct) == 1, (
        f"{tool} is pinned to more than one version: {named}. "
        f"Pick one; the whole point is that the hook, CI and a developer's "
        f"install are the same binary."
    )
