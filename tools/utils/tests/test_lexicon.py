import datetime

from tools.utils.lexicon import lexicon_to_yaml, yaml_to_lexicon

TEST_STANDARD_LEXICON = """\
name: "Test words"
kind: "standard"
language: "English"
updated_at: 2001-12-23
---
- "hello"
- "world"
"""

TEST_TABOO_LEXICON = """\
name: "Test words"
kind: "taboo"
language: "English"
updated_at: 2001-12-23
---
"hello":
- "hi"
- "bye"
"world":
- "universe"
"""

TEST_RUSSIAN_LEXICON = """\
name: "Тестовые слова"
kind: "standard"
language: "Russian"
updated_at: 2001-12-23
---
- "привет"
- "мир"
"""


def test_standard_lexicon():
    lexicon = yaml_to_lexicon(TEST_STANDARD_LEXICON)
    assert lexicon.name == "Test words"
    assert lexicon.language == "English"
    assert lexicon.updated_at == datetime.date(2001, 12, 23)
    assert lexicon.words == ["hello", "world"]
    assert lexicon_to_yaml(lexicon) == TEST_STANDARD_LEXICON


def test_taboo_lexicon():
    lexicon = yaml_to_lexicon(TEST_TABOO_LEXICON)
    assert lexicon.name == "Test words"
    assert lexicon.language == "English"
    assert lexicon.updated_at == datetime.date(2001, 12, 23)
    assert lexicon.words == {"hello": ["hi", "bye"], "world": ["universe"]}
    assert lexicon_to_yaml(lexicon) == TEST_TABOO_LEXICON


def test_russian_lexicon():
    lexicon = yaml_to_lexicon(TEST_RUSSIAN_LEXICON)
    assert lexicon.name == "Тестовые слова"
    assert lexicon.language == "Russian"
    assert lexicon.updated_at == datetime.date(2001, 12, 23)
    assert lexicon.words == ["привет", "мир"]
    assert lexicon_to_yaml(lexicon) == TEST_RUSSIAN_LEXICON
