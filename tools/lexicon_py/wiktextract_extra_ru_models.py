# Models needed to parse `raw-wiktextract-data.jsonl` missing in `wiktextract_ru_models.py`

from pydantic import ValidationError

from tools.lexicon_py.wiktextract_ru_models import BaseModelWrap, WordEntry


class TitleEntry(BaseModelWrap):
    title: str
    redirect: str
    pos: str


Entry = WordEntry | TitleEntry


def parse_entry(json: str) -> Entry:
    try:
        return TitleEntry.model_validate_json(json)
    except ValidationError:
        return WordEntry.model_validate_json(json)
