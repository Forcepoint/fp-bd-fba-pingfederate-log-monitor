#!/usr/bin/env bash

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _home_folder="$(cd "${_dir}/.." && pwd)"
readonly _fp_product="${1:-"fba"}"

validate_prerequisites() {
    local __r=0
    local __prerequisites=("$@")
    local __clear_previous_display="\r\033[K"
    for prerequisite in "${__prerequisites[@]}"; do
        echo -en "${__clear_previous_display}Prerequisite - ${prerequisite} - check" && sleep 0.1
        command -v ${prerequisite} >/dev/null 2>&1 || {
            echo -e "${__clear_previous_display}We require >>> ${prerequisite} <<< but it's not installed. Please try again after installing ${prerequisite}." &&
                __r=1 &&
                break
        }
    done
    echo -en "${__clear_previous_display}"
    return "${__r}"
}

setup_systemd_home_dir() {
    local -r __systemd_file="${1}"
    local -r __home_dir="${2}"
    local -r __home_dir_variable_name="${3}"
    local -r __user="${4}"
    local __r=1
    local __content="$(awk '{gsub(/Environment=.*$/,"Environment='"${__home_dir_variable_name}"'='"${__home_dir}"'")}1' "${__systemd_file}")"
    echo "${__content}" >"${__systemd_file}" && __r=0
    __content="$(awk '{gsub(/User=.*$/,"User='"${__user}"'")}1' "${__systemd_file}")"
    echo "${__content}" >"${__systemd_file}" && __r=0
    return "${__r}"
}

setup_logrotate_home_dir() {
    local -r __logrotate_file="${1}"
    local -r __home_dir="${2}"
    local -r __home_dir_variable_name="${3}"
    local __r=1
    local __content="$(awk '{gsub(/'"${__home_dir_variable_name}"'.*$/,"'"${__home_dir}"'/logs/* {")}1' "${__logrotate_file}")"
    echo "${__content}" >"${__logrotate_file}" && __r=0
    return "${__r}"
}

deploy() {
    local -r __service_name="${1}"
    cd "${_dir}"
    sudo cp ./"${__service_name}" /etc/systemd/system
    sudo systemctl daemon-reload
    sudo systemctl start "${__service_name}"
    sudo systemctl enable "${__service_name}"
    systemctl status "${__service_name}"
    return "$?"
}

main() {
    cd "${_dir}"
    local __prerequisites=(awk curl grep printf tail find cp head cut bc mv read test wc systemctl touch)
    local __home_dir_variable_name="APP_HOME"
    validate_prerequisites "${__prerequisites[@]}"
    local -r __user="$(whoami)"
    sudo chown -R "${__user}" "${_home_folder}"
    sudo chmod +x "${_home_folder}"/source/*.sh
    sudo chmod ugo+rw "${_dir}"/*.service "${_dir}"/*.conf
    setup_logrotate_home_dir fp-ping-failed-logins-logrotate.conf "${_home_folder}" "${__home_dir_variable_name}"
    sudo cp ./fp-ping-failed-logins-logrotate.conf /etc/logrotate.d/
    hostnamectl | grep -qi centos && ./trust-api-certs-centos.sh || ./trust-api-certs-debian.sh
    for _sysd_timer_file in "${_dir}"/"${_fp_product}"*.timer; do
        sudo cp "${_sysd_timer_file}" /etc/systemd/system
    done
    for _sysd_file in "${_dir}"/"${_fp_product}"*.service; do
        setup_systemd_home_dir "${_sysd_file}" "${_home_folder}" "${__home_dir_variable_name}" "${__user}"
        deploy "$(basename "${_sysd_file}")"
    done
    for _sysd_timer_file in "${_dir}"/"${_fp_product}"*.timer; do
        deploy "$(basename "${_sysd_timer_file}")"
    done
}

main "$@"
