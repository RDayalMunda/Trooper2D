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
btn_connect = [0, 0, 0, 0];
btn_join = [0, 0, 0, 0];
btn_use_ip = [0, 0, 0, 0];
browse_arrow_l = [0, 0, 0, 0];
browse_arrow_r = [0, 0, 0, 0];

if (menu_state == "connecting") {
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, room_height * 0.40, "Joining lobby...", _ts, _ts, 0);
	draw_set_color(c_ltgray);
	if (instance_exists(obj_net) && obj_net.host_ip != "") {
		draw_text_transformed(room_width * 0.5, room_height * 0.50, obj_net.host_ip + ":" + string(obj_net.host_port), _ts * 0.9, _ts * 0.9, 0);
	}
	draw_text_transformed(room_width * 0.5, room_height * 0.58, "Timeout in " + string(max(0, ceil((connect_timeout - connect_timer) / 60))) + "s", _ts * 0.85, _ts * 0.85, 0);

	var _bw = button_w;
	var _bh = button_h;
	var _bx1 = (room_width - _bw) * 0.5;
	var _by1 = room_height * 0.70;
	btn_cancel_connect = [_bx1, _by1, _bx1 + _bw, _by1 + _bh];
	draw_ui_button(_bx1, _by1, _bx1 + _bw, _by1 + _bh, "Cancel", false);
} else if (menu_state == "browse") {
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, room_height * 0.30, "Find Lobby", _ts * 1.1, _ts * 1.1, 0);

	var _has_net = instance_exists(obj_net);
	var _n = _has_net ? array_length(obj_net.discovered) : 0;
	var _card_w = min(room_width - round(80 * _s), round(560 * _s));
	var _card_h = round(110 * _s);
	var _cx1 = (room_width - _card_w) * 0.5;
	var _cy1 = room_height * 0.38;
	var _cx2 = _cx1 + _card_w;
	var _cy2 = _cy1 + _card_h;

	var _aw = round(64 * _s);
	browse_arrow_l = [_cx1 - _aw - round(12 * _s), _cy1, _cx1 - round(12 * _s), _cy2];
	browse_arrow_r = [_cx2 + round(12 * _s), _cy1, _cx2 + _aw + round(12 * _s), _cy2];

	draw_ui_panel(_cx1, _cy1, _cx2, _cy2, 0.45);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_lime);
	draw_text_transformed((browse_arrow_l[0] + browse_arrow_l[2]) * 0.5, (_cy1 + _cy2) * 0.5, "<", _ts * 1.4, _ts * 1.4, 0);
	draw_text_transformed((browse_arrow_r[0] + browse_arrow_r[2]) * 0.5, (_cy1 + _cy2) * 0.5, ">", _ts * 1.4, _ts * 1.4, 0);

	if (_n <= 0) {
		draw_set_color(c_ltgray);
		draw_text_transformed(room_width * 0.5, (_cy1 + _cy2) * 0.5 - round(12 * _s), "Searching LAN...", _ts, _ts, 0);
		draw_set_color(c_gray);
		draw_text_transformed(room_width * 0.5, (_cy1 + _cy2) * 0.5 + round(18 * _s), "Host a game on another phone", _ts * 0.75, _ts * 0.75, 0);
	} else {
		var _idx = clamp(obj_net.browse_index, 0, _n - 1);
		var _e = obj_net.discovered[_idx];
		draw_set_color(c_white);
		draw_text_transformed(room_width * 0.5, _cy1 + round(28 * _s), _e.lobby_name, _ts * 1.05, _ts * 1.05, 0);
		draw_set_color(c_ltgray);
		draw_text_transformed(room_width * 0.5, _cy1 + round(58 * _s), "Host: " + _e.host_name, _ts * 0.9, _ts * 0.9, 0);
		draw_text_transformed(room_width * 0.5, _cy1 + round(84 * _s), string(_e.players) + "/" + string(_e.max_players) + "  ·  " + string(_idx + 1) + "/" + string(_n), _ts * 0.8, _ts * 0.8, 0);
	}

	var _btn_w = round(200 * _s);
	var _btn_h = round(52 * _s);
	var _gap = round(12 * _s);
	var _by = _cy2 + round(18 * _s);
	btn_join = [(room_width - _btn_w) * 0.5, _by, (room_width + _btn_w) * 0.5, _by + _btn_h];
	draw_ui_button(btn_join[0], btn_join[1], btn_join[2], btn_join[3], "Join", false);

	var _iby = _by + _btn_h + _gap;
	btn_use_ip = [(room_width - _btn_w) * 0.5, _iby, (room_width + _btn_w) * 0.5, _iby + _btn_h];
	draw_ui_button(btn_use_ip[0], btn_use_ip[1], btn_use_ip[2], btn_use_ip[3], "Use IP", false);

	var _cby = _iby + _btn_h + _gap;
	btn_cancel = [(room_width - _btn_w) * 0.5, _cby, (room_width + _btn_w) * 0.5, _cby + _btn_h];
	draw_ui_button(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], "Cancel", false);
} else if (menu_state == "join_ip") {
	var _safe_bottom = room_height * 0.52;
	if (input_is_mobile_touch()) {
		var _kh2 = keyboard_virtual_height();
		if (_kh2 > 0) {
			var _frac2 = clamp(_kh2 / max(1, display_get_height()), 0.25, 0.65);
			_safe_bottom = room_height * (1 - _frac2) - round(16 * _s);
		}
	}
	var _btn_h2 = round(58 * _s);
	var _btn_w2 = round(170 * _s);
	var _gap2 = round(20 * _s);
	var _top_y2 = room_height * 0.08;
	btn_cancel = [_gap2, _top_y2, _gap2 + _btn_w2, _top_y2 + _btn_h2];
	btn_connect = [room_width - _gap2 - _btn_w2, _top_y2, room_width - _gap2, _top_y2 + _btn_h2];
	draw_ui_button(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], "Back", false);
	draw_ui_button(btn_connect[0], btn_connect[1], btn_connect[2], btn_connect[3], "Connect", false);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, _top_y2 + _btn_h2 * 0.5, "Host IP", _ts, _ts, 0);
	draw_set_color(c_ltgray);
	draw_text_transformed(room_width * 0.5, _top_y2 + _btn_h2 + round(18 * _s), "Type the host phone Wi-Fi IPv4", _ts * 0.8, _ts * 0.8, 0);
	var _box_w2 = min(room_width - round(80 * _s), round(520 * _s));
	var _box_h2 = round(72 * _s);
	var _bx12 = (room_width - _box_w2) * 0.5;
	var _by12 = _top_y2 + _btn_h2 + round(46 * _s);
	var _by22 = _by12 + _box_h2;
	if (_by22 > _safe_bottom - round(8 * _s)) {
		_by22 = _safe_bottom - round(8 * _s);
		_by12 = max(_top_y2 + _btn_h2 + round(12 * _s), _by22 - _box_h2);
	}
	name_box = [_bx12, _by12, _bx12 + _box_w2, _by22];
	draw_set_color(make_color_rgb(20, 20, 20));
	draw_rectangle(name_box[0], name_box[1], name_box[2], name_box[3], false);
	draw_set_color(c_lime);
	draw_rectangle(name_box[0], name_box[1], name_box[2], name_box[3], true);
	var _caret2 = ((customize_blink div 30) mod 2 == 0) ? "|" : "";
	var _field2 = keyboard_string;
	if (_field2 == "") {
		_field2 = "e.g. 192.168.1.10";
		draw_set_color(c_gray);
	} else {
		draw_set_color(c_white);
	}
	draw_text_transformed(room_width * 0.5, (name_box[1] + name_box[3]) * 0.5, _field2 + ((_field2 == "e.g. 192.168.1.10") ? "" : _caret2), _ts * 1.1, _ts * 1.1, 0);
} else if (menu_state == "customize") {
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

	btn_cancel = [_gap, _top_y, _gap + _btn_w, _top_y + _btn_h];
	btn_save = [room_width - _gap - _btn_w, _top_y, room_width - _gap, _top_y + _btn_h];
	draw_ui_button(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], "Cancel", false);
	draw_ui_button(btn_save[0], btn_save[1], btn_save[2], btn_save[3], "Save", false);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, _top_y + _btn_h * 0.5, "Customize", _ts, _ts, 0);

	var _hint_y = _top_y + _btn_h + round(18 * _s);
	draw_set_color(c_ltgray);
	draw_text_transformed(room_width * 0.5, _hint_y, "Type your trooper name", _ts * 0.8, _ts * 0.8, 0);

	var _box_w = min(room_width - round(80 * _s), round(520 * _s));
	var _box_h = round(72 * _s);
	var _bx1 = (room_width - _box_w) * 0.5;
	var _by1 = _hint_y + round(28 * _s);
	var _by2 = _by1 + _box_h;
	if (_by2 > _safe_bottom - round(8 * _s)) {
		_by2 = _safe_bottom - round(8 * _s);
		_by1 = max(_hint_y + round(10 * _s), _by2 - _box_h);
	}
	name_box = [_bx1, _by1, _bx1 + _box_w, _by2];

	draw_set_color(make_color_rgb(20, 20, 20));
	draw_rectangle(name_box[0], name_box[1], name_box[2], name_box[3], false);
	draw_set_color(c_lime);
	draw_rectangle(name_box[0], name_box[1], name_box[2], name_box[3], true);

	var _caret = ((customize_blink div 30) mod 2 == 0) ? "|" : "";
	draw_set_color(c_white);
	draw_text_transformed(room_width * 0.5, (name_box[1] + name_box[3]) * 0.5, keyboard_string + _caret, _ts * 1.1, _ts * 1.1, 0);
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
