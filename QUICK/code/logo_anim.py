"""
Codex-style logo animation for Waveshare ESP32-S3-LCD-1.28.

Uses only drawing calls confirmed in this firmware build:
- line
- fill_rect
"""

import math
import time
from machine import Pin, SPI
import gc9a01


def _color(r, g, b):
    return gc9a01.color565(r, g, b)


def _setup_display():
    spi = SPI(2, baudrate=60000000, polarity=0, sck=Pin(10), mosi=Pin(11))
    tft = gc9a01.GC9A01(
        spi,
        240,
        240,
        reset=Pin(12, Pin.OUT),
        cs=Pin(9, Pin.OUT),
        dc=Pin(8, Pin.OUT),
        backlight=Pin(40, Pin.OUT),
        rotation=0,
    )
    tft.init()
    return tft


def _draw_thick_line(tft, x1, y1, x2, y2, color, width=3):
    dx = abs(x2 - x1)
    dy = abs(y2 - y1)
    half = width // 2
    if dx >= dy:
        for offset in range(-half, half + 1):
            tft.line(x1, y1 + offset, x2, y2 + offset, color)
    else:
        for offset in range(-half, half + 1):
            tft.line(x1 + offset, y1, x2 + offset, y2, color)


def _draw_logo_frame(tft, frame):
    cx = 120
    cy = 112
    base = frame * 0.12
    outer_r = 74 + int(3 * math.sin(frame * 0.09))
    inner_r = 42 + int(2 * math.sin(frame * 0.11))

    outer = []
    inner = []
    for i in range(6):
        a = base + (math.pi / 3.0) * i
        outer.append((int(cx + outer_r * math.cos(a)), int(cy + outer_r * math.sin(a))))
        inner.append(
            (
                int(cx + inner_r * math.cos(a + math.pi / 6.0)),
                int(cy + inner_r * math.sin(a + math.pi / 6.0)),
            )
        )

    # Teal-forward palette with white accents for a Codex/OpenAI-like look.
    palette = (
        _color(10, 210, 185),
        _color(40, 160, 255),
        _color(120, 220, 255),
        _color(255, 255, 255),
        _color(90, 240, 210),
        _color(40, 210, 120),
    )

    tft.fill_rect(0, 0, 240, 240, gc9a01.BLACK)

    for i in range(6):
        c = palette[(i + (frame // 3)) % 6]
        x1, y1 = outer[i]
        x2, y2 = inner[i]
        x3, y3 = outer[(i + 1) % 6]
        _draw_thick_line(tft, x1, y1, x2, y2, c, 3)
        _draw_thick_line(tft, x2, y2, x3, y3, c, 3)

    # Center pulse.
    pulse = 10 + int(4 * (1 + math.sin(frame * 0.22)))
    tft.fill_rect(cx - pulse // 2, cy - pulse // 2, pulse, pulse, _color(235, 255, 250))

    # Animated status rail near bottom.
    rail_y = 214
    rail_w = 150
    rail_x = 45
    tft.fill_rect(rail_x, rail_y, rail_w, 4, _color(20, 40, 40))
    pos = (frame * 7) % (rail_w - 22)
    tft.fill_rect(rail_x + pos, rail_y, 22, 4, _color(60, 245, 210))


def run(frames=None, delay_ms=60):
    tft = _setup_display()
    frame = 0

    while True:
        _draw_logo_frame(tft, frame)
        frame += 1
        if frames is not None and frame >= frames:
            break
        time.sleep_ms(delay_ms)


if __name__ == "__main__":
    # Finite preview when run directly.
    run(frames=150, delay_ms=50)
