#!/bin/bash
# release.sh — bump the app version in index.html and version.json together.
# Usage: ./release.sh 2.1.1

# `set -e` means: if any command in this script fails, stop immediately.
# Without this, if one sed failed the other would still run and leave the
# two files out of sync — which is the exact bug this script exists to prevent.
set -e

NEW_VERSION="$1"

# 1. Did the user pass a version number?
if [ -z "$NEW_VERSION" ]; then
  echo "Error: please provide a version number."
  echo "Example: ./release.sh 2.1.1"
  exit 1
fi

# 2. Does it look like a version number (three numbers separated by dots)?
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: version should look like 2.1.1 (three numbers separated by dots)."
  exit 1
fi

# 3. Find the current version inside index.html so we can show what changed.
OLD_VERSION=$(grep -o "APP_VERSION = '[^']*'" index.html | head -1 | sed "s/APP_VERSION = '//;s/'$//")

if [ -z "$OLD_VERSION" ]; then
  echo "Error: couldn't find APP_VERSION in index.html."
  echo "Make sure you're running this from the My Kitchen folder."
  exit 1
fi

# 4. Are we already on the requested version? Nothing to do.
if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  echo "Version is already $NEW_VERSION. Nothing to do."
  exit 0
fi

# 5. Replace the version string in both files.
#    Writing to a temp file and then renaming is the cross-platform safe
#    way to do in-place edits (works on Mac, Linux, and inside CI).
sed "s#APP_VERSION = '$OLD_VERSION'#APP_VERSION = '$NEW_VERSION'#" index.html > index.html.tmp
mv index.html.tmp index.html

sed "s#\"version\": \"$OLD_VERSION\"#\"version\": \"$NEW_VERSION\"#" version.json > version.json.tmp
mv version.json.tmp version.json

# 6. Confirm + remind how to publish.
echo "Bumped $OLD_VERSION -> $NEW_VERSION"
echo ""
echo "Next steps:"
echo "  git add index.html version.json"
echo "  git commit -m \"Release $NEW_VERSION\""
echo "  git push"
