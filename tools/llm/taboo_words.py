import asyncio
import datetime
import hashlib
import time
from pathlib import Path
from typing import Literal

import typer
from litellm import Choices, acompletion
from litellm.cost_calculator import completion_cost
from litellm.types.utils import ModelResponse
from pydantic import BaseModel
from rich.console import Console
from tqdm.asyncio import tqdm

from tools.utils.lexicon import TabooLexicon, lexicon_to_yaml, yaml_to_lexicon

ReasoningEffort = Literal["none", "minimal", "low", "medium", "high", "default"]


class ForbiddenWordsResult(BaseModel):
    word: str
    forbidden_words: list[str] | None
    duration: float
    cost: float


MODEL = "gemini/gemini-2.5-pro"
REASONING_EFFORT = "low"

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
    language: str,
    word: str,
) -> ForbiddenWordsResult:
    start_time = time.monotonic()
    try:
        response = await acompletion(
            model=MODEL,
            reasoning_effort=REASONING_EFFORT,
            messages=[
                {
                    "role": "system",
                    "content": REQUEST_COLLATE.format(language=language),
                },
                {"role": "user", "content": word},
            ],
            max_retries=3,
            retry_strategy="exponential_backoff_retry",
        )
    except Exception:
        duration = time.monotonic() - start_time
        return ForbiddenWordsResult(
            word=word,
            forbidden_words=None,
            duration=duration,
            cost=0,
        )
    duration = time.monotonic() - start_time

    assert isinstance(response, ModelResponse)
    assert len(response.choices) == 1
    assert isinstance(response.choices[0], Choices)
    assert response.choices[0].message.content is not None
    cost = completion_cost(completion_response=response, model=MODEL)
    words = response.choices[0].message.content.split("\n")
    return ForbiddenWordsResult(
        word=word,
        forbidden_words=words,
        duration=duration,
        cost=cost,
    )


def stable_hash(word: str) -> int:
    return int(hashlib.blake2b(word.encode("utf-8")).hexdigest(), 16)


def include_word(word: str) -> bool:
    return stable_hash(word) % 32 == 0


async def generate_forbidden_words(
    *, source_lexicon_path: Path, target_lexicon_path: Path
):
    source_lexicon = yaml_to_lexicon(source_lexicon_path.read_text(encoding="utf-8"))
    assert source_lexicon.kind == "standard"
    assert source_lexicon.language in ("English", "Russian")
    source_words = source_lexicon.words

    if target_lexicon_path.exists():
        target_lexicon = yaml_to_lexicon(
            target_lexicon_path.read_text(encoding="utf-8")
        )
        assert target_lexicon.kind == "taboo"
        assert target_lexicon.language == source_lexicon.language
        target_lexicon.updated_at = datetime.date.today()
    else:
        target_lexicon = TabooLexicon(
            name=source_lexicon.name,
            kind="taboo",
            language=source_lexicon.language,
            updated_at=datetime.date.today(),
            words={},
        )

    tasks: list[asyncio.Task[ForbiddenWordsResult]] = []
    for word in source_words:
        if include_word(word) and word not in target_lexicon.words:
            tasks.append(
                asyncio.create_task(
                    gen_forbidden_words(
                        language=source_lexicon.language,
                        word=word,
                    )
                )
            )

    results: list[ForbiddenWordsResult] = await tqdm.gather(
        *tasks, desc="Generating forbidden words"
    )

    total_cost = 0
    for r in results:
        if r.forbidden_words is not None:
            target_lexicon.words[r.word] = r.forbidden_words
        total_cost += r.cost

    target_lexicon.words = {k: v for k, v in sorted(target_lexicon.words.items())}
    target_lexicon_path.write_text(lexicon_to_yaml(target_lexicon), encoding="utf-8")
    console.print(f"Total cost: {total_cost:.2f}$")


def main(
    source_lexicon_path: Path,
    target_lexicon_path: Path,
):
    asyncio.run(
        generate_forbidden_words(
            source_lexicon_path=source_lexicon_path,
            target_lexicon_path=target_lexicon_path,
        )
    )


if __name__ == "__main__":
    typer.run(main)
