import hashlib


def stable_hash(word: str) -> int:
    return int(hashlib.blake2b(word.encode("utf-8")).hexdigest(), 16)
