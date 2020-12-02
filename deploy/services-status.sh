#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _fp_product="${1:-"fba"}"

sudo systemctl status "${_fp_product}"-ping-failed-logins "${_fp_product}"-ping-failed-logins-batch-job "${_fp_product}"-ping-failed-logins-batch-job.timer "${_fp_product}"-ping-failed-logins-mfa-job "${_fp_product}"-ping-failed-logins-mfa-job.timer
