from tools.utils.defines import ASSERT_LEXICON_ROOT, YOFICATION_DICTIONARY_YAML
from tools.utils.lexicon import yaml_to_lexicon
from tools.utils.yoficator import Yoficator


def make_yofication_dictionary():
    full_yoficator = Yoficator.from_ru_wiktionary()
    if YOFICATION_DICTIONARY_YAML.exists():
        dictionary_yoficator = Yoficator.from_yofication_dictionary()
    else:
        dictionary_yoficator = Yoficator(yofications={})
    all_words: set[str] = set()

    for lexicon_path in ASSERT_LEXICON_ROOT.glob("*.yaml"):
        lexicon = yaml_to_lexicon(lexicon_path.read_text(encoding="utf-8"))
        if lexicon.language == "Russian":
            match lexicon.kind:
                case "standard":
                    all_words.update(lexicon.words)
                case "taboo":
                    all_words.update(lexicon.words.keys())
                    all_words.update(
                        word for words in lexicon.words.values() for word in words
                    )
                case _:
                    raise ValueError(f"Unknown lexicon kind: {lexicon.kind}")

    for w in all_words:
        w_lower = w.lower()
        if (
            "е" in w_lower
            and not "ё" in w_lower
            and not dictionary_yoficator.contains(w)
        ):
            try:
                yofications = full_yoficator(w)
            except KeyError:
                yofications = ["???"]
            dictionary_yoficator.yofications[w] = yofications

    dictionary_yoficator.save_to_yofication_dictionary()


if __name__ == "__main__":
    make_yofication_dictionary()
