#!/usr/bin/env bash

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _home_dir="$(cd "${_dir}/.." && pwd)"

install_prerequisite() {
   sudo apt install -y ca-certificates openssl
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

   chmod 644 ./*.crt
   sudo cp "${_dir}"/certs/*.crt /usr/local/share/ca-certificates
   sudo cp "${_dir}"/certs/*.crt /etc/ssl/certs/
   sudo dpkg-reconfigure -f noninteractive ca-certificates
   sudo update-ca-certificates --fresh
}

main() {
   install_prerequisite
   source "${_home_dir}"/user-config.sh
   trust_api_certs
}

main "$@"
