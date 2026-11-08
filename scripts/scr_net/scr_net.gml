#macro NET_PORT 5394
#macro NET_PORT_MIN 5394
#macro NET_PORT_MAX 5403
#macro NET_DISCOVER_PORT 5393
#macro NET_MSG_JOIN 1
#macro NET_MSG_WELCOME 2
#macro NET_MSG_INPUT 3
#macro NET_MSG_SNAPSHOT 4
#macro NET_MSG_LOBBY_STATE 5
#macro NET_MSG_START 6
#macro NET_MSG_KICK 7
#macro NET_MSG_REJECT 8
#macro NET_MSG_MATCH_END 9
#macro NET_MSG_RETURN_LOBBY 10
#macro NET_MSG_HOST_LEFT 11
#macro NET_MSG_DISCOVER 12
#macro NET_MSG_BEACON 13
#macro NET_MSG_WANT_PICKUP 14
#macro NET_MSG_LEAVE 15
#macro NET_MSG_KILL_FEED 16
#macro NET_MSG_FRAG_BOOM 17 // host → clients: explosion FX at x,y

#macro NET_REJECT_FULL 1
#macro NET_REJECT_IN_MATCH 2
#macro NET_DISCOVER_STALE_FRAMES 180
#macro NET_CLIENT_TIMEOUT_FRAMES 180 // drop silent lobby clients (~3s)
#macro NET_HOST_TIMEOUT_FRAMES 180 // clients leave match if host goes silent (~3s)
#macro NET_CLIENT_KEEPALIVE_FRAMES 45
#macro NET_NAME_BYTES 16
#macro NET_BULLET_MAX 48
#macro NET_SNAP_HARD 96
#macro NET_MATCH_END_RESENDS 8
#macro NET_MATCH_END_INTERVAL 12
#macro KILLFEED_MAX 3
#macro KILLFEED_LIFE 180 // 3 seconds
#macro PLAYER_HIT_BAR_TIME 120 // 2 seconds
// Ground guns: see NET_WEAPON_PICKUP_MAX in scr_weapons.

/// @function killfeed_ensure()
function killfeed_ensure() {
	if (!instance_exists(obj_net)) {
		return false;
	}
	if (!variable_instance_exists(obj_net, "kill_feed")) {
		obj_net.kill_feed = [];
	}
	return true;
}

/// @function killfeed_push(_killer_name, _victim_name, _weapon_name, _killer_id, _victim_id)
function killfeed_push(_killer_name, _victim_name, _weapon_name, _killer_id = 0, _victim_id = 0) {
	if (!killfeed_ensure()) {
		return;
	}
	array_insert(obj_net.kill_feed, 0, {
		killer: player_name_sanitize(_killer_name),
		victim: player_name_sanitize(_victim_name),
		weapon: string(_weapon_name),
		killer_id: _killer_id,
		victim_id: _victim_id,
		age: 0
	});
	while (array_length(obj_net.kill_feed) > KILLFEED_MAX) {
		array_delete(obj_net.kill_feed, KILLFEED_MAX, 1);
	}
}

/// @function killfeed_tick()
function killfeed_tick() {
	if (!killfeed_ensure()) {
		return;
	}
	for (var _i = array_length(obj_net.kill_feed) - 1; _i >= 0; _i--) {
		obj_net.kill_feed[_i].age += 1;
		if (obj_net.kill_feed[_i].age >= KILLFEED_LIFE) {
			array_delete(obj_net.kill_feed, _i, 1);
		}
	}
}

/// @function killfeed_draw()
function killfeed_draw() {
	if (!killfeed_ensure()) {
		return;
	}
	var _n = array_length(obj_net.kill_feed);
	if (_n <= 0) {
		return;
	}

	var _local_id = obj_net.local_player_id;
	var _s = ui_scale();
	var _ts = ui_text_scale() * 0.85;
	var _br = weapon_prompt_button_rect();
	// Sit just under the pickup button (and its "E / tap" hint line).
	var _y = _br[3] + round(24 * _s);
	var _cx = (_br[0] + _br[2]) * 0.5;
	var _row_h = round(28 * _s);
	var _pad = round(8 * _s);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	for (var _i = 0; _i < _n; _i++) {
		var _e = obj_net.kill_feed[_i];
		var _msg = _e.killer + " killed " + _e.victim + " with " + _e.weapon;
		var _fade = 1 - (_e.age / KILLFEED_LIFE);
		_fade = clamp(_fade * 1.25, 0, 1);

		var _col = make_color_rgb(200, 200, 200);
		if (_e.killer_id == _local_id && _local_id > 0) {
			_col = c_lime;
		} else if (_e.victim_id == _local_id && _local_id > 0) {
			_col = c_red;
		}

		var _tw = string_width(_msg) * _ts;
		var _x1 = _cx - _tw * 0.5 - _pad;
		var _x2 = _cx + _tw * 0.5 + _pad;
		var _y1 = _y + _i * (_row_h + round(4 * _s));
		var _y2 = _y1 + _row_h;

		var _old_a = draw_get_alpha();
		draw_set_alpha(0.35 * _fade);
		draw_set_color(c_black);
		draw_rectangle(_x1, _y1, _x2, _y2, false);
		draw_set_alpha(_fade);
		draw_set_color(_col);
		draw_text_transformed(_cx, (_y1 + _y2) * 0.5, _msg, _ts, _ts, 0);
		draw_set_alpha(_old_a);
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
}

/// @function net_host_broadcast_kill(_killer_name, _victim_name, _weapon_id, _killer_id, _victim_id)
function net_host_broadcast_kill(_killer_name, _victim_name, _weapon_id, _killer_id, _victim_id) {
	var _wname = weapon_name(_weapon_id);
	killfeed_push(_killer_name, _victim_name, _wname, _killer_id, _victim_id);

	if (!instance_exists(obj_net) || !obj_net.is_host) {
		return;
	}
	if (array_length(obj_net.client_ips) <= 0) {
		return;
	}

	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_KILL_FEED);
		net_write_name(send_buffer, _killer_name);
		net_write_name(send_buffer, _victim_name);
		buffer_write(send_buffer, buffer_u8, _weapon_id);
		buffer_write(send_buffer, buffer_u8, _killer_id);
		buffer_write(send_buffer, buffer_u8, _victim_id);
		var _size = buffer_tell(send_buffer);
		for (var _c = 0; _c < array_length(client_ips); _c++) {
			network_send_udp(socket, client_ips[_c], client_ports[_c], send_buffer, _size);
		}
	}
}

/// @function net_write_name(_buffer, _name)
function net_write_name(_buffer, _name) {
	_name = player_name_sanitize(_name);
	var _len = string_length(_name);
	for (var _i = 1; _i <= NET_NAME_BYTES; _i++) {
		var _c = (_i <= _len) ? ord(string_char_at(_name, _i)) : 0;
		buffer_write(_buffer, buffer_u8, _c);
	}
}

/// @function net_read_name(_buffer)
function net_read_name(_buffer) {
	var _name = "";
	for (var _i = 0; _i < NET_NAME_BYTES; _i++) {
		var _c = buffer_read(_buffer, buffer_u8);
		if (_c != 0) {
			_name += chr(_c);
		}
	}
	return player_name_sanitize(_name);
}

/// @function net_write_cosmetics(_buffer, _head, _torso, _leg, _hand)
function net_write_cosmetics(_buffer, _head, _torso, _leg, _hand) {
	buffer_write(_buffer, buffer_u8, cosmetics_clamp_id(COS_PART_HEAD, _head));
	buffer_write(_buffer, buffer_u8, cosmetics_clamp_id(COS_PART_TORSO, _torso));
	buffer_write(_buffer, buffer_u8, cosmetics_clamp_id(COS_PART_LEG, _leg));
	buffer_write(_buffer, buffer_u8, cosmetics_clamp_id(COS_PART_HAND, _hand));
}

/// @function net_read_cosmetics(_buffer)
/// @description Returns [head, torso, leg, hand]. Defaults to 0s if truncated.
function net_read_cosmetics(_buffer) {
	var _head = 0;
	var _torso = 0;
	var _leg = 0;
	var _hand = 0;
	if (buffer_tell(_buffer) + 4 <= buffer_get_size(_buffer)) {
		_head = buffer_read(_buffer, buffer_u8);
		_torso = buffer_read(_buffer, buffer_u8);
		_leg = buffer_read(_buffer, buffer_u8);
		_hand = buffer_read(_buffer, buffer_u8);
	}
	return [
		cosmetics_clamp_id(COS_PART_HEAD, _head),
		cosmetics_clamp_id(COS_PART_TORSO, _torso),
		cosmetics_clamp_id(COS_PART_LEG, _leg),
		cosmetics_clamp_id(COS_PART_HAND, _hand)
	];
}

/// @function net_find_bullet(_net_id)
function net_find_bullet(_net_id) {
	with (obj_bullet) {
		if (!is_predicted && net_id == _net_id) {
			return id;
		}
	}
	return noone;
}

/// @function net_claim_predicted_bullet(_x, _y, _weapon_id)
/// @description Joiners spawn a local predicted ghost on fire; the host later sends
/// the real bullet. Claim the nearest unmatched prediction so we don't draw two.
function net_claim_predicted_bullet(_x, _y, _weapon_id) {
	var _best = noone;
	var _best_d = 96;
	with (obj_bullet) {
		if (!is_predicted || !is_ghost) {
			continue;
		}
		if (_weapon_id != WEAPON_NONE && weapon_id != _weapon_id) {
			continue;
		}
		var _d = point_distance(x, y, _x, _y);
		if (_d < _best_d) {
			_best_d = _d;
			_best = id;
		}
	}
	return _best;
}

/// @function net_bind_host_socket()
function net_bind_host_socket() {
	for (var _port = NET_PORT_MIN; _port <= NET_PORT_MAX; _port++) {
		var _socket = network_create_socket_ext(network_socket_udp, _port);
		if (_socket >= 0) {
			return [_socket, _port];
		}
	}
	return [-1, -1];
}

/// @function net_shutdown()
function net_shutdown() {
	if (instance_exists(obj_net)) {
		instance_destroy(obj_net);
	}
}

/// @function net_host_notify_left()
/// @description Tell all clients the host closed the lobby, then shut down.
function net_host_notify_left() {
	if (!instance_exists(obj_net) || !obj_net.is_host) {
		return;
	}

	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_HOST_LEFT);
		var _size = buffer_tell(send_buffer);
		for (var _i = 0; _i < array_length(client_ips); _i++) {
			network_send_udp(socket, client_ips[_i], client_ports[_i], send_buffer, _size);
		}
	}
	net_shutdown();
}

/// @function net_find_player(_player_id)
function net_find_player(_player_id) {
	with (obj_player) {
		if (net_id == _player_id) {
			return id;
		}
	}
	return noone;
}

/// @function player_setup_net(_player, _player_id, _is_local, _display_name, _cosmetics)
/// @param {Array|Undefined} _cosmetics Optional [head, torso, leg, hand]. Local ignores and uses save.
function player_setup_net(_player, _player_id, _is_local, _display_name = undefined, _cosmetics = undefined) {
	_player.net_id = _player_id;
	_player.is_local = _is_local;
	if (_display_name != undefined) {
		_player.display_name = player_name_sanitize(_display_name);
	} else if (_is_local) {
		if (!variable_global_exists("player_name")) {
			player_name_load();
		}
		_player.display_name = global.player_name;
	}
	if (_is_local) {
		cosmetics_load();
		cosmetics_apply_local(_player);
	} else if (is_array(_cosmetics) && array_length(_cosmetics) >= 4) {
		cosmetics_apply_ids(_player, _cosmetics[0], _cosmetics[1], _cosmetics[2], _cosmetics[3]);
	}
	// Soft team tint on layered draw (via image_blend).
	if (_player_id == 1) {
		_player.image_blend = make_color_rgb(80, 200, 255);
	} else {
		_player.image_blend = make_color_rgb(255, 160, 60);
	}
}

/// @function player_gather_input(_player)
function player_gather_input(_player) {
	var _mobile = input_is_mobile_touch();

	_player.move_x = 0;
	_player.move_y = 0;
	_player.input_shoot = false;
	_player.input_reload = false;
	_player.input_throw_nade = false;

	// Pause overlay is local-only UI — block combat input while it's open.
	if (match_is_paused()) {
		return;
	}

	if (!_mobile) {
		var _kx = 0;
		var _ky = 0;
		if (keyboard_check(ord("A")) || keyboard_check(vk_left)) {
			_kx -= 1;
		}
		if (keyboard_check(ord("D")) || keyboard_check(vk_right)) {
			_kx += 1;
		}
		// Up thrust = jet (W / Up / Space). No separate jump.
		if (keyboard_check(ord("W")) || keyboard_check(vk_up) || keyboard_check(vk_space)) {
			_ky -= 1;
		}
		var _klen = point_distance(0, 0, _kx, _ky);
		if (_klen > 1) {
			_kx /= _klen;
			_ky /= _klen;
		}
		_player.move_x = _kx;
		_player.move_y = _ky;

		_player.input_shoot = mouse_check_button(mb_left);
		_player.input_reload = keyboard_check_pressed(ord("R"));
		_player.input_throw_nade = keyboard_check_pressed(ord("G"));

		var _cx = _player.x + _player.sprite_width * 0.5;
		var _cy = _player.y + _player.sprite_height * 0.5;
		_player.aim_dir = point_direction(_cx, _cy, mouse_x, mouse_y);
	}

	// Twin-stick / touch overlay — left stick is full analog move.
	if (instance_exists(obj_touch_controls)) {
		var _t = obj_touch_controls;
		if (_t.left_active) {
			var _stick = input_stick_deadzone(_t.left_nx, _t.left_ny);
			_player.move_x = _stick[0];
			_player.move_y = _stick[1];
		}
		if (_t.right_active) {
			_player.aim_dir = _t.right_dir;
			if (_t.shooting) {
				_player.input_shoot = true;
			}
		}
		if (_t.reload_pressed) {
			_player.input_reload = true;
		}
		if (_t.nade_pressed) {
			_player.input_throw_nade = true;
		}
	}

	// Desktop / shared GUI nade button (works even without a touch press this frame).
	var _nr = match_hud_nade_rect();
	if (ui_pointer_pressed_in(_nr[0], _nr[1], _nr[2], _nr[3], true)) {
		_player.input_throw_nade = true;
	}
	// Holding the Frag button must not also fire the gun (shared left click / touch).
	if (point_in_rectangle(
		device_mouse_x_to_gui(0),
		device_mouse_y_to_gui(0),
		_nr[0], _nr[1], _nr[2], _nr[3]
	) && device_mouse_check_button(0, mb_left)) {
		_player.input_shoot = false;
	}
}

/// @function player_spawn_at_point(_player_id, _is_local, _display_name, _cosmetics)
function player_spawn_at_point(_player_id, _is_local, _display_name = undefined, _cosmetics = undefined) {
	var _spawn = spawn_point_get_random();
	var _x = (_spawn != noone) ? _spawn.x : room_width * 0.5;
	var _y = (_spawn != noone) ? _spawn.y : room_height * 0.5;
	var _player = instance_create_layer(_x, _y, "Instances", obj_player);
	player_setup_net(_player, _player_id, _is_local, _display_name, _cosmetics);
	return _player;
}

/// @function net_lobby_player_count()
function net_lobby_player_count() {
	if (!instance_exists(obj_net)) {
		return 0;
	}
	return 1 + array_length(obj_net.client_ips);
}

/// @function net_host_find_client(_ip, _port)
function net_host_find_client(_ip, _port) {
	with (obj_net) {
		for (var _i = 0; _i < array_length(client_ips); _i++) {
			if (client_ips[_i] == _ip && client_ports[_i] == _port) {
				return _i;
			}
		}
	}
	return -1;
}

/// @function net_host_find_client_by_id(_player_id)
function net_host_find_client_by_id(_player_id) {
	with (obj_net) {
		for (var _i = 0; _i < array_length(client_player_ids); _i++) {
			if (client_player_ids[_i] == _player_id) {
				return _i;
			}
		}
	}
	return -1;
}

/// @function net_host_send_reject(_ip, _port, _reason)
function net_host_send_reject(_ip, _port, _reason) {
	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_REJECT);
		buffer_write(send_buffer, buffer_u8, _reason);
		network_send_udp(socket, _ip, _port, send_buffer, buffer_tell(send_buffer));
	}
}

/// @function net_host_add_client(_ip, _port, _display_name, _cosmetics)
/// @param {Array} _cosmetics [head, torso, leg, hand]
function net_host_add_client(_ip, _port, _display_name, _cosmetics = undefined) {
	var _name = player_name_sanitize(_display_name);
	if (!is_array(_cosmetics) || array_length(_cosmetics) < 4) {
		_cosmetics = [0, 0, 0, 0];
	}
	_cosmetics = [
		cosmetics_clamp_id(COS_PART_HEAD, _cosmetics[0]),
		cosmetics_clamp_id(COS_PART_TORSO, _cosmetics[1]),
		cosmetics_clamp_id(COS_PART_LEG, _cosmetics[2]),
		cosmetics_clamp_id(COS_PART_HAND, _cosmetics[3])
	];

	var _existing = net_host_find_client(_ip, _port);
	if (_existing >= 0) {
		obj_net.client_names[_existing] = _name;
		obj_net.client_cos_head[_existing] = _cosmetics[0];
		obj_net.client_cos_torso[_existing] = _cosmetics[1];
		obj_net.client_cos_leg[_existing] = _cosmetics[2];
		obj_net.client_cos_hand[_existing] = _cosmetics[3];
		obj_net.client_silent_frames[_existing] = 0;
		return obj_net.client_player_ids[_existing];
	}

	if (obj_net.phase != "lobby") {
		net_host_send_reject(_ip, _port, NET_REJECT_IN_MATCH);
		return -1;
	}

	if (net_lobby_player_count() >= obj_net.max_players) {
		net_host_send_reject(_ip, _port, NET_REJECT_FULL);
		return -1;
	}

	var _pid = obj_net.next_player_id;
	obj_net.next_player_id += 1;
	array_push(obj_net.client_ips, _ip);
	array_push(obj_net.client_ports, _port);
	array_push(obj_net.client_player_ids, _pid);
	array_push(obj_net.client_names, _name);
	array_push(obj_net.client_cos_head, _cosmetics[0]);
	array_push(obj_net.client_cos_torso, _cosmetics[1]);
	array_push(obj_net.client_cos_leg, _cosmetics[2]);
	array_push(obj_net.client_cos_hand, _cosmetics[3]);
	array_push(obj_net.client_silent_frames, 0);

	obj_net.status_text = "Hosting on port " + string(obj_net.bound_port);
	obj_net.status_detail = _name + " joined lobby";
	return _pid;
}

/// @function net_host_remove_client_index(_index)
function net_host_remove_client_index(_index) {
	with (obj_net) {
		if (_index < 0 || _index >= array_length(client_ips)) {
			return;
		}
		var _pid = client_player_ids[_index];
		var _player = net_find_player(_pid);
		if (_player != noone) {
			instance_destroy(_player);
		}
		array_delete(client_ips, _index, 1);
		array_delete(client_ports, _index, 1);
		array_delete(client_player_ids, _index, 1);
		array_delete(client_names, _index, 1);
		array_delete(client_cos_head, _index, 1);
		array_delete(client_cos_torso, _index, 1);
		array_delete(client_cos_leg, _index, 1);
		array_delete(client_cos_hand, _index, 1);
		if (array_length(client_silent_frames) > _index) {
			array_delete(client_silent_frames, _index, 1);
		}
	}
}

/// @function net_host_touch_client(_ip, _port)
/// @description Reset lobby timeout for a known client.
function net_host_touch_client(_ip, _port) {
	var _index = net_host_find_client(_ip, _port);
	if (_index < 0) {
		return;
	}
	obj_net.client_silent_frames[_index] = 0;
}

/// @function net_host_prune_silent_clients()
/// @description Drop lobby clients that stopped sending keepalives.
function net_host_prune_silent_clients() {
	if (!instance_exists(obj_net) || !obj_net.is_host || obj_net.phase != "lobby") {
		return;
	}

	var _changed = false;
	with (obj_net) {
		for (var _i = array_length(client_silent_frames) - 1; _i >= 0; _i--) {
			client_silent_frames[_i] += 1;
			if (client_silent_frames[_i] >= NET_CLIENT_TIMEOUT_FRAMES) {
				status_detail = client_names[_i] + " left lobby";
				net_host_remove_client_index(_i);
				_changed = true;
			}
		}
	}
	if (_changed) {
		net_host_send_lobby_state();
	}
}

/// @function net_client_send_leave()
function net_client_send_leave() {
	with (obj_net) {
		if (!is_client || !joined || socket < 0 || host_ip == "") {
			return;
		}
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_LEAVE);
		buffer_write(send_buffer, buffer_u8, local_player_id);
		network_send_udp(socket, host_ip, host_port, send_buffer, buffer_tell(send_buffer));
	}
}

/// @function net_client_leave_to_menu()
/// @description Tell host we left, then tear down net and return to menu.
function net_client_leave_to_menu() {
	net_client_send_leave();
	global.net_mode = "offline";
	global.menu_message = "";
	net_shutdown();
	room_goto(room_main_menu);
}

/// @function net_leave_match_to_menu(_message)
/// @description Leave match/results for the main menu. Host notifies clients first.
function net_leave_match_to_menu(_message = "") {
	if (!instance_exists(obj_net)) {
		global.net_mode = "offline";
		global.menu_message = _message;
		room_goto(room_main_menu);
		return;
	}

	if (obj_net.is_host) {
		global.net_mode = "offline";
		global.menu_message = _message;
		net_host_notify_left();
		room_goto(room_main_menu);
		return;
	}

	if (obj_net.is_client) {
		net_client_send_leave();
	}

	global.net_mode = "offline";
	global.menu_message = _message;
	net_shutdown();
	room_goto(room_main_menu);
}

/// @function net_host_kick_player(_player_id)
function net_host_kick_player(_player_id) {
	var _index = net_host_find_client_by_id(_player_id);
	if (_index < 0) {
		return false;
	}

	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_KICK);
		network_send_udp(socket, client_ips[_index], client_ports[_index], send_buffer, buffer_tell(send_buffer));
		status_detail = client_names[_index] + " was kicked";
	}
	net_host_remove_client_index(_index);
	net_host_send_lobby_state();
	return true;
}

/// @function net_client_send_discover()
/// @description Ask LAN hosts to announce themselves (unicast beacon reply).
/// Uses network_send_broadcast — Android denies plain UDP to 255.255.255.255.
function net_client_send_discover() {
	with (obj_net) {
		if (socket < 0 || joined) {
			return;
		}
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_DISCOVER);
		var _size = buffer_tell(send_buffer);
		for (var _port = NET_PORT_MIN; _port <= NET_PORT_MAX; _port++) {
			network_send_broadcast(socket, _port, send_buffer, _size);
		}
	}
}

/// @function net_host_send_beacon(_ip, _port)
/// @description Reply (or broadcast) lobby info for the join browser.
function net_host_send_beacon(_ip = undefined, _port = undefined) {
	with (obj_net) {
		if (!is_host || host_failed || socket < 0) {
			return;
		}
		if (phase != "lobby") {
			return;
		}

		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_BEACON);
		buffer_write(send_buffer, buffer_string, lobby_name);
		buffer_write(send_buffer, buffer_string, global.player_name);
		buffer_write(send_buffer, buffer_u8, net_lobby_player_count());
		buffer_write(send_buffer, buffer_u8, max_players);
		buffer_write(send_buffer, buffer_u16, bound_port);
		var _size = buffer_tell(send_buffer);

		if (_ip != undefined && _port != undefined) {
			network_send_udp(socket, _ip, _port, send_buffer, _size);
		} else {
			// Subnet broadcast to the discover port (clients bind here to listen).
			network_send_broadcast(socket, NET_DISCOVER_PORT, send_buffer, _size);
		}
	}
}

/// @function net_client_remember_beacon(_ip, _port, _lobby_name, _host_name, _players, _max_players, _host_port)
function net_client_remember_beacon(_ip, _port, _lobby_name, _host_name, _players, _max_players, _host_port) {
	with (obj_net) {
		var _key_ip = string(_ip);
		var _key_port = (_host_port > 0) ? _host_port : _port;
		var _found = -1;
		for (var _i = 0; _i < array_length(discovered); _i++) {
			if (discovered[_i].ip == _key_ip && discovered[_i].port == _key_port) {
				_found = _i;
				break;
			}
		}

		var _entry = {
			ip: _key_ip,
			port: _key_port,
			lobby_name: lobby_name_sanitize(_lobby_name),
			host_name: player_name_sanitize(_host_name),
			players: _players,
			max_players: _max_players,
			last_seen: current_time
		};

		if (_found >= 0) {
			discovered[_found] = _entry;
		} else {
			array_push(discovered, _entry);
		}

		if (browse_index >= array_length(discovered)) {
			browse_index = max(0, array_length(discovered) - 1);
		}
	}
}

/// @function net_client_prune_discovered()
function net_client_prune_discovered() {
	with (obj_net) {
		var _keep = [];
		var _selected_ip = "";
		var _selected_port = -1;
		if (browse_index >= 0 && browse_index < array_length(discovered)) {
			_selected_ip = discovered[browse_index].ip;
			_selected_port = discovered[browse_index].port;
		}

		for (var _i = 0; _i < array_length(discovered); _i++) {
			if (current_time - discovered[_i].last_seen <= 3000) {
				array_push(_keep, discovered[_i]);
			}
		}
		discovered = _keep;

		browse_index = 0;
		for (var _j = 0; _j < array_length(discovered); _j++) {
			if (discovered[_j].ip == _selected_ip && discovered[_j].port == _selected_port) {
				browse_index = _j;
				break;
			}
		}
		if (array_length(discovered) <= 0) {
			browse_index = 0;
		} else {
			browse_index = clamp(browse_index, 0, array_length(discovered) - 1);
		}
	}
}

/// @function net_client_send_join()
function net_client_send_join() {
	if (!variable_global_exists("player_name")) {
		player_name_load();
	}

	with (obj_net) {
		if (socket < 0) {
			return;
		}
		if (!joining && !joined) {
			return;
		}
		if (host_ip == "" || host_port < 0) {
			return;
		}

		var _cos = cosmetics_local_ids();
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_JOIN);
		buffer_write(send_buffer, buffer_string, global.player_name);
		net_write_cosmetics(send_buffer, _cos[0], _cos[1], _cos[2], _cos[3]);
		var _size = buffer_tell(send_buffer);

		if (joined) {
			network_send_udp(socket, host_ip, host_port, send_buffer, _size);
		} else {
			// Host may be on any port in the range until WELCOME locks it.
			for (var _p = NET_PORT_MIN; _p <= NET_PORT_MAX; _p++) {
				network_send_udp(socket, host_ip, _p, send_buffer, _size);
			}
		}
	}
}

/// @function net_client_send_input()
function net_client_send_input() {
	var _local = net_find_player(obj_net.local_player_id);
	if (_local == noone) {
		return;
	}

	player_gather_input(_local);

	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_INPUT);
		buffer_write(send_buffer, buffer_u8, local_player_id);

		var _bits = 0;
		if (_local.input_shoot) _bits |= 1;
		if (_local.input_reload) _bits |= 2;
		if (_local.input_throw_nade) _bits |= 4;
		buffer_write(send_buffer, buffer_u8, _bits);
		buffer_write(send_buffer, buffer_s8, clamp(round(_local.move_x * 127), -127, 127));
		buffer_write(send_buffer, buffer_s8, clamp(round(_local.move_y * 127), -127, 127));
		buffer_write(send_buffer, buffer_f32, _local.aim_dir);

		network_send_udp(socket, host_ip, host_port, send_buffer, buffer_tell(send_buffer));
	}
}

/// @function net_client_send_want_pickup(_pickup_net_id)
function net_client_send_want_pickup(_pickup_net_id) {
	if (_pickup_net_id <= 0 || !instance_exists(obj_net)) {
		return;
	}
	with (obj_net) {
		if (!is_client || !joined || socket < 0 || host_ip == "") {
			return;
		}
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_WANT_PICKUP);
		buffer_write(send_buffer, buffer_u8, local_player_id);
		buffer_write(send_buffer, buffer_u16, _pickup_net_id);
		network_send_udp(socket, host_ip, host_port, send_buffer, buffer_tell(send_buffer));
	}
}

/// @function net_host_send_welcome(_ip, _port, _player_id)
function net_host_send_welcome(_ip, _port, _player_id) {
	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_WELCOME);
		buffer_write(send_buffer, buffer_u8, _player_id);
		buffer_write(send_buffer, buffer_string, lobby_name);
		network_send_udp(socket, _ip, _port, send_buffer, buffer_tell(send_buffer));
	}
}

/// @function net_host_send_lobby_state()
function net_host_send_lobby_state() {
	with (obj_net) {
		if (array_length(client_ips) <= 0) {
			return;
		}

		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_LOBBY_STATE);
		buffer_write(send_buffer, buffer_string, lobby_name);
		buffer_write(send_buffer, buffer_u8, map_index);
		buffer_write(send_buffer, buffer_u16, match_time_sec);
		buffer_write(send_buffer, buffer_u8, max_players);

		var _count = net_lobby_player_count();
		buffer_write(send_buffer, buffer_u8, _count);

		cosmetics_ensure_globals();
		// Host entry
		buffer_write(send_buffer, buffer_u8, 1);
		buffer_write(send_buffer, buffer_string, global.player_name);
		buffer_write(send_buffer, buffer_u8, 1); // is host
		net_write_cosmetics(send_buffer, global.cosmetic_head, global.cosmetic_torso, global.cosmetic_leg, global.cosmetic_hand);

		for (var _i = 0; _i < array_length(client_player_ids); _i++) {
			buffer_write(send_buffer, buffer_u8, client_player_ids[_i]);
			buffer_write(send_buffer, buffer_string, client_names[_i]);
			buffer_write(send_buffer, buffer_u8, 0);
			net_write_cosmetics(send_buffer, client_cos_head[_i], client_cos_torso[_i], client_cos_leg[_i], client_cos_hand[_i]);
		}

		var _size = buffer_tell(send_buffer);
		for (var _c = 0; _c < array_length(client_ips); _c++) {
			network_send_udp(socket, client_ips[_c], client_ports[_c], send_buffer, _size);
		}
	}
}

/// @function net_host_send_start()
function net_host_send_start() {
	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_START);
		buffer_write(send_buffer, buffer_u8, map_index);
		buffer_write(send_buffer, buffer_u16, match_time_sec);
		var _size = buffer_tell(send_buffer);
		for (var _i = 0; _i < array_length(client_ips); _i++) {
			network_send_udp(socket, client_ips[_i], client_ports[_i], send_buffer, _size);
		}
	}
}

/// @function net_host_send_match_end()
function net_host_send_match_end() {
	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_MATCH_END);
		buffer_write(send_buffer, buffer_u8, array_length(results));
		for (var _i = 0; _i < array_length(results); _i++) {
			net_write_name(send_buffer, results[_i].name);
			buffer_write(send_buffer, buffer_u16, clamp(round(results[_i].kills), 0, 999));
			buffer_write(send_buffer, buffer_u16, clamp(round(results[_i].deaths), 0, 999));
		}
		var _size = buffer_tell(send_buffer);
		for (var _c = 0; _c < array_length(client_ips); _c++) {
			network_send_udp(socket, client_ips[_c], client_ports[_c], send_buffer, _size);
		}
	}
}

/// @function net_collect_results()
function net_collect_results() {
	var _results = [];
	with (obj_player) {
		array_push(_results, {
			name: display_name,
			kills: clamp(round(kills), 0, 999),
			deaths: clamp(round(deaths), 0, 999),
			net_id: net_id
		});
	}

	// Sort by kills desc, deaths asc
	array_sort(_results, function(_a, _b) {
		if (_a.kills == _b.kills) {
			return sign(_a.deaths - _b.deaths);
		}
		return sign(_b.kills - _a.kills);
	});
	return _results;
}

/// @function match_pause_draw_overlay()
/// @description Full-screen translucent pause UI: live scoreboard + Resume / Exit.
/// Does NOT freeze simulation — only blocks local controls/UI while open.
function match_pause_draw_overlay() {
	if (!instance_exists(obj_net) || !obj_net.match_paused) {
		return;
	}

	var _gw = display_get_gui_width();
	var _gh = display_get_gui_height();
	var _s = ui_scale();
	var _ts = ui_text_scale();
	var _board = net_collect_results();
	var _local_id = obj_net.local_player_id;

	// Dim everything underneath so sticks / HUD can't be used.
	var _old_a = draw_get_alpha();
	draw_set_alpha(0.72);
	draw_set_color(c_black);
	draw_rectangle(0, 0, _gw, _gh, false);
	draw_set_alpha(_old_a);

	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	draw_text_transformed(_gw * 0.5, round(48 * _s), "SCOREBOARD", _ts * 1.15, _ts * 1.15, 0);
	draw_set_color(c_ltgray);
	draw_text_transformed(
		_gw * 0.5,
		round(88 * _s),
		obj_net.lobby_name + "  |  " + arena_name_from_index(obj_net.map_index),
		_ts * 0.9,
		_ts * 0.9,
		0
	);

	var _y = round(130 * _s);
	draw_set_halign(fa_left);
	draw_set_color(c_ltgray);
	draw_text_transformed(_gw * 0.5 - 200, _y, "PLAYER", _ts * 0.9, _ts * 0.9, 0);
	draw_text_transformed(_gw * 0.5 + 40, _y, "KILLS", _ts * 0.9, _ts * 0.9, 0);
	draw_text_transformed(_gw * 0.5 + 140, _y, "DEATHS", _ts * 0.9, _ts * 0.9, 0);
	_y += round(36 * _s);

	for (var _i = 0; _i < array_length(_board); _i++) {
		var _row = _board[_i];
		var _is_you = (_row.net_id == _local_id && _local_id > 0);
		draw_set_color(_is_you ? c_lime : ((_i == 0) ? c_yellow : c_white));
		draw_text_transformed(_gw * 0.5 - 200, _y, string(_i + 1) + ". " + _row.name, _ts, _ts, 0);
		draw_text_transformed(_gw * 0.5 + 40, _y, string(_row.kills), _ts, _ts, 0);
		draw_text_transformed(_gw * 0.5 + 140, _y, string(_row.deaths), _ts, _ts, 0);
		_y += round(34 * _s);
	}

	var _resume = match_pause_resume_rect();
	var _exit = match_pause_exit_rect();
	draw_ui_button(_resume[0], _resume[1], _resume[2], _resume[3], "Resume", false);
	draw_ui_button(_exit[0], _exit[1], _exit[2], _exit[3], "Exit", false);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
}

/// @function match_pause_handle_input()
/// @description Open/close pause overlay; Exit leaves to main menu. Returns true if handled.
function match_pause_handle_input() {
	if (!instance_exists(obj_net) || obj_net.phase != "match") {
		return false;
	}

	if (obj_net.match_paused) {
		var _resume = match_pause_resume_rect();
		var _exit = match_pause_exit_rect();
		if (ui_pointer_pressed_in(_resume[0], _resume[1], _resume[2], _resume[3], true)
			|| ui_back_pressed()) {
			obj_net.match_paused = false;
			return true;
		}
		if (ui_pointer_pressed_in(_exit[0], _exit[1], _exit[2], _exit[3], true)) {
			obj_net.match_paused = false;
			net_leave_match_to_menu();
			return true;
		}
		// Swallow other UI while the overlay is up.
		return true;
	}

	var _pause = match_hud_pause_rect();
	if (ui_pointer_pressed_in(_pause[0], _pause[1], _pause[2], _pause[3], true)
		|| ui_back_pressed()) {
		obj_net.match_paused = true;
		return true;
	}
	return false;
}

/// @function net_begin_match()
function net_begin_match() {
	with (obj_net) {
		phase = "match";
		match_frames_left = match_time_sec * 60;
		results = [];
		kill_feed = [];
		match_paused = false;
		next_bullet_id = 1;
		next_grenade_id = 1;
		next_weapon_pickup_id = 1;
		weapon_spawn_timer = WEAPON_SPAWN_FIRST_DELAY;
		match_end_resend_left = 0;
		match_end_resend_timer = 0;
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
		with (obj_grenade) {
			instance_destroy();
		}
		with (obj_frag_explosion) {
			instance_destroy();
		}
		weapon_pickup_clear_all();
		net_host_send_start();
		room_goto(arena_room_from_index(map_index));
	}
}

/// @function net_end_match()
function net_end_match() {
	with (obj_net) {
		if (phase != "match") {
			return;
		}
		results = net_collect_results();
		phase = "results";
		match_paused = false;
		match_end_resend_left = NET_MATCH_END_RESENDS;
		match_end_resend_timer = NET_MATCH_END_INTERVAL;
		net_host_send_match_end();
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
		with (obj_grenade) {
			instance_destroy();
		}
		with (obj_frag_explosion) {
			instance_destroy();
		}
		weapon_pickup_clear_all();
		status_text = "Match over";
		status_detail = "View scoreboard";
	}
}

/// @function net_host_send_return_lobby()
function net_host_send_return_lobby() {
	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_RETURN_LOBBY);
		var _size = buffer_tell(send_buffer);
		for (var _i = 0; _i < array_length(client_ips); _i++) {
			network_send_udp(socket, client_ips[_i], client_ports[_i], send_buffer, _size);
		}
	}
}

/// @function net_return_to_lobby()
function net_return_to_lobby() {
	with (obj_net) {
		phase = "lobby";
		match_frames_left = 0;
		results = [];
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
		with (obj_grenade) {
			instance_destroy();
		}
		with (obj_frag_explosion) {
			instance_destroy();
		}
		weapon_pickup_clear_all();
		if (is_host) {
			net_host_send_return_lobby();
		}
		room_goto(room_lobby);
		if (is_host) {
			net_host_send_lobby_state();
		}
	}
}

/// @function net_spawn_match_players()
function net_spawn_match_players() {
	if (!instance_exists(obj_net)) {
		return;
	}

	with (obj_net) {
		if (is_host) {
			if (net_find_player(1) == noone) {
				player_spawn_at_point(1, true, global.player_name);
			}
			for (var _i = 0; _i < array_length(client_player_ids); _i++) {
				var _pid = client_player_ids[_i];
				if (net_find_player(_pid) == noone) {
					player_spawn_at_point(_pid, false, client_names[_i], [
						client_cos_head[_i],
						client_cos_torso[_i],
						client_cos_leg[_i],
						client_cos_hand[_i]
					]);
				}
			}
		} else if (is_client && joined) {
			if (net_find_player(local_player_id) == noone) {
				player_spawn_at_point(local_player_id, true, global.player_name);
			}
		}
	}
}

/// @function net_host_send_snapshots()
function net_host_send_snapshots() {
	with (obj_net) {
		if (phase != "match" || array_length(client_ips) <= 0) {
			return;
		}

		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_SNAPSHOT);
		buffer_write(send_buffer, buffer_u16, max(0, ceil(match_frames_left / 60)));

		var _player_count_pos = buffer_tell(send_buffer);
		buffer_write(send_buffer, buffer_u8, 0);
		var _player_count = 0;

		with (obj_player) {
			buffer_write(other.send_buffer, buffer_u8, net_id);
			buffer_write(other.send_buffer, buffer_f32, x);
			buffer_write(other.send_buffer, buffer_f32, y);
			buffer_write(other.send_buffer, buffer_f32, aim_dir);
			buffer_write(other.send_buffer, buffer_s16, hp);
			buffer_write(other.send_buffer, buffer_u8, alive ? 1 : 0);
			buffer_write(other.send_buffer, buffer_u8, weapon_id);
			buffer_write(other.send_buffer, buffer_u8, clamp(mag, 0, 255));
			buffer_write(other.send_buffer, buffer_u8, clamp(reserve, 0, 255));
			buffer_write(other.send_buffer, buffer_u8, clamp(grenades, 0, 255));
			buffer_write(other.send_buffer, buffer_u8, reloading ? 1 : 0);
			buffer_write(other.send_buffer, buffer_u8, clamp(round(fuel), 0, 255));
			buffer_write(other.send_buffer, buffer_u16, kills);
			buffer_write(other.send_buffer, buffer_u16, deaths);
			buffer_write(other.send_buffer, buffer_string, display_name);
			net_write_cosmetics(other.send_buffer, cosmetic_head, cosmetic_torso, cosmetic_leg, cosmetic_hand);
			_player_count += 1;
		}

		var _after_players = buffer_tell(send_buffer);
		buffer_seek(send_buffer, buffer_seek_start, _player_count_pos);
		buffer_write(send_buffer, buffer_u8, _player_count);
		buffer_seek(send_buffer, buffer_seek_start, _after_players);

		var _bullet_count_pos = buffer_tell(send_buffer);
		buffer_write(send_buffer, buffer_u8, 0);
		var _bullet_count = 0;

		with (obj_bullet) {
			if (!is_ghost && net_id > 0 && _bullet_count < NET_BULLET_MAX) {
				buffer_write(other.send_buffer, buffer_u16, net_id);
				buffer_write(other.send_buffer, buffer_u8, weapon_id);
				buffer_write(other.send_buffer, buffer_f32, x);
				buffer_write(other.send_buffer, buffer_f32, y);
				buffer_write(other.send_buffer, buffer_f32, hsp);
				buffer_write(other.send_buffer, buffer_f32, vsp);
				_bullet_count += 1;
			}
		}

		var _after_bullets = buffer_tell(send_buffer);
		buffer_seek(send_buffer, buffer_seek_start, _bullet_count_pos);
		buffer_write(send_buffer, buffer_u8, _bullet_count);
		buffer_seek(send_buffer, buffer_seek_start, _after_bullets);

		var _pickup_count_pos = buffer_tell(send_buffer);
		buffer_write(send_buffer, buffer_u8, 0);
		var _pickup_count = 0;

		with (obj_weapon_pickup) {
			if (!is_ghost && net_id > 0 && _pickup_count < NET_WEAPON_PICKUP_MAX) {
				buffer_write(other.send_buffer, buffer_u16, net_id);
				buffer_write(other.send_buffer, buffer_u8, weapon_id);
				buffer_write(other.send_buffer, buffer_f32, x);
				buffer_write(other.send_buffer, buffer_f32, y);
				buffer_write(other.send_buffer, buffer_u8, clamp(mag, 0, 255));
				buffer_write(other.send_buffer, buffer_u8, clamp(reserve, 0, 255));
				buffer_write(other.send_buffer, buffer_u16, clamp(life, 0, 65535));
				_pickup_count += 1;
			}
		}

		var _after_pickups = buffer_tell(send_buffer);
		buffer_seek(send_buffer, buffer_seek_start, _pickup_count_pos);
		buffer_write(send_buffer, buffer_u8, _pickup_count);
		buffer_seek(send_buffer, buffer_seek_start, _after_pickups);

		var _grenade_count_pos = buffer_tell(send_buffer);
		buffer_write(send_buffer, buffer_u8, 0);
		var _grenade_count = 0;
		with (obj_grenade) {
			if (!is_ghost && net_id > 0 && _grenade_count < NET_GRENADE_MAX) {
				buffer_write(other.send_buffer, buffer_u16, net_id);
				buffer_write(other.send_buffer, buffer_f32, x);
				buffer_write(other.send_buffer, buffer_f32, y);
				buffer_write(other.send_buffer, buffer_f32, hsp);
				buffer_write(other.send_buffer, buffer_f32, vsp);
				buffer_write(other.send_buffer, buffer_u16, clamp(fuse, 0, 65535));
				buffer_write(other.send_buffer, buffer_u8, owner_player_id);
				_grenade_count += 1;
			}
		}
		var _after_grenades = buffer_tell(send_buffer);
		buffer_seek(send_buffer, buffer_seek_start, _grenade_count_pos);
		buffer_write(send_buffer, buffer_u8, _grenade_count);
		buffer_seek(send_buffer, buffer_seek_start, _after_grenades);

		var _size = buffer_tell(send_buffer);
		for (var _i = 0; _i < array_length(client_ips); _i++) {
			network_send_udp(socket, client_ips[_i], client_ports[_i], send_buffer, _size);
		}
	}
}

/// @function net_host_broadcast_frag_boom(_x, _y)
/// @description Tell clients to play explosion FX (damage already applied on host).
function net_host_broadcast_frag_boom(_x, _y) {
	if (!instance_exists(obj_net) || !obj_net.is_host) {
		return;
	}
	if (array_length(obj_net.client_ips) <= 0) {
		return;
	}
	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_FRAG_BOOM);
		buffer_write(send_buffer, buffer_f32, _x);
		buffer_write(send_buffer, buffer_f32, _y);
		var _size = buffer_tell(send_buffer);
		for (var _c = 0; _c < array_length(client_ips); _c++) {
			network_send_udp(socket, client_ips[_c], client_ports[_c], send_buffer, _size);
		}
	}
}

/// @function net_find_grenade(_net_id)
function net_find_grenade(_net_id) {
	with (obj_grenade) {
		if (net_id == _net_id) {
			return id;
		}
	}
	return noone;
}

/// @function net_host_handle_message(_msg, _buffer, _ip, _port)
function net_host_handle_message(_msg, _buffer, _ip, _port) {
	if (_msg == NET_MSG_DISCOVER) {
		net_host_send_beacon(_ip, _port);
		return;
	}

	if (_msg == NET_MSG_JOIN) {
		var _join_name = PLAYER_NAME_DEFAULT;
		if (buffer_tell(_buffer) < buffer_get_size(_buffer)) {
			_join_name = buffer_read(_buffer, buffer_string);
		}
		var _join_cos = net_read_cosmetics(_buffer);
		var _pid = net_host_add_client(_ip, _port, _join_name, _join_cos);
		if (_pid < 0) {
			return;
		}
		net_host_touch_client(_ip, _port);
		net_host_send_welcome(_ip, _port, _pid);
		net_host_send_lobby_state();
		return;
	}

	if (_msg == NET_MSG_LEAVE) {
		var _leave_index = net_host_find_client(_ip, _port);
		if (_leave_index < 0) {
			return;
		}
		if (buffer_tell(_buffer) < buffer_get_size(_buffer)) {
			var _leave_pid = buffer_read(_buffer, buffer_u8);
			if (_leave_pid != obj_net.client_player_ids[_leave_index]) {
				return;
			}
		}
		obj_net.status_detail = obj_net.client_names[_leave_index] + " left lobby";
		net_host_remove_client_index(_leave_index);
		net_host_send_lobby_state();
		return;
	}

	if (_msg == NET_MSG_INPUT) {
		if (obj_net.phase != "match") {
			return;
		}
		var _index = net_host_find_client(_ip, _port);
		if (_index < 0) {
			return;
		}
		net_host_touch_client(_ip, _port);

		var _pid = buffer_read(_buffer, buffer_u8);
		if (_pid != obj_net.client_player_ids[_index]) {
			return;
		}

		var _player = net_find_player(_pid);
		if (_player == noone) {
			return;
		}

		var _bits = buffer_read(_buffer, buffer_u8);
		_player.input_shoot = (_bits & 1) != 0;
		_player.input_reload = (_bits & 2) != 0;
		// Throw is edge-triggered on client; OR so a late packet still arms one throw.
		if ((_bits & 4) != 0) {
			_player.input_throw_nade = true;
		}
		_player.move_x = clamp(buffer_read(_buffer, buffer_s8) / 127, -1, 1);
		_player.move_y = clamp(buffer_read(_buffer, buffer_s8) / 127, -1, 1);
		_player.aim_dir = buffer_read(_buffer, buffer_f32);
		return;
	}

	if (_msg == NET_MSG_WANT_PICKUP) {
		if (obj_net.phase != "match") {
			return;
		}
		var _windex = net_host_find_client(_ip, _port);
		if (_windex < 0) {
			return;
		}
		net_host_touch_client(_ip, _port);
		var _wpid = buffer_read(_buffer, buffer_u8);
		if (_wpid != obj_net.client_player_ids[_windex]) {
			return;
		}
		var _pickup_id = buffer_read(_buffer, buffer_u16);
		var _wplayer = net_find_player(_wpid);
		var _wpickup = weapon_pickup_find(_pickup_id);
		if (_wplayer != noone && _wpickup != noone && !_wpickup.is_ghost) {
			weapon_swap_with_pickup(_wplayer, _wpickup);
		}
		return;
	}
}

/// @function net_client_apply_lobby_state(_buffer)
function net_client_apply_lobby_state(_buffer) {
	with (obj_net) {
		lobby_name = buffer_read(_buffer, buffer_string);
		map_index = buffer_read(_buffer, buffer_u8);
		match_time_sec = buffer_read(_buffer, buffer_u16);
		max_players = buffer_read(_buffer, buffer_u8);

		var _count = buffer_read(_buffer, buffer_u8);
		lobby_roster = [];
		for (var _i = 0; _i < _count; _i++) {
			var _id = buffer_read(_buffer, buffer_u8);
			var _name = buffer_read(_buffer, buffer_string);
			var _is_host = buffer_read(_buffer, buffer_u8) == 1;
			var _cos = net_read_cosmetics(_buffer);
			array_push(lobby_roster, {
				net_id: _id,
				name: _name,
				is_host: _is_host,
				cosmetic_head: _cos[0],
				cosmetic_torso: _cos[1],
				cosmetic_leg: _cos[2],
				cosmetic_hand: _cos[3]
			});
		}
	}
}

/// @function net_client_apply_match_end(_buffer)
function net_client_apply_match_end(_buffer) {
	with (obj_net) {
		var _count = buffer_read(_buffer, buffer_u8);
		if (_count > 8) {
			return;
		}

		var _bytes_needed = _count * (NET_NAME_BYTES + 4);
		if (buffer_tell(_buffer) + _bytes_needed > buffer_get_size(_buffer)) {
			return;
		}

		var _parsed = [];
		for (var _i = 0; _i < _count; _i++) {
			var _name = net_read_name(_buffer);
			var _kills = buffer_read(_buffer, buffer_u16);
			var _deaths = buffer_read(_buffer, buffer_u16);
			if (_kills > 999 || _deaths > 999) {
				return;
			}
			array_push(_parsed, {
				name: _name,
				kills: _kills,
				deaths: _deaths
			});
		}

		results = _parsed;
		phase = "results";
		match_paused = false;
		status_text = "Match over";
		status_detail = "Waiting for host...";
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
		with (obj_grenade) {
			instance_destroy();
		}
		with (obj_frag_explosion) {
			instance_destroy();
		}
		weapon_pickup_clear_all();
	}
}

/// @function net_client_handle_message(_msg, _buffer, _ip, _port)
function net_client_handle_message(_msg, _buffer, _ip, _port) {
	if (_msg == NET_MSG_BEACON) {
		if (obj_net.joined) {
			return;
		}
		var _lobby = buffer_read(_buffer, buffer_string);
		var _host_name = buffer_read(_buffer, buffer_string);
		var _players = buffer_read(_buffer, buffer_u8);
		var _max_p = buffer_read(_buffer, buffer_u8);
		var _host_port = buffer_read(_buffer, buffer_u16);
		net_client_remember_beacon(_ip, _port, _lobby, _host_name, _players, _max_p, _host_port);
		return;
	}

	if (_msg == NET_MSG_WELCOME) {
		var _pid = buffer_read(_buffer, buffer_u8);
		var _lobby = lobby_name_default();
		if (buffer_tell(_buffer) < buffer_get_size(_buffer)) {
			_lobby = buffer_read(_buffer, buffer_string);
		}

		obj_net.local_player_id = _pid;
		obj_net.joined = true;
		obj_net.joining = false;
		obj_net.host_ip = _ip;
		obj_net.host_port = _port;
		obj_net.lobby_name = lobby_name_sanitize(_lobby);
		obj_net.phase = "lobby";
		obj_net.status_text = "Joined lobby";
		obj_net.status_detail = obj_net.lobby_name;

		if (room != room_lobby) {
			room_goto(room_lobby);
		}
		return;
	}

	if (_msg == NET_MSG_LOBBY_STATE) {
		net_client_apply_lobby_state(_buffer);
		return;
	}

	if (_msg == NET_MSG_START) {
		obj_net.map_index = buffer_read(_buffer, buffer_u8);
		obj_net.match_time_sec = buffer_read(_buffer, buffer_u16);
		obj_net.phase = "match";
		obj_net.match_frames_left = obj_net.match_time_sec * 60;
		obj_net.results = [];
		obj_net.kill_feed = [];
		obj_net.match_paused = false;
		obj_net.host_silent_frames = 0;
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
		with (obj_grenade) {
			instance_destroy();
		}
		with (obj_frag_explosion) {
			instance_destroy();
		}
		weapon_pickup_clear_all();
		room_goto(arena_room_from_index(obj_net.map_index));
		return;
	}

	if (_msg == NET_MSG_KILL_FEED) {
		var _kname = net_read_name(_buffer);
		var _vname = net_read_name(_buffer);
		var _wid = buffer_read(_buffer, buffer_u8);
		var _kid = buffer_read(_buffer, buffer_u8);
		var _vid = buffer_read(_buffer, buffer_u8);
		killfeed_push(_kname, _vname, weapon_name(_wid), _kid, _vid);
		return;
	}

	if (_msg == NET_MSG_FRAG_BOOM) {
		var _bx = buffer_read(_buffer, buffer_f32);
		var _by = buffer_read(_buffer, buffer_f32);
		grenade_spawn_explosion_fx(_bx, _by);
		return;
	}

	if (_msg == NET_MSG_KICK) {
		global.menu_message = "You were kicked from the lobby";
		global.net_mode = "offline";
		net_shutdown();
		room_goto(room_main_menu);
		return;
	}

	if (_msg == NET_MSG_HOST_LEFT) {
		global.menu_message = "Host left the match";
		global.net_mode = "offline";
		net_shutdown();
		room_goto(room_main_menu);
		return;
	}

	if (_msg == NET_MSG_REJECT) {
		// Stay in LAN browser so the player can pick another lobby.
		with (obj_net) {
			joining = false;
			host_ip = "";
			host_port = NET_PORT_MIN;
			var _next = [];
			for (var _j = 0; _j < array_length(discovered); _j++) {
				if (discovered[_j].ip != _ip || discovered[_j].port != _port) {
					array_push(_next, discovered[_j]);
				}
			}
			discovered = _next;
			if (array_length(discovered) <= 0) {
				browse_index = 0;
			} else {
				browse_index = clamp(browse_index, 0, array_length(discovered) - 1);
			}
		}
		if (instance_exists(obj_menu)) {
			obj_menu.menu_state = "browse";
			obj_menu.connect_timer = 0;
		} else if (room != room_main_menu) {
			global.net_mode = "offline";
			net_shutdown();
			room_goto(room_main_menu);
		}
		return;
	}

	if (_msg == NET_MSG_MATCH_END) {
		net_client_apply_match_end(_buffer);
		return;
	}

	if (_msg == NET_MSG_RETURN_LOBBY) {
		obj_net.phase = "lobby";
		obj_net.match_frames_left = 0;
		obj_net.results = [];
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
		with (obj_grenade) {
			instance_destroy();
		}
		with (obj_frag_explosion) {
			instance_destroy();
		}
		weapon_pickup_clear_all();
		room_goto(room_lobby);
		return;
	}

	if (_msg == NET_MSG_SNAPSHOT) {
		if (!is_arena_room() || obj_net.phase != "match") {
			return;
		}
		obj_net.host_silent_frames = 0;
		net_client_apply_snapshot(_buffer);
	}
}

/// @function net_client_apply_snapshot(_buffer)
function net_client_apply_snapshot(_buffer) {
	obj_net.match_frames_left = buffer_read(_buffer, buffer_u16) * 60;

	var _player_count = buffer_read(_buffer, buffer_u8);
	var _seen = [];

	for (var _i = 0; _i < _player_count; _i++) {
		var _pid = buffer_read(_buffer, buffer_u8);
		var _x = buffer_read(_buffer, buffer_f32);
		var _y = buffer_read(_buffer, buffer_f32);
		var _aim = buffer_read(_buffer, buffer_f32);
		var _hp = buffer_read(_buffer, buffer_s16);
		var _alive = buffer_read(_buffer, buffer_u8) == 1;
		var _wid = buffer_read(_buffer, buffer_u8);
		var _mag = buffer_read(_buffer, buffer_u8);
		var _reserve = buffer_read(_buffer, buffer_u8);
		var _grenades = buffer_read(_buffer, buffer_u8);
		var _reloading = buffer_read(_buffer, buffer_u8) == 1;
		var _fuel = buffer_read(_buffer, buffer_u8);
		var _kills = buffer_read(_buffer, buffer_u16);
		var _deaths = buffer_read(_buffer, buffer_u16);
		var _name = buffer_read(_buffer, buffer_string);
		var _cos = net_read_cosmetics(_buffer);

		array_push(_seen, _pid);

		var _player = net_find_player(_pid);
		var _is_local = (_pid == obj_net.local_player_id);
		var _spawned = false;
		if (_player == noone) {
			_player = instance_create_layer(_x, _y, "Instances", obj_player);
			player_setup_net(_player, _pid, _is_local, _name, _cos);
			_spawned = true;
		}

		_player.is_local = _is_local;
		_player.display_name = player_name_sanitize(_name);

		var _was_alive = _player.alive;
		var _prev_hp = _player.hp;

		if (!_is_local) {
			cosmetics_apply_ids(_player, _cos[0], _cos[1], _cos[2], _cos[3]);
			// Brief HP bar only after real damage — never on spawn/respawn.
			if (!_spawned && _was_alive && _alive && _hp < _prev_hp) {
				_player.hit_bar_timer = PLAYER_HIT_BAR_TIME;
			}
		}
		if (_spawned || (!_was_alive && _alive)) {
			_player.hit_bar_timer = 0;
		}

		_player.hp = _hp;
		// Authoritative loadout (also corrects client's random starter pick).
		if (_spawned || !_is_local || _player.weapon_id != _wid) {
			weapon_apply(_player, _wid, _mag, _reserve);
		} else {
			_player.mag = _mag;
			_player.reserve = _reserve;
		}
		_player.reloading = _reloading;
		_player.fuel = _fuel;
		_player.grenades = clamp(_grenades, 0, FRAG_MAX_CARRY);
		_player.kills = clamp(_kills, 0, 999);
		_player.deaths = clamp(_deaths, 0, 999);
		_player.alive = _alive;

		if (_is_local) {
			// Keep local aim; reconcile body to auth.
			var _dist = point_distance(_player.x, _player.y, _x, _y);
			if (_spawned || !_alive || !_was_alive || _dist >= NET_SNAP_HARD) {
				_player.x = _x;
				_player.y = _y;
			} else if (_dist > 8) {
				_player.x = lerp(_player.x, _x, 0.35);
				_player.y = lerp(_player.y, _y, 0.35);
			}
		} else {
			_player.net_from_x = _player.x;
			_player.net_from_y = _player.y;
			_player.net_to_x = _x;
			_player.net_to_y = _y;
			_player.net_aim_from = _player.aim_dir;
			_player.net_aim_to = _aim;
			_player.net_interp_dur = 3;
			_player.net_interp_t = 0;

			var _rdist = point_distance(_player.x, _player.y, _x, _y);
			if (_spawned || _rdist >= NET_SNAP_HARD) {
				_player.x = _x;
				_player.y = _y;
				_player.aim_dir = _aim;
				_player.net_from_x = _x;
				_player.net_from_y = _y;
				_player.net_aim_from = _aim;
				_player.net_interp_t = 1;
			}
		}
	}

	with (obj_player) {
		var _keep = false;
		for (var _s = 0; _s < array_length(_seen); _s++) {
			if (net_id == _seen[_s]) {
				_keep = true;
				break;
			}
		}
		if (!_keep) {
			instance_destroy();
		}
	}

	with (obj_bullet) {
		if (is_ghost && !is_predicted) {
			net_seen = false;
		}
	}

	var _bullet_count = buffer_read(_buffer, buffer_u8);
	for (var _b = 0; _b < _bullet_count; _b++) {
		var _bid = buffer_read(_buffer, buffer_u16);
		var _bwid = buffer_read(_buffer, buffer_u8);
		var _bx = buffer_read(_buffer, buffer_f32);
		var _by = buffer_read(_buffer, buffer_f32);
		var _bh = buffer_read(_buffer, buffer_f32);
		var _bv = buffer_read(_buffer, buffer_f32);

		var _bullet = net_find_bullet(_bid);
		if (_bullet == noone) {
			// Prefer promoting a local predicted shot over spawning a second sprite.
			_bullet = net_claim_predicted_bullet(_bx, _by, _bwid);
			if (_bullet == noone) {
				_bullet = instance_create_layer(_bx, _by, "Instances", obj_bullet);
			}
			_bullet.net_id = _bid;
			_bullet.is_ghost = true;
			_bullet.is_predicted = false;
			_bullet.life = -1;
			_bullet.max_range = 0; // host already culls by range
		} else {
			_bullet.x = lerp(_bullet.x, _bx, 0.65);
			_bullet.y = lerp(_bullet.y, _by, 0.65);
		}
		_bullet.weapon_id = _bwid;
		var _bdef = weapon_def(_bwid);
		if (_bdef != undefined) {
			_bullet.sprite_index = _bdef.bullet_sprite;
		}
		_bullet.image_xscale = BULLET_DRAW_SCALE;
		_bullet.image_yscale = BULLET_DRAW_SCALE;
		_bullet.hsp = _bh;
		_bullet.vsp = _bv;
		if (_bh != 0 || _bv != 0) {
			_bullet.image_angle = point_direction(0, 0, _bh, _bv);
		}
		_bullet.net_seen = true;
	}

	with (obj_bullet) {
		if (is_ghost && !is_predicted && !net_seen) {
			instance_destroy();
		}
	}

	with (obj_weapon_pickup) {
		net_seen = false;
	}

	var _pickup_count = 0;
	if (buffer_tell(_buffer) < buffer_get_size(_buffer)) {
		_pickup_count = buffer_read(_buffer, buffer_u8);
	}
	for (var _p = 0; _p < _pickup_count; _p++) {
		var _pid = buffer_read(_buffer, buffer_u16);
		var _pwid = buffer_read(_buffer, buffer_u8);
		var _px = buffer_read(_buffer, buffer_f32);
		var _py = buffer_read(_buffer, buffer_f32);
		var _pmag = buffer_read(_buffer, buffer_u8);
		var _pres = buffer_read(_buffer, buffer_u8);
		var _plife = buffer_read(_buffer, buffer_u16);

		var _pickup = weapon_pickup_find(_pid);
		if (_pickup == noone) {
			_pickup = instance_create_layer(_px, _py, "Instances", obj_weapon_pickup);
			weapon_pickup_setup(_pickup, _pwid, _pmag, _pres, _plife, noone, _pid, true);
		} else {
			weapon_pickup_setup(_pickup, _pwid, _pmag, _pres, _plife, _pickup.spawn_point, _pid, true);
			_pickup.x = _px;
			_pickup.y = _py;
		}
		_pickup.net_seen = true;
	}

	with (obj_weapon_pickup) {
		if (!net_seen) {
			instance_destroy();
		}
	}

	with (obj_grenade) {
		if (is_ghost) {
			net_seen = false;
		}
	}

	var _grenade_count = 0;
	if (buffer_tell(_buffer) < buffer_get_size(_buffer)) {
		_grenade_count = buffer_read(_buffer, buffer_u8);
	}
	for (var _g = 0; _g < _grenade_count; _g++) {
		var _gid = buffer_read(_buffer, buffer_u16);
		var _gx = buffer_read(_buffer, buffer_f32);
		var _gy = buffer_read(_buffer, buffer_f32);
		var _gh = buffer_read(_buffer, buffer_f32);
		var _gv = buffer_read(_buffer, buffer_f32);
		var _gfuse = buffer_read(_buffer, buffer_u16);
		var _gowner = buffer_read(_buffer, buffer_u8);

		var _gren = net_find_grenade(_gid);
		if (_gren == noone) {
			_gren = instance_create_layer(_gx, _gy, "Instances", obj_grenade);
			_gren.net_id = _gid;
			_gren.is_ghost = true;
		} else {
			_gren.x = lerp(_gren.x, _gx, 0.7);
			_gren.y = lerp(_gren.y, _gy, 0.7);
		}
		_gren.hsp = _gh;
		_gren.vsp = _gv;
		_gren.fuse = _gfuse;
		_gren.owner_player_id = _gowner;
		_gren.sprite_index = spr_weapon_frag;
		_gren.image_index = FRAG_IMAGE_PRIMED;
		_gren.image_speed = 0;
		_gren.image_xscale = FRAG_WORLD_SCALE;
		_gren.image_yscale = FRAG_WORLD_SCALE;
		_gren.mask_index = spr_weapon_frag;
		_gren.image_angle = 0; // collision stays axis-aligned
		if (!variable_instance_exists(_gren, "spin")) {
			_gren.spin = 0;
		}
		_gren.net_seen = true;
	}

	with (obj_grenade) {
		if (is_ghost && !net_seen) {
			instance_destroy();
		}
	}
}
