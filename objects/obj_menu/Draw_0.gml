var _s = ui_scale();
var _ts = ui_text_scale();

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text_transformed(room_width * 0.5, room_height * 0.12, "TROOPER 2D", _ts * 1.35, _ts * 1.35, 0);
draw_set_color(c_ltgray);
draw_text_transformed(room_width * 0.5, room_height * 0.20, "Trooper: " + global.player_name, _ts, _ts, 0);

btn_cancel_connect = [0, 0, 0, 0];
name_box = [0, 0, 0, 0];
btn_save = [0, 0, 0, 0];
btn_cancel = [0, 0, 0, 0];

if (menu_state == "connecting") {
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, room_height * 0.42, "Connecting...", _ts, _ts, 0);
	draw_set_color(c_ltgray);
	draw_text_transformed(room_width * 0.5, room_height * 0.52, "Timeout in " + string(max(0, ceil((connect_timeout - connect_timer) / 60))) + "s", _ts * 0.9, _ts * 0.9, 0);

	var _bw = button_w;
	var _bh = button_h;
	var _bx1 = (room_width - _bw) * 0.5;
	var _by1 = room_height * 0.64;
	btn_cancel_connect = [_bx1, _by1, _bx1 + _bw, _by1 + _bh];
	draw_ui_button(_bx1, _by1, _bx1 + _bw, _by1 + _bh, "Cancel", false);
} else if (menu_state == "customize") {
	// Keep the name field in the upper band so the OS keyboard never covers it.
	var _safe_bottom = room_height * 0.52;
	if (input_is_mobile_touch()) {
		var _kh = keyboard_virtual_height();
		if (_kh > 0) {
			var _frac = clamp(_kh / max(1, display_get_height()), 0.25, 0.65);
			_safe_bottom = room_height * (1 - _frac) - round(16 * _s);
		} else {
			_safe_bottom = room_height * 0.48;
		}
	}

	var _btn_h = round(58 * _s);
	var _btn_w = round(170 * _s);
	var _gap = round(20 * _s);
	var _top_y = room_height * 0.08;

	// Cancel / Save sit at the very top so they stay above the keyboard.
	btn_cancel = [_gap, _top_y, _gap + _btn_w, _top_y + _btn_h];
	btn_save = [room_width - _gap - _btn_w, _top_y, room_width - _gap, _top_y + _btn_h];
	draw_ui_button(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], "Cancel", false);
	draw_ui_button(btn_save[0], btn_save[1], btn_save[2], btn_save[3], "Save", false);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, _top_y + _btn_h * 0.5, "Customize", _ts, _ts, 0);

	var _box_w = min(room_width - round(80 * _s), round(520 * _s));
	var _box_h = round(72 * _s);
	var _bx1 = (room_width - _box_w) * 0.5;
	var _by1 = _top_y + _btn_h + round(28 * _s);
	var _by2 = _by1 + _box_h;
	if (_by2 > _safe_bottom - round(8 * _s)) {
		_by2 = _safe_bottom - round(8 * _s);
		_by1 = max(_top_y + _btn_h + round(12 * _s), _by2 - _box_h);
	}
	name_box = [_bx1, _by1, _bx1 + _box_w, _by2];

	draw_set_color(make_color_rgb(20, 20, 20));
	draw_rectangle(name_box[0], name_box[1], name_box[2], name_box[3], false);
	draw_set_color(c_lime);
	draw_rectangle(name_box[0], name_box[1], name_box[2], name_box[3], true);

	var _caret = ((customize_blink div 30) mod 2 == 0) ? "|" : "";
	var _name_scale = _ts * 1.15;
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, (name_box[1] + name_box[3]) * 0.5, keyboard_string + _caret, _name_scale, _name_scale, 0);
} else {
	for (var _i = 0; _i < menu_count; _i++) {
		var _bx1 = menu_x;
		var _by1 = menu_y + _i * (button_h + button_gap);
		var _bx2 = _bx1 + button_w;
		var _by2 = _by1 + button_h;
		draw_ui_button(_bx1, _by1, _bx2, _by2, menu_labels[_i], _i == menu_index);
	}
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
