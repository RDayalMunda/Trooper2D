if (!instance_exists(obj_net)) {
	exit;
}

var _net = obj_net;
var _cx = room_width * 0.5;
var _s = ui_scale();
var _ts = ui_text_scale() * 0.72;

arrow_left = [];
arrow_right = [];
btn_rects = [];
name_box = [0, 0, 0, 0];
btn_save = [0, 0, 0, 0];
btn_cancel = [0, 0, 0, 0];

// Rename overlay (host)
if (lobby_ui == "rename") {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text_transformed(_cx, room_height * 0.16, "Lobby Name", _ts * 1.2, _ts * 1.2, 0);

	var _btn_h = round(54 * _s);
	var _btn_w = round(160 * _s);
	var _gap = round(18 * _s);
	var _top_y = room_height * 0.08;
	btn_cancel = [_gap, _top_y, _gap + _btn_w, _top_y + _btn_h];
	btn_save = [room_width - _gap - _btn_w, _top_y, room_width - _gap, _top_y + _btn_h];
	draw_ui_button(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], "Cancel", false, _ts);
	draw_ui_button(btn_save[0], btn_save[1], btn_save[2], btn_save[3], "Save", false, _ts);

	var _box_w = min(room_width - round(80 * _s), round(520 * _s));
	var _box_h = round(70 * _s);
	var _bx1 = (room_width - _box_w) * 0.5;
	var _by1 = room_height * 0.36;
	name_box = [_bx1, _by1, _bx1 + _box_w, _by1 + _box_h];
	draw_set_color(make_color_rgb(20, 20, 20));
	draw_rectangle(name_box[0], name_box[1], name_box[2], name_box[3], false);
	draw_set_color(c_lime);
	draw_rectangle(name_box[0], name_box[1], name_box[2], name_box[3], true);

	var _caret = ((rename_blink div 30) mod 2 == 0) ? "|" : "";
	draw_set_color(c_white);
	draw_text_transformed(_cx, (_by1 + _by1 + _box_h) * 0.5, keyboard_string + _caret, _ts * 1.15, _ts * 1.15, 0);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	exit;
}

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text_transformed(_cx, round(36 * _s), "LOBBY", _ts * 1.15, _ts * 1.15, 0);
draw_set_color(c_ltgray);
draw_text_transformed(_cx, round(62 * _s), _net.lobby_name, _ts * 0.95, _ts * 0.95, 0);
if (_net.is_host) {
	draw_set_color(c_gray);
	draw_text_transformed(_cx, round(84 * _s), "Port " + string(_net.bound_port), _ts * 0.75, _ts * 0.75, 0);
}

if (_net.host_failed) {
	draw_set_color(c_orange);
	draw_text_transformed(_cx, room_height * 0.40, _net.status_text, _ts, _ts, 0);
	draw_text_transformed(_cx, room_height * 0.48, _net.status_detail, _ts * 0.9, _ts * 0.9, 0);

	var _bw = round(280 * _s);
	var _bh = round(56 * _s);
	var _bx1 = _cx - _bw * 0.5;
	var _by1 = room_height * 0.58;
	host_failed_btn = [_bx1, _by1, _bx1 + _bw, _by1 + _bh];
	draw_ui_button(_bx1, _by1, _bx1 + _bw, _by1 + _bh, "Back to Menu", true, _ts);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	exit;
}

var _content_top = round(100 * _s);
var _content_bot = room_height - round(16 * _s);

draw_ui_panel(col_left_x1, _content_top, col_left_x2, _content_bot, 0.32);
draw_ui_panel(col_right_x1, _content_top, col_right_x2, _content_bot, 0.32);

var _inner_pad = round(12 * _s);
var _left_x = col_left_x1 + _inner_pad;
var _right_x = col_right_x1 + _inner_pad;
row_w = (col_left_x2 - _inner_pad) - _left_x;
row_x1 = _left_x;

var _y = _content_top + _inner_pad;
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text_transformed(_left_x, _y, "Match Settings", _ts, _ts, 0);
_y += round(28 * _s);

row_y = [];

var _host_slots = _net.is_host ? 6 : 1;
var _avail = _content_bot - _inner_pad - _y;
row_gap = round(5 * _s);
row_h = floor((_avail - row_gap * (_host_slots - 1)) / _host_slots);
row_h = clamp(row_h, round(32 * _s), round(46 * _s));
arrow_w = min(round(44 * _s), floor(row_h * 0.9));
var _label_off = max(7, floor(row_h * 0.20));

if (_net.is_host) {
	// 0 Lobby Name (tap to rename)
	var _ny1 = _y;
	var _ny2 = _y + row_h;
	array_push(row_y, _ny1);
	array_push(btn_rects, [_left_x, _ny1, _left_x + row_w, _ny2, 0]);
	draw_ui_panel(_left_x, _ny1, _left_x + row_w, _ny2, selected_slot == 0 ? 0.55 : 0.38);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text_transformed((_left_x + row_w * 0.5), (_ny1 + _ny2) * 0.5 - _label_off, "Lobby Name", _ts * 0.75, _ts * 0.75, 0);
	draw_set_color(c_ltgray);
	draw_text_transformed((_left_x + row_w * 0.5), (_ny1 + _ny2) * 0.5 + _label_off, _net.lobby_name, _ts * 0.9, _ts * 0.9, 0);
	_y += row_h + row_gap;

	var _values = [
		arena_name_from_index(_net.map_index),
		format_match_time(_net.match_time_sec),
		string(_net.max_players)
	];
	var _labels = ["Map", "Match Time", "Max Players"];

	for (var _i = 0; _i < 3; _i++) {
		var _slot = _i + 1;
		var _ry1 = _y;
		var _ry2 = _y + row_h;
		array_push(row_y, _ry1);

		var _selected = (selected_slot == _slot);
		draw_ui_panel(_left_x, _ry1, _left_x + row_w, _ry2, _selected ? 0.55 : 0.38);

		var _alx1 = _left_x + arrow_pad;
		var _alx2 = _alx1 + arrow_w;
		var _arx2 = _left_x + row_w - arrow_pad;
		var _arx1 = _arx2 - arrow_w;
		array_push(arrow_left, [_alx1, _ry1, _alx2, _ry2, _slot]);
		array_push(arrow_right, [_arx1, _ry1, _arx2, _ry2, _slot]);

		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_color(c_lime);
		draw_text_transformed((_alx1 + _alx2) * 0.5, (_ry1 + _ry2) * 0.5, "<", _ts * 1.05, _ts * 1.05, 0);
		draw_text_transformed((_arx1 + _arx2) * 0.5, (_ry1 + _ry2) * 0.5, ">", _ts * 1.05, _ts * 1.05, 0);

		draw_set_color(c_white);
		draw_text_transformed((_left_x + row_w * 0.5), (_ry1 + _ry2) * 0.5 - _label_off, _labels[_i], _ts * 0.75, _ts * 0.75, 0);
		draw_set_color(c_ltgray);
		draw_text_transformed((_left_x + row_w * 0.5), (_ry1 + _ry2) * 0.5 + _label_off, _values[_i], _ts * 0.9, _ts * 0.9, 0);

		_y += row_h + row_gap;
	}

	for (var _j = 4; _j <= 5; _j++) {
		var _by1 = _y;
		var _by2 = min(_y + row_h, _content_bot - _inner_pad);
		array_push(row_y, _by1);
		array_push(btn_rects, [_left_x, _by1, _left_x + row_w, _by2, _j]);
		draw_ui_button(_left_x, _by1, _left_x + row_w, _by2, menu_rows[_j], selected_slot == _j, _ts * 0.9);
		_y += row_h + row_gap;
	}
} else {
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_ltgray);
	draw_text_transformed(_left_x, _y, "Map:  " + arena_name_from_index(_net.map_index), _ts * 0.95, _ts * 0.95, 0);
	_y += round(28 * _s);
	draw_text_transformed(_left_x, _y, "Match Time:  " + format_match_time(_net.match_time_sec), _ts * 0.95, _ts * 0.95, 0);
	_y += round(28 * _s);
	draw_text_transformed(_left_x, _y, "Max Players:  " + string(_net.max_players), _ts * 0.95, _ts * 0.95, 0);
	_y += round(34 * _s);

	var _ly1 = _y;
	var _ly2 = min(_y + row_h, _content_bot - _inner_pad);
	array_push(row_y, _ly1);
	array_push(btn_rects, [_left_x, _ly1, _left_x + row_w, _ly2, 0]);
	draw_ui_button(_left_x, _ly1, _left_x + row_w, _ly2, "Leave Lobby", selected_slot == 0, _ts * 0.95);
}

_y = _content_top + _inner_pad;
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text_transformed(_right_x, _y, "Players (" + string(array_length(_net.lobby_roster)) + "/" + string(_net.max_players) + ")", _ts, _ts, 0);
_y += round(34 * _s);

var _list_w = (col_right_x2 - _inner_pad) - _right_x;
list_x1 = _right_x;
list_y1 = _y;
list_x2 = _right_x + _list_w;
list_y2 = _content_bot - _inner_pad;

player_row_h = round(36 * _s);
var _row_gap = round(6 * _s);
var _roster_n = array_length(_net.lobby_roster);
var _content_h = _roster_n * (player_row_h + _row_gap);
var _view_h = max(1, list_y2 - list_y1);
player_scroll_max = max(0, _content_h - _view_h);
player_scroll = clamp(player_scroll, 0, player_scroll_max);

for (var _p = 0; _p < _roster_n; _p++) {
	var _py1 = list_y1 - player_scroll + _p * (player_row_h + _row_gap);
	var _py2 = _py1 + player_row_h;
	if (_py2 < list_y1 || _py1 > list_y2) {
		continue;
	}

	var _entry = _net.lobby_roster[_p];
	var _line = string(_entry.player_id) + ". " + _entry.name;
	if (_entry.is_host) {
		_line += "  (Host)";
	}

	var _draw_y1 = max(_py1, list_y1);
	var _draw_y2 = min(_py2, list_y2);
	draw_ui_panel(_right_x, _draw_y1, _right_x + _list_w, _draw_y2, 0.28);

	if (_py1 >= list_y1 - 4 && _py2 <= list_y2 + 4) {
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_color(c_white);
		draw_text_transformed(_right_x + round(10 * _s), (_py1 + _py2) * 0.5, _line, _ts * 0.95, _ts * 0.95, 0);
	}
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
