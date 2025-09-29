import re
import unicodedata
from collections.abc import Iterable

# Allow apostrophes for words like "д'Артаньян"
RUSSIAN_WORD_REGEXP = re.compile(r"^([а-яёА-ЯЁ][а-яёА-ЯЁ'-]*[а-яёА-ЯЁ]|[а-яёА-ЯЁ])$")
STRESSES_REGEXP = re.compile(r"[\u0300\u0301]")
# TODO: Finish list
ADDITIONAL_STRESS_REPLACEMENTS = {
    "á": "а",
    "ѐ": "е",
    "é": "е",
    "ó": "о",
    "ѝ": "и",
    "Ѝ": "И",
}


def is_russian_word(word: str) -> bool:
    return RUSSIAN_WORD_REGEXP.match(word) is not None


def remove_stresses(word: str) -> str:
    word = "".join(ADDITIONAL_STRESS_REPLACEMENTS.get(ch, ch) for ch in word)
    return STRESSES_REGEXP.sub("", word)


def ru_sort_key_with_case(word: str) -> str:
    def map_letter(ch: str) -> str:
        if ch == "ё":
            return "е1"
        elif ch == "Ё":
            return "Е1"
        else:
            return f"{ch}0"

    return "".join([map_letter(ch) for ch in unicodedata.normalize("NFC", word)])


def ru_sort_key_ignore_case(word: str) -> str:
    return ru_sort_key_with_case(word.casefold())


def ru_sorted_with_case(words: Iterable[str]) -> list[str]:
    return sorted(words, key=ru_sort_key_with_case)


def ru_sorted_ignore_case(words: Iterable[str]) -> list[str]:
    return sorted(words, key=ru_sort_key_ignore_case)
