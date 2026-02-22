# ESP32-S3-LCD-1.28 Quick Bring-up

This repository bootstraps a fresh embedded workflow for the Waveshare ESP32-S3-LCD-1.28 board using MicroPython.

## Current Status
- Compatible MicroPython firmware pulled: `QUICK/firmware/S3-Touch-LCD-1.28-MPY.bin`
- Firmware flashed to attached board on Pi5 (`/dev/ttyACM0`) using `uvx esptool`
- Display smoke test executed successfully: `display_smoke: completed`
- Boot demo deployed as `main.py` to cycle display colors

## Layout
- `QUICK/firmware/`: firmware binary
- `QUICK/code/`: first MicroPython scripts (`display_smoke.py`, `main.py`)
- `QUICK/DATASHEET.md`: board and component datasheet links/notes
- `WORKLOG.md`: epoch-stamped progress log

## Reproducible Flash Flow (Pi5)
- SSH target is provided by env var `DEV_DEVICE`
- Python tooling on Pi5 uses `uv`/`uvx` (no `pip`, no `requirements.txt`)

```bash
# 1) Copy artifacts to Pi5
scp -o IdentitiesOnly=yes -i ~/.ssh/id_rsa_glmpitwo QUICK/firmware/S3-Touch-LCD-1.28-MPY.bin rpc@rpilm3.local:/tmp/esp32_quick/
scp -o IdentitiesOnly=yes -i ~/.ssh/id_rsa_glmpitwo QUICK/code/display_smoke.py QUICK/code/main.py rpc@rpilm3.local:/tmp/esp32_quick/

# 2) Flash firmware with uvx esptool
$DEV_DEVICE 'sudo chmod 666 /dev/ttyACM0'
$DEV_DEVICE '~/.local/bin/uvx --from esptool esptool --chip esp32s3 --port /dev/ttyACM0 --baud 460800 erase-flash'
$DEV_DEVICE '~/.local/bin/uvx --from esptool esptool --chip esp32s3 --port /dev/ttyACM0 --baud 460800 write-flash 0x0 /tmp/esp32_quick/S3-Touch-LCD-1.28-MPY.bin'

# 3) Verify runtime and display module
$DEV_DEVICE '~/.local/bin/uvx --from mpremote mpremote connect /dev/ttyACM0 exec "import sys; print(sys.implementation); import gc9a01; print(\"gc9a01 ok\")"'

# 4) Upload code and run smoke test
$DEV_DEVICE '~/.local/bin/uvx --from mpremote mpremote connect /dev/ttyACM0 fs cp /tmp/esp32_quick/display_smoke.py :display_smoke.py + fs cp /tmp/esp32_quick/main.py :main.py'
$DEV_DEVICE '~/.local/bin/uvx --from mpremote mpremote connect /dev/ttyACM0 run /tmp/esp32_quick/display_smoke.py'
```

## Constraints
- Use `uv` for Python package/runtime management.
- Do not use `pip`.
- Do not add `requirements.txt`.
