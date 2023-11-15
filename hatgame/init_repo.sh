set -e
set -o xtrace

flutter pub get
./update_git_version.sh
dart run build_runner build
