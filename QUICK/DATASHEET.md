# ESP32-S3-LCD-1.28 Datasheet Notes

Collected using `ddgr`, `lynx` (with condensed URL fetches), and web search.

## Board Identity
- Product: Waveshare `ESP32-S3-LCD-1.28` (non-touch variant)
- MCU: `ESP32-S3R2` (dual-core LX7 up to 240MHz)
- External memory: `16MB Flash` + `2MB PSRAM`
- Display: round `1.28"` IPS, `240x240`, driver `GC9A01A`, SPI
- IMU: `QMI8658` 6-axis
- USB-UART: `CH343P`

## Verified Board Pin Map (from Waveshare wiki)
- `GPIO8` LCD_DC
- `GPIO9` LCD_CS
- `GPIO10` LCD_CLK
- `GPIO11` LCD_MOSI
- `GPIO12` LCD_RST
- `GPIO40` LCD_BL
- `GPIO6` I2C SDA
- `GPIO7` I2C SCL
- `GPIO5` touch interrupt (board-dependent)

## Datasheets / Manuals
- ESP32-S3 Technical Reference Manual:
  - https://files.waveshare.com/wiki/common/Esp32-s3_technical_reference_manual_en.pdf
- ESP32-S3 Series Datasheet:
  - https://files.waveshare.com/wiki/common/Esp32-s3_datasheet_en.pdf
- GC9A01A LCD Driver Datasheet:
  - https://files.waveshare.com/wiki/common/GC9A01A.pdf
- QMI8658A IMU Datasheet:
  - https://files.waveshare.com/wiki/common/QMI8658A_Datasheet_Rev_A.pdf

## Board-Specific Reference Assets
- Waveshare wiki page:
  - https://www.waveshare.com/wiki/ESP32-S3-LCD-1.28
- Schematic:
  - https://files.waveshare.com/wiki/ESP32-S3-LCD-1.28/Esp32-s3-lcd-.128-sch.pdf
- Demo package (contains `Firmware/MicroPython-bin`):
  - https://files.waveshare.com/wiki/ESP32-S3-LCD-1.28/ESP32-S3-LCD-1.28-Demo.zip

## MicroPython Firmware Pulled
- File: `QUICK/firmware/S3-Touch-LCD-1.28-MPY.bin`
- SHA256: `c99a28209696d368ea1b0b0f9689678924ed735a96f42503aeb52a0df4ece7b7`
- Source path inside vendor demo zip: `Firmware/MicroPython-bin/S3-Touch-LCD-1.28-MPY.bin`

## Notes
- Waveshare’s supplied MicroPython image is used for fastest board bring-up because the demo scripts depend on the `gc9a01` module and board-specific pin defaults.
