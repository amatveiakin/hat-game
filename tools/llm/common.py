def not_none[T](val: T | None) -> T:
    assert val is not None
    return val
