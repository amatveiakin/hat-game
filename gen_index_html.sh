# Need to change app version to avoid unwanted caching:
# https://medium.com/flutter-community/caching-in-flutter-for-web-42b3ae0e348f
#
# Based on https://pub.dev/packages/git_version.
# Couldn't use git_version itself due to build dependency issue:
# https://github.com/MikeMitterer/dart-git_version/issues/3

set -e
# TODO: Generate index.html inside some temp folder, e.g.:
#     .dart_tool/build/generated/hatgame/web/index.html
sed "s/%version%/`git describe --tags`/" web/index.tmpl.html > web/index.html
