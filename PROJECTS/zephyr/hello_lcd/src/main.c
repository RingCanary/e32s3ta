/*
 * First Zephyr app in this repo for Waveshare ESP32-S3-LCD-1.28:
 * render a static "Hello World" label to the onboard LCD.
 */

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

	if (!device_is_ready(display_dev)) {
		LOG_ERR("Display device is not ready");
		return 0;
	}

	/* Waveshare ESP32-S3-LCD-1.28 (non-touch): backlight control is GPIO40. */
	if (device_is_ready(gpio0_dev)) {
		if (gpio_pin_configure(gpio0_dev, 40, GPIO_OUTPUT_ACTIVE) != 0) {
			LOG_ERR("Failed to enable LCD backlight on GPIO40");
		} else {
			/* Visible probe: pulse backlight a few times during boot. */
			for (int i = 0; i < 3; i++) {
				gpio_pin_set(gpio0_dev, 40, 0);
				k_sleep(K_MSEC(120));
				gpio_pin_set(gpio0_dev, 40, 1);
				k_sleep(K_MSEC(120));
			}
		}
	} else {
		LOG_ERR("GPIO0 device is not ready");
	}

	lv_obj_t *screen = lv_scr_act();
	lv_obj_set_style_bg_opa(screen, LV_OPA_COVER, LV_PART_MAIN);
	lv_obj_set_style_bg_color(screen, lv_color_black(), LV_PART_MAIN);

	lv_obj_t *label = lv_label_create(screen);
	lv_label_set_text(label, "Hello World!");
	lv_obj_set_style_text_font(label, &lv_font_montserrat_20, LV_PART_MAIN);
	lv_obj_set_style_text_color(label, lv_color_white(), LV_PART_MAIN);
	lv_obj_align(label, LV_ALIGN_CENTER, 0, 0);

	lv_task_handler();
	display_blanking_off(display_dev);
	LOG_INF("LCD hello rendered");

	while (1) {
		lv_task_handler();
		k_sleep(K_MSEC(20));
	}
}
