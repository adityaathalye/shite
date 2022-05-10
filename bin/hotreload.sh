#!/usr/bin/env bash

# ##################################################
# Functions to power the poor shite's hot reload :)
# ##################################################
# The brainwave to use 'inotify-tools' and 'xdotool' is pinched from
# https://github.com/traviscross/inotify-refresh
#
# Because what could be hotter than hitting f5 for the target tab,
# in the target browser?
#
# While inotify-refresh tries to _periodically_ refresh a set of browser, we
# want to be more eager. We want page events to trigger refreshes and GOTOs.
#
# If this hot reload is not hot enough, there is Emacs impatient-mode.

# "Dev-ing/Drafting" time setup/Teardown scenario:
#
# When we first start development (maybe a 'dev_server' function):
# - xdotool open a new tab in the default browser (say, firefox).
# - xdotool goto the home page of the shite based on config.
# - xdotool 'set_window --name' to a UUID for the life of the session.
# - xdotool close the tab when we kill the dev session


# Hot reload scenarios:
#
# We want to define distinct reload scenarios: Mutually exclusive, collectively
# exhaustive buckets into which we can map file events we want to monitor. If we
# do this, then we can model updates as a write-ahead-log. Punch events through
# an analysis pipeline and associate them with the exact-match scenario.
#
# Refresh current tab when
# - static asset create, modify, move, delete
#
# Go home when
# - current page deleted
#
# Navigate to content when
# - current page content modified
# - any content page moved or created or modified

# Hot reload behaviour:
# Since we are emulating user behaviour, we can race with the user, e.g. when
# switching to the browser window. If the time gap is minimal, this should
# not be too annoying.

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
        # We have to grep, but a new version of inotifywait has an 'include'
        # option, which should obviate grep. So says Stackoverflow. Also we
        # must prevent grep stdio buffering, else things don't stream down-pipe.
        # Bah. https://www.perkin.org.uk/posts/how-to-fix-stdio-buffering.html
        stdbuf -oL grep -E -e "(html|js|css)$"
}

__shite_distinct_events() {
    # Some editing actions can cause multiple inotify events of the same type for
    # the same file for a single edit action. e.g. Writing an edit via Vim causes
    # the sequence CREATE, MODIFIED, MODIFIED.
    #
    # We want to ensure we dispatch a hotreload action only on the "final result"
    # of any single action on a file. For our purpose, this would be the last
    # event of any contiguous sequence of inotify events on the same file.

    stdbuf -oL awk 'BEGIN { FS = "," } {if(!seen[$0]++ && seen[$1]++) print}'
}

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

__shite_xdo_cmd_exec() {
    local cmd=$(
        if [[ ${SHITE_DEBUG} == "debug" ]]
        then "cat"
        else "xdotool"
        fi
          )
    stdbuf -oL grep -v '^$' | $cmd -
}

__shite_xdo_cmd_exec_debug_log() {
    tee >(1>&2 cat -)
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
        __shite_xdo_cmd_exec_debug_log |
        __shite_xdo_cmd_gen ${window_id} ${base_url} |
        __shite_xdo_cmd_exec_debug_log |
        __shite_xdo_cmd_exec
}

__shite_debug_run() {
    SHITE_DEBUG="debug" shite_hotreload \
               "./public" 'A static' \
               > /dev/null
}
