import datetime
from dataclasses import dataclass
from pathlib import Path

import typer

from tools.utils.lexicon import lexicon_header_to_yaml, yaml_to_lexicon
from tools.utils.yoficator import Yoficator


@dataclass
class Word:
    word: str
    comment: str | None = None


def yoficate_word(w: str, yoficate: Yoficator) -> list[Word]:
    yofications = yoficate(w)
    is_ambiguous = len(yofications) > 1
    return [Word(word=y, comment="???" if is_ambiguous else None) for y in yofications]


def word_to_yaml(w: Word) -> str:
    return f'- "{w.word}"{f" # {w.comment}" if w.comment else ""}'


def yoficate(lexicon_path: Path):
    yoficate = Yoficator.from_e2yo_kernel()
    lexicon = yaml_to_lexicon(lexicon_path.read_text(encoding="utf-8"))
    assert lexicon.language == "Russian"
    assert lexicon.kind == "standard"
    words = [y for w in lexicon.words for y in yoficate_word(w, yoficate)]

    lexicon.updated_at = datetime.date.today()
    new_lexicon_yaml = (
        lexicon_header_to_yaml(lexicon)
        + "---\n"
        + "\n".join(word_to_yaml(w) for w in words)
        + "\n"
    )
    lexicon_path.write_text(new_lexicon_yaml, encoding="utf-8")


if __name__ == "__main__":
    typer.run(yoficate)
