# shellcheck shell=sh
# Shared by the release scripts, source it: . "$(dirname "$0")/lib.sh"
# NPM_URL, WAIT_TRIES and WAIT_DELAY can be set to point at another registry or wait less or longer.

NPM_URL=${NPM_URL:-https://registry.npmjs.org}
WAIT_TRIES=${WAIT_TRIES:-180}
WAIT_DELAY=${WAIT_DELAY:-10}

# the name on npm, and the version being worked on (VERSION is the source of truth, package.json follows it)
package() {
    grep -m1 '"name"' package.json | cut -d'"' -f4
}

version() {
    cat VERSION
}

# listed version [name]: whether the registry has the version of the package (or another), it can lag
listed() {
    curl -sfL -o /dev/null "$NPM_URL/$(echo "${2:-$(package)}" | sed 's|/|%2f|')/$1"
}

# wait_for: waits for the version to show up on the registry, it can lag after a publish
wait_for() {
    tries=0
    while [ "$tries" -lt "$WAIT_TRIES" ]; do
        if listed "$(version)"; then
            echo "$(package) $(version) is on npm"
            return 0
        fi
        tries=$((tries + 1))
        [ "$tries" -lt "$WAIT_TRIES" ] && sleep "$WAIT_DELAY"
    done
    echo "$(package) $(version) is not on npm" >&2
    return 1
}

# write_version x.y.z: VERSION, then package.json and package-lock.json to match. npm puts the package's version at the top
# of each, two spaces in, and the lock file's root package is the first entry in packages, six spaces in. Nothing else changes.
write_version() {
    echo "$1" > VERSION
    for file in package.json package-lock.json; do
        [ -f "$file" ] || continue
        awk -v new="$1" '
            /^  "version": "/ && !top { sub(/"version": "[^"]*"/, "\"version\": \"" new "\""); top = 1 }
            /^      "version": "/ && FILENAME ~ /lock/ && !root { sub(/"version": "[^"]*"/, "\"version\": \"" new "\""); root = 1 }
            { print }' "$file" > "$file.new" && mv "$file.new" "$file"
    done
}

# guard: makes sure we're on a clean main that's level with origin.
guard() {
    git fetch -q origin
    branch=$(git rev-parse --abbrev-ref HEAD)
    [ "$branch" = main ] || { echo "not on main (on ${branch:-no branch})"; return 1; }
    [ -z "$(git status --porcelain)" ] || { echo "the working tree isn't clean"; return 1; }
    [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "main isn't level with origin/main"; return 1; }
}

# state: how far the release of this version is: released, tag-pending, publish-pending or unreleased
state() {
    tagged=no
    git ls-remote --exit-code --tags origin "$(version)" > /dev/null 2>&1 && tagged=yes
    live=no
    listed "$(version)" && live=yes
    case "$tagged$live" in
        yesyes) echo released ;;
        noyes) echo tag-pending ;;
        yesno) echo publish-pending ;;
        *) echo unreleased ;;
    esac
}

# problems: everything that would stop a release
problems() {
    grep -Eq "^## \[$(version)\] - [^ ]" CHANGELOG.md || echo "CHANGELOG.md has no ## [$(version)] - <date> section"

    # package.json and the lock file follow VERSION
    found=$(sed -n 's/^  "version": "\(.*\)",$/\1/p' package.json | head -1)
    [ "$found" = "$(version)" ] || echo "package.json is $found, VERSION is $(version)"
    if [ -f package-lock.json ]; then
        found=$(sed -n 's/^  "version": "\(.*\)",$/\1/p' package-lock.json | head -1)
        [ "$found" = "$(version)" ] || echo "package-lock.json is $found, VERSION is $(version)"
        found=$(sed -n 's/^      "version": "\(.*\)",$/\1/p' package-lock.json | head -1)
        [ "$found" = "$(version)" ] || echo "package-lock.json's root package is $found, VERSION is $(version)"
    fi

    # a dependency from git or a url can't be released
    awk '/"(dev|peer|optional)?[Dd]ependencies": *\{/ { inside = 1; next } inside && /\}/ { inside = 0 }
        inside && /"(git\+|git:|github:|https?:)/ { gsub(/^ +/, ""); print "package.json has a git dependency: " $0 }' package.json
}

# check: says where the release is up to and what would stop it
check() {
    current=$(state)
    echo "$(version): $current"

    if [ "$current" = released ]; then
        echo "nothing to release"
        return 0
    fi

    # a published version has already passed these, all that's left is the tag
    if [ "$current" != tag-pending ]; then
        found=$(problems)
        [ -z "$found" ] || { echo "$found"; return 1; }
        make build pack || return 1
    fi

    echo "ready to release"
}
