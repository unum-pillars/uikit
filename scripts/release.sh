#!/bin/sh
# release.sh: from main, does what's left of the release: the checks, npm, waiting for it, the tag
# npm has no test registry, so a version published is a version taken for good. That's what the checks are for.

. "$(dirname "$0")/lib.sh"

# release: does what's left, from main
release() {
    guard || return 1

    if [ "$(state)" = released ]; then
        echo "$(version): released, nothing to release"
        return 0
    fi

    check || return 1

    listed "$(version)" || make publish || return 1

    wait_for || return 1
    make tag || return 1

    echo "$(package) $(version) released"
}

release
