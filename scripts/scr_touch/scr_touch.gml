#macro TOUCH_STICK_RADIUS 72
#macro TOUCH_STICK_DEADZONE 0.28
#macro TOUCH_FIRE_THRESHOLD 0.55
#macro TOUCH_MAX_DEVICES 5

/// @function input_is_mobile_touch()
/// @description True on phones/tablets where taps must not act as mouse fire.
function input_is_mobile_touch() {
	return (os_type == os_android || os_type == os_ios);
}

/// @function draw_ui_panel(_x1, _y1, _x2, _y2, _alpha)
function draw_ui_panel(_x1, _y1, _x2, _y2, _alpha = 0.45) {
	var _old_a = draw_get_alpha();
	var _old_c = draw_get_color();
	draw_set_alpha(_alpha);
	draw_set_color(c_black);
	draw_rectangle(_x1, _y1, _x2, _y2, false);
	draw_set_alpha(min(1, _alpha + 0.25));
	draw_set_color(c_white);
	draw_rectangle(_x1, _y1, _x2, _y2, true);
	draw_set_alpha(_old_a);
	draw_set_color(_old_c);
}

/// @function draw_touch_stick(_cx, _cy, _knob_x, _knob_y, _radius, _active)
function draw_touch_stick(_cx, _cy, _knob_x, _knob_y, _radius, _active) {
	var _old_a = draw_get_alpha();
	var _old_c = draw_get_color();

	draw_set_alpha(_active ? 0.35 : 0.22);
	draw_set_color(c_black);
	draw_circle(_cx, _cy, _radius, false);
	draw_set_alpha(_active ? 0.55 : 0.35);
	draw_set_color(c_white);
	draw_circle(_cx, _cy, _radius, true);

	draw_set_alpha(_active ? 0.55 : 0.30);
	draw_set_color(c_ltgray);
	draw_circle(_knob_x, _knob_y, _radius * 0.38, false);
	draw_set_alpha(_active ? 0.85 : 0.45);
	draw_set_color(c_white);
	draw_circle(_knob_x, _knob_y, _radius * 0.38, true);

	draw_set_alpha(_old_a);
	draw_set_color(_old_c);
}
