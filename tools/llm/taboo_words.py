import asyncio
import time
from typing import Literal

from litellm import Choices, acompletion, completion
from litellm.cost_calculator import completion_cost
from litellm.types.utils import ModelResponse
from pydantic import BaseModel
from rich.console import Console
from rich.panel import Panel
from tqdm.asyncio import tqdm

ReasoningEffort = Literal["none", "minimal", "low", "medium", "high", "default"]


class ForbiddenDemoResult(BaseModel):
    model: str
    reasoning_effort: ReasoningEffort
    duration: float
    cost: float
    words: list[str]


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
- All words must be in lowercase, unless the word is a proper noun and is always capitalized.
- Output one word per line.
- Do not include any other text. NO bullets, NO numbering, NO comments, NO headers, NO nothing.
""".strip()

console = Console(highlight=False)


async def gen_forbidden_words(
    *,
    model: str,
    reasoning_effort: ReasoningEffort,
    language: str,
    word: str,
) -> ForbiddenDemoResult:
    start_time = time.monotonic()
    response = await acompletion(
        model=model,
        reasoning_effort=reasoning_effort,
        messages=[
            {
                "role": "system",
                "content": REQUEST_COLLATE.format(language=language),
            },
            {"role": "user", "content": word},
        ],
    )
    duration = time.monotonic() - start_time
    assert isinstance(response, ModelResponse)
    assert len(response.choices) == 1
    assert isinstance(response.choices[0], Choices)
    assert response.choices[0].message.content is not None
    cost = completion_cost(completion_response=response, model=model)
    words = response.choices[0].message.content.split("\n")
    return ForbiddenDemoResult(
        model=model,
        reasoning_effort=reasoning_effort,
        duration=duration,
        cost=cost,
        words=words,
    )


# LANGUAGE = "Russian"
# WORD = "тарелка"
LANGUAGE = "English"
WORD = "falcon"
MODELS = [
    "openai/gpt-5-nano",
    "openai/gpt-5-mini",
    "openai/gpt-5",
    "anthropic/claude-sonnet-4-20250514",
    "anthropic/claude-opus-4-1-20250805",
    "gemini/gemini-2.5-flash-lite",
    "gemini/gemini-2.5-flash",
    "gemini/gemini-2.5-pro",
]


async def main():
    console.print(Panel.fit(WORD))
    console.print()
    tasks: list[asyncio.Task[ForbiddenDemoResult]] = []
    for model in MODELS:
        for reasoning_effort in ("low", "medium", "high"):
            tasks.append(
                asyncio.create_task(
                    gen_forbidden_words(
                        model=model,
                        reasoning_effort=reasoning_effort,
                        language=LANGUAGE,
                        word=WORD,
                    )
                )
            )

    results = await tqdm.gather(*tasks, desc="Generating forbidden words")

    for r in results:
        console.print(
            f"[bright_yellow]{r.model}[/bright_yellow]@[bright_white]{r.reasoning_effort}[/bright_white] used [cyan]{r.cost:.4f}[/cyan]$ in [cyan]{r.duration:.1f}[/cyan]s"
        )
        console.print("\n".join(r.words))
        console.print()


if __name__ == "__main__":
    asyncio.run(main())
