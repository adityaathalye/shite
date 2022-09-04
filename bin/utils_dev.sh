#!/usr/bin/env bash
# ####################################################################
# SITE PUBLISHING
#
# Convenience functions to remind us how to create the full site, and
# publish it to the public directory.
#
# ####################################################################

source ./bin/utils.sh
source ./bin/templates.sh
source ./bin/templating.sh
source ./bin/events.sh
source ./bin/hotreload.sh

__shite_devutil_new_session() {
    local browser_name=${1:-"Mozilla Firefox"}
    local url=${2:-"file://$(pwd)/public/index.html"}

    declare -A browser_cmd=(
        ["Mozilla Firefox"]="firefox -new-window"
        ["Chromium"]="chromium-browser --new-window"
        ["Google Chrome"]="google-chrome --new-window"
    )

    ${browser_cmd[${browser_name}]} "${url}"
}

__shite_devutil_tidy_html() {
    tidy -q -i
}

__shite_devutil_build_public_static() {
    cp -fr ./static/* ./public
}

shite_devutil_build_all_html_static() {
    mkdir -p public # ensure the public dir. exists

    __shite_build_public_static

    find content/ -type f -name *.html |
        shite_publish_sources \
            shite_proc_html_content \
            __shite_tidy_html > /dev/null

    find content/ -type f -name *.md |
        shite_publish_sources \
            shite_proc_markdown_content \
            __shite_tidy_html > /dev/null

    find content/ -type f -name *.org |
        shite_publish_sources \
            shite_proc_orgmode_content \
            __shite_tidy_html > /dev/null

    # Write informational log to stderr
    (
        1>&2 cat <<EOF
Built and published HTML pages and static files to public/ directory.
cd into it, open index.html and enjoy your website.
EOF
    )
}

shite_devutil_rebuild_all_html_static() {
    # Rebuild from scratch
    rm -r public/*
    __shite_drop_page_header_data
}
