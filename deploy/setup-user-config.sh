#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

source "$(dirname "${0}")/../source/config.sh"
source "${_HOME_DIR}"/source/common-functions.sh

setup_user_config_ping_log() {
    local -r __user_config_file="${1}"
    local __r=1
    info "Enter ping logs directory path: " "nobreakline"
    read __user_input
    local -r __content="$(awk '{gsub(/_PING_AUDIT_LOG_DIR=.*$/,"_PING_AUDIT_LOG_DIR='\'"${__user_input}"\''")}1' "${__user_config_file}")"
    echo "${__content}" >"${__user_config_file}" && __r=0
    return "${__r}"
}

setup_user_config_event_api() {
    local -r __user_config_file="${1}"
    local __r=1
    info "Enter FBA Event API URL e.g. https://fba-event-api-hostname:9000 : " "nobreakline"
    read __user_input
    local -r __content="$(awk '{gsub(/_FBA_EVENT_API=.*$/,"_FBA_EVENT_API='\'"${__user_input}"\''")}1' "${__user_config_file}")"
    echo "${__content}" >"${__user_config_file}" && __r=0
    return "${__r}"
}

setup_user_config_risk_api() {
    local -r __user_config_file="${1}"
    local __r=1
    info "Enter Risk Exporter API URL e.g. https://risk-exporter-api-hostname:port-number : " "nobreakline"
    read __user_input
    local -r __content="$(awk '{gsub(/_RISK_EXPORTER_API=.*$/,"_RISK_EXPORTER_API='\'"${__user_input}"\''")}1' "${__user_config_file}")"
    echo "${__content}" >"${__user_config_file}" && __r=0
    return "${__r}"
}

setup_user_config_html_idp() {
    local -r __user_config_file="${1}"
    local __r=1
    info "Enter HTML form identity provider (idp) adapter ID: " "nobreakline"
    read __user_input
    local -r __content="$(awk '{gsub(/_IDP_HTML_FORM_ID=.*$/,"_IDP_HTML_FORM_ID='\'"${__user_input}"\''")}1' "${__user_config_file}")"
    echo "${__content}" >"${__user_config_file}" && __r=0
    return "${__r}"
}

setup_user_config_mfa_idp() {
    local -r __user_config_file="${1}"
    local __r=1
    info "Enter MFA PingID identity provider (idp) adapter ID: " "nobreakline"
    read __user_input
    local -r __content="$(awk '{gsub(/_IDP_MFA_ID=.*$/,"_IDP_MFA_ID='\'"${__user_input}"\''")}1' "${__user_config_file}")"
    echo "${__content}" >"${__user_config_file}" && __r=0
    return "${__r}"
}

setup_user_config_logging() {
    local -r __user_config_file="${1}"
    local __r=1
    info "Would you like to turn on logs? [Y/N] " "nobreakline"
    read -r __user_input
    case "${__user_input}" in
    [yY])
        __content="$(awk '{gsub(/_ENABLE_LOGGING=.*$/,"_ENABLE_LOGGING=true")}1' "${__user_config_file}")"
        echo "${__content}" >"${__user_config_file}" && __r=0
        ;;
    [nN])
        __content="$(awk '{gsub(/_ENABLE_LOGGING=.*$/,"_ENABLE_LOGGING=false")}1' "${__user_config_file}")"
        echo "${__content}" >"${__user_config_file}" && __r=0
        ;;
    *) echo "" && error "Invalid option ${__user_input}" ;;
    esac
    return "${__r}"
}

main() {
    setup_user_config_ping_log "${_USER_CONFIG_FILE}"
    setup_user_config_event_api "${_USER_CONFIG_FILE}"
    setup_user_config_risk_api "${_USER_CONFIG_FILE}"
    setup_user_config_html_idp "${_USER_CONFIG_FILE}"
    setup_user_config_mfa_idp "${_USER_CONFIG_FILE}"
    setup_user_config_logging "${_USER_CONFIG_FILE}"
}

main "$@"
