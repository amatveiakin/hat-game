from collections.abc import Callable
from pathlib import Path

import typer

from tools.utils.lexicon import lexicon_to_yaml, yaml_to_lexicon
from tools.utils.linguistics import ru_sort_key_ignore_case
from tools.utils.sort import sorted_unique


def format_lexicon(lexicon_path: Path):
    lexicon = yaml_to_lexicon(lexicon_path.read_text(encoding="utf-8"))

    sort_key: Callable[[str], str]
    match lexicon.language:
        case "Russian":
            sort_key = ru_sort_key_ignore_case
        case _:
            sort_key = lambda w: w.casefold()

    match lexicon.kind:
        case "standard":
            lexicon.words = sorted_unique(lexicon.words, key=sort_key)
        case "taboo":
            lexicon.words = {
                word: sorted_unique(forbidden, key=sort_key)
                for word, forbidden in sorted_unique(
                    lexicon.words.items(), key=lambda x: sort_key(x[0])
                )
            }
        case _:
            raise ValueError(f"Unknown lexicon kind: {lexicon.kind}")

    lexicon_path.write_text(lexicon_to_yaml(lexicon), encoding="utf-8")


if __name__ == "__main__":
    typer.run(format_lexicon)
