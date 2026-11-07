if (!instance_exists(obj_net) || obj_net.phase != "match") {
	left_active = false;
	right_active = false;
	shooting = false;
	reload_pressed = false;
	exit;
}

gui_w = display_get_gui_width();
gui_h = display_get_gui_height();
left_rest_x = 110;
left_rest_y = gui_h - 110;
right_rest_x = gui_w - 110;
right_rest_y = gui_h - 110;
reload_x1 = gui_w - 16 - reload_w;
reload_y1 = 64;
reload_x2 = reload_x1 + reload_w;
reload_y2 = reload_y1 + reload_h;

var _zone_mid_x = gui_w * 0.5;
var _zone_top = gui_h * 0.35;

reload_pressed = false;
var _reload_held = false;

// Release sticks if their finger lifted
if (left_active) {
	if (left_device < 0 || !device_mouse_check_button(left_device, mb_left)) {
		left_active = false;
		left_device = -1;
		left_nx = 0;
		left_ny = 0;
	}
}
if (right_active) {
	if (right_device < 0 || !device_mouse_check_button(right_device, mb_left)) {
		right_active = false;
		right_device = -1;
		right_nx = 0;
		right_ny = 0;
		right_mag = 0;
		shooting = false;
	}
}

for (var _d = 0; _d < TOUCH_MAX_DEVICES; _d++) {
	if (!device_mouse_check_button(_d, mb_left)) {
		continue;
	}

	var _tx = device_mouse_x_to_gui(_d);
	var _ty = device_mouse_y_to_gui(_d);

	// Reload button (top-right)
	if (point_in_rectangle(_tx, _ty, reload_x1, reload_y1, reload_x2, reload_y2)) {
		_reload_held = true;
		continue;
	}

	// Already claimed by a stick
	if (_d == left_device || _d == right_device) {
		continue;
	}

	// New press: assign to a free stick by screen side
	if (!left_active && _tx < _zone_mid_x && _ty > _zone_top) {
		left_active = true;
		left_device = _d;
		left_origin_x = _tx;
		left_origin_y = _ty;
	} else if (!right_active && _tx >= _zone_mid_x && _ty > _zone_top) {
		right_active = true;
		right_device = _d;
		right_origin_x = _tx;
		right_origin_y = _ty;
	}
}

if (_reload_held) {
	if (!reload_down) {
		reload_pressed = true;
	}
	reload_down = true;
} else {
	reload_down = false;
}

// Update left stick
if (left_active) {
	var _lx = device_mouse_x_to_gui(left_device);
	var _ly = device_mouse_y_to_gui(left_device);
	var _ldx = _lx - left_origin_x;
	var _ldy = _ly - left_origin_y;
	var _llen = point_distance(0, 0, _ldx, _ldy);
	if (_llen > stick_radius) {
		_ldx = (_ldx / _llen) * stick_radius;
		_ldy = (_ldy / _llen) * stick_radius;
		_llen = stick_radius;
	}
	left_knob_x = left_origin_x + _ldx;
	left_knob_y = left_origin_y + _ldy;
	left_nx = (_llen <= 0) ? 0 : (_ldx / stick_radius);
	left_ny = (_llen <= 0) ? 0 : (_ldy / stick_radius);
} else {
	left_knob_x = left_rest_x;
	left_knob_y = left_rest_y;
	left_origin_x = left_rest_x;
	left_origin_y = left_rest_y;
}

// Update right stick
if (right_active) {
	var _rx = device_mouse_x_to_gui(right_device);
	var _ry = device_mouse_y_to_gui(right_device);
	var _rdx = _rx - right_origin_x;
	var _rdy = _ry - right_origin_y;
	var _rlen = point_distance(0, 0, _rdx, _rdy);
	if (_rlen > stick_radius) {
		_rdx = (_rdx / _rlen) * stick_radius;
		_rdy = (_rdy / _rlen) * stick_radius;
		_rlen = stick_radius;
	}
	right_knob_x = right_origin_x + _rdx;
	right_knob_y = right_origin_y + _rdy;
	right_nx = (_rlen <= 0) ? 0 : (_rdx / stick_radius);
	right_ny = (_rlen <= 0) ? 0 : (_rdy / stick_radius);
	right_mag = point_distance(0, 0, right_nx, right_ny);
	if (right_mag > 0.05) {
		right_dir = point_direction(0, 0, right_nx, right_ny);
	}
	shooting = (right_mag >= TOUCH_FIRE_THRESHOLD);
} else {
	right_knob_x = right_rest_x;
	right_knob_y = right_rest_y;
	right_origin_x = right_rest_x;
	right_origin_y = right_rest_y;
	shooting = false;
}
