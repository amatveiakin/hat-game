# TODO: Idea: first, ask GPT to generate taboo words as it understands them,
# then request for structured output, then ask to choose the best options.

from typing import TypeVar

from tools.llm.cognates_via_letters import RussianCognateDetector
from common import not_none
from openai import OpenAI
from pydantic import BaseModel, Field
from termcolor import colored

# MODEL = "gpt-4o-2024-08-06"
MODEL = "gpt-4o-mini"

# TODO: Try writing prompts in Russian

REQUEST_IDEAS = """
You are an assistant that helps generate vocabulary for a Taboo-like game.
The words that you generate can be any part of speech.
Game language is {language}.
"""

# TODO: Consider: Replace this request with "evaluate how good it is a taboo word" for each word.
REQUEST_COLLATE = """
You are an assistant that helps generate vocabulary for a Taboo-like game.
The words that you generate can be any part of speech.
Game language is {language}.
You need to select the best taboo words from a list given to you.
You must select single words only (dashes are ok, spaces are not).
The words you select must not be cognates with the original word or with each other.
Feel free to use any parts of speech.
For adjectives, prefer forms that are in agreement with the gender of the original word.
Select 10 to 20 best taboo word options from the list below:
"""

client = OpenAI()
cognate_detector = RussianCognateDetector()


class ForbiddenWords(BaseModel):
    words: list[str]


class ForbiddenWordsStructured(BaseModel):
    similar: list[str] = Field(
        ..., description="synonyms and terms that denote similar things"
    )
    opposite: list[str] = Field(
        ..., description="antonyms and terms that denote contrary things"
    )
    hypernyms: list[str] = Field(
        ...,
        description="a more general term; a term whose referents form a set which includes the target word",
    )
    hyponyms: list[str] = Field(
        ...,
        description="a more specific term; a term designating a subclass of the target word",
    )
    meronyms: list[str] = Field(
        ...,
        description="a term used to denote a thing that is a part of the target word",
    )
    holonyms: list[str] = Field(
        ...,
        description="a term that denotes a whole, of which the target word is a part",
    )
    related: list[str] = Field(..., description="any other related words")
    adjectives: list[str] = Field(
        ..., description="adjectives that often go with the word"
    )
    collocations: list[str] = Field(
        ...,
        description="words used together in idioms, adages or any word combinations",
    )
    forms_title_together: list[str] = Field(
        ...,
        description="words that can be added to form the title of a book, a movie, a song, etc.",
    )
    other: list[str] = Field(
        ..., description="anything else that can be used to explain the target word"
    )


T = TypeVar("T", ForbiddenWords, ForbiddenWordsStructured)


def gen_forbidden_words(result_type: type[T], language: str, word: str) -> T:
    response = client.beta.chat.completions.parse(
        model=MODEL,
        messages=[
            {"role": "system", "content": REQUEST_IDEAS.format(language=language)},
            {"role": "user", "content": word},
        ],
        response_format=result_type,
    )
    response_message = response.choices[0].message
    if response_message.refusal:
        raise ValueError(
            f"Model refused to provide taboo words for {word}: {response_message.refusal}"
        )
    return not_none(response_message.parsed)


def collate_forbidden_words(
    language: str, word: str, candidates: list[str]
) -> ForbiddenWords:
    response = client.beta.chat.completions.parse(
        model=MODEL,
        messages=[
            {"role": "system", "content": REQUEST_COLLATE.format(language=language)},
            {"role": "user", "content": "\n".join(candidates)},
        ],
        response_format=ForbiddenWords,
    )
    response_message = response.choices[0].message
    if response_message.refusal:
        raise ValueError(
            f"Model refused to collate taboo words for {word}: {response_message.refusal}"
        )
    return not_none(response_message.parsed)


def normalize_taboo(original: str, taboo: str) -> str | None:
    taboo_parts = taboo.split(" ")
    if len(taboo_parts) == 1:
        return taboo_parts[0]
    elif len(taboo_parts) == 2:
        if taboo_parts[0].casefold() == original.casefold():
            return taboo_parts[1]
        elif taboo_parts[1].casefold() == original.casefold():
            return taboo_parts[0]
    return None


def fix_taboo_words(original: str, taboo: list[str]) -> list[str]:
    normalized = [
        word
        for taboo_word in taboo
        if (word := normalize_taboo(original, taboo_word)) is not None
    ]
    result = []
    for i in range(len(normalized)):
        if cognate_detector.is_cognate(normalized[i], original):
            continue
        for j in range(i):
            if cognate_detector.is_cognate(normalized[i], normalized[j]):
                break
        else:
            result.append(normalized[i])
    return result


# LANGUAGE = "English"
# WORDS = ["apple", "book", "color", "mission", "saucer", "doctor"]

LANGUAGE = "Russian"
WORDS = ["яблоко", "книга", "цвет", "миссия", "тарелка", "доктор"]

# for word in WORDS:
#     print(f"{colored(word, "white")}: {', '.join(gen_forbidden_words(word).words)}")

for word in WORDS:
    print(f"{colored(word, "white")}:")
    simple = gen_forbidden_words(ForbiddenWords, LANGUAGE, word)
    for key, value in simple.model_dump().items():
        print(f"  {colored(key, "cyan")}: {', '.join(value)}")
    simple_candidates = [
        word for words in simple.model_dump().values() for word in words
    ]

    structured = gen_forbidden_words(ForbiddenWordsStructured, LANGUAGE, word)
    for key, value in structured.model_dump().items():
        print(f"  {colored(key, "yellow")}: {', '.join(value)}")
    structured_candidates = [
        word for words in structured.model_dump().values() for word in words
    ]

    candidates = simple_candidates + structured_candidates
    collated = collate_forbidden_words(LANGUAGE, word, candidates).words
    print(f"  {colored("collated", "green")}: {', '.join(collated)}")
    fixed = fix_taboo_words(word, collated)
    print(f"  {colored("fixed", "light_green")}: {', '.join(fixed)}")
