#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _fp_product="${1:-"fba"}"

cd "$(dirname "${0}")" 

sudo cp ./"${_fp_product}"-ping-failed-logins.service /etc/systemd/system
sudo cp ./"${_fp_product}"-ping-failed-logins-batch-job.service /etc/systemd/system
sudo cp ./"${_fp_product}"-ping-failed-logins-batch-job.timer /etc/systemd/system
sudo cp ./"${_fp_product}"-ping-failed-logins-mfa-job.service /etc/systemd/system
sudo cp ./"${_fp_product}"-ping-failed-logins-mfa-job.timer /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl start "${_fp_product}"-ping-failed-logins "${_fp_product}"-ping-failed-logins-batch-job "${_fp_product}"-ping-failed-logins-batch-job.timer "${_fp_product}"-ping-failed-logins-mfa-job "${_fp_product}"-ping-failed-logins-mfa-job.timer
sudo systemctl enable "${_fp_product}"-ping-failed-logins "${_fp_product}"-ping-failed-logins-batch-job "${_fp_product}"-ping-failed-logins-batch-job.timer "${_fp_product}"-ping-failed-logins-mfa-job "${_fp_product}"-ping-failed-logins-mfa-job.timer

sudo cp ./"${_fp_product}"-ping-failed-logins-logrotate.conf /etc/logrotate.d/

./services-status.sh