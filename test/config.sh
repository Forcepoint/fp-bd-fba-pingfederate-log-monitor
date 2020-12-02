#!/usr/bin/env bash

set -o pipefail
set -o nounset

# Test Configs
readonly _HOME_DIR="${_TEST_DIR}/../source"
readonly _TEST_FILES_DIR="${_TEST_DIR}/test-files"

# Other Configs
readonly _MFA_FAILED_PERIOD_MIN=3
readonly _MFA_EPOCH_SEPARATOR="EPOCHTIMEFBA"
readonly _PING_AUDIT_LOG_NAME='audit.log'
readonly _LAST_EVENT_PROCESSED_FILE="${_TEST_FILES_DIR}/last-event-proccessed-file"
readonly _FBA_BATCH_EVENTS_FILE="${_TEST_FILES_DIR}/fba-batch-events-file"
readonly _FBA_BATCH_MFA_EVENTS_FILE="${_TEST_FILES_DIR}/fba-batch-mfa-events-file"
readonly _PING_AUDIT_LOG="${_TEST_FILES_DIR}/${_PING_AUDIT_LOG_NAME}"
readonly _FBA_PING_FAILED_EVENTS_LOG="${_TEST_FILES_DIR}/logs/fba-ping-events.log"