if (phase == "results") {
	var _gw = display_get_gui_width();
	var _gh = display_get_gui_height();
	var _s = ui_scale();

	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	draw_text_transformed(_gw * 0.5, round(60 * _s), "MATCH RESULTS", _s, _s, 0);
	draw_set_color(c_ltgray);
	draw_text(_gw * 0.5, round(95 * _s), lobby_name + "  |  " + arena_name_from_index(map_index));

	var _y = round(140 * _s);
	draw_set_halign(fa_left);
	draw_text(_gw * 0.5 - 180, _y, "PLAYER");
	draw_text(_gw * 0.5 + 40, _y, "KILLS");
	draw_text(_gw * 0.5 + 120, _y, "DEATHS");
	_y += round(28 * _s);

	for (var _i = 0; _i < array_length(results); _i++) {
		draw_set_color((_i == 0) ? c_lime : c_white);
		draw_text(_gw * 0.5 - 180, _y, string(_i + 1) + ". " + results[_i].name);
		draw_text(_gw * 0.5 + 40, _y, string(results[_i].kills));
		draw_text(_gw * 0.5 + 120, _y, string(results[_i].deaths));
		_y += round(26 * _s);
	}

	var _btn_w = round(260 * _s);
	var _btn_h = round(56 * _s);
	var _btn_y1 = _gh - round(100 * _s);
	var _btn_y2 = _btn_y1 + _btn_h;

	if (is_host) {
		var _lx1 = _gw * 0.5 - _btn_w - 12;
		var _rx1 = _gw * 0.5 + 12;
		draw_ui_button(_lx1, _btn_y1, _lx1 + _btn_w, _btn_y2, "Back to Lobby", false);
		draw_ui_button(_rx1, _btn_y1, _rx1 + _btn_w, _btn_y2, "Main Menu", false);
	} else {
		var _mx1 = (_gw - _btn_w) * 0.5;
		draw_set_color(c_gray);
		draw_set_halign(fa_center);
		draw_text(_gw * 0.5, _btn_y1 - round(28 * _s), "Waiting for host to return to lobby");
		draw_ui_button(_mx1, _btn_y1, _mx1 + _btn_w, _btn_y2, "Main Menu", false);
	}

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	exit;
}

if (phase == "match") {
	var _gw = display_get_gui_width();
	var _timer_text = format_match_time(ceil(match_frames_left / 60));
	var _map_text = arena_name_from_index(map_index);

	draw_ui_panel(_gw * 0.5 - 54, 8, _gw * 0.5 + 54, 40, 0.42);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text(_gw * 0.5, 24, _timer_text);

	draw_set_halign(fa_right);
	draw_set_valign(fa_top);
	var _map_w = 120;
	var _map_x2 = _gw - 12;
	var _map_x1 = _map_x2 - _map_w;
	draw_ui_panel(_map_x1, 10, _map_x2, 42, 0.42);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text((_map_x1 + _map_x2) * 0.5, 26, _map_text);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	exit;
}

draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_set_color(c_ltgray);
draw_text(display_get_gui_width() - 16, 16, status_text);
if (status_detail != "") {
	draw_text(display_get_gui_width() - 16, 36, status_detail);
}

if (is_host && !host_failed && phase == "lobby") {
	draw_text(display_get_gui_width() - 16, 56, "Clients: " + string(array_length(client_ips)));
}

if (is_host && host_failed) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.45, status_text);
	draw_set_color(c_orange);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.52, status_detail);
	draw_set_color(c_ltgray);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.60, "Use Back to return to menu");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
