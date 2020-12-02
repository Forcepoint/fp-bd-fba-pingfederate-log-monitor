#!/usr/bin/env bash

set -o pipefail
set -o nounset

main() {
    export readonly _TEST_DIR="$(cd "$(dirname "${0}")" && pwd)"
    cd "${_TEST_DIR}"
    find . -maxdepth 1 -type f -iname "*tests.sh" | while read __test_files; do ${__test_files}; done
}

main "$@"
