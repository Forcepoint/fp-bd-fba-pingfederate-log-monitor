#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly __config_file="${1:-"${_dir}/config.sh"}"

source "${_dir}"/functions.sh "${__config_file}"

main() {
    process_previous_ping_events || true
    monitor_streamed_events
}

main "$@"
