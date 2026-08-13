"""Tests for the frozen-results helpers."""

import datetime as dt

import pytest

from analysis.results import NOT_GROUND_TRUTH, freeze, results_dir


def test_results_dir_is_dated_and_created(tmp_path):
    out = results_dir(tmp_path, date=dt.date(2026, 8, 13))
    assert out.name == "results-2026-08-13"
    assert out.is_dir()


def test_results_dir_defaults_to_today(tmp_path):
    out = results_dir(tmp_path)
    assert out.name == f"results-{dt.date.today().isoformat()}"


def test_freeze_refuses_to_overwrite(tmp_path):
    target = tmp_path / "metrics.csv"
    target.write_text("already,here\n")
    with pytest.raises(FileExistsError, match="never overwritten"):
        freeze(target)


def test_freeze_creates_parents_for_new_paths(tmp_path):
    target = freeze(tmp_path / "results-2026-08-13" / "metrics.csv")
    assert target.parent.is_dir()
    assert not target.exists()


def test_not_ground_truth_marker_is_loud():
    column = f"pyprevent_risk_pct{NOT_GROUND_TRUTH}"
    assert column == "pyprevent_risk_pct_NOT_GROUND_TRUTH"
