#!/usr/bin/env bash

set -o pipefail
set -o nounset

source "${_TEST_DIR}/config.sh"

# User Configs
readonly _RISK_EXPORTER_API='https://ups-iamlab.wbsntest.net:980'
readonly _ENABLE_LOGGING=false
