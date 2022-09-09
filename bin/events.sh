#!/usr/bin/env bash

# ##################################################
# FILE EVENTS
#
# Events are structured as a CSV:
#
# unix_epoch_seconds,event_type,base_dir,sub_dir,url_slug,file_type,content_type
#
# ##################################################

__shite_events_detect_changes() {
    # Monitor a target directory for file CRUD events and emit a structured
    # record for each event of interest. Emit a CSV record of the form:
    #
    # UNIX_EPOCH_SECONDS,EVENT_TYPE,WATCHED_DIR,FILE_NAME
    #
    # Downstream, we massage this CSV into shite's canonical CSV record.
    local watch_dir="$(realpath -e ${1:-$(pwd)})"
    local watch_events=${2}

    # WATCH A DIRECTORY
    inotifywait -m -r --exclude '/\.git/|/\.#|/#|.*(swp|swx|\~)$' \
                --timefmt "%s" \
                --format '%T,%:e,%w,%f' \
                $([[ -n ${watch_events} ]] && printf "%s %s" "-e" ${watch_events})  \
                ${watch_dir} |
        # INCLUDE FILES
        # The 'include' filter of inotifywait V3.2+ will obviate this grep
        stdbuf -oL grep -E -e "(org|md|json|html|css|js|jpg|jpeg|png|svg|pdf)$"
}

__shite_events_gen_csv() {
    local base_dir="$(realpath -e ${1:-$(pwd)})"
    # Given a raw stream of file events, emit a rich CSV record of event info,
    # having fields:
    #
    # UNIX_EPOCH_SECONDS,EVENT_TYPE,BASE_DIR,SUB_DIR,URL_SLUG,FILE_TYPE,CONTENT_TYPE
    #
    # We analyse events and enrich them with data that will ease dispatch of
    # various actions downstream. For example:
    #
    # - Split the full watched_dir path into base_dir and url_slug parts
    # - Enrich file and content type for fine-grained dispatch of file actions
    # - etc.
    #
    # NOTE: we strip trailing slashes from BASE_DIR, and URL_SLUG paths, so that
    # we can join them back with slashes interposed, when needed.
    sed -u -E \
        -e "s;(.*),(${base_dir})\/(sources|public)\/(.*\/?),(.*);\1,\2,\3,\4\5;"  \
        -e "s;.*\.(.*)$;\0,\1;" \
        -e 's;.*,static\/.*;\0,static;' \
        -e 's;.*,posts\/.*;\0,blog;' \
        -e '/static|blog$/{p ; d}' \
        -e 's;.*;\0,generic;'
}

# ##################################################
# EVENT FILTERS
# ##################################################

__shite_events_dedupe() {
    # Some editing actions can cause multiple inotify events of the same type for
    # the same file for a single edit action. e.g. Writing an edit via Vim causes
    # the sequence CREATE, MODIFIED, MODIFIED. Pulling up the helm minibuffer in
    # Emacs causes a whole slew of events that are no-ops for us.
    #
    # We want to ensure we dispatch a hotreload action only on the "final result"
    # of any single action on a file. For us, this would be the last event of any
    # contiguous sequence of desirable inotify events on the same file.

    stdbuf -oL awk 'BEGIN { FS = "," } {if(!seen[$0]++ && seen[$1]++) print}'
}

__shite_events_select_sources() {
    stdbuf -oL grep -E -e ".*,sources,.*"
}

__shite_events_select_public() {
    stdbuf -oL grep -E -e ".*,public,.*"
}

# ##################################################
# THE EVENT STREAM
# ##################################################

shite_events_stream() {
    # Watch all relevant files in the given directory, for the given events.
    local watch_dir=${1:?"Fail. Please specify a directory to watch"}
    local watched_events=${2:-'create,modify,close_write,moved_to,delete'}

    __shite_events_detect_changes \
        ${watch_dir} ${watched_events} |
        # Construct events records as a CSV (consider JSON, if jq isn't too expensive)
        __shite_events_gen_csv ${watch_dir} |
        # Deduplicate file events
        __shite_events_dedupe
}
