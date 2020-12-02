#!/usr/bin/env bash

# Location of Ping Identity Logs on the server e.g. /usr/local/pingfederate-9.2.0/pingfederate/log
_PING_AUDIT_LOG_DIR=''
# Forcepoint Behavioral Analytics Event API e.g. https://fba-event-api-hostname:9000
_FBA_EVENT_API=''
# Forcepoint Behavioral Analytics Risk Exporter API e.g. https://risk-exporter-api-hostname:port-number
_RISK_EXPORTER_API=''
# Forcepoint Risk Score Source e.g. fba or casb
_FORCEPOINT_RISK_SCORE_SOURCE=''
# HTML Identity Provider Adapter ID e.g. HTMLFormSimplePCV
_IDP_HTML_FORM_ID=''
# MFA Identity Provider Adapter ID if it's available, otherwise it can stay empty
_IDP_MFA_ID=''
# Enable logging for this service e.g. true or false
_ENABLE_LOGGING=true