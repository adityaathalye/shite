#!/usr/bin/env bash

# ##################################################
# FILE EVENTS
#
# Events are structured as a CSV:
#
# unix_epoch_seconds,event_type,base_dir,sub_dir,file_name,file_type,content_type
#
# ##################################################

__shite_detect_changes() {
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
    # UNIX_EPOCH_SECONDS,EVENT_TYPE,BASE_DIR,SUB_DIR,FILE_NAME,FILE_TYPE,CONTENT_TYPE
    #
    # We analyse events and enrich them with data that will ease dispatch of
    # various actions downstream. For example:
    #
    # - Split the full watched_dir path into base_dir and sub_dir parts
    # - Enrich file and content type for fine-grained dispatch of file actions
    # - etc.
    #
    # NOTE: we strip trailing slashes from BASE_DIR, and SUB_DIR paths, so that
    # we can join them back with slashes interposed, when needed.
    sed -u -E \
        -e "s;(.*),(${base_dir})\/sources\/(.*)\/,(.*);\1,\2,\3,\4;"  \
        -e "s;.*\.(.*)$;\0,\1;" \
        -e 's;.*,static\/.*;\0,static;' \
        -e 's;.*,content\/posts\/.*;\0,blog;' \
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

__shite_events_select_by_sub_dir() {
    local sub_dir=${1:?"Fail. We expect a sub-directory like content, static, public"}
    stdbuf -oL grep -E -e ".*\/shite,${sub_dir}.*\/,"
}
