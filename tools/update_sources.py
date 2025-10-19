import urllib.request
from pathlib import Path

from tools.utils.defines import E2YO_KERNEL_NOT_SAFE_TXT, E2YO_KERNEL_SAFE_TXT


def size_kb(size: int) -> str:
    return f"{size / 1024:.0f} KB"


def download_file(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response:
        content = response.read()
    destination.write_bytes(content)
    print(f"Downloaded {destination} ({size_kb(len(content))})")


def main() -> None:
    files_to_download = [
        (
            "https://raw.githubusercontent.com/e2yo/eyo-kernel/master/dictionary/safe.txt",
            E2YO_KERNEL_SAFE_TXT,
        ),
        (
            "https://raw.githubusercontent.com/e2yo/eyo-kernel/master/dictionary/not_safe.txt",
            E2YO_KERNEL_NOT_SAFE_TXT,
        ),
    ]
    for url, destination in files_to_download:
        download_file(url, destination)


if __name__ == "__main__":
    main()
