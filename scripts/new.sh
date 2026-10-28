#!/bin/sh
# new.sh [+0.0.1|+0.1|+1|x.y.z] [branch name]
# Starts a release. From a clean main that's level with origin: works out the version, makes the branch (gaf3/name,
# or gaf3/version), writes VERSION, package.json, package-lock.json and the changelog section for it, and commits.

. "$(dirname "$0")/lib.sh"

spec=${1:-+0.0.1}
name=$2
prefix=${BRANCH_PREFIX:-gaf3}

guard || exit 1

new=$(sh "$(dirname "$0")/version.sh" next "$spec") || exit 1

branch="$prefix/${name:-$new}"

git switch -q -c "$branch" || exit 1

write_version "$new"

# the changelog gets a dated section, above the newest version, or at the end if there isn't one
if ! grep -Eq "^## \[$new\] - [^ ]" CHANGELOG.md; then
    heading="## [$new] - $(date +%F)"
    if grep -q '^## \[' CHANGELOG.md; then
        awk -v heading="$heading" '!done && /^## \[/ { print heading; print ""; done = 1 } { print }' CHANGELOG.md > CHANGELOG.md.new
    else
        { cat CHANGELOG.md; printf '\n%s\n' "$heading"; } > CHANGELOG.md.new
    fi
    mv CHANGELOG.md.new CHANGELOG.md
fi

git add VERSION package.json package-lock.json CHANGELOG.md
git commit -q -m "Version $new"

echo "$branch: $new"
