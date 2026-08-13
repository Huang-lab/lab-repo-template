"""Three-valued logic for cohort eligibility (DD-01).

In clinical data "not known" is not "no": an absent diabetes diagnosis may mean
the field was never asked. Collapsing UNKNOWN to False yields a cohort that looks
clean and is wrong, with nothing downstream able to tell.

Kleene semantics::

    UNKNOWN and False -> False      one failed criterion excludes regardless
    UNKNOWN and True  -> UNKNOWN    still undetermined
    UNKNOWN or  True  -> True
    UNKNOWN or  False -> UNKNOWN

:func:`resolve` forces UNKNOWN handling to be a recorded decision, not an accident.
"""

from __future__ import annotations

from enum import Enum

__all__ = ["Tri", "resolve", "tri_all", "tri_and", "tri_any", "tri_not", "tri_or"]


class Tri(Enum):
    """A truth value that admits "not known"."""

    TRUE = "true"
    FALSE = "false"
    UNKNOWN = "unknown"

    @classmethod
    def of(cls, value: bool | None) -> Tri:
        """Lift ``bool | None`` into :class:`Tri`, mapping ``None`` to UNKNOWN."""
        if value is None:
            return cls.UNKNOWN
        return cls.TRUE if value else cls.FALSE


def tri_not(a: Tri) -> Tri:
    if a is Tri.UNKNOWN:
        return Tri.UNKNOWN
    return Tri.FALSE if a is Tri.TRUE else Tri.TRUE


def tri_and(a: Tri, b: Tri) -> Tri:
    if a is Tri.FALSE or b is Tri.FALSE:
        return Tri.FALSE
    if a is Tri.UNKNOWN or b is Tri.UNKNOWN:
        return Tri.UNKNOWN
    return Tri.TRUE


def tri_or(a: Tri, b: Tri) -> Tri:
    if a is Tri.TRUE or b is Tri.TRUE:
        return Tri.TRUE
    if a is Tri.UNKNOWN or b is Tri.UNKNOWN:
        return Tri.UNKNOWN
    return Tri.FALSE


def tri_all(values: list[Tri]) -> Tri:
    """Conjunction over a list. Empty list is TRUE, as with :func:`all`."""
    result = Tri.TRUE
    for v in values:
        result = tri_and(result, v)
    return result


def tri_any(values: list[Tri]) -> Tri:
    """Disjunction over a list. Empty list is FALSE, as with :func:`any`."""
    result = Tri.FALSE
    for v in values:
        result = tri_or(result, v)
    return result


def resolve(value: Tri, *, unknown_as: bool | None = None) -> bool:
    """Collapse to ``bool``, forcing the caller to state what UNKNOWN means.

    Args:
        value: the three-valued result.
        unknown_as: what an UNKNOWN resolves to. ``None`` means "refuse" - the
            default, so that an unhandled UNKNOWN fails loudly at the boundary
            instead of silently becoming an exclusion.

    Raises:
        ValueError: if ``value`` is UNKNOWN and ``unknown_as`` was not given.
    """
    if value is not Tri.UNKNOWN:
        return value is Tri.TRUE
    if unknown_as is None:
        raise ValueError(
            "UNKNOWN eligibility reached a boolean boundary. Pass unknown_as=True/False "
            "to record the decision, and document it in docs/DESIGN_DECISIONS.md."
        )
    return unknown_as
