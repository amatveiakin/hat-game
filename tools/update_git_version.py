# Need to change app version to avoid unwanted caching:
# https://medium.com/flutter-community/caching-in-flutter-for-web-42b3ae0e348f
#
# Based on https://pub.dev/packages/git_version.
# Couldn't use git_version itself due to build dependency issue:
# https://github.com/MikeMitterer/dart-git_version/issues/3

import subprocess
from pathlib import Path

from tools.utils.defines import REPO_ROOT

FLUTTER_ROOT = REPO_ROOT / "hatgame"
VERSION = subprocess.check_output(["git", "describe", "--tags"]).decode("utf-8").strip()


def generate_file(tmpl_path: Path, output_path: Path):
    tmpl = tmpl_path.read_text()
    html = tmpl.replace("%version%", VERSION)
    output_path.write_text(html)


generate_file(
    FLUTTER_ROOT / "web/index.tmpl.html",
    FLUTTER_ROOT / "web/index.html",
)
generate_file(
    FLUTTER_ROOT / "lib/git_version.tmpl",
    FLUTTER_ROOT / "lib/git_version.dart",
)

print(f"Git version update. New version: {VERSION}")
