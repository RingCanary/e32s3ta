"""
Default boot demo: rotating color screens to verify display operation.
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

palette = (
    gc9a01.RED,
    gc9a01.ORANGE,
    gc9a01.YELLOW,
    gc9a01.GREEN,
    gc9a01.CYAN,
    gc9a01.BLUE,
    gc9a01.MAGENTA,
    gc9a01.BLACK,
)

while True:
    for color in palette:
        tft.fill(color)
        time.sleep(0.8)
