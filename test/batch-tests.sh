#!/usr/bin/env bash

set -o pipefail
set -o nounset

source "${_TEST_DIR}/config.sh"
source "${_TEST_DIR}/test-util.sh"

readonly __fba_up_config="${_TEST_DIR}/fba-up-config.sh"
readonly __fba_down_config="${_TEST_DIR}/fba-down-config.sh"
readonly __fba_ping_batch_script="${_HOME_DIR}/run-fba-ping-batch-events.sh"

test-fba-down() {
    # Expected Result
    local __expected_return_code=1
    # When
    "${__fba_ping_batch_script}" "${__fba_down_config}"
    # Actual Result
    local __actual_return_code=$?
    expected-return-code "${0}" "${FUNCNAME[0]}" "${__expected_return_code}" "${__actual_return_code}"
}

test-fba-up-no-batch-file() {
    # Expected Result
    local __expected_return_code=0
    # When
    "${__fba_ping_batch_script}" "${__fba_up_config}"
    # Actual Result
    local __actual_return_code=$?
    expected-return-code "${0}" "${FUNCNAME[0]}" "${__expected_return_code}" "${__actual_return_code}"
}

test-fba-up-empty-batch-file() {
    # Expected Result
    local __expected_return_code=0
    # Prep
    local __validation_number=1 # Validation 1
    touch "${_FBA_BATCH_EVENTS_FILE}"
    local -r __operation_file="${_FBA_BATCH_EVENTS_FILE}-temp"
    # When
    "${__fba_ping_batch_script}" "${__fba_up_config}"
    # Actual Result
    local __actual_return_code=$?
    expected-return-code "${0}" "${FUNCNAME[0]}" "${__expected_return_code}" "${__actual_return_code}" "${__validation_number}"

    # Expected Result
    __expected_return_code=0
    # Prep
    ((__validation_number++)) # Post operation validation - 2
    # Actual Result
    test ! -f "${_LAST_EVENT_PROCESSED_FILE}" &&
        test -f "${_FBA_BATCH_EVENTS_FILE}" && ! test -s "${_FBA_BATCH_EVENTS_FILE}" &&
        test -f "${__operation_file}" && ! test -s "${__operation_file}"

    __actual_return_code=$?
    expected-return-code "${0}" "${FUNCNAME[0]}" "${__expected_return_code}" "${__actual_return_code}" "${__validation_number}"

    # Clean Up
    rm -f "${_FBA_BATCH_EVENTS_FILE}" "${__operation_file}"
}

test-fba-up-batch-file-with-data() {
    # Expected Result
    local __expected_return_code=0
    # Prep
    local __validation_number=1 # Validation 1
    get-batch-event-test-data >"${_FBA_BATCH_EVENTS_FILE}"
    local -r __operation_file="${_FBA_BATCH_EVENTS_FILE}-temp"
    # When
    "${__fba_ping_batch_script}" "${__fba_up_config}"
    # Actual Result
    local __actual_return_code=$?
    expected-return-code "${0}" "${FUNCNAME[0]}" "${__expected_return_code}" "${__actual_return_code}" "${__validation_number}"

    # Expected Result
    __expected_return_code=0
    # Prep
    ((__validation_number++)) # Post operation validation - 2
    # Actual Result
    test ! -f "${_LAST_EVENT_PROCESSED_FILE}" &&
        test -f "${_FBA_BATCH_EVENTS_FILE}" && ! test -s "${_FBA_BATCH_EVENTS_FILE}" &&
        test -f "${__operation_file}" && ! test -s "${__operation_file}"

    __actual_return_code=$?
    expected-return-code "${0}" "${FUNCNAME[0]}" "${__expected_return_code}" "${__actual_return_code}" "${__validation_number}"

    # Clean Up
    rm -f "${_LAST_EVENT_PROCESSED_FILE}" "${_FBA_BATCH_EVENTS_FILE}" "${__operation_file}"
}

main() {
    grep "^test-" $0 | awk '{print substr($0, 1, length($0)-4)}' | while read __test_function; do ${__test_function}; done
}

main "$@"
