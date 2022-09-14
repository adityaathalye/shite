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
    local url_status
    local prev_url_slug

    # Process events only for relevant `public` files.
    __shite_events_select_public |
        __shite_events_drop_public_noisy_events |
        # Generate commands for browser hot reload / navigate.
        while IFS=',' read -r timestamp event_type watch_dir sub_dir url_slug file_type content_type
        do
            # TODO: Find a cleaner alternative. This stateful logic messes up
            # occasionally, especially when I also click about the site manually.
            # It's not annoying UX-wise, just annoying that the bug exists.
            url_status=$(
                if [[ "${url_slug}" == "${prev_url_slug}" ]]
                then printf "%s" "SAMEURL"
                else printf "%s" "NEWURL"
                fi
                       )

            case "${event_type}:${file_type}:${url_status}" in
                # RELOAD
                # - When any content file is modified
                # - When any non-current content file is deleted
                #   (because that may affect the current page)
                MODIFY:html:SAMEURL ) ;& # catch vim edits
                CLOSE_WRITE:CLOSE:html:SAMEURL ) ;& # catch emacs edits
                DELETE:html:NEWURL )
                    __shite_hot_cmd_browser_refresh ${window_id}
                    ;;
                # GOTO - NAVIGATE
                # - Newly-created content file, or
                # - Moved/renamed content file
                MODIFY:html:NEWURL ) ;& # vim new file
                CLOSE_WRITE:CLOSE:html:NEWURL ) ;& # emacs new file
                CREATE:html:* ) ;&
                MOVED_TO:html:* )
                    __shite_hot_cmd_goto_url \
                        ${window_id} \
                        "${base_url}/${url_slug}"
                    ;;
                # GOTO - FALLBACK
                # - home page when the current content file is deleted
                DELETE:html:SAMEURL )
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
            prev_url_slug=${url_slug}
        done
}


# ##################################################
# COMMAND EXECUTOR
# ##################################################

__shite_hot_cmd_exec() {
    # In debug mode, only show the actions, don't do them.
    if [[ ${SHITE_DEBUG} == "debug" ]]
    then cat -
    else stdbuf -oL grep -v '^$' | __tap_stream | xdotool -
    fi
}

shite_hot_browser_reload() {
    local browser_window_id=${1:?"Fail. Window ID not set."}
    local base_url=${base_url:?"Fail. Base URL not set."}
    __shite_hot_cmd_public_events ${browser_window_id} ${base_url} |
        __shite_hot_cmd_exec
}

shite_hot_build_reload() {
    # React to various file events, hot-build-and-publish `sources` to `public`,
    # and then hot-reload (navigate) the browser.
    #
    # Browser navigation will work only when the site's tab is currently active.
    # Hot build / publish works whether or not the tab is active.

    # Maybe improve with getopts later
    local watch_dir=${1:?"Fail. Please specify a directory to watch"}
    local browser_name=${2:?"Fail. We expect a browser name like \"Mozilla Firefox\"."}
    local base_url=${3:?"Fail. We expect a base URL like `file://`"}

    # LOOKUP WINDOW ID
    local window_id=$(xdotool search --onlyvisible --name ".*${browser_name}$")

    __log_info $(printf "%s" "Hotreloadin' your shite now! " \
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
    shite_events_stream ${watch_dir} 'create,modify,close_write,moved_to,delete' |
        # Copy events stream to stderr for observability and debugging
        __tap_stream |
        # React to source events and CRUD public files
        tee >(shite_templating_publish_sources ${base_url} > /dev/null) |
        # Perform hot-reload actions only against changes to public files
        tee >(shite_hot_browser_reload ${window_id} ${base_url}) |
        # Trigger rebuilds of metadata indices
        tee >(shite_metadata_rebuild_indices)
}
