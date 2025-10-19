from collections.abc import Callable, Iterable
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from _typeshed import SupportsRichComparison


def sorted_unique[V, K: SupportsRichComparison](
    items: Iterable[V], key: Callable[[V], K]
) -> list[V]:
    seen: dict[K, V] = {}
    for item in items:
        k = key(item)
        if k not in seen:
            seen[k] = item
    return sorted(seen.values(), key=key)
