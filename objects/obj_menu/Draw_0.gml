draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text(room_width * 0.5, room_height * 0.18, "TROOPER 2D");
draw_set_color(c_ltgray);
draw_text(room_width * 0.5, room_height * 0.24, "LAN arena shooter");
draw_text(room_width * 0.5, room_height * 0.30, "Playing as: " + global.player_name);

if (menu_state == "connecting") {
	draw_set_color(c_white);
	draw_text(room_width * 0.5, room_height * 0.45, "Connecting...");
	draw_set_color(c_ltgray);
	draw_text(room_width * 0.5, room_height * 0.52, "Looking for host at " + global.join_ip);
	draw_text(room_width * 0.5, room_height * 0.58, "Ports " + string(NET_PORT_MIN) + "-" + string(NET_PORT_MAX));

	var _seconds_left = max(0, ceil((connect_timeout - connect_timer) / 60));
	draw_text(room_width * 0.5, room_height * 0.66, "Timeout in " + string(_seconds_left) + "s");
	draw_set_color(c_gray);
	draw_text(room_width * 0.5, room_height * 0.78, "Esc to cancel");
} else if (menu_state == "customize") {
	draw_set_color(c_white);
	draw_text(room_width * 0.5, room_height * 0.42, "Customize");
	draw_set_color(c_ltgray);
	draw_text(room_width * 0.5, room_height * 0.48, "Type your player name");

	var _box_w = 320;
	var _box_h = 48;
	var _bx1 = (room_width - _box_w) * 0.5;
	var _by1 = room_height * 0.55;
	var _bx2 = _bx1 + _box_w;
	var _by2 = _by1 + _box_h;

	draw_set_color(make_color_rgb(28, 28, 28));
	draw_rectangle(_bx1, _by1, _bx2, _by2, false);
	draw_set_color(c_lime);
	draw_rectangle(_bx1, _by1, _bx2, _by2, true);

	var _caret = ((customize_blink div 30) mod 2 == 0) ? "|" : "";
	draw_set_color(c_white);
	draw_text(room_width * 0.5, (_by1 + _by2) * 0.5, keyboard_string + _caret);

	draw_set_color(c_gray);
	draw_text(room_width * 0.5, room_height * 0.72, "Max " + string(PLAYER_NAME_MAX) + " characters");
	draw_text(room_width * 0.5, room_height * 0.78, "Enter to save  |  Esc to cancel");
} else {
	for (var _i = 0; _i < menu_count; _i++) {
		var _bx1 = menu_x;
		var _by1 = menu_y + _i * (button_h + button_gap);
		var _bx2 = _bx1 + button_w;
		var _by2 = _by1 + button_h;
		var _selected = (_i == menu_index);

		draw_set_color(_selected ? c_dkgray : make_color_rgb(28, 28, 28));
		draw_rectangle(_bx1, _by1, _bx2, _by2, false);
		draw_set_color(_selected ? c_lime : c_white);
		draw_rectangle(_bx1, _by1, _bx2, _by2, true);
		draw_text((_bx1 + _bx2) * 0.5, (_by1 + _by2) * 0.5, menu_labels[_i]);
	}

	if (global.menu_message != "") {
		draw_set_color(c_orange);
		draw_text(room_width * 0.5, room_height * 0.78, global.menu_message);
	}

	draw_set_color(c_gray);
	draw_text(room_width * 0.5, room_height * 0.86, "W/S or arrows  |  Enter / click  |  Host opens a lobby first");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
