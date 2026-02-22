/*
 * First Zephyr app in this repo for Waveshare ESP32-S3-LCD-1.28:
 * render a simple animated "Hello World" scene to the onboard LCD.
 */

#include <stdio.h>
#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/display.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <lvgl.h>

LOG_MODULE_REGISTER(app, CONFIG_LOG_DEFAULT_LEVEL);

int main(void)
{
	const struct device *display_dev = DEVICE_DT_GET(DT_CHOSEN(zephyr_display));
	const struct device *gpio0_dev = DEVICE_DT_GET(DT_NODELABEL(gpio0));
	static const int8_t y_wave[] = {0, 1, 2, 3, 2, 1, 0, -1, -2, -3, -2, -1};
	static const char spin[] = "|/-\\";
	uint32_t frame = 0;
	lv_obj_t *screen;
	lv_obj_t *title;
	lv_obj_t *status;

	if (!device_is_ready(display_dev)) {
		LOG_ERR("Display device is not ready");
		return 0;
	}

	/* Waveshare ESP32-S3-LCD-1.28 (non-touch): backlight control is GPIO40. */
	if (device_is_ready(gpio0_dev)) {
		if (gpio_pin_configure(gpio0_dev, 40, GPIO_OUTPUT_ACTIVE) != 0) {
			LOG_ERR("Failed to enable LCD backlight on GPIO40");
		}
	} else {
		LOG_ERR("GPIO0 device is not ready");
	}

	screen = lv_scr_act();
	lv_obj_set_style_bg_opa(screen, LV_OPA_COVER, LV_PART_MAIN);
	lv_obj_set_style_bg_color(screen, lv_color_black(), LV_PART_MAIN);

	title = lv_label_create(screen);
	lv_label_set_text(title, "Hello World!");
	lv_obj_set_style_text_font(title, &lv_font_montserrat_20, LV_PART_MAIN);
	lv_obj_set_style_text_color(title, lv_color_white(), LV_PART_MAIN);
	lv_obj_align(title, LV_ALIGN_CENTER, 0, -12);

	status = lv_label_create(screen);
	lv_label_set_text(status, "Zephyr UI |");
	lv_obj_set_style_text_color(status, lv_color_hex(0x9AA3AB), LV_PART_MAIN);
	lv_obj_align(status, LV_ALIGN_CENTER, 0, 18);

	lv_task_handler();
	display_blanking_off(display_dev);
	LOG_INF("LCD hello rendered (animated)");

	while (1) {
		char status_text[24];
		int8_t dy = y_wave[frame % (sizeof(y_wave) / sizeof(y_wave[0]))];
		uint16_t hue = (frame * 8U) % 360U;

		snprintf(status_text, sizeof(status_text), "Zephyr UI %c", spin[frame & 0x3U]);
		lv_label_set_text(status, status_text);
		lv_obj_align(title, LV_ALIGN_CENTER, 0, -12 + dy);
		lv_obj_set_style_text_color(title, lv_color_hsv_to_rgb(hue, 90, 100), LV_PART_MAIN);

		lv_task_handler();
		k_sleep(K_MSEC(80));
		frame++;
	}
}
