draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text(room_width * 0.5, room_height * 0.22, "TROOPER 2D");
draw_set_color(c_ltgray);
draw_text(room_width * 0.5, room_height * 0.28, "LAN arena shooter");

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

draw_set_color(c_gray);
draw_text(room_width * 0.5, room_height * 0.78, "W/S or arrows  |  Enter / click");
draw_text(room_width * 0.5, room_height * 0.84, "Join uses 127.0.0.1 for now");
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
