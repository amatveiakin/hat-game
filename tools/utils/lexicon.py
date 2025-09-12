import datetime
from typing import Any, Literal

import yaml
from pydantic import BaseModel


class LexiconBase(BaseModel):
    name: str
    language: str
    updated_at: datetime.date


class StandardLexicon(LexiconBase):
    kind: Literal["standard"]
    words: list[str]


class TabooLexicon(LexiconBase):
    kind: Literal["taboo"]
    words: dict[str, list[str]]


Lexicon = StandardLexicon | TabooLexicon


def yaml_to_lexicon(content: str) -> Lexicon:
    documents = list(yaml.safe_load_all(content))
    assert len(documents) == 2
    header, body = documents
    assert isinstance(header, dict)
    data: dict[str, Any] = header.copy()
    data["words"] = body
    match data["kind"]:
        case "standard":
            return StandardLexicon(**data)
        case "taboo":
            return TabooLexicon(**data)
        case _:
            raise ValueError(f"Unknown lexicon kind: {data['kind']}")


def lexicon_to_yaml(lexicon: Lexicon) -> str:
    # Quotes all strings except for dictionary keys.
    def make_dumper(*, quote_keys: bool):
        class ValueQuotingDumper(yaml.Dumper):
            def _represent_quoted(self, value: Any) -> yaml.Node:
                if isinstance(value, str):
                    return self.represent_scalar(
                        "tag:yaml.org,2002:str", value, style='"'
                    )
                else:
                    return self.represent_data(value)

            def represent_sequence(self, tag, sequence, flow_style=None):
                processed_sequence: list[yaml.Node] = []
                for item in sequence:
                    processed_sequence.append(self._represent_quoted(item))
                return yaml.SequenceNode(tag, processed_sequence, flow_style=False)

            def represent_mapping(self, tag, mapping, flow_style=None):
                processed_mapping: list[tuple[yaml.Node, yaml.Node]] = []
                for key, value in mapping.items():  # pyright: ignore[reportAttributeAccessIssue]
                    key = (
                        self._represent_quoted(key)
                        if quote_keys
                        else self.represent_data(key)
                    )
                    processed_mapping.append((key, self._represent_quoted(value)))
                return yaml.MappingNode(tag, processed_mapping, flow_style=flow_style)

        return ValueQuotingDumper

    header = {
        "name": lexicon.name,
        "kind": lexicon.kind,
        "language": lexicon.language,
        "updated_at": lexicon.updated_at,
    }
    body = lexicon.words
    return (
        yaml.dump(
            header,
            allow_unicode=True,
            default_flow_style=False,
            Dumper=make_dumper(quote_keys=False),
        )
        + "---\n"
        + yaml.dump(
            body,
            allow_unicode=True,
            default_flow_style=False,
            Dumper=make_dumper(quote_keys=True),
        )
    )
