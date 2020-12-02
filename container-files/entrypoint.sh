#!/usr/bin/env bash

readonly _conf_file_name=user-config.sh
readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _home_dir="$(cd "${_dir}/.." && pwd)"/"${_HOME_DIR_NAME}"

trust_cert() {
   local -r __service_name="${1}"
   mkdir -p "${_dir}"/certs && cd $_
   local -r __count="$(ls | wc -l)"

   openssl s_client -showcerts -verify 5 -connect "${__service_name}" </dev/null |
      awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a"_'"${__count}"'.crt"; print >out}'
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

   cd "${_dir}"/certs
   for cert in *.crt; do
      cat $cert >>./api-certs.pem
   done
   cp -f "${_dir}"/certs/api-certs.pem /usr/local/share/ca-certificates/
   update-ca-certificates
   cd "${_dir}"
}

main() {
   if [ ! -z ${CONFIG_FILE_URL_LOCATION} ]; then
      wget -O "${_home_dir}"/"${_conf_file_name}" "${CONFIG_FILE_URL_LOCATION}"
   fi
   source "${_home_dir}"/"${_conf_file_name}"
   if [ ! -z ${PING_NFS_MAPPING} ]; then
      /sbin/rpcbind
      mount -t nfs "${PING_NFS_MAPPING}" /mnt/ping/logs
   fi
   trust_api_certs
   "${_dir}"/start-services.sh
}

main "$@"
