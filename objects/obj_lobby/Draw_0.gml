if (!instance_exists(obj_net)) {
	exit;
}

var _net = obj_net;
var _cx = room_width * 0.5;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text(_cx, 70, "LOBBY");
draw_set_color(c_ltgray);
draw_text(_cx, 105, _net.lobby_name);

if (_net.host_failed) {
	draw_set_color(c_orange);
	draw_text(_cx, room_height * 0.45, _net.status_text);
	draw_text(_cx, room_height * 0.52, _net.status_detail);
	draw_set_color(c_gray);
	draw_text(_cx, room_height * 0.62, "Esc to return to menu");
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	exit;
}

var _left_x = room_width * 0.28;
var _y = 170;
draw_set_halign(fa_left);
draw_set_color(c_white);
draw_text(_left_x, _y, "Match Settings");
_y += 36;

row_x1 = _left_x;
row_y = [];

if (_net.is_host) {
	var _map_value = arena_name_from_index(_net.map_index);
	var _time_value = format_match_time(_net.match_time_sec);
	var _max_value = string(_net.max_players);
	var _values = [_map_value, _time_value, _max_value, "", ""];

	for (var _i = 0; _i < array_length(menu_rows); _i++) {
		array_push(row_y, _y - 12);
		var _selected = (selected_slot == _i);
		draw_set_color(_selected ? c_lime : c_ltgray);
		var _label = menu_rows[_i];
		if (_i < 3) {
			_label += ":  " + _values[_i];
			if (_selected) {
				_label = "< " + _label + " >";
			}
		}
		draw_text(_left_x, _y, _label);
		_y += 34;
	}
} else {
	// Read-only settings for joiners
	draw_set_color(c_ltgray);
	draw_text(_left_x, _y, "Map:  " + arena_name_from_index(_net.map_index));
	_y += 34;
	draw_text(_left_x, _y, "Match Time:  " + format_match_time(_net.match_time_sec));
	_y += 34;
	draw_text(_left_x, _y, "Max Players:  " + string(_net.max_players));
	_y += 44;

	draw_set_color(c_gray);
	draw_text(_left_x, _y, "Only the host can change settings");
	_y += 44;

	// Leave Lobby — selectable / clickable
	array_push(row_y, _y - 12);
	var _leave_selected = (selected_slot == 0);
	draw_set_color(_leave_selected ? c_lime : c_white);
	draw_text(_left_x, _y, _leave_selected ? "> Leave Lobby <" : "Leave Lobby");
	_y += 34;
}

// Player list
var _right_x = room_width * 0.62;
_y = 170;
draw_set_color(c_white);
draw_text(_right_x, _y, "Players (" + string(array_length(_net.lobby_roster)) + "/" + string(_net.max_players) + ")");
_y += 36;

for (var _p = 0; _p < array_length(_net.lobby_roster); _p++) {
	var _entry = _net.lobby_roster[_p];
	var _line = string(_entry.player_id) + ". " + _entry.name;
	if (_entry.is_host) {
		_line += "  (Host)";
	}
	draw_set_color(c_white);
	draw_text(_right_x, _y, _line);
	_y += 28;
}

draw_set_halign(fa_center);
draw_set_color(c_gray);
if (_net.is_host) {
	draw_text(_cx, room_height - 90, "W/S select  |  A/D change  |  Enter / click confirm");
	draw_text(_cx, room_height - 60, "Press 2-8 to kick that player id  |  Port " + string(_net.bound_port));
} else {
	draw_text(_cx, room_height - 70, "W/S or click Leave Lobby  |  Enter confirm  |  Esc also leaves");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
