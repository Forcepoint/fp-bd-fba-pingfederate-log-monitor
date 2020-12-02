#!/usr/bin/env bash

set -o pipefail
set -o nounset

source "${_HOME_DIR}"/common-config.sh

expected-return-code() {
    local -r __test_file_name="${1}"
    local -r __function_name="${2}"
    local -r __expected_return_code="${3}"
    local -r __actual_return_code="${4}"
    local -r __validation_number="${5:-""}"

    if [[ "${__expected_return_code}" == "${__actual_return_code}" ]]; then
        printf "${_WHITE}${__test_file_name} - ${_GREEN}${__function_name} Passed ${__validation_number}${_NO_COLOR}\n"
    else
        printf "${_WHITE}${__test_file_name} - ${_BOLD_RED}${__function_name} Failed ${__validation_number}${_NO_COLOR}\n"
    fi
}

get-batch-event-test-data() {
    local -r __current_hour="$(date | awk '{print substr($4,1,2)}')"
    printf "2019-11-11 ${__current_hour}:10:35,237| tid:xDm3h3_CUZ84nAoivKMKgsrvIwI| AUTHN_ATTEMPT| ralpha@thp.com| 10.25.161.21 | | ac_client| | ping-iamlab.wbsntest.net| IdP| inprogress| HTMLFormSimplePCV| | 12
    2019-11-11 ${__current_hour}:15:35,237| tid:xDm3h3_CUZ84nAoivKMKgsrvIwE| AUTHN_ATTEMPT| jsmith@thp.com| 10.25.161.22 | | ac_client| | ping-iamlab.wbsntest.net| IdP| inprogress| HTMLFormSimplePCV| | 13
    2019-11-11 ${__current_hour}:30:35,237| tid:xDm3h3_CUZ84nAoivKMKgsrvIwI| AUTHN_ATTEMPT| ralpha@thp.com| 10.25.161.21 | | ac_client| | ping-iamlab.wbsntest.net| IdP| inprogress| HTMLFormSimplePCV| | 12
    2019-11-11 ${__current_hour}:45:35,237| tid:xDm3h3_CUZ84nAoivKMKgsrvIwE| AUTHN_ATTEMPT| jsmith@thp.com| 10.25.161.22 | | ac_client| | ping-iamlab.wbsntest.net| IdP| inprogress| HTMLFormSimplePCV| | 13 \n"
}
