"""
Display the OpenAI logo image once.

Requires `openai_logo_240.jpg` on the device filesystem.
"""

import time
from machine import Pin, SPI
import gc9a01


def main(path="openai_logo_240.jpg", hold_ms=2500):
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
    tft.fill_rect(0, 0, 240, 240, gc9a01.BLACK)
    tft.jpg(path, 0, 0, gc9a01.SLOW)
    time.sleep_ms(hold_ms)
    print("logo_show: completed")


main()
