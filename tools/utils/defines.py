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

E2YO_KERNEL_SAFE_TXT = WAREHOUSE_LEXICON_ROOT / "ru" / "e2yo_kernel_safe.txt"
E2YO_KERNEL_NOT_SAFE_TXT = WAREHOUSE_LEXICON_ROOT / "ru" / "e2yo_kernel_not_safe.txt"
