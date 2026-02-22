#!/usr/bin/env bash
set -euo pipefail

ZEPHYR_VERSION="${ZEPHYR_VERSION:-v3.7.1}"
ZEPHYR_SDK_VERSION="${ZEPHYR_SDK_VERSION:-0.16.8}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/zephyrproject}"
VENV_DIR="${VENV_DIR:-$WORKSPACE_DIR/.venv}"
SDK_DIR="${SDK_DIR:-$HOME/zephyr-sdk-${ZEPHYR_SDK_VERSION}}"
INSTALL_DEPS="${INSTALL_DEPS:-1}"
INSTALL_UDEV_RULES="${INSTALL_UDEV_RULES:-0}"
FETCH_BLOBS="${FETCH_BLOBS:-1}"
RUN_HELLO_BUILD="${RUN_HELLO_BUILD:-0}"
ALLOW_SUDO_PROMPT="${ALLOW_SUDO_PROMPT:-0}"

log() { printf '[setup][%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }
warn() { printf '[setup][%s][WARN] %s\n' "$(date -u +%H:%M:%S)" "$*"; }

have_noninteractive_sudo() {
  sudo -n true >/dev/null 2>&1
}

sudo_run() {
  if [[ "$ALLOW_SUDO_PROMPT" == "1" ]]; then
    sudo "$@"
  else
    sudo -n "$@"
  fi
}

if [[ "$(uname -m)" != "aarch64" ]]; then
  warn "Host arch is $(uname -m), script is tuned for Pi5 aarch64. Continuing."
fi

# Ensure user-local tools are discoverable in non-login shells.
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [[ "$INSTALL_DEPS" == "1" ]]; then
  if [[ "$ALLOW_SUDO_PROMPT" != "1" ]] && ! have_noninteractive_sudo; then
    echo "INSTALL_DEPS=1 requires passwordless sudo for unattended setup." >&2
    echo "Re-run with INSTALL_DEPS=0 or set ALLOW_SUDO_PROMPT=1." >&2
    exit 1
  fi
  log "Installing host dependencies via apt"
  sudo_run apt-get update
  sudo_run apt-get install --no-install-recommends -y \
    git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget \
    python3-dev python3-venv python3-setuptools python3-wheel python3-tk \
    xz-utils file make gcc g++ libsdl2-dev libmagic1 ca-certificates
fi

if ! command -v uv >/dev/null 2>&1; then
  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv was not found after installation" >&2
  exit 1
fi

log "Using uv version: $(uv --version)"

mkdir -p "$WORKSPACE_DIR"

if [[ ! -d "$VENV_DIR" ]]; then
  log "Creating Python virtual environment at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

log "Installing west into virtual environment with uv"
uv pip install --upgrade west

if [[ ! -d "$WORKSPACE_DIR/.west" ]]; then
  log "Initializing west workspace ($ZEPHYR_VERSION)"
  west init "$WORKSPACE_DIR" --mr "$ZEPHYR_VERSION"
fi

cd "$WORKSPACE_DIR"
log "Updating west modules"
west update

log "Exporting Zephyr CMake package"
west zephyr-export

log "Installing Zephyr Python requirements with uv"
uv pip install -r "$WORKSPACE_DIR/zephyr/scripts/requirements.txt"

if [[ ! -d "$SDK_DIR" ]]; then
  log "Downloading Zephyr SDK v$ZEPHYR_SDK_VERSION for linux-aarch64"
  cd "$HOME"
  sdk_file="zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-aarch64.tar.xz"
  base_url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}"

  wget --tries=3 --timeout=30 --progress=dot:giga -O "$sdk_file" "$base_url/$sdk_file"
  wget --tries=3 --timeout=30 -O "sha256.sum" "$base_url/sha256.sum"
  grep " $sdk_file$" sha256.sum | sha256sum --check --

  tar xf "$sdk_file"
fi

if [[ -x "$SDK_DIR/setup.sh" && ! -f "$SDK_DIR/.setup-complete" ]]; then
  log "Running Zephyr SDK setup.sh (-h -c, log: /tmp/zephyr_sdk_setup.log)"
  (
    cd "$SDK_DIR"
    ./setup.sh -h -c >/tmp/zephyr_sdk_setup.log 2>&1
  )
  touch "$SDK_DIR/.setup-complete"
fi

if [[ "$INSTALL_UDEV_RULES" == "1" ]]; then
  if [[ "$ALLOW_SUDO_PROMPT" != "1" ]] && ! have_noninteractive_sudo; then
    warn "Skipping udev rules: non-interactive sudo is unavailable."
  else
    rule_src="$(find "$SDK_DIR/sysroots" -maxdepth 4 -type f -name '60-openocd.rules' | head -n1 || true)"
    if [[ -n "$rule_src" ]]; then
      log "Installing udev rules for OpenOCD"
      sudo_run cp "$rule_src" /etc/udev/rules.d/
      sudo_run udevadm control --reload
    else
      warn "Could not find 60-openocd.rules under $SDK_DIR/sysroots"
    fi
  fi
fi

sdk_export="export ZEPHYR_SDK_INSTALL_DIR=$SDK_DIR"
if ! grep -Fqx "$sdk_export" "$HOME/.bashrc"; then
  log "Persisting ZEPHYR_SDK_INSTALL_DIR in ~/.bashrc"
  echo "$sdk_export" >> "$HOME/.bashrc"
fi
export ZEPHYR_SDK_INSTALL_DIR="$SDK_DIR"

cd "$WORKSPACE_DIR"
if [[ "$FETCH_BLOBS" == "1" ]]; then
  log "Fetching Espressif HAL blobs"
  west blobs fetch hal_espressif
fi

if [[ "$RUN_HELLO_BUILD" == "1" ]]; then
  log "Running hello_world build for esp32s3_touch_lcd_1_28/esp32s3/procpu"
  cd "$WORKSPACE_DIR/zephyr"
  west build -p always -b esp32s3_touch_lcd_1_28/esp32s3/procpu samples/hello_world
fi

log "Setup complete"
log "Next steps:"
log "  source $VENV_DIR/bin/activate"
log "  cd $WORKSPACE_DIR/zephyr"
log "  west build -p always -b esp32s3_touch_lcd_1_28/esp32s3/procpu samples/hello_world"
log "  west flash"
log "  west espressif monitor"
