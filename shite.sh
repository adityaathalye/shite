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
    source ./bin/metadata.sh
    source ./bin/hotreload.sh

    # Check for various requirements and dependencies
    __ensure_min_bash_version "4.4"
    # Events and streaming
    __ensure_deps "inotifywait" "stdbuf"
    # Events and Content Processing
    __ensure_deps "gawk" "pandoc" "tidy" "xmllint"
    # GUI / Browser actions
    __ensure_deps "xdotool" "xdg-open"

    # Cue shite for everyday local editing and publishing
    base_dir="$(pwd)"
    SHITE_HOTRELOAD=${1:-"yes"}
    base_url=${2:-"file://${base_dir}/public"}
    browser_name=${3:-"Mozilla Firefox"}
    SHITE_DEBUG_TEMPLATES="debug"

    # Set globally-relevant information that we inject into components,
    # and that we may also use to control site build behaviour.
    # TODO: Don't hardcode. Instead, put a canonical index.org in the
    # index.org (and/or index.html) at
    # the root of `sources`, using our little metadata parser from templating.sh
    declare -A shite_global_data=(
        [title]="Eval / Apply is pure magic"
        [title_icon]="static/img/Lisp_logo.svg"
        [title_icon_png]="static/img/Lisp_logo.png"
        [author]="Aditya Athalye"
        [description]="Evaling and Applying forever."
        [keywords]="systems thinking,functional programming,architecture,software design,technology leadership,devops,clojure"
        [base_url]="${base_url}"
        [feed_xml]="index.xml"
        [sitemap_xml]="sitemap.xml"
    )

    # Oh yeah!
    if [[ ${SHITE_HOTRELOAD} == "yes" ]]
    then # Run hotreload in streaming mode, with a
        ( firefox --new-tab "${base_url}/index.html" & )
        shite_hot_build_reload "${base_dir}" "${browser_name}" "${base_url}" \
                               > /dev/null

    else # Run backgrounded hotreload in timeout mode, and trigger full rebuild
        # by updating mtime of all sources
        shite_hot_build_reload "${base_dir}" "${browser_name}" "${base_url}" \
                               > /dev/null &

        > "${base_dir}/sources.txt"
        find "${base_dir}/sources" -depth -type f -print \
             >> "${base_dir}/sources.txt"

        # xargs, why u no work with `touch`? :thinking-face:
        cat "${base_dir}/sources.txt" |
            while read -r f; do sleep 1; touch -m "${f}"; done;
    fi
)
