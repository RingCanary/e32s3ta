"""
Minimal display smoke test for Waveshare ESP32-S3-LCD-1.28.
Runs once, cycling full-screen colors so we can visually confirm panel bring-up.
"""

import time
from machine import Pin, SPI
import gc9a01


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

for color in (gc9a01.RED, gc9a01.GREEN, gc9a01.BLUE, gc9a01.WHITE, gc9a01.BLACK):
    tft.fill(color)
    time.sleep(0.6)

# End on black to avoid max backlight current after the test.
tft.fill(gc9a01.BLACK)
print("display_smoke: completed")
