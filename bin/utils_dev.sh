#!/usr/bin/env bash
# ####################################################################
# SITE PUBLISHING
#
# Convenience functions to remind us how to create the full site, and
# publish it to the public directory.
#
# TODO: Fix this whole namespace. It has fallen to ruin from disuse.
#
# ####################################################################

__shite_devutil_tidy_check_html() {
    find "${base_dir}/public/"  -type f -name "*.html" |
        __tap_stream |
        xargs -0 tidy -q -e
}

__shite_devutil_trigger_all_sources() {
    find "$(pwd)/sources" -type f |
        while read -r f
        do touch -m ${f}
        done
}

__shite_devutil_minify_all_in_place() {
    minify -r -o . .
}
