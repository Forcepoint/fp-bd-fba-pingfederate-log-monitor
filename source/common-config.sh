#!/usr/bin/env bash

set -o pipefail
set -o nounset

readonly _ENABLE_DEBUG=false
readonly _WHITE='\033[0;37m'
readonly _BOLD_WHITE='\033[1;37m'
readonly _NO_COLOR='\033[0m'
readonly _BOLD_RED='\033[1;31m'
readonly _GREEN='\033[0;32m'
readonly _BOLD_GREEN='\033[1;32m'
readonly _BOLD_YELLOW='\033[1;33m'
readonly _ERROR="ERROR"
readonly _INFO="INFO"
readonly _WARNING="WARNING"
