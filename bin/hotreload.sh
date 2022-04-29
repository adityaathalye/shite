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
# Refresh current tab when
# - static asset create, modify, move, delete
#
# Go home when
# - current page deleted
#
# Navigate to content when
# - current page content modified
# - any content page moved or created or modified


__shite_refresh_browser_tab() {
    local browser_name=${1:-"firefox"}
    local tab_name=${2:-'*'}

    xdotool search --onlyvisible --name "${tab_name}.*${browser_name}$" \
            key --clearmodifiers --window %@ 'F5'
}

__shite_detect_changes() {
    local dir_path="${1:-.}"

    inotifywait -m -r --exclude '/\.git/|/\.#|/#' \
                --format '%e %w%f' \
                -e 'modify,moved_to,moved_from,move,create,delete' \
                ${dir_path}
}

__shite_is_reload_page_event() {
    # truthy/falsey
    # return the event as-is /when/ it implies reload
    false
}

__shite_is_goto_page_event() {
    # truthy/falsey
    # return the event as-is /when/ it implies navigate to page
    false
}
