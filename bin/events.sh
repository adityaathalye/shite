#!/usr/bin/env bash

# ##################################################
# FILE EVENTS
#
# Events are structured as a CSV:
#
# unix_epoch_seconds,event_type,base_dir,sub_dir,url_slug,file_type,content_type
#
# ##################################################

__shite_events_select_filetypes() {
    stdbuf -oL grep -E -e "(org|md|json|csv|html|css|js|jpg|jpeg|png|svg|ico|pdf|webm)$"
}

__shite_events_detect_changes() {
    # Monitor a target directory for file CRUD events and emit a structured
    # record for each event of interest. Emit a CSV record of the form:
    #
    # UNIX_EPOCH_SECONDS,EVENT_TYPE,WATCHED_DIR,FILE_NAME
    #
    # Downstream, we massage this CSV into shite's canonical CSV record.
    local watch_dir="$(realpath -e ${1:-$(pwd)})"
    local watch_events=${2}
    local indefinite=0 # seconds
    local one_time=10 #seconds
    local seconds=$([[ ${SHITE_BUILD} == "full" ]] && printf ${one_time} || printf ${indefinite})
    # WATCH A DIRECTORY
    inotifywait -m --timeout ${seconds} -r --exclude '/\.git/|/\.#|/#|.*(swp|swx|\~)$' \
                --timefmt "%s" \
                --format '%T,%:e,%w,%f' \
                $([[ -n ${watch_events} ]] && printf "%s %s" "-e" ${watch_events})  \
                ${watch_dir} |
        # INCLUDE FILES
        # Alas, inotifywait prohibits use of --exclude _and_ --include filters together.
        __shite_events_select_filetypes
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
    #
    # TODO: switch to relying on metadata from page front matter (e.g. define
    # content_type directly in each post). Also switch to JSON, and depend on jq.
    sed -u -E \
        -e "s;(.*),(${base_dir})\/(sources|public)\/(.*\/?),(.*);\1,\2,\3,\4\5;"  \
        -e "s;.*\.(.*)$;\0,\1;" \
        -e "s;.*,sources,index.org,.*;\0,rootindex;"\
        -e '/,rootindex$/{p ; d}' \
        -e "s;.*,sources,[-[:alnum:]_]?+\.(org|md|html),.*;\0,rootpages;"\
        -e "s;.*,sources,posts/index.org,.*;\0,blogindex;"\
        -e 's;.*,static\/.*;\0,static;' \
        -e 's;.*,posts\/[-[:alnum:]_]+\/index\.(org|md|html),.*;\0,blog;' \
        -e '/,static|blog|rootindex|rootpages|blogindex|(^$)$/{p ; d}' \
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

__shite_events_drop_public_noisy_events() {
    # to suppress noisy events, like when tags are bulk-updated
    stdbuf -oL grep -E -v -e ".*,public,tags/.*,.*"
}


# ##################################################
# THE EVENT STREAM
# ##################################################

shite_events_source() {
    # UNIX_EPOCH_SECONDS,EVENT_TYPE,WATCHED_DIR,FILE_NAME
    local dir_path=${1:?"Fail. Please specify a directory to generate events for."}
    local event_name=${2:-'MODIFY'}
    find "${dir_path}" \
         -depth -type f \
         -printf "%Ts,${event_name},%h/,%f\n" |
        __shite_events_select_filetypes |
        __shite_events_gen_csv
}

shite_events_stream() {
    # Watch all relevant files in the given directory, for the given events.
    local watch_dir=${1:?"Fail. Please specify a directory to watch"}
    local watched_events=${2:-'create,modify,close_write,moved_to,delete'}

    __shite_events_detect_changes \
        ${watch_dir} ${watched_events} |
        # Construct events records as a CSV (consider JSON, if jq isn't too expensive)
        __shite_events_gen_csv ${watch_dir}
}
