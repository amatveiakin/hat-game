# TODO: Idea: first, ask GPT to generate taboo words as it understands them,
# then request for structured output, then ask to choose the best options.

from openai import OpenAI
from pydantic import BaseModel, Field
from termcolor import colored

from common import not_none

# MODEL = "gpt-4o-2024-08-06"
MODEL = "gpt-4o-mini"

SYSTEM_MESSAGE = """
You are an assistant that helps generate vocabulary for a Taboo-like game.
The words that you generate can be any part of speech.
"""

client = OpenAI()


# class ForbiddenWords(BaseModel):
#     words: list[str]


class ForbiddenWords(BaseModel):
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


def gen_forbidden_words(word) -> ForbiddenWords:
    response = client.beta.chat.completions.parse(
        model=MODEL,
        messages=[
            {"role": "system", "content": SYSTEM_MESSAGE},
            {"role": "user", "content": word},
        ],
        response_format=ForbiddenWords,
    )
    response_message = response.choices[0].message
    if response_message.refusal:
        raise ValueError(
            f"Model refused to provide taboo words for {word}: {response_message.refusal}"
        )
    return not_none(response_message.parsed)


WORDS = ["apple", "book", "color", "mission", "saucer", "doctor"]

# for word in WORDS:
#     print(f"{colored(word, "white")}: {', '.join(gen_forbidden_words(word).words)}")

for word in WORDS:
    print(f"{colored(word, "white")}:")
    for key, value in gen_forbidden_words(word).model_dump().items():
        print(f"  {key}: {', '.join(value)}")
