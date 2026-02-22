# Zephyr ESP32-S3 Debug Recon (Latest vs LTS)

Date: 2026-02-22

## Scope
- Compare latest upstream Zephyr/Espressif debug guidance against our LTS (`v3.7.1`) workflow.
- Keep actionable config/code snapshots in-repo.
- Document blockers, root causes, and mitigation paths.

## Upstream Snapshot Used
- Zephyr `main` fetched in Pi workspace at commit: `251fe8177b9`
- Relevant upstream files reviewed:
  - `boards/waveshare/esp32s3_touch_lcd_1_28/support/openocd.cfg`
  - `boards/espressif/common/openocd-debugging.rst`

## Upstream Delta We Adopted
- `openocd.cfg` delta (`main` vs `v3.7.1`):
  - `set ESP_RTOS none` -> `set ESP_RTOS Zephyr`
  - `set ESP32_ONLYCPU 1` -> `set ESP_ONLYCPU 1`
- In-repo mirror added:
  - `configs/openocd/esp32s3_touch_lcd_1_28.openocd.main.cfg`
  - Source metadata tracked in `configs/openocd/README.md`

## Non-Interactive Flows Added
- Monitor backend (idf_monitor) capture:
  - `scripts/zephyr_idf_monitor_capture.sh`
  - Uses the same backend process as `west espressif monitor`:
    - `modules/hal/espressif/tools/idf_monitor/idf_monitor.py`
  - Runs with `script + timeout` for headless/non-interactive sessions.
- OpenOCD + xtensa-gdb batch flow:
  - `scripts/zephyr_openocd_gdb_batch.sh`
  - Adds hard precheck for ESP USB-JTAG VID:PID `303a:1001`.

## Issues Seen and Mitigations
- Issue: `west espressif monitor` fails in non-interactive SSH (`termios` TTY error).
  - Mitigation: use `idf_monitor.py` through pseudo-TTY (`script`) + bounded timeout.
- Issue: direct `idf_monitor.py` call fails with missing `build_helpers`.
  - Mitigation: export `PYTHONPATH=$ZEPHYR_BASE/scripts/west_commands` before launch.
- Issue: Zephyr SDK bundled OpenOCD lacked required ESP scripts (`interface/esp_usb_jtag.cfg`).
  - Mitigation: install system OpenOCD with ESP32-S3 script support and allow script-path override.
- Issue: OpenOCD debug unavailable on current physical USB link.
  - Evidence: Pi `lsusb` shows `1a86:55d3` (QinHeng USB serial), not `303a:1001`.
  - Root cause: USB-UART bridge provides serial flashing/monitor only; no USB-JTAG endpoint.
  - Mitigation: connect native ESP32-S3 USB D+/D- debug port (or external JTAG probe).

## Practical Status
- Flash + serial runtime verification works and is stable.
- Non-interactive monitor capture works and is scripted.
- GDB/OpenOCD scripting is prepared, but blocked until USB-JTAG endpoint is present.

## Module USB/Pinout Study (Waveshare ESP32-S3-LCD-1.28)
| Area | Board Net / Function | ESP32-S3 Pin | Notes |
|---|---|---|---|
| USB-C D+ / D- | `DP1/DP2`, `DN1/DN2` -> `USB_P/USB_N` -> CH343P `UD+`/`UD-` | Not direct to native USB path | USB data pair is routed through CH343P USB-UART bridge path |
| USB serial bridge | CH343P UART path | `GPIO43` (`U0TXD`), `GPIO44` (`U0RXD`) | Primary flashing/log serial path over USB-C |
| Auto download | CH343P DTR/RTS control | `GPIO0` + reset line | Used for boot/reset automation |
| LCD SPI | `LCD_DC`, `LCD_CS`, `LCD_CLK`, `LCD_MOSI`, `LCD_RST` | `GPIO8`, `GPIO9`, `GPIO10`, `GPIO11`, `GPIO12` | Occupied by display |
| LCD backlight | `LCD_BL` | `GPIO40` | Occupied by display backlight |
| IMU I2C | `SDA`, `SCL` | `GPIO6`, `GPIO7` | Occupied by QMI8658 |
| IMU interrupts | `INT1`, `INT2` | `GPIO47`, `GPIO48` | Occupied by QMI8658 |
| Battery sense | `BAT_ADC` divider | `GPIO1` | Occupied by battery voltage monitor |
| JTAG signals (header) | `MTCK`, `MTDO`, `MTDI`, `MTMS` | `GPIO39`, `GPIO40`, `GPIO41`, `GPIO42` | Exposed, but note GPIO40 overlap with LCD backlight |

Decision:
- Current debug policy for this module is `UART-only` until a USB-JTAG-capable path/probe is available.
- Non-interactive monitor capture is the default verification method in this repo.

## UART-Only Validation (hello_lcd)
- Project: `PROJECTS/zephyr/hello_lcd`
- Build/flash target: `esp32s3_touch_lcd_1_28/esp32s3/procpu`
- Verified markers over UART after flash:
  - `*** Booting Zephyr OS build v3.7.1 ***`
  - `<inf> app: LCD hello rendered`
- Touch controller logs were initially noisy (`cst816s` + `i2c_esp32` transfer errors).
- Mitigation adopted for this display-only app:
  - `PROJECTS/zephyr/hello_lcd/app.overlay` disables `&cst816s` and root `lvgl_pointer`.
  - Result: zero CST/I2C error spam in UART capture for this app.

## Sources
- Zephyr latest espressif OpenOCD guidance:
  - https://docs.zephyrproject.org/latest/boards/espressif/common/openocd-debugging.html
- Zephyr latest esp32s3_touch_lcd_1_28 board docs:
  - https://docs.zephyrproject.org/latest/boards/waveshare/esp32s3_touch_lcd_1_28/doc/index.html
- Espressif ESP32-S3 JTAG debugging:
  - https://docs.espressif.com/projects/esp-idf/en/release-v5.3/esp32s3/api-guides/jtag-debugging/index.html
