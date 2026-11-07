if (phase == "results") {
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	draw_text(display_get_gui_width() * 0.5, 80, "MATCH RESULTS");
	draw_set_color(c_ltgray);
	draw_text(display_get_gui_width() * 0.5, 110, lobby_name + "  |  " + arena_name_from_index(map_index));

	var _y = 160;
	draw_set_halign(fa_left);
	draw_text(display_get_gui_width() * 0.5 - 180, _y, "PLAYER");
	draw_text(display_get_gui_width() * 0.5 + 40, _y, "KILLS");
	draw_text(display_get_gui_width() * 0.5 + 120, _y, "DEATHS");
	_y += 28;

	for (var _i = 0; _i < array_length(results); _i++) {
		draw_set_color((_i == 0) ? c_lime : c_white);
		draw_text(display_get_gui_width() * 0.5 - 180, _y, string(_i + 1) + ". " + results[_i].name);
		draw_text(display_get_gui_width() * 0.5 + 40, _y, string(results[_i].kills));
		draw_text(display_get_gui_width() * 0.5 + 120, _y, string(results[_i].deaths));
		_y += 26;
	}

	draw_set_halign(fa_center);
	draw_set_color(c_gray);
	if (is_host) {
		draw_text(display_get_gui_width() * 0.5, display_get_gui_height() - 80, "Enter: return everyone to lobby    Esc: main menu");
	} else {
		draw_text(display_get_gui_width() * 0.5, display_get_gui_height() - 80, "Waiting for host to return to lobby    Esc: main menu");
	}
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

if (phase == "match") {
	draw_set_halign(fa_center);
	draw_set_color(c_white);
	draw_text(display_get_gui_width() * 0.5, 16, format_match_time(ceil(match_frames_left / 60)));
}

if (is_host && host_failed) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.45, status_text);
	draw_set_color(c_orange);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.52, status_detail);
	draw_set_color(c_ltgray);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.60, "Press Esc to return to menu");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
