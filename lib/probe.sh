#!/bin/bash
# probe.sh — check one host for a TP-Link AWTK NVR web UI.
# Usage: probe.sh <host>
#   PROBE_PORT     port to probe (default 80)
#   PROBE_RESULTS  file to append "host:port" on match (required)
# Designed to be driven by xargs, which appends hosts as $1.
set -u

HOST="${1:?host required}"
PORT="${PROBE_PORT:-80}"
RESULT_FILE="${PROBE_RESULTS:?PROBE_RESULTS must be set}"

BODY=$(curl -sf -m 2 "http://${HOST}:${PORT}/" 2>/dev/null) || exit 1

case "${BODY}" in
  *awtk*|*"<title>NVR"*)
    printf '%s:%s\n' "${HOST}" "${PORT}" >> "${RESULT_FILE}"
    ;;
esac
