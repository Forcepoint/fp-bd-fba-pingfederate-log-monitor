#!/usr/bin/env bash

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _home_dir="$(cd "${_dir}/.." && pwd)"

install_prerequisite() {
   sudo yum install -y ca-certificates openssl
}

trust_cert() {
   local -r __service_name="${1}"
   mkdir -p "${_dir}"/certs && cd $_
   local -r __count="$(ls | wc -l)"

   _host_name="$(echo "${__service_name}" | awk -F':' '{print $1}')"
   ping -c 1 "${_host_name}" && {
      openssl s_client -showcerts -verify 5 -connect "${__service_name}" </dev/null |
         awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a"_'"${__count}"'.crt"; print >out}'
   } || echo "failed to reach "${_host_name}" - please investigate"
}

trust_api_certs() {
   _risk_score_api_service="$(echo "${_RISK_EXPORTER_API}" | awk -F'https://' '{print $2}')"
   if [ ! -z ${_risk_score_api_service} ]; then
      trust_cert "${_risk_score_api_service}"
   fi

   _fba_api_service="$(echo "${_FBA_EVENT_API}" | awk -F'https://' '{print $2}')"
   if [ ! -z ${_fba_api_service} ]; then
      trust_cert "${_fba_api_service}"
   fi

   sudo update-ca-trust force-enable
   chmod 644 "${_dir}"/certs/*.crt
   sudo cp -f "${_dir}"/certs/*.crt /etc/pki/ca-trust/source/anchors/
   sudo update-ca-trust extract
   cd "${_dir}"
}

main() {
   install_prerequisite
   source "${_home_dir}"/user-config.sh
   trust_api_certs
}

main "$@"
