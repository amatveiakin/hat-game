import asyncio
import datetime
from pathlib import Path
from typing import Literal

import litellm
import typer
from pydantic import BaseModel
from rich.console import Console

from tools.utils.lexicon import TabooLexicon, lexicon_to_yaml, yaml_to_lexicon
from tools.utils.llm import simple_llm_request
from tools.utils.parallel_process import parallel_process

ReasoningEffort = Literal["none", "minimal", "low", "medium", "high", "default"]


class ForbiddenWordsResult(BaseModel):
    word: str
    forbidden_words: list[str]
    cost_usd: float


MODEL = "gemini/gemini-2.5-pro"
# MODEL = "anthropic/claude-opus-4-1"
REASONING_EFFORT: ReasoningEffort = "low"

REQUEST = """
Generate 10 forbidden words for a Taboo-like game in {language}.

Good forbidden words make the target word hard to explain and include:
- Synonyms, antonyms and related words: parts, categories, descriptions, etc.
- Words commonly used together with the target word: idioms, quotes, names, movie titles, etc.
- Any words that would naturally come up when explaining the target word.

Requirements:
- Single words only (hyphens OK, spaces not allowed).
- No abbreviations (initialisms or acronyms).
- Never include cognates of the target word or other forbidden words.
- Match gender/number agreement for adjectives when relevant.
- All words must be in lowercase, unless the word is a proper noun and is always capitalized.
- Output one word per line.
- Do not include any other text. NO bullets, NO numbering, NO comments, NO headers, NO nothing.
""".strip()

litellm.suppress_debug_info = True

console = Console(highlight=False)


async def gen_forbidden_words(
    *,
    language: str,
    word: str,
) -> ForbiddenWordsResult:
    response = await simple_llm_request(
        model=MODEL,
        reasoning_effort=REASONING_EFFORT,
        system_message=REQUEST.format(language=language),
        user_message=word,
    )
    words = response.text.split("\n")
    return ForbiddenWordsResult(
        word=word,
        forbidden_words=words,
        cost_usd=response.cost_usd,
    )


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

    words_to_process = [
        word for word in source_words if word not in target_lexicon.words
    ]

    if len(words_to_process) == 0:
        console.print("No words to process")
        return

    results = await parallel_process(
        words_to_process,
        lambda word: gen_forbidden_words(language=source_lexicon.language, word=word),
        console=console,
        progress_description="Generating forbidden words",
    )

    total_cost = 0
    for result in results:
        if result.status == "success":
            r = result.value
            target_lexicon.words[r.word] = r.forbidden_words
            total_cost += r.cost_usd

    target_lexicon.words = {k: v for k, v in sorted(target_lexicon.words.items())}
    target_lexicon_path.write_text(lexicon_to_yaml(target_lexicon), encoding="utf-8")
    console.print(f"Saved to {target_lexicon_path}")
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
