#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _fp_product="${1:-"fba"}"

cd "$(dirname "${0}")"

sudo systemctl stop "${_fp_product}"-ping-failed-logins "${_fp_product}"-ping-failed-logins-batch-job "${_fp_product}"-ping-failed-logins-batch-job.timer "${_fp_product}"-ping-failed-logins-mfa-job "${_fp_product}"-ping-failed-logins-mfa-job.timer
sudo systemctl disable "${_fp_product}"-ping-failed-logins "${_fp_product}"-ping-failed-logins-batch-job "${_fp_product}"-ping-failed-logins-batch-job.timer "${_fp_product}"-ping-failed-logins-mfa-job "${_fp_product}"-ping-failed-logins-mfa-job.timer
sudo rm /etc/systemd/system/"${_fp_product}"-ping-failed-logins.service
sudo rm /etc/systemd/system/"${_fp_product}"-ping-failed-logins-batch-job.service
sudo rm /etc/systemd/system/"${_fp_product}"-ping-failed-logins-batch-job.timer
sudo rm /etc/systemd/system/"${_fp_product}"-ping-failed-logins-mfa-job.service
sudo rm /etc/systemd/system/"${_fp_product}"-ping-failed-logins-mfa-job.timer
sudo systemctl daemon-reload
sudo systemctl reset-failed

ps aux | grep "${_fp_product}"
jobs -l
systemctl list-unit-files | grep "${_fp_product}"

sudo rm /etc/logrotate.d/"${_fp_product}"-ping-failed-logins-logrotate.conf