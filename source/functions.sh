#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

source "${1:-"$(cd "$(dirname "${0}")" && pwd)/config.sh"}"
source "${_HOME_DIR}"/source/common-functions.sh

monitor() {
  local -r __msg="${1}"
  local -r __msg_type="${2:-"${_INFO}"}"
  if "${_ENABLE_LOGGING}"; then log "${__msg}" "${__msg_type}" "${_FBA_PING_FAILED_EVENTS_LOG}"; fi
  debug "${__msg}" "${__msg_type}"
}

process_ping_mfa_success_log_event() {
  local -r __log_event="${1}"
  debug "MFA Success Event Received"
  if test -f "${_FBA_BATCH_MFA_EVENTS_FILE}"; then
    local -r __success_event_pattren="$(echo "${__log_event}" | cut -d'|' -f2-10)"
    local -r __inprogress_event_time_epoch="$(cat "${_FBA_BATCH_MFA_EVENTS_FILE}" | grep -iw "${__success_event_pattren}" |
      awk -F "${_MFA_EPOCH_SEPARATOR}" '{ print $NF}' | sort -n | tail -1)" || ""
    if test ! -z "${__inprogress_event_time_epoch}"; then
      local -r __event_time="$(echo "${__log_event}" | cut -d'|' -f1)"
      local -r __event_time_epoch="$(get_epoch_time "${__event_time}")"
      local -r __time_gap_allowed="$(echo "60*${_MFA_FAILED_PERIOD_MIN}" | bc)"
      local -r __time_difference="$(echo "${__event_time_epoch} - ${__inprogress_event_time_epoch}" | bc)"
      if [ "$__time_difference" -le "$__time_gap_allowed" ]; then
        local -r __inprogress_matched_event="$(grep -iw "${__success_event_pattren}.*${__inprogress_event_time_epoch}" "${_FBA_BATCH_MFA_EVENTS_FILE}" | tail -1)"
        local -r __content_to_keep="$(grep -v "${__inprogress_matched_event}" "${_FBA_BATCH_MFA_EVENTS_FILE}")" || ""
        echo "${__content_to_keep}" >"${_FBA_BATCH_MFA_EVENTS_FILE}"
      fi
    fi
  fi
}

validate_log_event() {
  local __r=1
  local -r __log_event="${1}"
  local -r __pattern="${2}"
  echo "${__log_event}" |
    grep -Eiw "${__pattern}" |
    awk -F '[||]' '{ sub(/^[ \t]+/, "", $4); sub(/[ \t]+$/, "", $4); print $4}' |
    grep -q . && __r=0
  debug "${__log_event} - Valid Event - Result "${__r}""
  return "${__r}"
}

validate_ping_log_event() {
  local __r=1
  local -r __log_event="${1}"
  local -r __failed_attempt_pattern="AUTHN_ATTEMPT\|.*inprogress\|.*${_IDP_HTML_FORM_ID}\|"
  local -r __lockedout_attempt_pattern="AUTHN_ATTEMPT\|.*failure\|.*${_IDP_HTML_FORM_ID}\| Account Locked\|"
  local -r __mfa_idp_id="$(echo "${_IDP_MFA_ID}" | awk '{ sub(/^[ \t]+/, "", $0); sub(/[ \t]+$/, "", $0); print $0}')"
  if ! test -z "${__mfa_idp_id}"; then
    local -r __inprogress_mfa_pattern="AUTHN_ATTEMPT\|.*inprogress\|.*${_IDP_MFA_ID}\|"
    local -r __success_mfa_pattern="AUTHN_ATTEMPT\|.*success\|.*${_IDP_MFA_ID}\|"
    validate_log_event "${__log_event}" "${__failed_attempt_pattern}|${__lockedout_attempt_pattern}|${__inprogress_mfa_pattern}|${__success_mfa_pattern}" &&
      __r=0
  else
    validate_log_event "${__log_event}" "${__failed_attempt_pattern}|${__lockedout_attempt_pattern}" &&
      __r=0
  fi
  return "${__r}"
}

is_mfa_event() {
  local __r=1
  local -r __log_event="${1}"
  echo "${__log_event}" | grep -iw "${_IDP_MFA_ID}" | grep -q . && __r=0
  return "${__r}"
}

is_success_event() {
  local __r=1
  local -r __log_event="${1}"
  echo "${__log_event}" | grep -iw "success" | grep -q . && __r=0
  return "${__r}"
}

validate_fba_user() {
  local __r=1
  local -r __log_event="${1}"
  local -r __user="$(echo "${__log_event}" | awk -F '[||]' '{ sub(/^[ \t]+/, "", $4); sub(/[ \t]+$/, "", $4); print $4}')"
  if ! test -z "${__user}"; then
    local -r __fba_user=$(utf8_encode_string "${__user}")
    curl -s "${_RISK_EXPORTER_API}""${_USER_RISK_ENDPOINT}""${__fba_user}" | grep -q -v '"risk_level":-1' && __r=0
  fi
  debug "${__user} - Valid User - Result "${__r}""
  return "${__r}"
}

send_fba_event() {
  local __r=1
  local -r __log_event="${1}"
  local -r __email=$(echo "${__log_event}" | awk -F '[||]' '{ sub(/^[ \t]+/, "", $4); sub(/[ \t]+$/, "", $4); printf $4}')
  local -r __host=$(echo "${__log_event}" | awk -F '[||]' '{ sub(/^[ \t]+/, "", $9); sub(/[ \t]+$/, "", $9); printf $9}')
  local -r __adapter=$(echo "${__log_event}" | awk -F '[||]' '{ sub(/^[ \t]+/, "", $12); sub(/[ \t]+$/, "", $12); printf $12}')
  local -r __description=$(echo "${__log_event}" | awk -F '[||]' '{ sub(/^[ \t]+/, "", $13); sub(/[ \t]+$/, "", $13); printf $13}')
  local -r __event_timestamp=$(echo "${__log_event}" | awk -F'[||]' '{print $1}' | awk -F ' ' '{printf "%sT%s\n", $1, $2}' |
    awk '{gsub(",","."); printf $0}')
  local -r __time_zone=$(date +"%z")
  local -r __iso_timestamp="${__event_timestamp}""${__time_zone}"
  local -r __fba_event_pattern_start="{\"timestamp\": \"%s\", 
         \"type\": \"authentication\", 
         \"entities\": [{\"entities\": [\"%s\"], \"role\": \"User\"}], 
         \"attributes\": [{\"type\": \"string\", \"name\": \"Vendor\", \"value\": \"Ping Federate\"}, 
                          {\"type\": \"boolean\", \"name\": \"Success\", \"value\": false}, 
                          {\"type\": \"string\", \"name\": \"Host\", \"value\": \"%s\"},
                          {\"type\": \"string\", \"name\": \"Adapter\", \"value\": \"%s\"}"
  local -r __fba_event_pattern_desc=",{\"type\": \"string\", \"name\": \"Description\", \"value\": \"%s\"}"
  local -r __fba_event_pattern_end="]}"
  if ! test -z "${__description}"; then
    local -r __fba_event_pattern="${__fba_event_pattern_start}${__fba_event_pattern_desc}${__fba_event_pattern_end}"
    local -r __fba_event="$(printf "${__fba_event_pattern}" "${__iso_timestamp}" "${__email}" "${__host}" "${__adapter}" "${__description}")"
  else
    local -r __fba_event_pattern="${__fba_event_pattern_start}${__fba_event_pattern_end}"
    local -r __fba_event="$(printf "${__fba_event_pattern}" "${__iso_timestamp}" "${__email}" "${__host}" "${__adapter}")"
  fi
  curl -s -XPOST "${_FBA_EVENT_API}"/event \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "${__fba_event}" | grep -q '"acknowledged":true' && __r=0
  debug "${__iso_timestamp}: ${__email} - Event Attempt Sent - Result "${__r}""
  return "${__r}"
}

process_now() {
  local -r __log_event="${1}"
  validate_fba_user "${__log_event}" && send_fba_event "${__log_event}"
  return "${?}"
}

process_mfa() {
  local -r __log_event="${1}"
  validate_fba_user "${__log_event}" && {
    is_success_event "${__log_event}" &&
      process_ping_mfa_success_log_event "${__log_event}" || {
      local -r __event_timestamp="$(echo "${__log_event}" | cut -d'|' -f1)"
      local -r __event_timestamp_epoch="$(get_epoch_time "${__event_timestamp}")"
      local -r __number_of_columns="$(echo "${__log_event}" | awk -F "${_MFA_EPOCH_SEPARATOR}" '{print NF}')"
      if [ "${__number_of_columns}" -gt 1 ]; then
        process_later "${__log_event}" "${_FBA_BATCH_MFA_EVENTS_FILE}"
      else
        debug "MFA Inprogress Event"
        process_later "${__log_event} ${_MFA_EPOCH_SEPARATOR} ${__event_timestamp_epoch}" "${_FBA_BATCH_MFA_EVENTS_FILE}"
      fi
    }
  }
  return "${?}"
}

fba_services_status() {
  local __r=1
  curl -s "${_RISK_EXPORTER_API}${_RISK_API_HEALTH_ENDPOINT}" |
    grep -q 'Risk Exporter Service' &&
    __r=0 ||
    error "Risk Exporter Service is not reachable"
  curl -s "${_FBA_EVENT_API}" |
    grep -q 'Reveal Public API' &&
    __r=0 ||
    error "FBA API is not reachable"
  test "${__r}" -eq 0 && info "FBA Services are UP"
  return "${__r}"
}

are_fba_services_up() {
  local __r=1
  curl -s "${_RISK_EXPORTER_API}${_RISK_API_HEALTH_ENDPOINT}" |
    grep -q 'Risk Exporter Service' && {
    curl -s "${_FBA_EVENT_API}" |
      grep -q 'Reveal Public API' &&
      __r=0 || monitor "FBA Reveal Public API is not reachable!" "${_ERROR}"
  } || monitor "FBA Risk Exporter Service is not reachable!" "${_ERROR}"
  return "${__r}"
}

process_fba_event() {
  read __input
  local -r __log_event="${__input}"
  debug "${__log_event} - Event Received"
  [[ -f "${_LAST_EVENT_PROCESSED_FILE}" ]] || {
    touch "${_LAST_EVENT_PROCESSED_FILE}" && chmod ugo+rw "${_LAST_EVENT_PROCESSED_FILE}"
  }
  echo "${__log_event}" | awk -F'[||]' '{print $1}' >"${_LAST_EVENT_PROCESSED_FILE}"
  validate_ping_log_event "${__log_event}" && {
    if are_fba_services_up; then
      is_mfa_event "${__log_event}" && process_mfa "${__log_event}" || process_now "${__log_event}"
    else
      process_later "${__log_event}" "${_FBA_BATCH_EVENTS_FILE}"
    fi
  }
}

process_fba_batch_event() {
  read __input
  local -r __log_event="${__input}"
  local -r __mfa_batch_event="${1:-false}"
  debug "${__log_event} - Batch Event Received"
  if are_fba_services_up; then
    if "${__mfa_batch_event}"; then
      process_now "${__log_event}"
    else
      is_mfa_event "${__log_event}" && process_mfa "${__log_event}" || process_now "${__log_event}"
    fi
  else
    process_later "${__log_event}" "${_FBA_BATCH_EVENTS_FILE}"
  fi
}

mfa_file_content_split() {
  local -r __original_file="${1}"
  local -r __operation_file="${2}"
  if [[ -f "${__original_file}" && -s "${__original_file}" ]]; then
    local -r __current_timestamp="$(date)"
    local -r __current_timestamp_epoch="$(get_epoch_time "${__current_timestamp}")"
    local -r __time_gap_allowed="$(echo "60*${_MFA_FAILED_PERIOD_MIN}" | bc)"
    local -r __clear_up_to_epoch_time="$(echo "${__current_timestamp_epoch} - ${__time_gap_allowed}" | bc)"
    local -r __content_to_process="$(cat "${__original_file}" | awk -v __match_value="${__clear_up_to_epoch_time}" -F "${_MFA_EPOCH_SEPARATOR}" '$NF < __match_value' | grep .)" || ""
    if test ! -z "${__content_to_process}"; then
      echo "${__content_to_process}" >>"${__operation_file}"
    fi
    local -r __content_to_keep="$(cat "${__original_file}" | awk -v __match_value="${__clear_up_to_epoch_time}" -F "${_MFA_EPOCH_SEPARATOR}" '$NF >= __match_value' | grep .)" || ""
    if test ! -z "${__content_to_keep}"; then
      echo "${__content_to_keep}" >"${__original_file}"
    else
      echo -n "" >"${__original_file}"
    fi
  fi
}

process_fba_events_file() {
  local -r __target_file="${1}"
  local -r __mfa_process="${2:-false}"
  monitor "process_fba_events_file started for "${__target_file}""
  if test -f "${__target_file}"; then
    local -r __operation_file="${__target_file}-temp"
    if "${__mfa_process}"; then
      monitor "Processing MFA events started"
      mfa_file_content_split "${__target_file}" "${__operation_file}"
    else
      monitor "Processing missed events started"
      cat "${__target_file}" >>"${__operation_file}" && echo -n "" >"${__target_file}"
    fi
    if [[ -f "${__operation_file}" && -s "${__operation_file}" ]]; then
      local -r __number_of_lines="$(wc -l <"${__operation_file}")"
      local __current_line_number=1
      while [ $__current_line_number -le $__number_of_lines ]; do
        local __log_event=$(head -n $__current_line_number "${__operation_file}" | tail -1) || ""
        echo "${__log_event}" | process_fba_batch_event "${__mfa_process}" || true
        ((__current_line_number++))
      done
      echo -n "" >"${__operation_file}"
      monitor "${__number_of_lines} events has been processed"
    else
      monitor "No events to process"
    fi
  fi
}

process_previous_ping_events() {
  monitor "Process previous events started"
  test -f "${_LAST_EVENT_PROCESSED_FILE}" && __last_event="$(tail -n 1 "${_LAST_EVENT_PROCESSED_FILE}")" || __last_event=""
  echo "${__last_event}" |
    grep -q . && {
    monitor "First previous event is starting from ${__last_event}" &&
      awk -v __event_time="${__last_event}" '$0~__event_time,EOF' "${_PING_AUDIT_LOG}" |
      tail -n +1 | {
        while read __log_event; do
          echo "${__log_event}" | process_fba_event || true
        done
      }
  } || monitor "No previous events to process"
}

monitor_streamed_events() {
  monitor "Monitor streamed log events started"
  tail -F -n 1 "${_PING_AUDIT_LOG}" | while read __log_event; do echo "${__log_event}" | process_fba_event || true; done
}
