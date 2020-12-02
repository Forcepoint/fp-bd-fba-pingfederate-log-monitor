#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _parent_dir="$(cd "$(dirname "${0}")"/.. && pwd)"
source "${_parent_dir}"/source/common-config.sh

info() {
  local -r __msg="${1}"
  local -r __nobreakline="${2:-""}"
  test ! -z "${__nobreakline}" &&
    printf "${_BOLD_WHITE}${__msg}${_NO_COLOR}" ||
    printf "${_BOLD_WHITE}${__msg}${_NO_COLOR}\n"
}

warning() {
  local -r __msg="${1}"
  printf "${_BOLD_YELLOW}[${_WARNING}] ${__msg}${_NO_COLOR}\n"
}

error() {
  local -r __msg="${1}"
  printf "${_BOLD_RED}[${_ERROR}] ${__msg}${_NO_COLOR}\n"
}

debug() {
  if "${_ENABLE_DEBUG}"; then
    local -r __msg="${1}"
    local -r __msg_type="${2:-"${_INFO}"}"
    if [[ "$__msg_type" != "${_ERROR}" ]]; then info "[${__msg_type}] ${__msg}"; else error "${__msg}"; fi
  fi
}

log() {
  local -r __msg="${1}"
  local -r __msg_type="${2:-"${_INFO}"}"
  local -r __log_file="${3:-"$(dirname "${0}")/../logs/out.log"}"
  local -r __time_and_date="$(date)"
  mkdir "$(dirname "${__log_file}")" 2>/dev/null && chmod ugo+rw "$(dirname "${__log_file}")"
  [[ -f "${__log_file}" ]] || {
    touch "${__log_file}" && chmod ugo+rw "${__log_file}"
  }
  printf "[${__time_and_date}] [${__msg_type}] ${__msg}\n" >>"${__log_file}"
}

validate_prerequisites() {
  local __r=0
  local __prerequisites=("$@")
  local __clear_previous_display="\r\033[K"
  for prerequisite in "${__prerequisites[@]}"; do
    echo -en "${__clear_previous_display}Prerequisite - ${prerequisite} - check" && sleep 0.1
    command -v ${prerequisite} >/dev/null 2>&1 || {
      error "${__clear_previous_display}We require >>> ${prerequisite} <<< but it's not installed. Please try again after installing ${prerequisite}." &&
        __r=1 &&
        break
    }
  done
  echo -en "${__clear_previous_display}"
  return "${__r}"
}

process_later() {
  local -r __log_event="${1}"
  local -r __target_file="${2}"
  [[ -f "${__target_file}" ]] || {
    touch "${__target_file}" && chmod ugo+rw "${__target_file}"
  }
  echo "${__log_event}" >>"${__target_file}"
  return "${?}"
}

utf8_encode_string() {
  local -r __input="${1}"
  local __character
  local __pos
  local __output=""
  for ((__pos = 0; __pos < "${#__input}"; __pos++)); do
    __character="${__input:$__pos:1}"
    case "${__character}" in
    [-_.~a-zA-Z0-9]) __output+="${__character}" ;;
    *) __output+="$(printf '%%%02x' "'${__character}")" ;;
    esac
  done
  echo "${__output}"
}

get_epoch_time() {
  local -r __event_time="${1}"
  local -r __epoch_time="$(echo "$(date -d "${__event_time}" "+%s")")"
  echo "${__epoch_time}"
}
