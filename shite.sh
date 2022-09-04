#!/usr/bin/env bash

# Do it all in a subshell so we don't pollute the existing teminal session.
(
    # Ensure extglob is set, for enhanced Pattern Matching (see Bash manual).
    shopt -s extglob

    # Bring in all the functions.
    source ./bin/utils.sh
    source ./bin/templates.sh
    source ./bin/templating.sh
    source ./bin/events.sh
    source ./bin/hotreload.sh

    # Orient for local editing and publishing in my preferred browser.
    declare -r browser_name=${1:-"Mozilla Firefox"}
    declare -r base_url=${2:-"file://$(pwd)"}

    # Set globally-relevant information that we inject into components,
    # and that we may also use to control site build behaviour.
    # TODO: Don't hardcode. Instead, put a canonical index.org in the
    # index.org (and/or index.html) at
    # the root of `sources`, using our little metadata parser from templating.sh
    declare -A shite_global_data=(
        [title]="A static shite from shell"
        [author]="Yours Truly"
        [description]="In which we work our way to world domination the hard way."
        [keywords]="blog, world domination, being awesome"
    )

    # Oh yeah!
    shite_hot_build_reload \
        "./" \
        "${shite_global_data[title]}" \
        ${browser_name} \
        ${base_url} \
        > /dev/null
)
