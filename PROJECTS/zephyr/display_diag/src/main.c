/*
 * Raw display diagnostic for Waveshare ESP32-S3-LCD-1.28.
 * This app does not use LVGL; it writes color blocks directly via display_write().
 */

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/display.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(display_diag, CONFIG_LOG_DEFAULT_LEVEL);

#define DIAG_MAX_WIDTH 320
#define DIAG_MAX_BPP 4

struct rgb_color {
	uint8_t r;
	uint8_t g;
	uint8_t b;
};

static uint8_t line_buf[DIAG_MAX_WIDTH * DIAG_MAX_BPP];

static size_t bytes_per_pixel(enum display_pixel_format fmt)
{
	switch (fmt) {
	case PIXEL_FORMAT_RGB_888:
		return 3;
	case PIXEL_FORMAT_RGB_565:
	case PIXEL_FORMAT_BGR_565:
		return 2;
	default:
		return 0;
	}
}

static int fill_line(enum display_pixel_format fmt, uint16_t width, struct rgb_color c)
{
	if (width > DIAG_MAX_WIDTH) {
		return -EINVAL;
	}

	switch (fmt) {
	case PIXEL_FORMAT_RGB_888:
		for (uint16_t i = 0; i < width; i++) {
			line_buf[i * 3 + 0] = c.r;
			line_buf[i * 3 + 1] = c.g;
			line_buf[i * 3 + 2] = c.b;
		}
		return 0;

	case PIXEL_FORMAT_RGB_565: {
		uint16_t packed = ((uint16_t)(c.r & 0xF8) << 8) |
					 ((uint16_t)(c.g & 0xFC) << 3) |
					 ((uint16_t)(c.b) >> 3);
		for (uint16_t i = 0; i < width; i++) {
			line_buf[i * 2 + 0] = (packed >> 8) & 0xFF;
			line_buf[i * 2 + 1] = packed & 0xFF;
		}
		return 0;
	}

	case PIXEL_FORMAT_BGR_565: {
		uint16_t packed = ((uint16_t)(c.r & 0xF8) << 8) |
					 ((uint16_t)(c.g & 0xFC) << 3) |
					 ((uint16_t)(c.b) >> 3);
		for (uint16_t i = 0; i < width; i++) {
			line_buf[i * 2 + 0] = packed & 0xFF;
			line_buf[i * 2 + 1] = (packed >> 8) & 0xFF;
		}
		return 0;
	}

	default:
		return -ENOTSUP;
	}
}

static int draw_rect(const struct device *display_dev,
		     enum display_pixel_format fmt,
		     uint16_t x, uint16_t y, uint16_t w, uint16_t h,
		     struct rgb_color color)
{
	struct display_buffer_descriptor desc;
	size_t bpp = bytes_per_pixel(fmt);
	int rc;

	if ((w == 0U) || (h == 0U) || (bpp == 0U)) {
		return -EINVAL;
	}

	rc = fill_line(fmt, w, color);
	if (rc != 0) {
		return rc;
	}

	desc.width = w;
	desc.height = 1;
	desc.pitch = w;
	desc.buf_size = w * bpp;

	for (uint16_t row = 0; row < h; row++) {
		rc = display_write(display_dev, x, y + row, &desc, line_buf);
		if (rc != 0) {
			return rc;
		}
	}

	return 0;
}

int main(void)
{
	const struct device *display_dev = DEVICE_DT_GET(DT_CHOSEN(zephyr_display));
	const struct device *gpio0_dev = DEVICE_DT_GET(DT_NODELABEL(gpio0));
	struct display_capabilities caps;
	enum display_pixel_format fmt;
	bool marker_on = false;
	int rc;

	if (!device_is_ready(display_dev)) {
		LOG_ERR("Display device not ready");
		return 0;
	}

	if (device_is_ready(gpio0_dev)) {
		rc = gpio_pin_configure(gpio0_dev, 40, GPIO_OUTPUT_ACTIVE);
		if (rc != 0) {
			LOG_ERR("Failed to enable LCD backlight on GPIO40 (%d)", rc);
		}
	} else {
		LOG_ERR("GPIO0 device not ready");
	}

	display_get_capabilities(display_dev, &caps);
	fmt = caps.current_pixel_format;

	if (bytes_per_pixel(fmt) == 0U) {
		LOG_ERR("Unsupported pixel format for diag app: 0x%x", fmt);
		return 0;
	}

	if (caps.x_resolution > DIAG_MAX_WIDTH) {
		LOG_ERR("Screen width %u exceeds diag buffer max %u", caps.x_resolution, DIAG_MAX_WIDTH);
		return 0;
	}

	rc = display_blanking_off(display_dev);
	if (rc != 0) {
		LOG_ERR("display_blanking_off failed: %d", rc);
	}

	/* Full-screen color quadrants. */
	uint16_t x_mid = caps.x_resolution / 2U;
	uint16_t y_mid = caps.y_resolution / 2U;

	rc = draw_rect(display_dev, fmt, 0, 0, caps.x_resolution, caps.y_resolution,
		      (struct rgb_color){0, 0, 0});
	if (rc != 0) {
		LOG_ERR("Background draw failed: %d", rc);
		return 0;
	}

	rc = draw_rect(display_dev, fmt, 0, 0, x_mid, y_mid, (struct rgb_color){255, 0, 0});
	if (rc != 0) {
		LOG_ERR("Top-left draw failed: %d", rc);
		return 0;
	}

	rc = draw_rect(display_dev, fmt, x_mid, 0,
		      caps.x_resolution - x_mid, y_mid, (struct rgb_color){0, 255, 0});
	if (rc != 0) {
		LOG_ERR("Top-right draw failed: %d", rc);
		return 0;
	}

	rc = draw_rect(display_dev, fmt, 0, y_mid,
		      x_mid, caps.y_resolution - y_mid, (struct rgb_color){0, 0, 255});
	if (rc != 0) {
		LOG_ERR("Bottom-left draw failed: %d", rc);
		return 0;
	}

	rc = draw_rect(display_dev, fmt, x_mid, y_mid,
		      caps.x_resolution - x_mid, caps.y_resolution - y_mid,
		      (struct rgb_color){255, 255, 255});
	if (rc != 0) {
		LOG_ERR("Bottom-right draw failed: %d", rc);
		return 0;
	}

	LOG_INF("display_diag pattern rendered (%ux%u, fmt=0x%x)",
		caps.x_resolution, caps.y_resolution, fmt);

	/* Blinking center marker confirms continuous updates. */
	uint16_t marker_w = 24U;
	uint16_t marker_h = 24U;
	uint16_t marker_x = (caps.x_resolution - marker_w) / 2U;
	uint16_t marker_y = (caps.y_resolution - marker_h) / 2U;

	while (1) {
		struct rgb_color marker_color = marker_on ?
			(struct rgb_color){255, 200, 0} : (struct rgb_color){0, 0, 0};

		rc = draw_rect(display_dev, fmt, marker_x, marker_y, marker_w, marker_h, marker_color);
		if (rc != 0) {
			LOG_ERR("Marker draw failed: %d", rc);
		}

		marker_on = !marker_on;
		k_sleep(K_MSEC(500));
	}

	return 0;
}
