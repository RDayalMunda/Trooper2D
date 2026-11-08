var _ts = ui_text_scale();

if (phase == "results") {
	var _gw = display_get_gui_width();
	var _gh = display_get_gui_height();
	var _s = ui_scale();

	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	draw_text_transformed(_gw * 0.5, round(48 * _s), "MATCH RESULTS", _ts * 1.15, _ts * 1.15, 0);
	draw_set_color(c_ltgray);
	draw_text_transformed(_gw * 0.5, round(88 * _s), lobby_name + "  |  " + arena_name_from_index(map_index), _ts * 0.9, _ts * 0.9, 0);

	var _y = round(130 * _s);
	draw_set_halign(fa_left);
	draw_set_color(c_ltgray);
	draw_text_transformed(_gw * 0.5 - 200, _y, "PLAYER", _ts * 0.9, _ts * 0.9, 0);
	draw_text_transformed(_gw * 0.5 + 40, _y, "KILLS", _ts * 0.9, _ts * 0.9, 0);
	draw_text_transformed(_gw * 0.5 + 140, _y, "DEATHS", _ts * 0.9, _ts * 0.9, 0);
	_y += round(36 * _s);

	for (var _i = 0; _i < array_length(results); _i++) {
		draw_set_color((_i == 0) ? c_lime : c_white);
		draw_text_transformed(_gw * 0.5 - 200, _y, string(_i + 1) + ". " + results[_i].name, _ts, _ts, 0);
		draw_text_transformed(_gw * 0.5 + 40, _y, string(results[_i].kills), _ts, _ts, 0);
		draw_text_transformed(_gw * 0.5 + 140, _y, string(results[_i].deaths), _ts, _ts, 0);
		_y += round(34 * _s);
	}

	var _btn_w = round(280 * _s);
	var _btn_h = round(64 * _s);
	var _btn_y1 = _gh - round(110 * _s);
	var _btn_y2 = _btn_y1 + _btn_h;

	if (is_host) {
		var _lx1 = _gw * 0.5 - _btn_w - 12;
		var _rx1 = _gw * 0.5 + 12;
		draw_ui_button(_lx1, _btn_y1, _lx1 + _btn_w, _btn_y2, "Back to Lobby", false);
		draw_ui_button(_rx1, _btn_y1, _rx1 + _btn_w, _btn_y2, "Main Menu", false);
	} else {
		var _mx1 = (_gw - _btn_w) * 0.5;
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
	var _s = ui_scale();

	draw_ui_panel(_gw * 0.5 - round(70 * _s), 8, _gw * 0.5 + round(70 * _s), round(44 * _s), 0.42);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text_transformed(_gw * 0.5, round(26 * _s), _timer_text, _ts, _ts, 0);

	// Map label sits left of the zoom button (drawn by touch controls).
	var _map = match_hud_map_rect();
	draw_ui_panel(_map[0], _map[1], _map[2], _map[3], 0.42);
	draw_set_color(c_white);
	draw_text_transformed((_map[0] + _map[2]) * 0.5, (_map[1] + _map[3]) * 0.5, _map_text, _ts * 0.9, _ts * 0.9, 0);

	var _pause = match_hud_pause_rect();
	draw_ui_button(_pause[0], _pause[1], _pause[2], _pause[3], "Pause", false, _ts * 0.85);

	killfeed_draw();

	// Drawn last so the overlay sits above HUD / touch controls.
	match_pause_draw_overlay();

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	exit;
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
