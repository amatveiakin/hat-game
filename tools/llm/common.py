from typing import TypeVar


__T = TypeVar("__T")


def not_none(val: __T | None) -> __T:
    assert val is not None
    return val
