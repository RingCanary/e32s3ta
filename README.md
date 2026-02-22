# ESP32-S3-LCD-1.28 Quick Bring-up

This repository bootstraps a fresh embedded workflow for the Waveshare ESP32-S3-LCD-1.28 board using MicroPython.

## Current Status
- Compatible MicroPython firmware pulled: `QUICK/firmware/S3-Touch-LCD-1.28-MPY.bin`
- Firmware flashing flow validated with `uvx esptool`
- Display smoke test executed successfully: `display_smoke: completed`
- OpenAI logo assets prepared: BMP + JPEG in `QUICK/assets/`
- Boot demo deployed as `main.py` with a low-refresh Codex-style animation

## Layout
- `QUICK/`: MicroPython quickstart assets only
- `QUICK/firmware/`: firmware binary
- `QUICK/code/`: first MicroPython scripts (`display_smoke.py`, `logo_show.py`, `logo_anim.py`, `main.py`)
- `QUICK/assets/`: image assets (`openai_logo_240.bmp`, `openai_logo_240.jpg`)
- `QUICK/DATASHEET.md`: board and component datasheet links/notes
- `scripts/setup_zephyr_lts_pi5.sh`: automated Zephyr LTS setup script (uv + west + SDK + optional hello build)
- `scripts/zephyr_idf_monitor_capture.sh`: non-interactive monitor capture via Espressif `idf_monitor.py` backend
- `scripts/zephyr_openocd_gdb_batch.sh`: batch OpenOCD + xtensa-gdb debug entrypoint with USB-JTAG precheck
- `configs/openocd/`: locally tracked upstream OpenOCD config mirror(s)
- `DEV_STACK_COMPARISON.md`: research-backed comparison of next development stacks
- `ZEPHYR_LTS_PI5_SETUP.md`: Pi5 setup guide for Zephyr LTS (`v3.7.1`)
- `ZEPHYR_DEBUG_RECON.md`: latest-vs-LTS debug recon, issues, and mitigations
- `WORKLOG.md`: epoch-stamped progress log

## Next-Step Planning
- Before moving from quick bring-up to full development, review stack tradeoffs in:
  - `DEV_STACK_COMPARISON.md`
- Selected implementation direction: `Zephyr RTOS` on the latest LTS line.
- Start from:
  - `ZEPHYR_LTS_PI5_SETUP.md`

## Zephyr LTS Quick Setup Script
Run from repo root:

```bash
# Base setup (non-interactive defaults)
bash scripts/setup_zephyr_lts_pi5.sh

# Include hello_world build for board-target validation
RUN_HELLO_BUILD=1 bash scripts/setup_zephyr_lts_pi5.sh
```

If re-running after an interrupted attempt:

```bash
INSTALL_DEPS=0 RUN_HELLO_BUILD=1 INSTALL_UDEV_RULES=0 bash scripts/setup_zephyr_lts_pi5.sh
```

## Non-Interactive Monitor (Espressif Backend)
This runs the same backend process used by `west espressif monitor`, but in bounded headless mode:

```bash
bash scripts/zephyr_idf_monitor_capture.sh
```

Useful overrides:

```bash
PORT=/dev/ttyACM0 DURATION_SEC=15 EXPECT_PATTERN="Hello World!" bash scripts/zephyr_idf_monitor_capture.sh
```

## OpenOCD + xtensa-gdb (Batch)
This path requires ESP32-S3 USB-JTAG visibility (`lsusb` should show `303a:1001`), not only a USB-UART bridge.

```bash
bash scripts/zephyr_openocd_gdb_batch.sh
```

## Prerequisites (Linux/WSL)
- USB-connected ESP32-S3 board visible as a serial device
- `uv` installed (https://docs.astral.sh/uv/)
- Access to the serial port (group membership or `sudo`)
- Python tooling must use `uv`/`uvx` only (no `pip`, no `requirements.txt`)

## Reproducible Flash Flow
1. Set your serial device path.
   - Common Linux values: `/dev/ttyACM0`, `/dev/ttyUSB0`
   - On WSL, first attach USB to WSL (`usbipd` workflow), then use the Linux device path inside WSL
2. Erase and flash the firmware with `esptool` via `uvx`.
3. Verify MicroPython + display driver module.
4. Upload scripts and run smoke test.

```bash
PORT=/dev/ttyACM0

# 1) (Optional) ensure serial access
sudo chmod 666 "$PORT"

# 2) Flash firmware
uvx --from esptool esptool --chip esp32s3 --port "$PORT" --baud 460800 erase-flash
uvx --from esptool esptool --chip esp32s3 --port "$PORT" --baud 460800 write-flash 0x0 QUICK/firmware/S3-Touch-LCD-1.28-MPY.bin

# 3) Verify MicroPython and gc9a01 module
uvx --from mpremote mpremote connect "$PORT" exec "import sys; print(sys.implementation); import gc9a01; print('gc9a01 ok')"

# 4) Upload scripts and run display smoke test
uvx --from mpremote mpremote connect "$PORT" fs cp QUICK/code/logo_anim.py :logo_anim.py + fs cp QUICK/code/logo_show.py :logo_show.py + fs cp QUICK/code/main.py :main.py + fs cp QUICK/code/display_smoke.py :display_smoke.py + fs cp QUICK/assets/openai_logo_240.jpg :openai_logo_240.jpg
uvx --from mpremote mpremote connect "$PORT" run QUICK/code/display_smoke.py
uvx --from mpremote mpremote connect "$PORT" run QUICK/code/logo_show.py
```

## What You Should See
- `display_smoke.py`: full-screen color sequence (red -> green -> blue -> white -> black), then `display_smoke: completed` on serial output
- `logo_show.py`: OpenAI logo centered on black background
- On reset/boot (`main.py`): OpenAI logo splash, then continuous Codex-style knot scene with only small dirty-region updates (center pulse + status rail)

## Asset Note
- Both BMP and JPEG logo assets are included.
- The bundled `gc9a01` MicroPython module renders JPEG directly (`tft.jpg(...)`), so runtime display uses `openai_logo_240.jpg`.

## If You Only See Backlight
- Check script boot errors:
  - `uvx --from mpremote mpremote connect "$PORT" exec "import main"`
- Confirm module availability:
  - `uvx --from mpremote mpremote connect "$PORT" exec "import gc9a01; print('ok')"`
- Ensure no serial-port grabber is running (for example `ModemManager` on Linux)

## Constraints
- Use `uv` for Python package/runtime management.
- Do not use `pip`.
- Do not add `requirements.txt`.
