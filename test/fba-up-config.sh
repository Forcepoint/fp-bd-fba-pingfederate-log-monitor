#!/usr/bin/env bash

set -o pipefail
set -o nounset

source "${_TEST_DIR}/config.sh"

# User Configs
readonly _RISK_EXPORTER_API='https://ups-iamlab.wbsntest.net:9800'
readonly _FBA_EVENT_API='https://api-iamlab.wbsntest.net:9000'
readonly _IDP_HTML_FORM_ID='HTMLFormSimplePCV'
readonly _IDP_MFA_ID='PingID'
readonly _ENABLE_LOGGING=false
