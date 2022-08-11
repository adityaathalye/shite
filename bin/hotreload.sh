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

source ./bin/utils.sh
source ./bin/events.sh

# ##################################################
# BROWSER COMMAND INTERPRETER FOR FILE EVENTS
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

__shite_xdo_cmd_public_events() {
    # When we see events for files under the `public` target directory,
    # generate xdotool commands using information like event type, file type,
    # and how the file has changed (updated, deleted, moved etc.).
    local window_id=${1:?"Fail. We expect a window ID."}
    local base_url=${2}
    local file_status
    local prev_file_name

    while IFS=',' read -r timestamp event_type watch_dir sub_dir file_name file_type content_type
    do
        file_status=$(
            if [[ ${file_name} == ${prev_file_name} ]]
            then printf "%s" "SAMEFILE"
            else printf "%s" "NEWFILE"
            fi
                   )

        # First catch "content" pages, which require special casing.
        # At last, catch all non-content pages and do the only sane
        # thing for anything done to those pages; viz. reload the site.
        case "${sub_dir}:${event_type}:${file_type}:${file_status}" in
            [!.public.]*:*:*:* )
                # Gate events to process.
                # Skip event immediately when NOT for a `public` file.
            ;;
            # RELOAD
            # - When any content file is modified
            # - When any non-current content file is deleted
            #   (because that may affect the current page)
            *:MODIFY:html:SAMEFILE ) ;& # catch vim edits
            *:CLOSE_WRITE:CLOSE:html:SAMEFILE ) ;& # catch emacs edits
            *:DELETE:html:NEWFILE )
                __shite_xdo_cmd_browser_refresh ${window_id}
                ;;
            # GOTO - NAVIGATE
            # - Newly-created content file, or
            # - Moved/renamed content file
            *:MODIFY:html:NEWFILE ) ;& # vim new file
            *:CLOSE_WRITE:CLOSE:html:NEWFILE ) ;& # emacs new file
            *:CREATE:html:* ) ;&
            *:MOVED_TO:html:* )
                __shite_xdo_cmd_goto_url \
                    ${window_id} \
                    "${base_url}/${sub_dir}/${file_name}"
                ;;
            # GOTO - FALLBACK
            # - home page when the current content file is deleted
            *:DELETE:html:SAMEFILE )
                __shite_xdo_cmd_goto_url \
                    ${window_id} \
                    "${base_url}/index.html"
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
    # In debug mode, only show the actions, don't do them.
    if [[ ${SHITE_DEBUG} == "debug" ]]
    then cat -
    else stdbuf -oL grep -v '^$' | xdotool -
    fi
}

shite_hotreload() {
    # Maybe improve with getopts later
    local watch_dir=${1:?"Fail. Please specify a directory to watch"}
    local tab_name=${2:?"Fail. We want to target a single specific tab only."}
    local browser_name=${3:?"Fail. We expect a browser name like \"Mozilla Firefox\"."}
    local base_url=${4:?"Fail. We expect a base URL like `file://`"}

    # LOOKUP WINDOW ID
    local window_id=$(xdotool search --onlyvisible --name "${tab_name}.*${browser_name}$")

    SHITE_DEBUG="debug" __log_info \
               $(printf "%s" "Hotreloadin' your shite now! " \
                        "'{" \
                        "\"watch_dir\": \"$(realpath ${watch_dir})\", "\
                        "\"tab_name\": \"${tab_name}\", " \
                        "\"browser_name\": \"${browser_name}\", " \
                        "\"base_url\": \"${base_url}\", " \
                        "\"window_id\": \"${window_id}\"" \
                        "}'")

    # RUN PIPELINE
    # Watch all files we care about, across content, static, public,
    # for events of interest: 'create,modify,close_write,moved_to,delete'
    __shite_detect_changes \
        ${watch_dir} 'create,modify,close_write,moved_to,delete' |
        # Construct events records as a CSV (consider JSON, if jq isn't too expensive)
        __shite_events_gen_csv ${watch_dir} |
        # Deduplicate file events
        __shite_events_dedupe |
        # Process changes to non-public files (static, pages, posts etc.)
        # and CRUD corresponding files in the public directory
        tee >(__tap_stream | shite_publish) |
        # Perform hot-reload actions only against changes to public files
        tee >(__shite_xdo_cmd_public_events ${window_id} ${base_url} |
                  __tap_stream |
                  __shite_xdo_cmd_exec)
}
