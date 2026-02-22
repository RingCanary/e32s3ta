# Zephyr LTS Setup on Raspberry Pi 5 (Pi5)

Date: 2026-02-22

## Goal
Prepare a reproducible Zephyr LTS environment on Pi5 for Waveshare ESP32-S3-LCD-1.28 development.

## Fast Path (Script)
Preferred entrypoint:

```bash
bash scripts/setup_zephyr_lts_pi5.sh
```

Common script flags:

```bash
# Full smoke including hello_world build
RUN_HELLO_BUILD=1 bash scripts/setup_zephyr_lts_pi5.sh

# Resume after a partial run (skip apt, keep non-interactive)
INSTALL_DEPS=0 RUN_HELLO_BUILD=1 INSTALL_UDEV_RULES=0 bash scripts/setup_zephyr_lts_pi5.sh

# If your sudo requires a password and you are running interactively
ALLOW_SUDO_PROMPT=1 INSTALL_UDEV_RULES=1 bash scripts/setup_zephyr_lts_pi5.sh
```

Notes:
- Default is `INSTALL_UDEV_RULES=0` to avoid hidden sudo prompts in unattended runs.
- SDK installer output is written to `/tmp/zephyr_sdk_setup.log`.

## Version Pin (LTS)
- Zephyr line: `LTS3`
- Zephyr release tag to use: `v3.7.1` (latest patch release on LTS3 line)
- Zephyr SDK baseline for 3.7 docs: `v0.16.8`

Notes:
- Zephyr release docs identify `3.7.0 (LTS3)` as the currently supported LTS line.
- `v3.7.1` is the newer patch in that same LTS line.

## Board Target
Use this Zephyr board target:
- `esp32s3_touch_lcd_1_28/esp32s3/procpu`

Why this target:
- In Zephyr `v3.7.1`, board metadata declares this identifier for the Waveshare touch-LCD variant.
- Our hardware is `ESP32-S3-LCD-1.28` (non-touch). This is the closest upstream board target in LTS.

## 0) Pi5 Preflight
Run on Pi5:

```bash
for c in git cmake ninja gperf ccache dfu-util dtc wget make gcc g++; do
  command -v "$c" >/dev/null 2>&1 || echo "missing:$c"
done
python3 --version
uname -m
```

Expected host architecture:
- `aarch64`

## 1) Install Host Dependencies (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install --no-install-recommends \
  git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget \
  python3-dev python3-venv python3-setuptools python3-wheel python3-tk \
  xz-utils file make gcc g++ libsdl2-dev libmagic1
```

## 2) Python Environment with uv (No pip)

```bash
command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh

python3 -m venv ~/zephyrproject/.venv
source ~/zephyrproject/.venv/bin/activate

# Convenience wrapper: west via uvx
westx(){ uvx --from west west "$@"; }
westx --version
```

## 3) Get Zephyr LTS Source

```bash
westx init ~/zephyrproject --mr v3.7.1
cd ~/zephyrproject
westx update
westx zephyr-export

# Zephyr Python deps installed through uv
uv pip install -r ~/zephyrproject/zephyr/scripts/requirements.txt
```

## 4) Install Zephyr SDK (aarch64)

```bash
cd ~
SDK_VER=0.16.8
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VER}/zephyr-sdk-${SDK_VER}_linux-aarch64.tar.xz
wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VER}/sha256.sum | shasum --check --ignore-missing

tar xvf zephyr-sdk-${SDK_VER}_linux-aarch64.tar.xz
cd zephyr-sdk-${SDK_VER}
./setup.sh

# Optional: udev rules for OpenOCD
HOST_SYSROOT=$(find "$HOME/zephyr-sdk-${SDK_VER}/sysroots" -maxdepth 1 -type d -name '*-pokysdk-linux' | head -n1)
sudo cp "$HOST_SYSROOT/usr/share/openocd/contrib/60-openocd.rules" /etc/udev/rules.d/
sudo udevadm control --reload
```

Persist SDK environment:

```bash
echo "export ZEPHYR_SDK_INSTALL_DIR=$HOME/zephyr-sdk-${SDK_VER}" >> ~/.bashrc
```

Open a new shell (or `source ~/.bashrc`) before building.

## 5) Fetch Espressif Binary Blobs

```bash
source ~/zephyrproject/.venv/bin/activate
westx(){ uvx --from west west "$@"; }

cd ~/zephyrproject
westx blobs fetch hal_espressif
```

## 6) First Build/Flash/Monitor

```bash
source ~/zephyrproject/.venv/bin/activate
westx(){ uvx --from west west "$@"; }

cd ~/zephyrproject/zephyr
westx build -p always -b esp32s3_touch_lcd_1_28/esp32s3/procpu samples/hello_world
westx flash
westx espressif monitor
```

Expected serial output:
- `***** Booting Zephyr OS ... *****`
- `Hello World! ...`

## 7) Serial Access Stability on Pi5
If flashing/monitor intermittently fails due serial-device grabs:

```bash
sudo usermod -aG dialout $USER
# re-login required

# Optional, if ModemManager grabs /dev/ttyACM*
sudo systemctl stop ModemManager
sudo systemctl disable ModemManager
```

## 8) Important Hardware Note
- Zephyr LTS target used above is for `ESP32-S3-Touch-LCD-1.28`.
- Our board is `ESP32-S3-LCD-1.28` (non-touch).
- `hello_world` bring-up is suitable for toolchain validation, but board-specific display/touch behavior may require DTS/overlay adjustments.

## Sources
- Zephyr releases (LTS status and supported releases):
  - https://docs.zephyrproject.org/latest/releases/index.html
  - https://github.com/zephyrproject-rtos/zephyr/releases/tag/v3.7.1
- Zephyr 3.7 getting started docs:
  - https://docs.zephyrproject.org/3.7.0/develop/getting_started/index.html
- Waveshare ESP32-S3 touch board docs (3.7.0):
  - https://docs.zephyrproject.org/3.7.0/boards/waveshare/esp32s3_touch_lcd_1_28/doc/index.html
- Board metadata in Zephyr `v3.7.1` (identifier and targets):
  - https://github.com/zephyrproject-rtos/zephyr/tree/v3.7.1/boards/waveshare/esp32s3_touch_lcd_1_28
- Zephyr SDK releases:
  - https://github.com/zephyrproject-rtos/sdk-ng/releases/tag/v0.16.8
