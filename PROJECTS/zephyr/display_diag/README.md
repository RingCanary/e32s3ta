# display_diag

Raw display diagnostic app for Waveshare ESP32-S3-LCD-1.28.

This project bypasses LVGL and writes color data directly with
`display_write()`, useful for panel/path bring-up and fault isolation.

## What it shows
- Full-screen 4-quadrant pattern:
  - top-left: red
  - top-right: green
  - bottom-left: blue
  - bottom-right: white
- Blinking center marker (yellow/black at 2 Hz) to confirm refresh updates

## Notes
- Includes non-touch board pin corrections in `app.overlay`:
  - LCD reset on `GPIO12`
  - SPI2 pinctrl changed to MOSI/SCLK/CS-only
- Touch input nodes are disabled to keep logs clean.

## Build

```bash
source ~/zephyrproject/.venv/bin/activate
cd ~/zephyrproject
west build -p always \
  -b esp32s3_touch_lcd_1_28/esp32s3/procpu \
  -s /path/to/repo/PROJECTS/zephyr/display_diag \
  -d /path/to/repo/PROJECTS/zephyr/display_diag/build
```

## Flash

```bash
sudo chmod 666 /dev/ttyACM0
cd ~/zephyrproject
west flash -d /path/to/repo/PROJECTS/zephyr/display_diag/build
```
