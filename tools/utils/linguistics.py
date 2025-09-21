import re


def is_russian_word(word: str) -> bool:
    # Allow apostrophes for words like "д'Артаньян"
    return len(word) > 0 and re.match(r"^[а-яёА-ЯЁ'-]+$", word) is not None
