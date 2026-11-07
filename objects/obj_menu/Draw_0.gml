var _s = ui_scale();

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text_transformed(room_width * 0.5, room_height * 0.14, "TROOPER 2D", _s * 1.15, _s * 1.15, 0);
draw_set_color(c_ltgray);
draw_text_transformed(room_width * 0.5, room_height * 0.21, "LAN arena shooter", _s, _s, 0);
draw_text_transformed(room_width * 0.5, room_height * 0.27, "Playing as: " + global.player_name, _s, _s, 0);

btn_cancel_connect = [0, 0, 0, 0];
name_box = [0, 0, 0, 0];
btn_save = [0, 0, 0, 0];
btn_cancel = [0, 0, 0, 0];

if (menu_state == "connecting") {
	draw_set_color(c_white);
	draw_text(room_width * 0.5, room_height * 0.42, "Connecting...");
	draw_set_color(c_ltgray);
	draw_text(room_width * 0.5, room_height * 0.49, "Looking for host at " + global.join_ip);
	draw_text(room_width * 0.5, room_height * 0.55, "Ports " + string(NET_PORT_MIN) + "-" + string(NET_PORT_MAX));

	var _seconds_left = max(0, ceil((connect_timeout - connect_timer) / 60));
	draw_text(room_width * 0.5, room_height * 0.62, "Timeout in " + string(_seconds_left) + "s");

	var _bw = button_w;
	var _bh = button_h;
	var _bx1 = (room_width - _bw) * 0.5;
	var _by1 = room_height * 0.72;
	var _bx2 = _bx1 + _bw;
	var _by2 = _by1 + _bh;
	btn_cancel_connect = [_bx1, _by1, _bx2, _by2];
	draw_ui_button(_bx1, _by1, _bx2, _by2, "Cancel", false);
} else if (menu_state == "customize") {
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, room_height * 0.36, "Customize", _s, _s, 0);
	draw_set_color(c_ltgray);
	draw_text(room_width * 0.5, room_height * 0.42, "Type your player name");

	var _box_w = round(360 * _s);
	var _box_h = round(56 * _s);
	var _bx1 = (room_width - _box_w) * 0.5;
	var _by1 = room_height * 0.48;
	var _bx2 = _bx1 + _box_w;
	var _by2 = _by1 + _box_h;
	name_box = [_bx1, _by1, _bx2, _by2];

	draw_set_color(make_color_rgb(28, 28, 28));
	draw_rectangle(_bx1, _by1, _bx2, _by2, false);
	draw_set_color(c_lime);
	draw_rectangle(_bx1, _by1, _bx2, _by2, true);

	var _caret = ((customize_blink div 30) mod 2 == 0) ? "|" : "";
	draw_set_color(c_white);
	draw_text(room_width * 0.5, (_by1 + _by2) * 0.5, keyboard_string + _caret);

	draw_set_color(c_gray);
	draw_text(room_width * 0.5, _by2 + round(18 * _s), "Max " + string(PLAYER_NAME_MAX) + " characters");

	var _btn_w = round(160 * _s);
	var _btn_h = round(54 * _s);
	var _gap = round(24 * _s);
	var _sy = _by2 + round(48 * _s);
	var _save_x1 = room_width * 0.5 - _btn_w - _gap * 0.5;
	var _cancel_x1 = room_width * 0.5 + _gap * 0.5;
	btn_save = [_save_x1, _sy, _save_x1 + _btn_w, _sy + _btn_h];
	btn_cancel = [_cancel_x1, _sy, _cancel_x1 + _btn_w, _sy + _btn_h];
	draw_ui_button(btn_save[0], btn_save[1], btn_save[2], btn_save[3], "Save", false);
	draw_ui_button(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], "Cancel", false);
} else {
	for (var _i = 0; _i < menu_count; _i++) {
		var _bx1 = menu_x;
		var _by1 = menu_y + _i * (button_h + button_gap);
		var _bx2 = _bx1 + button_w;
		var _by2 = _by1 + button_h;
		draw_ui_button(_bx1, _by1, _bx2, _by2, menu_labels[_i], _i == menu_index);
	}

	if (global.menu_message != "") {
		draw_set_color(c_orange);
		draw_text(room_width * 0.5, room_height * 0.86, global.menu_message);
	} else {
		draw_set_color(c_gray);
		draw_text(room_width * 0.5, room_height * 0.86, input_is_mobile_touch()
			? "Tap a button to play  |  Host opens a lobby first"
			: "W/S or arrows  |  Enter / click  |  Host opens a lobby first");
	}
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
