"""
Codex-style boot animation optimized for low refresh cost.

Rendering strategy:
1) Draw static scene once.
2) Animate only tiny dirty regions (center pulse + bottom rail).
"""

import math
import time
from machine import Pin, SPI
import gc9a01

WIDTH = 240
HEIGHT = 240
CX = 120
CY = 112

BG = gc9a01.BLACK
PULSE_COLOR = gc9a01.color565(235, 255, 250)
RAIL_BG = gc9a01.color565(20, 40, 40)
RAIL_FG = gc9a01.color565(60, 245, 210)
KNOT_COLORS = (
    gc9a01.color565(10, 210, 185),
    gc9a01.color565(40, 160, 255),
    gc9a01.color565(120, 220, 255),
    gc9a01.color565(255, 255, 255),
    gc9a01.color565(90, 240, 210),
    gc9a01.color565(40, 210, 120),
)


def _setup_display():
    spi = SPI(2, baudrate=60000000, polarity=0, sck=Pin(10), mosi=Pin(11))
    tft = gc9a01.GC9A01(
        spi,
        WIDTH,
        HEIGHT,
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


def _hex_points(cx, cy, radius, phase_deg):
    out = []
    for i in range(6):
        a = math.radians(phase_deg + i * 60)
        out.append((int(cx + radius * math.cos(a)), int(cy + radius * math.sin(a))))
    return out


def _draw_static_knot(tft):
    outer = _hex_points(CX, CY, 74, 0)
    inner = _hex_points(CX, CY, 46, 30)
    tft.fill_rect(0, 0, WIDTH, HEIGHT, BG)
    for i in range(6):
        c = KNOT_COLORS[i]
        x1, y1 = outer[i]
        x2, y2 = inner[i]
        x3, y3 = outer[(i + 1) % 6]
        _draw_thick_line(tft, x1, y1, x2, y2, c, 3)
        _draw_thick_line(tft, x2, y2, x3, y3, c, 3)


def _show_logo(tft, path="openai_logo_240.jpg", hold_ms=1400):
    try:
        tft.fill_rect(0, 0, WIDTH, HEIGHT, BG)
        tft.jpg(path, 0, 0, gc9a01.SLOW)
        time.sleep_ms(hold_ms)
    except Exception:
        # Continue boot animation even if file decode is unavailable.
        pass


def run(frames=None, delay_ms=85, logo_path="openai_logo_240.jpg"):
    tft = _setup_display()
    _show_logo(tft, logo_path)
    _draw_static_knot(tft)

    rail_x = 45
    rail_y = 214
    rail_w = 150
    slider_w = 22
    tft.fill_rect(rail_x, rail_y, rail_w, 4, RAIL_BG)

    step = 0
    prev_pulse = -1
    prev_slider = -1

    while True:
        # Triangle wave pulse: small area update around the center.
        phase = step & 31
        pulse = 8 + ((phase if phase < 16 else (31 - phase)) >> 1)
        if pulse != prev_pulse:
            if prev_pulse > 0:
                tft.fill_rect(CX - (prev_pulse >> 1), CY - (prev_pulse >> 1), prev_pulse, prev_pulse, BG)
            tft.fill_rect(CX - (pulse >> 1), CY - (pulse >> 1), pulse, pulse, PULSE_COLOR)
            prev_pulse = pulse

        # Sweep rail: erase old slider and draw new slider only.
        slider = (step * 3) % (rail_w - slider_w)
        if slider != prev_slider:
            if prev_slider >= 0:
                tft.fill_rect(rail_x + prev_slider, rail_y, slider_w, 4, RAIL_BG)
            tft.fill_rect(rail_x + slider, rail_y, slider_w, 4, RAIL_FG)
            prev_slider = slider

        step += 1
        if frames is not None and step >= frames:
            break
        time.sleep_ms(delay_ms)


if __name__ == "__main__":
    run(frames=220, delay_ms=75)
