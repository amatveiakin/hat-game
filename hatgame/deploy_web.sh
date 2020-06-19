set -e
set -o xtrace

./update_git_version.sh
flutter build web
firebase deploy
