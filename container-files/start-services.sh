#!/usr/bin/env bash

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _home_dir="$(cd "${_dir}/.." && pwd)"/"${_HOME_DIR_NAME}"
readonly _source_dir="${_home_dir}"/source

mv ./fp-ping-failed-logins-logrotate.conf /etc/logrotate.d/

echo -e "*/5\t*\t*\t*\t*\t"${_source_dir}"/run-fba-ping-batch-events.sh" >>/etc/crontabs/root
echo -e "*/30\t*\t*\t*\t*\t"${_source_dir}"/run-fba-ping-mfa-batch-events.sh" >>/etc/crontabs/root
crond -b -l 0

"${_source_dir}"/start-fba-ping-streamed-events.sh
