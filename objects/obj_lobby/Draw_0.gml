if (!instance_exists(obj_net)) {
	exit;
}

var _net = obj_net;
var _cx = room_width * 0.5;
var _s = ui_scale();

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text_transformed(_cx, 60, "LOBBY", _s, _s, 0);
draw_set_color(c_ltgray);
draw_text_transformed(_cx, 95, _net.lobby_name, _s * 0.9, _s * 0.9, 0);

arrow_left = [];
arrow_right = [];
btn_rects = [];

if (_net.host_failed) {
	draw_set_color(c_orange);
	draw_text(_cx, room_height * 0.40, _net.status_text);
	draw_text(_cx, room_height * 0.48, _net.status_detail);

	var _bw = round(280 * _s);
	var _bh = round(56 * _s);
	var _bx1 = (_cx - _bw * 0.5);
	var _by1 = room_height * 0.58;
	var _bx2 = _bx1 + _bw;
	var _by2 = _by1 + _bh;
	host_failed_btn = [_bx1, _by1, _bx2, _by2];
	draw_ui_button(_bx1, _by1, _bx2, _by2, "Back to Menu", true);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	exit;
}

var _left_x = room_width * 0.10;
var _y = 150;
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text_transformed(_left_x, _y, "Match Settings", _s, _s, 0);
_y += round(40 * _s);

row_x1 = _left_x;
row_y = [];

if (_net.is_host) {
	var _values = [
		arena_name_from_index(_net.map_index),
		format_match_time(_net.match_time_sec),
		string(_net.max_players)
	];

	for (var _i = 0; _i < 3; _i++) {
		var _ry1 = _y;
		var _ry2 = _y + row_h;
		array_push(row_y, _ry1);

		var _selected = (selected_slot == _i);
		draw_ui_panel(_left_x, _ry1, _left_x + row_w, _ry2, _selected ? 0.55 : 0.35);

		// Left / right arrows
		var _alx1 = _left_x + arrow_pad;
		var _alx2 = _alx1 + arrow_w;
		var _arx2 = _left_x + row_w - arrow_pad;
		var _arx1 = _arx2 - arrow_w;
		array_push(arrow_left, [_alx1, _ry1, _alx2, _ry2]);
		array_push(arrow_right, [_arx1, _ry1, _arx2, _ry2]);

		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_color(c_lime);
		draw_text((_alx1 + _alx2) * 0.5, (_ry1 + _ry2) * 0.5, "<");
		draw_text((_arx1 + _arx2) * 0.5, (_ry1 + _ry2) * 0.5, ">");

		draw_set_color(c_white);
		draw_text((_left_x + row_w * 0.5), (_ry1 + _ry2) * 0.5 - round(10 * _s), menu_rows[_i]);
		draw_set_color(c_ltgray);
		draw_text((_left_x + row_w * 0.5), (_ry1 + _ry2) * 0.5 + round(12 * _s), _values[_i]);

		_y += row_h + round(12 * _s);
	}

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);

	// Start Match / Leave Lobby buttons
	for (var _j = 3; _j < array_length(menu_rows); _j++) {
		var _by1 = _y;
		var _by2 = _y + row_h;
		var _bx1 = _left_x;
		var _bx2 = _left_x + row_w;
		array_push(row_y, _by1);
		array_push(btn_rects, [_bx1, _by1, _bx2, _by2, _j]);
		draw_ui_button(_bx1, _by1, _bx2, _by2, menu_rows[_j], selected_slot == _j);
		_y += row_h + round(12 * _s);
	}
} else {
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_ltgray);
	draw_text(_left_x, _y, "Map:  " + arena_name_from_index(_net.map_index));
	_y += round(34 * _s);
	draw_text(_left_x, _y, "Match Time:  " + format_match_time(_net.match_time_sec));
	_y += round(34 * _s);
	draw_text(_left_x, _y, "Max Players:  " + string(_net.max_players));
	_y += round(40 * _s);

	draw_set_color(c_gray);
	draw_text(_left_x, _y, "Only the host can change settings");
	_y += round(40 * _s);

	var _ly1 = _y;
	var _ly2 = _y + row_h;
	array_push(row_y, _ly1);
	array_push(btn_rects, [_left_x, _ly1, _left_x + row_w, _ly2, 0]);
	draw_ui_button(_left_x, _ly1, _left_x + row_w, _ly2, "Leave Lobby", selected_slot == 0);
}

// Player list
var _right_x = room_width * 0.58;
_y = 150;
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text_transformed(_right_x, _y, "Players (" + string(array_length(_net.lobby_roster)) + "/" + string(_net.max_players) + ")", _s, _s, 0);
_y += round(40 * _s);

for (var _p = 0; _p < array_length(_net.lobby_roster); _p++) {
	var _entry = _net.lobby_roster[_p];
	var _line = string(_entry.player_id) + ". " + _entry.name;
	if (_entry.is_host) {
		_line += "  (Host)";
	}
	draw_set_color(c_white);
	draw_text(_right_x, _y, _line);
	_y += round(28 * _s);
}

draw_set_halign(fa_center);
draw_set_color(c_gray);
if (_net.is_host) {
	draw_text(_cx, room_height - 70, input_is_mobile_touch()
		? "Tap < > to change settings  |  Tap Start / Leave"
		: "W/S select  |  A/D or arrows change  |  Enter confirm");
	draw_text(_cx, room_height - 42, "Press 2-8 to kick player id  |  Port " + string(_net.bound_port));
} else {
	draw_text(_cx, room_height - 50, "Tap Leave Lobby  |  Back also leaves");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
