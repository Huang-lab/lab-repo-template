"""Tests for three-valued eligibility logic.

Every test here was mutation-checked: the implementation was broken on purpose
and each test was confirmed to fail before being committed. Do the same for
anything you add - a test that passes against the bug it was written for is
worse than no test. See CONVENTIONS.md#tests.
"""

import pytest

from analysis.criteria import Tri, resolve, tri_all, tri_and, tri_any, tri_not, tri_or


def test_of_maps_none_to_unknown():
    assert Tri.of(None) is Tri.UNKNOWN
    assert Tri.of(True) is Tri.TRUE
    assert Tri.of(False) is Tri.FALSE


def test_unknown_and_false_is_false():
    # One failed criterion excludes regardless of what else is unknown. This is
    # the case that plain booleans get right by accident and wrong in general.
    assert tri_and(Tri.UNKNOWN, Tri.FALSE) is Tri.FALSE
    assert tri_and(Tri.FALSE, Tri.UNKNOWN) is Tri.FALSE


def test_unknown_and_true_stays_unknown():
    # The case that matters: a missing diagnosis is not a negative diagnosis.
    assert tri_and(Tri.UNKNOWN, Tri.TRUE) is Tri.UNKNOWN


def test_unknown_or_true_is_true():
    assert tri_or(Tri.UNKNOWN, Tri.TRUE) is Tri.TRUE
    assert tri_or(Tri.TRUE, Tri.UNKNOWN) is Tri.TRUE


def test_unknown_or_false_stays_unknown():
    assert tri_or(Tri.UNKNOWN, Tri.FALSE) is Tri.UNKNOWN


def test_not_unknown_is_unknown():
    assert tri_not(Tri.UNKNOWN) is Tri.UNKNOWN
    assert tri_not(Tri.TRUE) is Tri.FALSE
    assert tri_not(Tri.FALSE) is Tri.TRUE


def test_empty_reductions_match_builtin_semantics():
    assert tri_all([]) is Tri.TRUE
    assert tri_any([]) is Tri.FALSE


def test_all_short_circuits_to_false_with_unknowns_present():
    assert tri_all([Tri.TRUE, Tri.UNKNOWN, Tri.FALSE]) is Tri.FALSE
    assert tri_all([Tri.TRUE, Tri.UNKNOWN]) is Tri.UNKNOWN


def test_resolve_refuses_bare_unknown():
    # The point of the module: an unhandled UNKNOWN fails loudly at the boolean
    # boundary rather than silently becoming an exclusion.
    with pytest.raises(ValueError, match="UNKNOWN eligibility"):
        resolve(Tri.UNKNOWN)


def test_resolve_honors_explicit_unknown_policy():
    assert resolve(Tri.UNKNOWN, unknown_as=False) is False
    assert resolve(Tri.UNKNOWN, unknown_as=True) is True
    assert resolve(Tri.TRUE) is True
    assert resolve(Tri.FALSE) is False
