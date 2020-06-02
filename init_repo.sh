set -e
set -o xtrace

flutter pub get
./update_git_version.sh
flutter pub run build_runner build
