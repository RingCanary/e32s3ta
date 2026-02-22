# hello_lcd

First Zephyr project in this repository: render an animated `Hello World!`
scene on the Waveshare ESP32-S3-LCD-1.28 display.

## Notes
- Current bring-up mode is UART-only debugging.
- This app disables touch input in `app.overlay` to keep UART logs clean.
- `app.overlay` also applies non-touch board pin fixes:
  - LCD reset remapped to `GPIO12` (Waveshare ESP32-S3-LCD-1.28 pin map)
  - SPI2 pinctrl changed to MOSI/SCLK/CS only (to avoid GPIO12 MISO/reset conflict)
- App sets `CONFIG_MAIN_STACK_SIZE=4096` in `prj.conf` for stable LVGL runtime.

## Build

```bash
source ~/zephyrproject/.venv/bin/activate
export ZEPHYR_SDK_INSTALL_DIR=$HOME/zephyr-sdk-0.16.8

cd ~/zephyrproject
west build -p always \
  -b esp32s3_touch_lcd_1_28/esp32s3/procpu \
  -s /path/to/repo/PROJECTS/zephyr/hello_lcd \
  -d /path/to/repo/PROJECTS/zephyr/hello_lcd/build
```

## Flash

```bash
PORT=/dev/ttyACM0
sudo chmod 666 "$PORT"

cd ~/zephyrproject
west flash -d /path/to/repo/PROJECTS/zephyr/hello_lcd/build
```

## UART Check (non-interactive)

```bash
source ~/zephyrproject/.venv/bin/activate
python - <<'PY'
import serial, time

ser = serial.Serial('/dev/ttyACM0', 115200, timeout=0.05)
ser.setDTR(False)
ser.setRTS(True)
time.sleep(0.12)
ser.setRTS(False)
time.sleep(0.12)

end = time.time() + 6
buf = bytearray()
while time.time() < end:
    data = ser.read(2048)
    if data:
        buf.extend(data)
ser.close()

text = buf.decode('utf-8', errors='ignore')
print("*** Booting Zephyr OS ***" if "Booting Zephyr OS" in text else "Boot banner not found")
print("LCD hello rendered (animated)" if "LCD hello rendered" in text else "App marker not found")
PY
```
