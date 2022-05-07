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
    # Emit a CSV record of UNIX_EPOCH_SECONDS,EVENT_TYPE,FILE_PATH
    local dir_path="${1:-$(pwd)/public}"
    local file_types="${2:-'html,js,css'}"

    # WATCH A DIRECTORY
    inotifywait -m -r --exclude '/\.git/|/\.#|/#|.*(swp|swx|\~)$' \
                --timefmt "%s" \
                --format '%T,%:e,%w%f' \
                -e 'create,modify,delete,moved_to' \
                ${dir_path} |
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

__shite_test_actions() {
    cp -f public/index.html public/deleteme.html
    echo "foo" >> public/deleteme.html
    mv public/deleteme.html public/deleteme2.html
    rm public/deleteme2.html
    # Should produce these "distinct" events:
    # 1652008576,MODIFY,/home/adi/src/github/adityaathalye/shite/public/deleteme.html
    # 1652008576,MOVED_TO,/home/adi/src/github/adityaathalye/shite/public/deleteme2.html
    # 1652008576,DELETE,/home/adi/src/github/adityaathalye/shite/public/deleteme2.html
}

__shite_test_events() {
    cat <<EOF
1651991204,CREATE,/home/adi/src/github/adityaathalye/shite/public/deleteme.html
1651991204,MODIFY,/home/adi/src/github/adityaathalye/shite/public/deleteme.html
1651991204,MODIFY,/home/adi/src/github/adityaathalye/shite/public/deleteme.html
1651991204,MOVED_TO,/home/adi/src/github/adityaathalye/shite/public/deleteme2.html
1651991204,DELETE,/home/adi/src/github/adityaathalye/shite/public/deleteme2.html
1651991221,CREATE,/home/adi/src/github/adityaathalye/shite/public/deleteme.html
1651991221,MODIFY,/home/adi/src/github/adityaathalye/shite/public/deleteme.html
1651991221,MODIFY,/home/adi/src/github/adityaathalye/shite/public/deleteme.html
EOF
}


__shite_event_cmd() {
    # Write-ahead log of event_type data, and commands to execute
    while IFS=',' read -r timestamp event_type filepath
    do
        case ${event_type} in
            MODIFY )
                echo "${event_type} implies Reload page ${filepath}"
                ;;
            CREATE|MOVED_TO )
                echo "${event_type} implies Goto new page ${filepath}"
                ;;
            DELETE )
                echo "${event_type} implies Goto home page ${filepath}"
                ;;
            * )
                echo "${event_type} implies No-op ${filepath}"
                ;;
        esac
    done
}

__shite_xdo_cmd_get_window() {
    local tab_name=${1:?"Fail. We want to target a single specific tab only."}
    local browser_name=${2:-"Mozilla Firefox"}

    printf "%s\n" \
           "search --onlyvisible --name \"${tab_name}.*${browser_name}$\""
}

__shite_xdo_cmd_browser_refresh() {
    local window_id=${1:?"Fail. We expect window ID to be set in scope."}
    printf "%s\n" \
           "key_path --window ${window_id} --clearmodifiers 'F5'"
}

__shite_xdo_cmd_goto_url() {
    local window_id=${1:?"Fail. We expect window ID to be set in scope."}
    local url=${2:-"http://localhost:1313"}
    printf "%s\n" \
           "key_path --window ${window_id} --clearmodifiers 'ctrl+l'" \
           "type --window ${window_id} --clearmodifiers --delay 1 \"${url}\"" \
           "key_path --window ${window_id} --clearmodifiers 'Return'"
}

__shite_xdo_cmd_exec() {
    # Presumably receives legal xdotool commands at stdin.
    # Empty lines imply no-op.
    local command_fn=${1:?"Fail. We expect a command function."}
    shift
    local command_fn_args="${@}"

    ${command_fn} "${command_fn_args}" |
        grep -v '^$' |
        xdotool -
}
