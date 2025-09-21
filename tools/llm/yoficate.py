import asyncio
from pathlib import Path
from typing import Literal

import litellm
import typer
import yaml
from pydantic import BaseModel
from rich.console import Console

from tools.utils.lexicon import yaml_to_lexicon
from tools.utils.linguistics import is_russian_word
from tools.utils.llm import simple_llm_request
from tools.utils.parallel_process import parallel_process

ReasoningEffort = Literal["none", "minimal", "low", "medium", "high", "default"]


class YoficationDictionary(BaseModel):
    yofications: dict[str, list[str]]

    @classmethod
    def from_yaml(cls, content: str) -> "YoficationDictionary":
        yofications: dict[str, list[str]] = yaml.safe_load(content)
        yofications = {
            k: [k if v == "=" else v for v in vs] for k, vs in yofications.items()
        }
        return cls(yofications=yofications)

    def to_yaml(self) -> str:
        class FlowListDumper(yaml.SafeDumper):
            def represent_sequence(self, tag, sequence, flow_style=None):
                processed_sequence = [self.represent_data(item) for item in sequence]
                return yaml.SequenceNode(tag, processed_sequence, flow_style=True)

            def represent_str(self, data):
                return self.represent_scalar("tag:yaml.org,2002:str", data, style='"')

        FlowListDumper.add_representer(str, FlowListDumper.represent_str)

        yofications = {
            k: sorted(["=" if v == k else v for v in vs])
            for k, vs in self.yofications.items()
        }
        return yaml.dump(
            yofications,
            allow_unicode=True,
            Dumper=FlowListDumper,
            default_flow_style=False,
        )


class YoficateResult(BaseModel):
    word: str
    yoficated_words: list[str]
    cost_usd: float


MODELS = [
    "gemini/gemini-2.5-pro",
    "anthropic/claude-opus-4-1",
]
REASONING_EFFORT: ReasoningEffort = "medium"

REQUEST = """
Ты ёфицатор. Я тебе даю слово, а помогаешь мне восстановить его написание.

В данном тебе слове буква «ё», возможно, заменена на «е». Твоя задача — перечислить все правильные варианты написания этого слова. Исправляй «е» на «ё» только там, где в действительности должна быть буква «ё». Если вариантов с «ё» нет, то просто выведи исходное слово.
Выводи по одному слову на строку и больше ничего: заголовков, нумерации, комментариев — НИКАКОГО ДРУГОГО ТЕКСТА.
Сохрани форму слова.
Сохрани капитализацию кроме как если слово стало собственным именем.

Примеры:

<input>
пень
</input>
<output>
пень
</output>

<input>
перепел
</input>
<output>
перепел
</output>

<input>
перепелка
</input>
<output>
перепёлка
</output>

<input>
Еж
</input>
<output>
Ёж
</output>

<input>
зеленого
</input>
<output>
зелёного
</output>

<input>
небо
</input>
<output>
небо
нёбо
</output>

<input>
тема
</input>
<output>
тема
Тёма
</output>
""".strip()

litellm.suppress_debug_info = True

console = Console(highlight=False)


async def yoficate(word: str) -> YoficateResult:
    assert is_russian_word(word)
    responses = [
        await simple_llm_request(
            model=model,
            reasoning_effort=REASONING_EFFORT,
            system_message=REQUEST,
            user_message=word,
        )
        for model in MODELS
    ]

    yoficated_word_options = [sorted(r.text.split("\n")) for r in responses]
    assert all(
        ws == yoficated_word_options[0] for ws in yoficated_word_options
    ), f"{word} => {yoficated_word_options}"

    yoficated_words = yoficated_word_options[0]
    assert all(
        is_russian_word(w) for w in yoficated_words
    ), f"{word} => {yoficated_words}"

    assert all(
        word.lower() == w.lower().replace("ё", "е") for w in yoficated_words
    ), f"{word} => {yoficated_words}"

    return YoficateResult(
        word=word,
        yoficated_words=yoficated_words,
        cost_usd=sum(r.cost_usd for r in responses),
    )


async def generate_yofication_dictionary(
    *, source_lexicon_path: Path, yofication_dictionary_path: Path
):
    source_lexicon = yaml_to_lexicon(source_lexicon_path.read_text(encoding="utf-8"))
    assert source_lexicon.language == "Russian"
    match source_lexicon.kind:
        case "standard":
            source_words = set(source_lexicon.words)
        case "taboo":
            source_words = set(source_lexicon.words.keys()) | set(
                word
                for forbidden_words in source_lexicon.words.values()
                for word in forbidden_words
            )

    source_words = set(w.replace("ё", "е").replace("Ё", "Е") for w in source_words)
    source_words = set(w for w in source_words if "е" in w or "Е" in w)

    if yofication_dictionary_path.exists():
        yofication_dictionary = YoficationDictionary.from_yaml(
            yofication_dictionary_path.read_text(encoding="utf-8")
        )
    else:
        yofication_dictionary = YoficationDictionary(yofications={})

    words_to_process = list(
        source_words - set(yofication_dictionary.yofications.keys())
    )

    if len(words_to_process) == 0:
        console.print("No words to process")
        return

    results = await parallel_process(
        words_to_process,
        yoficate,
        console=console,
        progress_description="Generating yofications",
    )

    total_cost = 0
    for result in results:
        if result.status == "success":
            r = result.value
            yofication_dictionary.yofications[r.word] = r.yoficated_words
            total_cost += r.cost_usd

    yofication_dictionary.yofications = {
        k: vs for k, vs in sorted(yofication_dictionary.yofications.items())
    }
    yofication_dictionary_path.write_text(
        yofication_dictionary.to_yaml(), encoding="utf-8"
    )
    console.print(f"Saved to {yofication_dictionary_path}")
    console.print(f"Total cost: {total_cost:.2f}$")


def main(
    source_lexicon_path: Path,
    yofication_dictionary_path: Path,
):
    asyncio.run(
        generate_yofication_dictionary(
            source_lexicon_path=source_lexicon_path,
            yofication_dictionary_path=yofication_dictionary_path,
        )
    )


if __name__ == "__main__":
    typer.run(main)
