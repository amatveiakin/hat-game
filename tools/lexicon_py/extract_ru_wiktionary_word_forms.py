import json
import re
from collections import defaultdict
from collections.abc import Iterable
from pathlib import Path
from typing import Annotated

import typer
from tqdm import tqdm

from tools.lexicon_py.wiktextract_extra_ru_models import TitleEntry, parse_entry
from tools.lexicon_py.wiktextract_ru_models import WordEntry
from tools.utils.defines import LEXICON_ROOT
from tools.utils.linguistics import (
    is_russian_word,
    remove_stresses,
    ru_sorted_with_case,
)

OUTPUT_ROOT = LEXICON_ROOT / "ru" / "wikiextract"


def clear_word(word: str, stats: defaultdict[str, int], key: str) -> list[str]:
    stats[f"{key}_total"] += 1

    cleaned_word = remove_stresses(word.replace("’", "'"))
    if cleaned_word != word:
        stats[f"{key}_stresses"] += 1

    subwords = [w.strip() for w in re.split(r"[,/]", cleaned_word) if w.strip()]

    russian_subwords = [w for w in subwords if is_russian_word(w)]
    if len(russian_subwords) != len(subwords):
        stats[f"{key}_skipped"] += 1
    if len(russian_subwords) > 1:
        stats[f"{key}_compound"] += 1

    return russian_subwords


def dump_dict(words: Iterable[str], name: str):
    (OUTPUT_ROOT / f"{name}.txt").write_text(
        "\n".join(ru_sorted_with_case(words)), encoding="utf-8"
    )


def main(
    raw_wiktextract_data_path: Annotated[
        Path,
        typer.Argument(
            ..., help="Path to raw-wiktextract-data.jsonl from https://kaikki.org/"
        ),
    ],
    include_intermediates: Annotated[bool, typer.Option(default=False)],
):
    title_entries: list[TitleEntry] = []

    words: set[str] = set()
    forms: set[str] = set()
    titles: set[str] = set()

    stats: dict[str, int] = defaultdict(int)

    with open(raw_wiktextract_data_path, encoding="utf-8") as f:
        for line in tqdm(f, desc="Parsing entries"):
            entry = parse_entry(line)
            if isinstance(entry, WordEntry):
                if entry.lang_code == "ru":
                    for form in entry.forms:
                        forms.update(clear_word(form.form, stats, "forms"))
                    words.update(clear_word(entry.word, stats, "words"))
            elif isinstance(entry, TitleEntry):
                title_entries.append(entry)

    for entry in title_entries:
        if remove_stresses(entry.redirect) in words:  # check if Russian word
            titles.update(clear_word(entry.title, stats, "titles"))

    stats = dict(sorted(stats.items()))
    print(json.dumps(stats, indent=2))

    if include_intermediates:
        forms_casefold = {w.casefold() for w in forms}
        titles_minus_forms_ignore_case = [
            w for w in titles if w.casefold() not in forms_casefold
        ]
        words_minus_forms_ignore_case = [
            w for w in words if w.casefold() not in forms_casefold
        ]
        dump_dict(words, "words")
        dump_dict(forms, "forms")
        dump_dict(titles, "titles")
        dump_dict(titles - forms, "titles_minus_forms")
        dump_dict(words - forms, "words_minus_forms")
        dump_dict(titles_minus_forms_ignore_case, "titles_minus_forms_ignore_case")
        dump_dict(words_minus_forms_ignore_case, "words_minus_forms_ignore_case")

    dump_dict(words | forms | titles, "all")


if __name__ == "__main__":
    typer.run(main)
