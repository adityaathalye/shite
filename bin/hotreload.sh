#!/usr/bin/env bash

# ##################################################
# Functions to power this poor shite's hot reload
#
# USAGE
#
# source this file and call the shite_hotreload function with arguments for
#
#   shite_hotreload [WATCH DIR] [BROWSER TAB NAME] \
#                   [OPTIONAL BROWSER NAME] \
#                   [OPTIONAL BASE URL]
#
# It assumes Mozilla Firefox and file:// based navigation by default.
#
#
# EXAMPLES
#
#   shite_hotreload "public" 'A site'
#
#   shite_hotreload "public" 'A site' "Google Chrome"
#
#   shite_hotreload "public" 'A site' "Google Chrome" "http://localhost:8080"
#
#
# LOGIC
#
# - MONITOR files with inotifywait, and stream events as CSV records
# - INTERPRET events and generate commands to feed to a command executor
#   - "Content" (html) file changes require special handling
#   - "Static" (css,js,img) file changes only ever trigger page reload
# - EXECUTE the incoming commands in a streaming fashion
# - TAP into the stream at any point, for debugging, with the logging utility
#
#
# WARNINGS
#
# Beware of stdio buffering. Use stdbuf to control it.
#
# Some tools like grep and awk buffer their output and thus block downstream
# actions. But we want instant reaction time. So buffers are bad for us.
#
# Luckily stdbuf is a general way to tune buffering behaviour. We can work
# with line-buffered output streaming. e.g.:
#
#   stdbuf -oL grep something
#
# c.f https://www.perkin.org.uk/posts/how-to-fix-stdio-buffering.html
# ##################################################


__shite_tap_stream() {
    tee >(1>&2 cat -)
}


# ##################################################
# FILE EVENTS
# ##################################################

__shite_detect_changes() {
    # Continuously monitor the target directory for file CRUD events
    # Emit a CSV record of UNIX_EPOCH_SECONDS,EVENT_TYPE,DIR_PATH,FILE_NAME
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
        stdbuf -oL grep -E -e "(html|js|css)$"
}

__shite_distinct_events() {
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

# ##################################################
# INTERPRETER FOR FILE EVENTS
# ##################################################

__shite_xdo_cmd_browser_refresh() {
    local window_id=${1:?"Fail. We expect window ID to be set in scope."}

    printf "%s\n" \
           "key --window ${window_id} --clearmodifiers 'F5'"
}

__shite_xdo_cmd_goto_url() {
    local window_id=${1}
    local url=${2}

    printf "%s\n" \
           "key --window ${window_id} --clearmodifiers 'ctrl+l'" \
           "type --window ${window_id} --clearmodifiers --delay 1 ${url}" \
           "key --window ${window_id} --clearmodifiers 'Return'"
}

__shite_xdo_cmd_gen() {
    # Generate xdotool commands based on information about the
    # event type, file type, and whether the file has changed.
    local window_id=${1:?"Fail. We expect a window ID."}
    local base_url=${2}
    local file_type
    local file_status
    local prev_file_name

    while IFS=',' read -r timestamp event_type dir_path file_name
    do
        file_type="${file_name#*\.}"

        file_status=$(
            if [[ ${file_name} == ${prev_file_name} ]]
            then printf "%s" "SAMEFILE"
            else printf "%s" "NEWFILE"
            fi
                   )

        # First catch "content" pages, which require special casing.
        # At last, catch all non-content pages and do the only sane
        # thing for anything done to those pages; viz. reload the site.
        case "${event_type}:${file_type}:${file_status}" in
            # RELOAD
            # - When any content file is modified
            # - When any non-current content file is deleted
            #   (because that may affect the current page)
            MODIFY:html:SAMEFILE ) ;& # catch vim edits
            CLOSE_WRITE:CLOSE:html:SAMEFILE ) ;& # catch emacs edits
            DELETE:html:NEWFILE )
                __shite_xdo_cmd_browser_refresh ${window_id}
                ;;
            # GOTO - NAVIGATE
            # - Newly-created content file, or
            # - Moved/renamed content file
            MODIFY:html:NEWFILE ) ;& # vim new file
            CLOSE_WRITE:CLOSE:html:NEWFILE ) ;& # emacs new file
            CREATE:html:* ) ;&
            MOVED_TO:html:* )
                __shite_xdo_cmd_goto_url \
                    ${window_id} \
                    "${base_url:-file://${dir_path%\/}}/${file_name}"
                ;;
            # GOTO - FALLBACK
            # - home page when the current content file is deleted
            DELETE:html:SAMEFILE )
                __shite_xdo_cmd_goto_url \
                    ${window_id} \
                    "${base_url:-file://${dir_path%\/}}"
                ;;

            # RELOAD page for any action on non-content pages,
            # presumably static assets.
            * )
                __shite_xdo_cmd_browser_refresh ${window_id}
                ;;
        esac

        # Remember the file for the next cycle
        prev_file_name=${file_name}
    done
}


# ##################################################
# COMMAND EXECUTOR
# ##################################################

__shite_xdo_cmd_exec() {
    if [[ ${SHITE_DEBUG} == "debug" ]]
    then cat -
    else stdbuf -oL grep -v '^$' | xdotool -
    fi
}

shite_hotreload() {
    # Maybe improve with getopts later
    local watch_dir=${1:?"Fail. Please specify a directory to watch"}
    local tab_name=${2:?"Fail. We want to target a single specific tab only."}
    local browser_name=${3:-"Mozilla Firefox"}
    local base_url=${4:-""}

    # Lookup window ID
    local window_id=$(xdotool search --onlyvisible --name "${tab_name}.*${browser_name}$")

    # Run pipeline
    # - Events of interest 'create,modify,close_write,moved_to,delete'
    __shite_detect_changes \
        ${watch_dir} 'create,modify,close_write,moved_to,delete' |
        __shite_distinct_events |
        __shite_tap_stream |
        __shite_xdo_cmd_gen ${window_id} ${base_url} |
        __shite_tap_stream |
        __shite_xdo_cmd_exec
}


# ##################################################
# CONVENIENCE UTILITIES
# ##################################################

__shite_debug_run() {
    SHITE_DEBUG="debug" shite_hotreload \
               "./public" 'A static' \
               > /dev/null
}
