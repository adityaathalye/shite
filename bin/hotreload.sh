#!/usr/bin/env bash

# ##################################################
# Functions to drive browser hot reload.
#
# USAGE
#
# Source these files and call the shite_hot_build_reload function:
#
#   source ./bin/utils.sh
#   source ./bin/events.sh
#   source ./bin/hotreload.sh
#
#   shite_hot_build_reload [WATCH DIR] [BROWSER TAB NAME] \
#                   [OPTIONAL BROWSER NAME] \
#                   [OPTIONAL BASE URL]
#
# It assumes Mozilla Firefox and file:// based navigation by default.
#
#
# EXAMPLES
#
#   shite_hot_build_reload "public" 'A site'
#
#   shite_hot_build_reload "public" 'A site' "Google Chrome"
#
#   shite_hot_build_reload "public" 'A site' "Google Chrome" "http://localhost:8080"
#
#
# LOGIC
#
# Given a stream of event records, in shite's "canonical" CSV record structure:
# - INTERPRET events and generate commands to feed to a command executor
#   - "Content" (html) file changes require special handling
#   - "Static" (css,js,img) file changes only ever trigger page reload
# - EXECUTE the incoming commands in a streaming fashion
#
#
# WARNINGS
#
# Beware of stdio buffering. Use stdbuf to control it.
#
# Some tools like grep and awk buffer their output and thus block downstream
# actions. But we want instant reaction time. So those buffers are bad for us.
#
# Luckily stdbuf is a general way to tune buffering behaviour. We can work
# with line-buffered output streaming. e.g.:
#
#   stdbuf -oL grep something
#
# c.f https://www.perkin.org.uk/posts/how-to-fix-stdio-buffering.html
# ##################################################


# ##################################################
# BROWSER COMMAND INTERPRETER FOR FILE EVENTS
# ##################################################

__shite_hot_cmd_browser_refresh() {
    local window_id=${1:?"Fail. We expect window ID to be set in scope."}

    printf "%s\n" \
           "key --window ${window_id} --clearmodifiers 'F5'"
}

__shite_hot_cmd_goto_url() {
    local window_id=${1}
    local url=${2}

    printf "%s\n" \
           "key --window ${window_id} --clearmodifiers 'ctrl+l'" \
           "type --window ${window_id} --clearmodifiers --delay 1 ${url}" \
           "key --window ${window_id} --clearmodifiers 'Return'"
}

__shite_hot_cmd_public_events() {
    # Consume the shite event stream and generate xdotool commands to drive
    # browser navigation, based on information like event type, file type,
    # and how the public file has changed (updated, deleted, moved etc.).
    #
    # The browser should react only to changes in the `public` directory,
    # so we select only those events.
    #
    # This interpreter:
    #
    # - Ignores events for non-public files
    # - Generates special commands depending on type of modifications to HTML
    #   "content" pages
    # - Emits a catch-all page reload command for events for non-"content"
    #   files. i.e. "Reload page" is the only sane thing to do when, say,
    #   some CSS or JS or image changes.
    #
    local window_id=${1:?"Fail. We expect a window ID."}
    local base_url=${2:?"Fail. We expect a base url."}
    local file_status
    local prev_file_name

    # Process events only for `public` files.
    __shite_events_select_public |
        # Generate commands for browser hot reload / navigate.
        while IFS=',' read -r timestamp event_type watch_dir sub_dir url_slug file_name file_type content_type
        do
            file_status=$(
                if [[ ${file_name} == ${prev_file_name} ]]
                then printf "%s" "SAMEFILE"
                else printf "%s" "NEWFILE"
                fi
                       )

            case "${event_type}:${file_type}:${file_status}" in
                # RELOAD
                # - When any content file is modified
                # - When any non-current content file is deleted
                #   (because that may affect the current page)
                MODIFY:html:SAMEFILE ) ;& # catch vim edits
                CLOSE_WRITE:CLOSE:html:SAMEFILE ) ;& # catch emacs edits
                DELETE:html:NEWFILE )
                    __shite_hot_cmd_browser_refresh ${window_id}
                    ;;
                # GOTO - NAVIGATE
                # - Newly-created content file, or
                # - Moved/renamed content file
                MODIFY:html:NEWFILE ) ;& # vim new file
                CLOSE_WRITE:CLOSE:html:NEWFILE ) ;& # emacs new file
                CREATE:html:* ) ;&
                MOVED_TO:html:* )
                    __shite_hot_cmd_goto_url \
                        ${window_id} \
                        "${base_url}/${url_slug}/${file_name}"
                    ;;
                # GOTO - FALLBACK
                # - home page when the current content file is deleted
                DELETE:html:SAMEFILE )
                    __shite_hot_cmd_goto_url \
                        ${window_id} \
                        "${base_url}/index.html"
                    ;;
                # RELOAD page for any action on non-content pages,
                # presumably static assets.
                * )
                    __shite_hot_cmd_browser_refresh ${window_id}
                    ;;
            esac

            # Remember the file for the next cycle
            prev_file_name=${file_name}
        done
}


# ##################################################
# COMMAND EXECUTOR
# ##################################################

__shite_hot_cmd_exec() {
    # In debug mode, only show the actions, don't do them.
    if [[ ${SHITE_DEBUG} == "debug" ]]
    then cat -
    else stdbuf -oL grep -v '^$' | xdotool -
    fi
}

shite_hot_build_reload() {
    # React to various file events, hot-build-and-publish `sources` to `public`,
    # and then hot-reload (navigate) the browser.
    #
    # Browser navigation will work only when the site's tab is currently active.
    # Hot build / publish works whether or not the tab is active.

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
    # Watch all files we care about, across sources (org, md, CSS, JS etc.), and
    # public (published HTML, CSS, JS etc.), for events of interest, viz.:
    # 'create,modify,close_write,moved_to,delete'
    __shite_events_detect_changes \
        ${watch_dir} 'create,modify,close_write,moved_to,delete' |
        # Construct events records as a CSV (consider JSON, if jq isn't too expensive)
        __shite_events_gen_csv ${watch_dir} |
        # Deduplicate file events
        __shite_events_dedupe |
        # Process changes to non-public files (static, pages, posts etc.)
        # and CRUD corresponding files in the public directory
        tee >(__tap_stream |
                  shite_publish_sources ${base_url:?"Fail. Base URL not set."} > /dev/null) |
        # Perform hot-reload actions only against changes to public files
        tee >(__shite_hot_cmd_public_events \
                  ${window_id:?"Fail. Window ID not set."} \
                  ${base_url:?"Fail. Base URL not set."} |
                  __tap_stream |
                  # to ensure only event record propogates, swallow any stdout
                  # emitted by command execution
                  __shite_hot_cmd_exec > /dev/null)
}
