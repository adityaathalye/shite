#!/usr/bin/env bash

source ./bin/templating.sh
source ./bin/hotreload.sh

(
    declare -r browser_name=${1:-"Mozilla Firefox"}
    declare -r base_url=${2:-"file://$(pwd)"}

    # Set globally-relevant information that we inject into components,
    # and that we may also use to control site build behaviour.
    declare -A shite_global_data=(
        [title]="A static shite from shell"
        [author]="Yours Truly"
        [description]="In which we work our way to world domination the hard way."
        [keywords]="blog, world domination, being awesome"
    )

    shite_hotreload \
        "./" \
        "${shite_global_data[title]}" \
        ${browser_name} \
        ${base_url} \
        > /dev/null
)
