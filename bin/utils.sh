#!/usr/bin/env bash

__to_stderr() {
    # Ref: I/O Redirection: http://tldp.org/LDP/abs/html/io-redirection.html
    1>&2 printf "%s\n" "$(date --iso-8601=seconds) $@"
}

__log_info() {
    __to_stderr "$(echo "INFO $0 $@")"
}

__tap_stream() {
    tee >(1>&2 cat -)
}
