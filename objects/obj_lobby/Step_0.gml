if (!instance_exists(obj_net)) {
	room_goto(room_main_menu);
	exit;
}

if (obj_net.host_failed) {
	var _hb = host_failed_btn;
	var _back = ui_back_pressed();
	if (array_length(_hb) >= 4 && ui_pointer_pressed_in(_hb[0], _hb[1], _hb[2], _hb[3], false)) {
		_back = true;
	}
	if (_back) {
		global.net_mode = "offline";
		global.menu_message = obj_net.status_detail;
		net_shutdown();
		room_goto(room_main_menu);
	}
	exit;
}

if (obj_net.phase == "results" || obj_net.phase == "match") {
	exit;
}

var _net = obj_net;
var _rows = menu_rows;
var _count = array_length(_rows);

if (_net.is_host) {
	_net.lobby_roster = [{
		player_id: 1,
		name: global.player_name,
		is_host: true
	}];
	for (var _i = 0; _i < array_length(_net.client_player_ids); _i++) {
		array_push(_net.lobby_roster, {
			player_id: _net.client_player_ids[_i],
			name: _net.client_names[_i],
			is_host: false
		});
	}
}

if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
	selected_slot = (selected_slot - 1 + _count) mod _count;
}
if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
	selected_slot = (selected_slot + 1) mod _count;
}

var _left = keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"));
var _right = keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"));
var _confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);

// Touch / click: arrows for Map / Time / Max, buttons for Start / Leave
if (_net.is_host && array_length(arrow_left) >= 3) {
	for (var _a = 0; _a < 3; _a++) {
		var _al = arrow_left[_a];
		var _ar = arrow_right[_a];
		if (ui_pointer_pressed_in(_al[0], _al[1], _al[2], _al[3], false)) {
			selected_slot = _a;
			_left = true;
		}
		if (ui_pointer_pressed_in(_ar[0], _ar[1], _ar[2], _ar[3], false)) {
			selected_slot = _a;
			_right = true;
		}
	}
}

if (array_length(btn_rects) > 0) {
	for (var _b = 0; _b < array_length(btn_rects); _b++) {
		var _br = btn_rects[_b];
		if (ui_pointer_pressed_in(_br[0], _br[1], _br[2], _br[3], false)) {
			selected_slot = _br[4];
			_confirm = true;
		}
	}
}

if (_net.is_host) {
	if (selected_slot == 0 && (_left || _right)) {
		_net.map_index = (_net.map_index + (_right ? 1 : -1) + arena_index_count()) mod arena_index_count();
		net_host_send_lobby_state();
	}

	if (selected_slot == 1 && (_left || _right)) {
		_net.match_time_sec += _right ? MATCH_TIME_STEP : -MATCH_TIME_STEP;
		_net.match_time_sec = clamp(_net.match_time_sec, MATCH_TIME_MIN, MATCH_TIME_MAX);
		net_host_send_lobby_state();
	}

	if (selected_slot == 2 && (_left || _right)) {
		_net.max_players += _right ? 1 : -1;
		_net.max_players = clamp(_net.max_players, LOBBY_MAX_PLAYERS_MIN, LOBBY_MAX_PLAYERS_MAX);
		_net.max_players = max(_net.max_players, net_lobby_player_count());
		net_host_send_lobby_state();
	}

	if (_confirm) {
		if (selected_slot == 3) {
			net_begin_match();
			exit;
		}
		if (selected_slot == 4) {
			global.net_mode = "offline";
			global.menu_message = "Left lobby";
			net_host_notify_left();
			room_goto(room_main_menu);
			exit;
		}
	}

	for (var _k = 2; _k <= 8; _k++) {
		if (keyboard_check_pressed(ord(string(_k)))) {
			net_host_kick_player(_k);
		}
	}

	if (ui_back_pressed()) {
		global.net_mode = "offline";
		global.menu_message = "Left lobby";
		net_host_notify_left();
		room_goto(room_main_menu);
	}
} else {
	if (_confirm && selected_slot == 0) {
		global.net_mode = "offline";
		global.menu_message = "Left lobby";
		net_shutdown();
		room_goto(room_main_menu);
		exit;
	}

	if (ui_back_pressed()) {
		global.net_mode = "offline";
		global.menu_message = "Left lobby";
		net_shutdown();
		room_goto(room_main_menu);
	}
}
