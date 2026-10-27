#!/bin/sh
# Sets the app's version, as semantic versioning has it (MAJOR.MINOR.PATCH),
# and counts the build number up by one: every build handed out has its own.
#
#   scripts/version.sh            prints the version and build
#   scripts/version.sh 1.2.0      sets the version to 1.2.0, the next build
set -eu

project="$(dirname "$0")/../FiestaBoard.xcodeproj/project.pbxproj"
version=$(sed -n 's/.*MARKETING_VERSION = \(.*\);/\1/p' "$project" | head -1)
build=$(sed -n 's/.*CURRENT_PROJECT_VERSION = \(.*\);/\1/p' "$project" | head -1)

if [ $# -eq 0 ]; then
  echo "$version ($build)"
  exit 0
fi

case "$1" in
  *[!0-9.]* | .* | *. | *..* ) echo "Not MAJOR.MINOR.PATCH: $1" >&2; exit 1 ;;
esac
[ "$(echo "$1" | tr -cd . | wc -c | tr -d ' ')" = 2 ] || { echo "Not MAJOR.MINOR.PATCH: $1" >&2; exit 1; }

next=$((build + 1))
sed -i '' -e "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $1;/" \
  -e "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = $next;/" "$project"
echo "$1 ($next)"
