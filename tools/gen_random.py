import argparse
from pathlib import Path
import random
import sys

import yaml

parser = argparse.ArgumentParser(
    description="Generates random works for a tournament that were not used earlier"
)
parser.add_argument("source_dict", type=Path, help="Input file")
parser.add_argument("n", type=int, help="Number of words to generate")
parser.add_argument("--denylist", nargs="*", type=Path, help="Denylist")


def parse_source_dict(path: Path) -> set[str]:
    with open(path, "r", encoding="utf-8") as f:
        doc = list(yaml.safe_load_all(f))
        return set(doc[1])


def parse_denylist(path: Path) -> set[str]:
    return set(path.read_text(encoding="utf-8").splitlines())


def parse_denylists(args: argparse.Namespace) -> set[str]:
    denylist = set()
    for path in args.denylist or []:
        denylist.update(parse_denylist(path))
    return denylist


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

    args = parser.parse_args()

    source_dict = parse_source_dict(args.source_dict)
    denylist = parse_denylists(args)
    allowed_words = source_dict - denylist
    print(f"Allowed words: {len(allowed_words)} of {len(source_dict)}", file=sys.stderr)
    print("\n".join(random.sample(list(allowed_words), args.n)))


if __name__ == "__main__":
    main()
