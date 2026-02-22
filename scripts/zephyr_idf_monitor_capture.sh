#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/zephyrproject}"
VENV_DIR="${VENV_DIR:-$WORKSPACE_DIR/.venv}"
BUILD_DIR="${BUILD_DIR:-$WORKSPACE_DIR/zephyr/build}"
ELF_FILE="${ELF_FILE:-$BUILD_DIR/zephyr/zephyr.elf}"
MONITOR_CWD="${MONITOR_CWD:-$WORKSPACE_DIR/zephyr}"
PORT="${PORT:-/dev/ttyACM0}"
BAUD="${BAUD:-115200}"
DURATION_SEC="${DURATION_SEC:-12}"
LOG_FILE="${LOG_FILE:-/tmp/idf_monitor_capture.log}"
RESET_BEFORE_MONITOR="${RESET_BEFORE_MONITOR:-1}"
EXPECT_PATTERN="${EXPECT_PATTERN:-Hello World!}"
IDF_MONITOR_EXTRA_ARGS="${IDF_MONITOR_EXTRA_ARGS:-}"

log() { printf '[monitor][%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }

if [[ ! -x "$VENV_DIR/bin/python3" ]]; then
  echo "Missing virtualenv Python at $VENV_DIR/bin/python3" >&2
  exit 1
fi

if [[ ! -f "$ELF_FILE" ]]; then
  echo "Missing ELF file: $ELF_FILE" >&2
  exit 1
fi

if [[ ! -d "$MONITOR_CWD" ]]; then
  echo "Monitor working directory not found: $MONITOR_CWD" >&2
  exit 1
fi

if [[ ! -e "$PORT" ]]; then
  echo "Serial port not found: $PORT" >&2
  exit 1
fi

if ! command -v script >/dev/null 2>&1; then
  echo "'script' command is required (util-linux package)." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"
export PYTHONPATH="$WORKSPACE_DIR/zephyr/scripts/west_commands:${PYTHONPATH:-}"

MONITOR_PY="$WORKSPACE_DIR/modules/hal/espressif/tools/idf_monitor/idf_monitor.py"
if [[ ! -f "$MONITOR_PY" ]]; then
  echo "Missing idf_monitor backend: $MONITOR_PY" >&2
  exit 1
fi

if [[ "$RESET_BEFORE_MONITOR" == "1" ]]; then
  log "Pulsing reset lines on $PORT"
  python3 - <<PY
import serial
import time

s = serial.Serial("$PORT", baudrate=$BAUD, timeout=0.2)
s.dtr = False
s.rts = True
time.sleep(0.12)
s.rts = False
s.close()
print("reset_pulse_done")
PY
fi

rm -f "$LOG_FILE"

cmd=(python3 "$MONITOR_PY" -p "$PORT" -b "$BAUD" "$ELF_FILE" --eol CRLF)
if [[ -n "$IDF_MONITOR_EXTRA_ARGS" ]]; then
  # shellcheck disable=SC2206
  extra_args=($IDF_MONITOR_EXTRA_ARGS)
  cmd+=("${extra_args[@]}")
fi
printf -v cmd_str '%q ' "${cmd[@]}"

log "Using backend: $MONITOR_PY"
log "Capturing monitor output for ${DURATION_SEC}s -> $LOG_FILE"
cd "$MONITOR_CWD"
set +e
timeout "${DURATION_SEC}s" script -qefc "$cmd_str" "$LOG_FILE" >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -ne 0 && "$rc" -ne 124 ]]; then
  echo "Monitor capture failed (exit=$rc)" >&2
  exit "$rc"
fi

clean_log="${LOG_FILE%.log}.clean.log"
sed -e 's/\x1b\[[0-9;]*[A-Za-z]//g' "$LOG_FILE" >"$clean_log"

log "Last 80 lines from monitor capture:"
tail -n 80 "$clean_log"

if grep -Fq "$EXPECT_PATTERN" "$clean_log"; then
  log "Matched expected pattern: $EXPECT_PATTERN"
else
  echo "Expected pattern not found: $EXPECT_PATTERN" >&2
  exit 2
fi
