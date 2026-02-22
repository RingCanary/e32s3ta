# Development Stack Comparison (ESP32-S3-LCD-1.28)

Date: 2026-02-22

Scope: Waveshare `ESP32-S3-LCD-1.28` (non-touch board variant).

## Decision Override
- User-selected path: `Zephyr RTOS`.
- Current implementation track starts with `ZEPHYR_LTS_PI5_SETUP.md` (LTS3 line).

## Recommendation (Short)
- Primary stack for serious product development: `ESP-IDF`.
- Secondary spike after ESP-IDF baseline: `Zephyr RTOS`.
- Parallel exploratory spike: `Embedded Rust` on `esp-hal` (Embassy only if async is required).
- Defer `bare-metal C from scratch` for production unless you have a very specific reason and budget for platform work.

## Comparison Table

| Stack | Maturity Snapshot (as of 2026-02-22) | Board Fit for This Hardware | Bring-up Effort | Main Pros | Main Risks / Gaps | Recommendation |
|---|---|---|---|---|---|---|
| Bare-metal C from scratch | No official Espressif bare-metal framework; ESP-IDF is the official framework for ESP32 family | No board scaffold; you own startup/linker/boot integration | Very high | Maximum control, minimal abstraction | You must replicate boot/startup concerns (ROM + second-stage bootloader + partition model + app startup path) [inference from ESP-IDF startup flow], slower time-to-first-feature | Not recommended as first serious stack |
| ESP-IDF | Official framework; latest release `v5.5.3` (2026-02-18) | Best fit; vendor-native support path for ESP32-S3 | Medium | Most complete docs, drivers, examples, tooling, long-term vendor alignment | Vendor-specific APIs, C/C++ ergonomics, FreeRTOS-centric model | **Recommended baseline** |
| Zephyr RTOS | Latest release `v4.3.0` (2025-11-13); board docs include `esp32s3_touch_lcd_1_28` | Good but not exact: our board is non-touch while Zephyr board is touch variant | Medium-high | Strong RTOS architecture, devicetree/Kconfig discipline, portability | Requires adaptation from touch board to non-touch board config; still depends on Espressif blobs (`west blobs fetch hal_espressif`) | Recommended as second-stage evaluation |
| Embedded Rust (`esp-hal`) | `esp-hal` reached `1.0.0`; crate docs show stable + unstable split | Good for low-level MCU work; ecosystem moving quickly | Medium-high | Memory safety, modern async options, high code quality potential | Many APIs/modules still marked `unstable`; `esp-hal-embassy` and `esp-wifi` currently require `esp-hal` unstable feature | Recommended as focused spike, not first production baseline |

## Board-Specific Notes
- Waveshare documents this product as **non-touch** and distinguishes it from `ESP32-S3-Touch-LCD-1.28`.
- Zephyr has a documented board target for the **touch** model (`esp32s3_touch_lcd_1_28`), which is close but not identical to our hardware.
- Practical implication: Zephyr likely needs board overlay / DTS / Kconfig adjustments for non-touch behavior.

## Decision Guidance

1. Pick `ESP-IDF` for the first full implementation milestone.
2. Keep Zephyr and Rust as controlled spikes (time-boxed) once baseline hardware drivers are stable.
3. Gate each spike on objective criteria:
   - Display + IMU + storage + update path all working
   - Debugging workflow quality (flash, monitor, breakpoints)
   - Build reproducibility and CI friction
   - Team velocity and maintainability

## Suggested Next Milestones

1. `ESP-IDF` bring-up repo skeleton: board config, display driver path, IMU readout, build+flash scripts.
2. `Zephyr` spike: boot `hello_world`, then display draw on closest board target + overlay.
3. `Rust` spike: `esp-hal` blinky + SPI display primitive; add Embassy only if async need is proven.

## Sources

- ESP-IDF official status and ESP32-S3 guide:
  - https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/
  - https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/get-started/
- ESP-IDF startup flow (bootloader/partition/app startup details):
  - https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/api-guides/startup.html
- ESP-IDF latest release:
  - https://github.com/espressif/esp-idf/releases/tag/v5.5.3
- Zephyr releases:
  - https://github.com/zephyrproject-rtos/zephyr/releases/tag/v4.3.0
  - https://docs.zephyrproject.org/latest/releases/index.html
- Zephyr Waveshare ESP32-S3 touch board docs:
  - https://docs.zephyrproject.org/latest/boards/waveshare/esp32s3_touch_lcd_1_28/doc/index.html
- Zephyr board index (shows available ESP32-S3 boards):
  - https://docs.zephyrproject.org/latest/boards/index.html
- Waveshare non-touch vs touch variant distinction:
  - https://www.waveshare.com/wiki/ESP32-S3-LCD-1.28
- Rust on ESP book (stability guidance):
  - https://esp-rs.github.io/book/
- `esp-hal` release and docs:
  - https://github.com/esp-rs/esp-hal/releases/tag/esp-hal-v1.0.0
  - https://docs.espressif.com/projects/rust/esp-hal/1.0.0/esp32s3/esp_hal/index.html
- `esp-hal-embassy` docs (requires `esp-hal` unstable feature):
  - https://docs.rs/crate/esp-hal-embassy/latest
  - https://docs.espressif.com/projects/rust/esp-hal-embassy/0.9.0/esp32s3/esp_hal_embassy/index.html
- `esp-wifi` crate status:
  - https://docs.rs/crate/esp-wifi/latest
