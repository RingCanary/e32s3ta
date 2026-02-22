/*
 * First Zephyr app in this repo for Waveshare ESP32-S3-LCD-1.28:
 * render a static "Hello World" label to the onboard LCD.
 */

#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/display.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <lvgl.h>

LOG_MODULE_REGISTER(app, CONFIG_LOG_DEFAULT_LEVEL);

int main(void)
{
	const struct device *display_dev = DEVICE_DT_GET(DT_CHOSEN(zephyr_display));

	if (!device_is_ready(display_dev)) {
		LOG_ERR("Display device is not ready");
		return 0;
	}

	lv_obj_t *label = lv_label_create(lv_scr_act());
	lv_label_set_text(label, "Hello World!");
	lv_obj_set_style_text_font(label, &lv_font_montserrat_20, LV_PART_MAIN);
	lv_obj_align(label, LV_ALIGN_CENTER, 0, 0);

	lv_task_handler();
	display_blanking_off(display_dev);
	LOG_INF("LCD hello rendered");

	while (1) {
		lv_task_handler();
		k_sleep(K_MSEC(20));
	}
}

