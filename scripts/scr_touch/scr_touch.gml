#macro TOUCH_STICK_RADIUS 88
#macro TOUCH_STICK_DEADZONE 0.28
#macro TOUCH_FIRE_THRESHOLD 0.55
#macro TOUCH_MAX_DEVICES 5

/// @function input_stick_deadzone(_nx, _ny, _dead)
/// @description Remap stick so values inside deadzone are 0 and outside scale 0..1.
function input_stick_deadzone(_nx, _ny, _dead = TOUCH_STICK_DEADZONE) {
	var _mag = point_distance(0, 0, _nx, _ny);
	if (_mag <= _dead) {
		return [0, 0];
	}
	var _scale = (_mag - _dead) / max(0.001, 1 - _dead);
	_scale = clamp(_scale, 0, 1);
	return [(_nx / _mag) * _scale, (_ny / _mag) * _scale];
}

/// @function input_is_mobile_touch()
function input_is_mobile_touch() {
	return (os_type == os_android || os_type == os_ios);
}

/// @function ui_scale()
/// @description Layout / hit-target scale for mobile.
function ui_scale() {
	return input_is_mobile_touch() ? 1.55 : 1.0;
}

/// @function ui_text_scale()
/// @description Drawn text scale — larger on phones so labels stay readable.
function ui_text_scale() {
	return input_is_mobile_touch() ? 1.85 : 1.2;
}

/// @function ui_back_pressed()
/// @description Escape / Android system back. Ignores backspace while the
/// virtual keyboard is open so name typing is not treated as "go back".
function ui_back_pressed() {
	if (keyboard_check_pressed(vk_escape)) {
		return true;
	}
	if (input_is_mobile_touch()) {
		if (keyboard_virtual_status()) {
			return false;
		}
		return keyboard_check_pressed(vk_backspace);
	}
	return keyboard_check_pressed(vk_backspace);
}

/// @function match_hud_zoom_rect()
/// @description Top-right zoom button in GUI space: [x1,y1,x2,y2]
function match_hud_zoom_rect() {
	var _gw = display_get_gui_width();
	var _s = ui_scale();
	var _w = round(76 * _s);
	var _h = round(44 * _s);
	var _x2 = _gw - 12;
	var _x1 = _x2 - _w;
	var _y1 = 10;
	return [_x1, _y1, _x2, _y1 + _h];
}

/// @function match_hud_map_rect()
/// @description Map name panel sits just left of the zoom button.
function match_hud_map_rect() {
	var _z = match_hud_zoom_rect();
	var _s = ui_scale();
	var _w = round(140 * _s);
	var _x2 = _z[0] - 8;
	var _x1 = _x2 - _w;
	return [_x1, _z[1], _x2, _z[3]];
}

/// @function match_hud_exit_rect()
/// @description Exit Match button sits just left of the map panel.
function match_hud_exit_rect() {
	var _m = match_hud_map_rect();
	var _s = ui_scale();
	var _w = round(76 * _s);
	var _x2 = _m[0] - 8;
	var _x1 = _x2 - _w;
	return [_x1, _m[1], _x2, _m[3]];
}

/// @function ui_pointer_pressed_in(_x1, _y1, _x2, _y2, _use_gui)
function ui_pointer_pressed_in(_x1, _y1, _x2, _y2, _use_gui = false) {
	if (_x2 <= _x1 || _y2 <= _y1) {
		return false;
	}
	for (var _d = 0; _d < TOUCH_MAX_DEVICES; _d++) {
		if (!device_mouse_check_button_pressed(_d, mb_left)) {
			continue;
		}
		var _px = _use_gui ? device_mouse_x_to_gui(_d) : device_mouse_x(_d);
		var _py = _use_gui ? device_mouse_y_to_gui(_d) : device_mouse_y(_d);
		if (point_in_rectangle(_px, _py, _x1, _y1, _x2, _y2)) {
			return true;
		}
	}

	if (mouse_check_button_pressed(mb_left)) {
		var _mx = _use_gui ? device_mouse_x_to_gui(0) : mouse_x;
		var _my = _use_gui ? device_mouse_y_to_gui(0) : mouse_y;
		if (point_in_rectangle(_mx, _my, _x1, _y1, _x2, _y2)) {
			return true;
		}
	}
	return false;
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

/// @function draw_ui_button(_x1, _y1, _x2, _y2, _label, _selected, _text_scale)
function draw_ui_button(_x1, _y1, _x2, _y2, _label, _selected = false, _text_scale = undefined) {
	var _ts = (_text_scale == undefined) ? ui_text_scale() : _text_scale;
	draw_set_color(_selected ? c_dkgray : make_color_rgb(28, 28, 28));
	draw_rectangle(_x1, _y1, _x2, _y2, false);
	draw_set_color(_selected ? c_lime : c_white);
	draw_rectangle(_x1, _y1, _x2, _y2, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text_transformed((_x1 + _x2) * 0.5, (_y1 + _y2) * 0.5, _label, _ts, _ts, 0);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
}

/// @function draw_ui_text(_x, _y, _text, _scale_mul)
function draw_ui_text(_x, _y, _text, _scale_mul = 1) {
	var _ts = ui_text_scale() * _scale_mul;
	draw_text_transformed(_x, _y, _text, _ts, _ts, 0);
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
