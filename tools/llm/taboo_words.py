import time

from litellm import Choices, completion
from litellm.cost_calculator import completion_cost
from litellm.types.utils import ModelResponse
from rich.console import Console

REQUEST_COLLATE = """
You are an assistant that generates forbidden words for a Taboo-like game.
The words that you generate can be any part of speech.
Remember that good forbidden words include everything that makes a word hard to explain:
synonyms, antonyms, hypernyms, hyponyms, meronyms, holonyms,
adjectives that often go with the word, common collocations (such as words that form idioms),
words that can be added to form the title of a book, a movie, a song, etc.,
and generally any words that one would naturally use to explain the word.

Game language is {language}.

You must produce a list of single words only (dashes are ok, spaces are not).
The words you select must not be cognates with the original word or with each other.
For adjectives, prefer forms that are in agreement with the gender of the original word.

Generate 10 to 20 forbidden words for the requested word.
Output exactly one word per line. Do not include any other text.
Don't capitalize the words unless they are always capitalized.
""".strip()

console = Console(highlight=False)


def gen_forbidden_words(*, model: str, language: str, word: str) -> list[str]:
    try:
        start_time = time.monotonic()
        response = completion(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": REQUEST_COLLATE.format(language=language),
                },
                {"role": "user", "content": word},
            ],
            # cache_control={"type": "ephemeral"},
        )
        duration = time.monotonic() - start_time
        assert isinstance(response, ModelResponse)
        assert len(response.choices) == 1
        assert isinstance(response.choices[0], Choices)
        assert response.choices[0].message.content is not None
        cost = completion_cost(completion_response=response, model=model)
        console.print(
            f"[bright_yellow]{model}[/bright_yellow] used [cyan]{cost:.4f}[/cyan]$ in [cyan]{duration:.1f}[/cyan]s"
        )
        return response.choices[0].message.content.split("\n")
    except Exception as e:
        console.print(f"[bright_red]{model}[/bright_red] failed: {e}")
        return []


LANGUAGE = "Russian"
WORD = "яблоко"
MODELS = [
    "openai/gpt-5-nano",
    "openai/gpt-5-mini",
    "openai/gpt-5",
    "anthropic/claude-3-5-haiku-20241022",
    "anthropic/claude-sonnet-4-20250514",
    "anthropic/claude-opus-4-1-20250805",
    "gemini/gemini-2.5-flash-lite",
    "gemini/gemini-2.5-flash",
    "gemini/gemini-2.5-pro",
]
for model in MODELS:
    words = gen_forbidden_words(model=model, language=LANGUAGE, word=WORD)
    console.print("\n".join(words))
    console.print()
