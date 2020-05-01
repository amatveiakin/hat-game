set -e
set -o xtrace

./update_git_version.sh
flutter pub run build_runner build
