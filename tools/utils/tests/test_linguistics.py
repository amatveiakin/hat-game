import locale

import pytest

from tools.utils.linguistics import (
    remove_stresses,
    ru_sorted_ignore_case,
    ru_sorted_with_case,
)


def test_remove_stresses():
    # No accents - no change
    assert remove_stresses("ген") == "ген"

    # COMBINING ACUTE ACCENT (U+0301) - Proper stress
    assert remove_stresses("ге́н") == "ген"

    # COMBINING GRAVE ACCENT (U+0300) - Sometimes used as stress
    assert remove_stresses("гѐн") == "ген"

    # Supports similarly looking English letters
    assert remove_stresses("гѐн") == "ген"
    assert remove_stresses("гéн") == "ген"

    # Removed all accents
    assert remove_stresses("ге́нѐратор") == "генератор"
    assert remove_stresses("ге́нера́то́р") == "генератор"

    # Does not affect other diactrics
    assert remove_stresses("ёж") == "ёж"


@pytest.mark.parametrize(
    ("letters", "sorted_letters"),
    [
        (["и", "к", "е", "ж", "й", "ё"], ["е", "ё", "ж", "и", "й", "к"]),
        (["И", "К", "Е", "Ж", "Й", "Ё"], ["Е", "Ё", "Ж", "И", "Й", "К"]),
        (["Б", "б", "А", "а"], ["А", "Б", "а", "б"]),
    ],
)
def test_russian_letters_sort_with_case(letters, sorted_letters):
    assert ru_sorted_with_case(letters) == sorted_letters


@pytest.mark.parametrize(
    ("letters", "sorted_letters"),
    [
        (["и", "к", "е", "ж", "й", "ё"], ["е", "ё", "ж", "и", "й", "к"]),
        (["И", "К", "Е", "Ж", "Й", "Ё"], ["Е", "Ё", "Ж", "И", "Й", "К"]),
        (["Б", "б", "А", "а"], ["А", "а", "Б", "б"]),
    ],
)
def test_russian_letters_sort_ignore_case(letters, sorted_letters):
    assert ru_sorted_ignore_case(letters) == sorted_letters


def test_russian_words_sort():
    locale.setlocale(locale.LC_COLLATE, "ru_RU.UTF-8")
    assert ru_sorted_ignore_case(
        [
            "жже",
            "жжж",
            "ееж",
            "ёжё",
            "ееё",
            "ежё",
            "жёё",
            "жжё",
            "ёеё",
            "ёеж",
            "еёё",
            "ёёё",
            "ёёе",
            "еже",
            "жёе",
            "ёее",
            "еее",
            "жее",
            "ёже",
            "ёжж",
            "еёж",
            "ежж",
            "жеё",
            "жёж",
            "ёёж",
            "еёе",
            "жеж",
        ]
    ) == [
        "еее",
        "ееё",
        "ееж",
        "еёе",
        "еёё",
        "еёж",
        "еже",
        "ежё",
        "ежж",
        "ёее",
        "ёеё",
        "ёеж",
        "ёёе",
        "ёёё",
        "ёёж",
        "ёже",
        "ёжё",
        "ёжж",
        "жее",
        "жеё",
        "жеж",
        "жёе",
        "жёё",
        "жёж",
        "жже",
        "жжё",
        "жжж",
    ]
