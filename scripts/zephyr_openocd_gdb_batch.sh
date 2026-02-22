#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DEFAULT_REPO_OPENOCD_CFG="$REPO_ROOT/configs/openocd/esp32s3_touch_lcd_1_28.openocd.main.cfg"
if [[ -f "$DEFAULT_REPO_OPENOCD_CFG" ]]; then
  DEFAULT_OPENOCD_CFG="$DEFAULT_REPO_OPENOCD_CFG"
else
  DEFAULT_OPENOCD_CFG="/usr/share/openocd/scripts/board/esp32s3-builtin.cfg"
fi

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/zephyrproject}"
BUILD_DIR="${BUILD_DIR:-$WORKSPACE_DIR/zephyr/build}"
ELF_FILE="${ELF_FILE:-$BUILD_DIR/zephyr/zephyr.elf}"

OPENOCD_BIN="${OPENOCD_BIN:-/usr/bin/openocd}"
OPENOCD_CFG="${OPENOCD_CFG:-$DEFAULT_OPENOCD_CFG}"
OPENOCD_SCRIPTS_DIR="${OPENOCD_SCRIPTS_DIR:-/usr/share/openocd/scripts}"
GDB_BIN="${GDB_BIN:-$HOME/zephyr-sdk-0.16.8/xtensa-espressif_esp32s3_zephyr-elf/bin/xtensa-espressif_esp32s3_zephyr-elf-gdb}"

GDB_PORT="${GDB_PORT:-3333}"
TCL_PORT="${TCL_PORT:-6333}"
TELNET_PORT="${TELNET_PORT:-4444}"

OPENOCD_LOG="${OPENOCD_LOG:-/tmp/esp32s3_openocd.log}"
GDB_LOG="${GDB_LOG:-/tmp/esp32s3_gdb.log}"
START_TIMEOUT_SEC="${START_TIMEOUT_SEC:-12}"

REQUIRE_USB_JTAG="${REQUIRE_USB_JTAG:-1}"
USB_JTAG_VIDPID="${USB_JTAG_VIDPID:-303a:1001}"

log() { printf '[debug][%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }

if [[ ! -f "$ELF_FILE" ]]; then
  echo "Missing ELF file: $ELF_FILE" >&2
  exit 1
fi

if [[ ! -x "$OPENOCD_BIN" ]]; then
  echo "OpenOCD binary not found/executable: $OPENOCD_BIN" >&2
  exit 1
fi

if [[ ! -f "$OPENOCD_CFG" ]]; then
  echo "OpenOCD config not found: $OPENOCD_CFG" >&2
  exit 1
fi

if [[ ! -d "$OPENOCD_SCRIPTS_DIR" ]]; then
  echo "OpenOCD scripts directory not found: $OPENOCD_SCRIPTS_DIR" >&2
  exit 1
fi

if [[ ! -x "$GDB_BIN" ]]; then
  echo "xtensa GDB not found/executable: $GDB_BIN" >&2
  exit 1
fi

if [[ "$REQUIRE_USB_JTAG" == "1" ]]; then
  if ! command -v lsusb >/dev/null 2>&1; then
    echo "lsusb is required for USB-JTAG precheck." >&2
    exit 1
  fi
  if ! lsusb | awk '{print tolower($6)}' | grep -Fxq "$USB_JTAG_VIDPID"; then
    echo "ESP USB-JTAG endpoint ($USB_JTAG_VIDPID) not detected." >&2
    echo "Current USB devices:" >&2
    lsusb >&2
    echo "Use the board's native USB D+/D- debug port (not USB-UART bridge), or attach an external JTAG probe." >&2
    echo "If you only see a QinHeng/CH34x VID:PID (for example 1a86:55d3), that is UART-only." >&2
    exit 2
  fi
fi

rm -f "$OPENOCD_LOG" "$GDB_LOG"

log "Starting OpenOCD: $OPENOCD_BIN -s $OPENOCD_SCRIPTS_DIR -f $OPENOCD_CFG"
"$OPENOCD_BIN" -f "$OPENOCD_CFG" \
  -s "$OPENOCD_SCRIPTS_DIR" \
  -c "gdb port $GDB_PORT" \
  -c "tcl port $TCL_PORT" \
  -c "telnet port $TELNET_PORT" \
  >"$OPENOCD_LOG" 2>&1 &
openocd_pid=$!

cleanup() {
  if kill -0 "$openocd_pid" >/dev/null 2>&1; then
    kill "$openocd_pid" >/dev/null 2>&1 || true
    wait "$openocd_pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

ready=0
for _ in $(seq 1 "$START_TIMEOUT_SEC"); do
  if grep -q "Listening on port $GDB_PORT for gdb connections" "$OPENOCD_LOG"; then
    ready=1
    break
  fi
  if ! kill -0 "$openocd_pid" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if [[ "$ready" -ne 1 ]]; then
  echo "OpenOCD did not become ready for GDB on port $GDB_PORT." >&2
  tail -n 120 "$OPENOCD_LOG" >&2 || true
  exit 3
fi

log "Running xtensa GDB batch commands"
set +e
"$GDB_BIN" -q "$ELF_FILE" \
  -ex "set pagination off" \
  -ex "set confirm off" \
  -ex "set remotetimeout 10" \
  -ex "target remote :$GDB_PORT" \
  -ex "monitor esp32s3.cpu0 curstate" \
  -ex "monitor esp32s3.cpu0 arp_halt" \
  -ex "monitor esp32s3.cpu0 curstate" \
  -ex "info reg pc a0 a1 a2 a3 sp" \
  -ex "bt" \
  -ex "detach" \
  -ex "quit" \
  >"$GDB_LOG" 2>&1
gdb_rc=$?
set -e

log "OpenOCD tail:"
tail -n 80 "$OPENOCD_LOG"
log "GDB output:"
tail -n 120 "$GDB_LOG"

if [[ "$gdb_rc" -ne 0 ]]; then
  echo "GDB batch failed (exit=$gdb_rc)." >&2
  exit "$gdb_rc"
fi

if grep -q "Remote debugging using" "$GDB_LOG"; then
  log "GDB connected successfully."
else
  echo "GDB did not report a remote connection." >&2
  exit 4
fi
