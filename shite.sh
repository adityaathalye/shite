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

    # Check for various requirements and dependencies
    __ensure_min_bash_version "4.4"
    # Events and streaming
    __ensure_deps "inotifywait" "stdbuf"
    # Events and Content Processing
    __ensure_deps "gawk" "pandoc" "tidy"
    # GUI / Browser actions
    __ensure_deps "xdotool" "xdg-open"

    # Cue shite for everyday local editing and publishing
    browser_name=${1:-"Mozilla Firefox"}
    base_url=${2:-"file://$(pwd)/public"}
    SHITE_DEBUG="nodebug"
    SHITE_DEBUG_TEMPLATES="debug"

    # Set globally-relevant information that we inject into components,
    # and that we may also use to control site build behaviour.
    # TODO: Don't hardcode. Instead, put a canonical index.org in the
    # index.org (and/or index.html) at
    # the root of `sources`, using our little metadata parser from templating.sh
    declare -A shite_global_data=(
        [title]="Eval / Apply is pure magic"
        [title_icon]="(λx.(x x) λx.(x x))"
        [author]="Aditya Athalye"
        [description]="Evaling and Applying forever."
        [keywords]="systems thinking,functional programming,architecture,software design,technology leadership,devops,clojure"
        [base_url]="${base_url}"
    )

    # Helpfully open a tab in the specified browser
    ( firefox --new-tab "${base_url}/index.html" & )

    # Oh yeah!
    shite_hot_build_reload \
        "$(pwd)" \
        "${browser_name}" \
        "${base_url}" \
        > /dev/null
)
