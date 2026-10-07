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

Mutation-checked: restoring either half of the split fails the matching test, and so
does writing the version into a second file (see the one-file test below).
"""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).parent.parent
PRE_COMMIT = ROOT / ".pre-commit-config.yaml"
PYPROJECT = ROOT / "pyproject.toml"
CI = ROOT / ".github" / "workflows" / "ci.yml"
REQUIREMENTS_DEV = ROOT / "requirements-dev.txt"

# Tools that gate CI and also run in a pre-commit hook, so a version split
# between the two is invisible until the build goes red. Add to this when a
# tool acquires both roles.
GATING_TOOLS = ["ruff"]


def _dev_dependencies() -> list:
    """The requirement strings in requirements-dev.txt, the one pin file.

    `pyproject.toml`'s `dev` extra is dynamic and reads this file, so this is
    also what `pip install -e '.[dev]'` installs.
    """
    reqs = []
    for line in REQUIREMENTS_DEV.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            reqs.append(line)
    return reqs


@pytest.mark.parametrize("tool", GATING_TOOLS)
def test_gating_tool_is_pinned_exactly(tool):
    """`tool==X.Y.Z`, not `tool>=X.Y`.

    A floor is not a version. Two people installing on different days get
    different linters, and so does CI.
    """
    reqs = [r for r in _dev_dependencies() if re.match(rf"^{tool}\b", r)]
    assert reqs, f"{tool} is not in requirements-dev.txt"
    for req in reqs:
        assert "==" in req, (
            f"{req!r} is a floor, not a pin. CI resolves it to whatever is "
            f"newest that day; a developer resolves it to whatever they "
            f"installed. Pin it and let dependabot propose the bump."
        )


@pytest.mark.parametrize("tool", GATING_TOOLS)
def test_gating_tool_has_no_second_version_in_pre_commit(tool):
    """No remote pre-commit hook supplies a tool requirements-dev.txt already pins.

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
        f"{offenders} pins its own {tool}, while requirements-dev.txt pins another. "
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
def test_exactly_one_file_names_a_version_of_the_tool(tool):
    """The version is written once, in requirements-dev.txt, and nowhere else.

    This replaces an assertion that every file naming a version named the same
    one. That held the line against drift but made every dependabot bump fail:
    dependabot edits one manifest per pull request, so a version also written
    in ci.yml could never be moved by the bot, and the bump went red for a
    reason no bot can fix (lab-repo-template #9, ruff 0.16.5 -> 0.16.9, where
    `ruff check` and `ruff format --check` both passed and only this test
    failed). One file means one edit, and dependabot makes it.
    """
    named = {}
    for path in (REQUIREMENTS_DEV, PYPROJECT, CI, PRE_COMMIT):
        versions = _versions_named(tool, path)
        if versions:
            named[path.name] = versions
    assert list(named) == [REQUIREMENTS_DEV.name], (
        f"{tool} must be pinned in {REQUIREMENTS_DEV.name} and nowhere else, "
        f"but it is named in {named}. A version in a second file is one "
        f"dependabot cannot move."
    )


def test_pyproject_reads_the_dev_extra_from_the_pin_file():
    """`pip install -e '.[dev]'` and the no-pyproject CI branch install the same bytes.

    A static `[project.optional-dependencies]` table next to the dynamic one is
    not valid, but a tidy-up that replaces the dynamic entry with a static list
    would be, and would quietly make `.[dev]` and requirements-dev.txt two lists
    again. Check the wiring, not just the contents.
    """
    text = PYPROJECT.read_text()
    assert re.search(r'^dynamic\s*=\s*\[[^\]]*"optional-dependencies"', text, re.MULTILINE), (
        'pyproject.toml must declare dynamic = ["optional-dependencies"]'
    )
    assert re.search(
        r'^dev\s*=\s*\{\s*file\s*=\s*\[\s*"requirements-dev\.txt"\s*\]\s*\}', text, re.MULTILINE
    ), 'the dev extra must be `dev = { file = ["requirements-dev.txt"] }`'
    assert not re.search(r"^\[project\.optional-dependencies\]", text, re.MULTILINE), (
        "a static optional-dependencies table is a second list of dev tools"
    )


def test_ci_fallback_installs_the_pin_file():
    """A repo with no pyproject.toml gets the same pinned tools, not whatever is newest."""
    assert re.search(
        r"pip install[^\n]*-r requirements\.txt[^\n]*-r requirements-dev\.txt", CI.read_text()
    ), "the no-pyproject branch of ci.yml must install -r requirements-dev.txt"
