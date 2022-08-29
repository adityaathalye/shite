#!/usr/bin/env bash

__to_stderr() {
    # Ref: I/O Redirection: http://tldp.org/LDP/abs/html/io-redirection.html
    if [[ ${SHITE_DEBUG} == "debug" ]]
    then 1>&2 printf "%s\n" "$(date --iso-8601=seconds) $@"
    fi
}

__log_info() {
    __to_stderr "$(echo "INFO $0 $@")"
}

__tap_stream() {
    tee >(1>&2 cat -)
}
