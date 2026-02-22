# ESP32-S3-LCD-1.28 Quick Bring-up

This repository bootstraps a fresh embedded workflow for the Waveshare ESP32-S3-LCD-1.28 board using MicroPython.

## Current Status
- Compatible MicroPython firmware pulled: `QUICK/firmware/S3-Touch-LCD-1.28-MPY.bin`
- Firmware flashing flow validated with `uvx esptool`
- Display smoke test executed successfully: `display_smoke: completed`
- OpenAI logo assets prepared: BMP + JPEG in `QUICK/assets/`
- Boot demo deployed as `main.py` with a low-refresh Codex-style animation

## Layout
- `QUICK/firmware/`: firmware binary
- `QUICK/code/`: first MicroPython scripts (`display_smoke.py`, `logo_show.py`, `logo_anim.py`, `main.py`)
- `QUICK/assets/`: image assets (`openai_logo_240.bmp`, `openai_logo_240.jpg`)
- `QUICK/DATASHEET.md`: board and component datasheet links/notes
- `WORKLOG.md`: epoch-stamped progress log

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
