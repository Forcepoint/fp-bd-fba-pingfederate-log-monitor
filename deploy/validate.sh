#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

source "$(dirname "${0}")/../source/config.sh"
source "${_HOME_DIR}"/source/common-functions.sh

is_ping_installed() {
    local __r=1
    find / -path \*/pingfederate >/dev/null 2>&1 && __r=0 || error "Are you sure pingfederate setup on this server, we don't seem to find it!"
    return "${__r}"
}

validate_user_config_ping_log() {
    local -r __user_config_file="${1}"
    local __r=1
    local -r __content="$(grep "_PING_AUDIT_LOG_DIR=" "${__user_config_file}" | awk -F '[=]' '{ sub(/^[\"'\'']+/, "", $2); sub(/[\"'\'']+$/, "", $2); printf $2}')"
    find "${__content}" -maxdepth 1 -type f -name "${_PING_AUDIT_LOG_NAME}" 2>/dev/null | grep -q "${_PING_AUDIT_LOG_NAME}" && __r=0 ||
        error "There is no ping audit log file in this directory: "${__content}""
    return "${__r}"
}

validate_user_config_event_api() {
    local -r __user_config_file="${1}"
    local __r=1
    local -r __content="$(grep "_FBA_EVENT_API=" "${__user_config_file}" | awk -F '[=]' '{ sub(/^[\"'\'']+/, "", $2); sub(/[\"'\'']+$/, "", $2); printf $2}')"
    curl -s "${__content}" | grep -q 'Reveal Public API' && __r=0 ||
        error "Are you sure this is the right URL for FBA EVENT API: "${__content}""
    return "${__r}"
}

validate_user_config_risk_api() {
    local -r __user_config_file="${1}"
    local __r=1
    local -r __content="$(grep "_RISK_EXPORTER_API=" "${__user_config_file}" | awk -F '[=]' '{ sub(/^[\"'\'']+/, "", $2); sub(/[\"'\'']+$/, "", $2); printf $2}')"
    curl -s "${__content}${_RISK_API_HEALTH_ENDPOINT}" | grep -q 'Risk Exporter Service' && __r=0 ||
        error "Are you sure this is the right URL for FBA Risk Exporter API: "${__content}""
    return "${__r}"
}

validate_user_config_html_idp() {
    local -r __user_config_file="${1}"
    local __r=1
    local -r __ping_adapters=($(find / -path \*/pingfederate/server/default/data/adapter-config/*.xml -printf "%f\n" 2>/dev/null | cut -d'.' -f1))
    local -r __content="$(grep "_IDP_HTML_FORM_ID=" "${__user_config_file}" | awk -F '[=]' '{ sub(/^[\"'\'']+/, "", $2); sub(/[\"'\'']+$/, "", $2); printf $2}')"
    printf '%s\n' ${__ping_adapters[@]} | grep -qP "^${__content}$" && {
        grep -qw "Reset" "$(find / -path \*/pingfederate/server/default/data/adapter-config/${__content}.xml 2>/dev/null)" && __r=0 ||
            error "Are you sure this is right adapter: ${__content} for the HTML Form IDP"
    } || error "No HTML Form adapter exists with this ID: [${__content}]"
    return "${__r}"
}

validate_user_config_mfa_idp() {
    local -r __user_config_file="${1}"
    local __r=1
    local -r __ping_adapters=($(find / -path \*/pingfederate/server/default/data/adapter-config/*.xml -printf "%f\n" 2>/dev/null | cut -d'.' -f1))
    local -r __content="$(grep "_IDP_MFA_ID=" "${__user_config_file}" | awk -F '[=]' '{ sub(/^[\"'\'']+/, "", $2); sub(/[\"'\'']+$/, "", $2); printf $2}')"
    if ! test -z "${__content}"; then
        printf '%s\n' ${__ping_adapters[@]} | grep -qP "^${__content}$" && {
            grep -qw "REJECT" "$(find / -path \*/pingfederate/server/default/data/adapter-config/${__content}.xml 2>/dev/null)" && __r=0 ||
                error "Are you sure this is right adapter: ${__content} for the MFA PingID IDP"
        } || error "No MFA PingID adapter exists with this ID: [${__content}]"
    else
        warning "MFA adapter is not setup, that's ok if you don't have MFA setup." && __r=0
    fi
    return "${__r}"
}

validate_user_config_logging() {
    local -r __user_config_file="${1}"
    local __r=1
    local -r __content="$(grep "_ENABLE_LOGGING=" "${__user_config_file}" | awk -F '[=]' '{ sub(/^[\"'\'']+/, "", $2); sub(/[\"'\'']+$/, "", $2); printf $2}')"
    echo "${__content}" | grep -qwIE "true|false" && __r=0 || error "Invalid value in _ENABLE_LOGGING ${__content}"
    return "${__r}"
}

are_scripts_executable() {
    local __r=1
    for file in ./*.sh; do
        test -x "$file" && __r=0 || {
            error "Not all shell scripts are executable! Run chmod +x ./*.sh" &&
                __r=1 &&
                break
        }
    done
    return "${__r}"
}

main() {
    local __r=0
    local __prerequisites=(awk curl grep printf tail find cp head cut bc mv read test wc touch)
    validate_prerequisites "${__prerequisites[@]}"
    is_ping_installed
    validate_user_config_ping_log "${_USER_CONFIG_FILE}" || __r=1
    validate_user_config_event_api "${_USER_CONFIG_FILE}" || __r=1
    validate_user_config_risk_api "${_USER_CONFIG_FILE}" || __r=1
    validate_user_config_html_idp "${_USER_CONFIG_FILE}" || __r=1
    validate_user_config_mfa_idp "${_USER_CONFIG_FILE}" || __r=1
    validate_user_config_logging "${_USER_CONFIG_FILE}" || __r=1
    are_scripts_executable || __r=1

    test "${__r}" -eq 0 && {
        echo "" && info "Validation passed, thank you."
    } || {
        echo "" && error "Please review the errors above before proceeding any further. Please run the validation script again once the above is fixed."
    }
}

main "$@"
