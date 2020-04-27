set -e
set -o xtrace

./gen_index_html.sh
flutter build web
firebase deploy
