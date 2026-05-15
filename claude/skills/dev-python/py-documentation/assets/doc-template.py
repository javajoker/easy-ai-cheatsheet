"""Module summary in one sentence.

Additional paragraphs explain context, design rationale, or unusual
constraints — anything that the module's name and the public symbols'
types don't say.
"""

from __future__ import annotations

from dataclasses import dataclass


def charge(customer_id: str, amount_cents: int) -> str:
    """Charge the customer for the given amount.

    Additional paragraphs explain *why* the function exists, when to prefer
    it over alternatives, and any constraints the type can't carry (units,
    ranges, side effects, ordering, thread safety).

    Args:
        customer_id: Stripe customer ID; must start with ``cus_``.
        amount_cents: Amount in cents; must be >= 50 (Stripe minimum).

    Returns:
        The Stripe charge ID on success.

    Raises:
        InsufficientFundsError: When the card is declined.

    Example:
        >>> charge("cus_123", 1500)
        'ch_abc'
    """
    raise NotImplementedError


@dataclass(frozen=True, slots=True)
class User:
    """A user account known to the application.

    Equality is by ``id``; two ``User`` instances with the same id are the
    same user regardless of other fields.

    Attributes:
        id: Stable, opaque identifier issued by the auth system.
        email: Verified primary email; lowercased.
        is_admin: True iff the user has the admin role.
    """

    id: str
    email: str
    is_admin: bool


class UserRepository:
    """SQL-backed persistence for ``User`` records.

    This class is thread-safe; the underlying connection pool is assumed to
    be thread-safe (HikariCP-equivalent / asyncpg pool).

    Designed for use as a singleton; constructor injection only.
    """

    def __init__(self, pool: object) -> None:
        """Initialise with a configured connection pool.

        Args:
            pool: A connection pool exposing ``acquire()`` and ``release()``.
        """
        self._pool = pool


def fetch_user(id: str) -> User:
    """Load a user by id.

    .. deprecated:: 0.5.0
        Use :func:`get_user_by_id` instead. Will be removed in 1.0.
    """
    return get_user_by_id(id)


def get_user_by_id(id: str) -> User:
    """Load a user by id; raises ``NotFoundError`` if missing."""
    raise NotImplementedError
