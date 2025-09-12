import time

from litellm import Choices, completion
from litellm.cost_calculator import completion_cost
from litellm.types.utils import ModelResponse
from rich.console import Console
from rich.panel import Panel

REQUEST_COLLATE = """
Generate 10 forbidden words for a Taboo-like game in {language}.

Good forbidden words make the target word hard to explain and include:
- Synonyms, antonyms and related words: parts, categories, descriptions, etc.
- Words commonly used together with the target word: idioms, quotes, names, movie titles, etc.
- Any words that would naturally come up when explaining the target word.

Requirements:
- Single words only (hyphens OK, spaces not allowed).
- Never include cognates of the target word or other forbidden words.
- Match gender/number agreement for adjectives when relevant.
- Use standard capitalization. Do not capitalize the words unless they are always capitalized.
- Output one word per line.
- Do not include any other text. NO bullets, NO numbering, NO comments, NO headers, NO nothing.
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
