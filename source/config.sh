#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _HOME_DIR="$(cd "$(dirname "${0}")"/.. && pwd)"
source "${_HOME_DIR}"/user-config.sh

readonly _MFA_FAILED_PERIOD_MIN=3
readonly _MFA_EPOCH_SEPARATOR="EPOCHTIMEFBA"
readonly _PING_AUDIT_LOG_NAME='audit.log'
readonly _LAST_EVENT_PROCESSED_FILE="${_HOME_DIR}/last-event-proccessed-file"
readonly _FBA_BATCH_EVENTS_FILE="${_HOME_DIR}/fba-batch-events-file"
readonly _FBA_BATCH_MFA_EVENTS_FILE="${_HOME_DIR}/fba-batch-mfa-events-file"
readonly _PING_AUDIT_LOG="${_PING_AUDIT_LOG_DIR}/${_PING_AUDIT_LOG_NAME}"
readonly _FBA_PING_FAILED_EVENTS_LOG="${_HOME_DIR}/logs/fba-ping-events.log"
readonly _USER_CONFIG_FILE="${_HOME_DIR}/user-config.sh"
readonly _USER_RISK_ENDPOINT=/"${_FORCEPOINT_RISK_SCORE_SOURCE}"/risk/score/
readonly _RISK_API_HEALTH_ENDPOINT=/riskexporter
