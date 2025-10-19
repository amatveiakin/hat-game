from zipfile import ZipFile

import yaml
from pydantic import TypeAdapter

from tools.utils.defines import RU_WIKTIONARY_WORD_FORMS_ZIP, YOFICATION_DICTIONARY_YAML
from tools.utils.linguistics import is_relaxed_russian_word, ru_sorted_ignore_case
from tools.utils.yaml import FlowListDumper


def deyoficate(word: str) -> str:
    return word.replace("ё", "е").replace("Ё", "Е")


class Yoficator:
    def __init__(self, yofications: dict[str, list[str]]):
        self.yofications = yofications

    @classmethod
    def from_yofication_dictionary(cls) -> "Yoficator":
        yofications = TypeAdapter(dict[str, list[str]]).validate_python(
            yaml.safe_load(YOFICATION_DICTIONARY_YAML.read_text(encoding="utf-8"))
        )
        return cls(
            yofications={
                k: sorted([k if v == "=" else v for v in vs])
                for k, vs in yofications.items()
            }
        )

    @classmethod
    def from_ru_wiktionary(cls) -> "Yoficator":
        with ZipFile(RU_WIKTIONARY_WORD_FORMS_ZIP) as z:
            lines = z.read("ru_wiktionary_word_forms.txt").decode("utf-8").split("\n")
            words = set(w.strip() for w in lines if w.strip())

        yofications: dict[str, list[str]] = {}
        for w in words:
            w_lower = w.lower()
            # Note: we store words with “е” not because it's useful for
            # yofication, but because when we save the yofication dictionary it
            # shows that we've processed this word and confirmed that it
            # shouldn't be yoficated.
            if "е" in w_lower or "ё" in w_lower:
                yofications.setdefault(deyoficate(w), []).append(w)

        for ys in yofications.values():
            ys_lower = [y.lower() for y in ys]
            ys[:] = [
                y
                for y in ru_sorted_ignore_case(ys)
                # filter out capitalized version of common nouns
                if y == y.lower() or y.lower() not in ys_lower
            ]

        return cls(yofications=yofications)

    def save_to_yofication_dictionary(self):
        yofications = {
            k: sorted(["=" if v == k else v for v in vs])
            for k, vs in sorted(self.yofications.items())
        }
        YOFICATION_DICTIONARY_YAML.write_text(
            yaml.dump(yofications, allow_unicode=True, Dumper=FlowListDumper),
            encoding="utf-8",
        )

    def contains(self, word: str) -> bool:
        assert is_relaxed_russian_word(word), f'"{word}" is not a Russian word'
        return word.lower() in self.yofications

    def __call__(self, word: str) -> list[str]:
        assert is_relaxed_russian_word(word), f'"{word}" is not a Russian word'
        return self.yofications[word.lower()]
