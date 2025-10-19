from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent.parent
ASSERT_LEXICON_ROOT = REPO_ROOT / "hatgame" / "lexicon"
WAREHOUSE_LEXICON_ROOT = REPO_ROOT / "warehouse" / "lexicon"

RU_WIKTIONARY_WORD_FORMS_ZIP = (
    WAREHOUSE_LEXICON_ROOT / "ru" / "ru_wiktionary_word_forms.zip"
)
YOFICATION_DICTIONARY_YAML = (
    WAREHOUSE_LEXICON_ROOT / "ru" / "yofication_dictionary.yaml"
)
