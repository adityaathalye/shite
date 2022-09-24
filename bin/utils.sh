#!/usr/bin/env bash

# Utils mostly copied over from my "Bash Toolkit"
# cf. https://github.com/adityaathalye/bash-toolkit

__to_stderr() {
    # Ref: I/O Redirection: http://tldp.org/LDP/abs/html/io-redirection.html
    1>&2 printf "%s\n" "$(date --iso-8601=seconds) $@"
}

__log_info() {
    __to_stderr "$(echo "INFO $0 $@")"
}

__tap_stream() {
    tee >(1>&2 cat -)
}

__ensure_deps() {
    # Given a list of dependencies, emit unmet dependencies to stderr,
    # and return 1. Otherwise silently return 0.
    local required_deps="${@}"
    local err_code=0
    for prog in ${required_deps}
    do if ! which ${prog} > /dev/null
       then __log_info "PACKAGE NOT FOUND: ${prog}. Things will break."
            err_code=1
       fi
    done
    return ${err_code}
}

__ensure_min_bash_version() {
    # Given a 'Major.Minor.Patch' SemVer number, return 1 if the system's
    # bash version is older than the given version. Default to 4.0.0.
    # Hat tip: https://unix.stackexchange.com/a/285928
    local semver="${1:-4.0.0}"
    local bashver="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}"

    [[ $(printf "%s\n" ${semver} ${bashver} | sort -V | head -1) == ${semver} ]]
}

__html_escape() {
    # Use to escape HTML when making XML files like RSS feeds or Sitemaps.
    # It could be a sed one-liner, but it could also be a very badly behaved
    # sed one-liner, causing all manner of breakages and bugs. But we have jq,
    # and jq is neat! Thanks to: https://stackoverflow.com/a/71191653
    #
    # echo "\"'&<>" | jq -Rr @html
    # &quot;&apos;&amp;&lt;&gt;

    jq -Rr @html
}
