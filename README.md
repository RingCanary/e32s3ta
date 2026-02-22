# ESP32-S3-LCD-1.28 Quick Bring-up

This repository bootstraps a fresh embedded workflow for the Waveshare ESP32-S3-LCD-1.28 board using MicroPython.

## Goals
- Fetch and pin a compatible MicroPython firmware image.
- Flash the firmware via Raspberry Pi 5 (`$DEV_DEVICE`).
- Add first MicroPython program to drive the onboard display.
- Keep all quickstart artifacts inside `QUICK/`.

## Layout
- `QUICK/firmware/`: downloaded firmware binaries
- `QUICK/code/`: first MicroPython app/scripts
- `QUICK/DATASHEET.md`: hardware/datasheet notes
- `WORKLOG.md`: timestamped task log (epoch)

## Constraints
- Python tooling is managed with `uv`.
- `pip` and `requirements.txt` are not used.
