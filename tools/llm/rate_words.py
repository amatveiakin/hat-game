import argparse
from pathlib import Path
from typing import Literal

import pandas as pd
from openai import OpenAI
from pydantic import BaseModel, Field
from termcolor import colored
from tqdm import tqdm

from tools.llm.common import not_none

MODEL = "gpt-4o-mini"

SYSTEM_MESSAGE = """
You provide information about the Russian word given to you.
All numerical ratings are from 0 to 10.
"""

parser = argparse.ArgumentParser()
parser.add_argument(
    "words", help="Pickle file with a (possible partially parsed) word dataframe"
)
args = parser.parse_args()
words_df_path = Path(args.words)

client = OpenAI()


# TODO: Add `ge=0, le=10` when ChatGPT supports it.
# TODO: Add something like "could be confused with" (other parts of speech,
# homonyms, forms of other words). Need to make sure that the model understands
# the request though. I tried doing this and got bogus results.
class WordRatings(BaseModel):
    part_of_speech: Literal[
        "common_noun",
        "proper_noun",
        "verb",
        "adjective",
        "participle",
        "adverb",
        "gerund",
        "pronoun",
        "numeral",
        "function_word",
    ]
    composition: Literal["simple", "compound", "acronym", "abbreviation"]
    domain: Literal[
        "religion",
        "soviet_union",
        "politics",
        "science",
        "information_technology",
        "art",
        "sports",
        "other",
    ]
    female_pair: str | None = Field(
        description="Female analog for words denoting males"
    )
    male_pair: str | None = Field(description="Male analog for words denoting females")
    standard: int = Field(
        ..., description="How common the word is, as opposed to slang or jargon"
    )
    frequent: int = Field(
        ..., description="How frequently the word is used in everyday language"
    )
    difficult: int = Field(
        ..., description="How difficult it is to explain the word in the game of Alias"
    )
    formal: int = Field(
        ..., description="5 is neutral, less is informal, more is formal"
    )
    neologism: int = Field(..., description="How new the word is")
    archaic: int = Field(..., description="How old the word is")
    pejorative: int = Field(
        ...,
        description="How much the word expresses contempt or disapproval towards a group identity",
    )
    vulgar: int = Field(
        ...,
        description="How much the words makes explicit reference to sex or bodily functions",
    )
    child_friendly: int = Field(
        ..., description="How appropriate the word is for children"
    )
    confidence: int = Field(
        ..., description="How confident you are in your other ratings"
    )


class ModelRefusal(ValueError):
    pass


def gen_word_ratings(word) -> WordRatings:
    response = client.beta.chat.completions.parse(
        model=MODEL,
        messages=[
            {"role": "system", "content": SYSTEM_MESSAGE},
            {"role": "user", "content": word},
        ],
        response_format=WordRatings,
    )
    response_message = response.choices[0].message
    if response_message.refusal:
        raise ModelRefusal(
            f"Model refused to provide word ratings for {word}: {response_message.refusal}"
        )
    return not_none(response_message.parsed)


def ensure_columns(df: pd.DataFrame, columns: list[str]) -> None:
    for col in columns:
        if col not in df.columns:
            df[col] = pd.NA


def inspect(words: list[str]) -> None:
    for word in words:
        print(f"{colored(word, 'white')}:")
        for key, value in gen_word_ratings(word).model_dump().items():
            print(f"  {key}: {value}")


# inspect(["яблоко", "комсомолец", "комсомолка", "вуз", "комп", "сейв", "ярмо", "диакон", "дьякон", "рим", "москва", "десятый"])
# exit(0)


# TODO: Consider using a CSV instead for better git diffs.
# TODO: Add "difficulty level" column and scripts to sync it with lexicon files
# in both directions.
df = pd.read_pickle(words_df_path)
assert isinstance(df, pd.DataFrame)
ensure_columns(df, ["confidence", "refusal"])

total_rows = len(df)
rows_to_process = list(df.loc[df["confidence"].isna() & df["refusal"].isna()].index)
num_processed = 0
num_refused = 0
num_skipped = total_rows - len(rows_to_process)

try:
    pbar = tqdm(rows_to_process)
    for word in pbar:
        pbar.set_description(f"{word:20}")
        assert isinstance(word, str)
        try:
            for key, value in gen_word_ratings(word).model_dump().items():
                df.at[word, key] = value
        except ModelRefusal as e:
            df.at[word, "refusal"] = str(e)
            num_refused += 1
        num_processed += 1
except KeyboardInterrupt:
    print("Bye!")

PAD = 5
print(f"{num_skipped:{PAD}} words skipped")
print(f"{num_processed:{PAD}} words processed successfully")
print(f"{num_refused:{PAD}} words refused by the model")

df.to_pickle(words_df_path)
print(f"Data saved to {words_df_path}")
