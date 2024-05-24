#!/usr/bin/env bash

# ─────────────────────────────────────────────────────────────
# Logging helpers
# ─────────────────────────────────────────────────────────────
prompt()  { printf "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')]\033[1;36m[USER]\033[0m  %s"   "$1"; }
info()    { printf "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')]\033[1;34m[INFO]\033[0m  %s\n" "$1"; }
success() { printf "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')]\033[1;32m[DONE]\033[0m  %s\n" "$1"; }
warn()    { printf "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')]\033[1;33m[WARN]\033[0m  %s\n" "$1"; }
error()   { printf "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')]\033[1;31m[FAIL]\033[0m  %s\n" "$1"; }

# How to use:
#     local USER_INPUT=$(read_user_input "Digite a porta SSH" false 22)
#
# read_user_input() {
#   local text="$1"
#   local required="$2"
#   local default_value="$3"
#   local value
#   read_input "$text" value false false "Default: ${default_value}"
#   value=${value:-$default_value}
#   echo "$value"
# }

log() {
  echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"
}

require_env() {
  : "${!1:?Missing environment variable: $1}"
}

format_eta() {
  local ELAPSED="$1"
  local H=$((ELAPSED / 3600))
  local M=$(((ELAPSED % 3600) / 60))
  local S=$((ELAPSED % 60))

  printf "%02dh %02dm %02ds" "$H" "$M" "$S"
}











# send_notification() {
#   local MESSAGE="$1"

#   [[ -z "${NOTIFICATION_WEBHOOK_URL:-}" ]] && return

#   curl -s -X POST "$NOTIFICATION_WEBHOOK_URL" \
#     -H "Content-Type: application/json" \
#     -d "$(jq -nc --arg text "$MESSAGE" '{text: $text}')" \
#     >/dev/null
# }