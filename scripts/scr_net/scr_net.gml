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

#macro NET_REJECT_FULL 1
#macro NET_REJECT_IN_MATCH 2
#macro NET_DISCOVER_STALE_FRAMES 180
#macro NET_NAME_BYTES 16
#macro NET_BULLET_MAX 48
#macro NET_SNAP_HARD 96
#macro NET_MATCH_END_RESENDS 8
#macro NET_MATCH_END_INTERVAL 12

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

/// @function net_find_bullet(_net_id)
function net_find_bullet(_net_id) {
	with (obj_bullet) {
		if (!is_predicted && net_id == _net_id) {
			return id;
		}
	}
	return noone;
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
		if (player_id == _player_id) {
			return id;
		}
	}
	return noone;
}

/// @function player_setup_net(_player, _player_id, _is_local, _display_name)
function player_setup_net(_player, _player_id, _is_local, _display_name = undefined) {
	_player.player_id = _player_id;
	_player.is_local = _is_local;
	if (_display_name != undefined) {
		_player.display_name = player_name_sanitize(_display_name);
	} else if (_is_local) {
		if (!variable_global_exists("player_name")) {
			player_name_load();
		}
		_player.display_name = global.player_name;
	}
	if (_player_id == 1) {
		_player.image_blend = make_color_rgb(80, 200, 255);
	} else {
		_player.image_blend = make_color_rgb(255, 160, 60);
	}
}

/// @function player_gather_input(_player)
function player_gather_input(_player) {
	var _mobile = input_is_mobile_touch();

	_player.input_left = false;
	_player.input_right = false;
	_player.input_jet = false;
	_player.input_shoot = false;
	_player.input_reload = false;

	if (!_mobile) {
		_player.input_left = keyboard_check(ord("A")) || keyboard_check(vk_left);
		_player.input_right = keyboard_check(ord("D")) || keyboard_check(vk_right);
		// Up thrust = jet (W / Up / Space). No separate jump.
		_player.input_jet = keyboard_check(ord("W")) || keyboard_check(vk_up) || keyboard_check(vk_space);
		_player.input_shoot = mouse_check_button(mb_left);
		_player.input_reload = keyboard_check_pressed(ord("R"));

		var _cx = _player.x + _player.sprite_width * 0.5;
		var _cy = _player.y + _player.sprite_height * 0.5;
		_player.aim_dir = point_direction(_cx, _cy, mouse_x, mouse_y);
	}

	// Twin-stick / touch overlay — on mobile, aim ONLY from the right stick.
	if (instance_exists(obj_touch_controls)) {
		var _t = obj_touch_controls;
		if (_t.left_active) {
			_player.input_left = _player.input_left || (_t.left_nx < -TOUCH_STICK_DEADZONE);
			_player.input_right = _player.input_right || (_t.left_nx > TOUCH_STICK_DEADZONE);
			_player.input_jet = _player.input_jet || (_t.left_ny < -TOUCH_STICK_DEADZONE);
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
	}
}

/// @function player_spawn_at_point(_player_id, _is_local, _display_name)
function player_spawn_at_point(_player_id, _is_local, _display_name = undefined) {
	var _spawn = spawn_point_get_random();
	var _x = (_spawn != noone) ? _spawn.x : room_width * 0.5;
	var _y = (_spawn != noone) ? _spawn.y : room_height * 0.5;
	var _player = instance_create_layer(_x, _y, "Instances", obj_player);
	player_setup_net(_player, _player_id, _is_local, _display_name);
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

/// @function net_host_add_client(_ip, _port, _display_name)
function net_host_add_client(_ip, _port, _display_name) {
	var _name = player_name_sanitize(_display_name);
	var _existing = net_host_find_client(_ip, _port);
	if (_existing >= 0) {
		obj_net.client_names[_existing] = _name;
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
	}
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

		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_JOIN);
		buffer_write(send_buffer, buffer_string, global.player_name);
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
		if (_local.input_left) _bits |= 1;
		if (_local.input_right) _bits |= 2;
		if (_local.input_jet) _bits |= 4;
		if (_local.input_shoot) _bits |= 8;
		if (_local.input_reload) _bits |= 16;
		buffer_write(send_buffer, buffer_u8, _bits);
		buffer_write(send_buffer, buffer_f32, _local.aim_dir);

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

		// Host entry
		buffer_write(send_buffer, buffer_u8, 1);
		buffer_write(send_buffer, buffer_string, global.player_name);
		buffer_write(send_buffer, buffer_u8, 1); // is host

		for (var _i = 0; _i < array_length(client_player_ids); _i++) {
			buffer_write(send_buffer, buffer_u8, client_player_ids[_i]);
			buffer_write(send_buffer, buffer_string, client_names[_i]);
			buffer_write(send_buffer, buffer_u8, 0);
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
			player_id: player_id
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

/// @function net_begin_match()
function net_begin_match() {
	with (obj_net) {
		phase = "match";
		match_frames_left = match_time_sec * 60;
		results = [];
		next_bullet_id = 1;
		match_end_resend_left = 0;
		match_end_resend_timer = 0;
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
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
		match_end_resend_left = NET_MATCH_END_RESENDS;
		match_end_resend_timer = NET_MATCH_END_INTERVAL;
		net_host_send_match_end();
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
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
					player_spawn_at_point(_pid, false, client_names[_i]);
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
			buffer_write(other.send_buffer, buffer_u8, player_id);
			buffer_write(other.send_buffer, buffer_f32, x);
			buffer_write(other.send_buffer, buffer_f32, y);
			buffer_write(other.send_buffer, buffer_f32, aim_dir);
			buffer_write(other.send_buffer, buffer_s16, hp);
			buffer_write(other.send_buffer, buffer_u8, alive ? 1 : 0);
			buffer_write(other.send_buffer, buffer_u8, ammo);
			buffer_write(other.send_buffer, buffer_u8, reloading ? 1 : 0);
			buffer_write(other.send_buffer, buffer_u8, clamp(round(fuel), 0, 255));
			buffer_write(other.send_buffer, buffer_u16, kills);
			buffer_write(other.send_buffer, buffer_u16, deaths);
			buffer_write(other.send_buffer, buffer_string, display_name);
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

		var _size = buffer_tell(send_buffer);
		for (var _i = 0; _i < array_length(client_ips); _i++) {
			network_send_udp(socket, client_ips[_i], client_ports[_i], send_buffer, _size);
		}
	}
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
		var _pid = net_host_add_client(_ip, _port, _join_name);
		if (_pid < 0) {
			return;
		}
		net_host_send_welcome(_ip, _port, _pid);
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

		var _pid = buffer_read(_buffer, buffer_u8);
		if (_pid != obj_net.client_player_ids[_index]) {
			return;
		}

		var _player = net_find_player(_pid);
		if (_player == noone) {
			return;
		}

		var _bits = buffer_read(_buffer, buffer_u8);
		_player.input_left = (_bits & 1) != 0;
		_player.input_right = (_bits & 2) != 0;
		_player.input_jet = (_bits & 4) != 0;
		_player.input_shoot = (_bits & 8) != 0;
		_player.input_reload = (_bits & 16) != 0;
		_player.aim_dir = buffer_read(_buffer, buffer_f32);
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
			array_push(lobby_roster, {
				player_id: _id,
				name: _name,
				is_host: _is_host
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
		status_text = "Match over";
		status_detail = "Waiting for host...";
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
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
		with (obj_player) {
			instance_destroy();
		}
		with (obj_bullet) {
			instance_destroy();
		}
		room_goto(arena_room_from_index(obj_net.map_index));
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
		global.menu_message = "Host left the lobby";
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
		room_goto(room_lobby);
		return;
	}

	if (_msg == NET_MSG_SNAPSHOT) {
		if (!is_arena_room() || obj_net.phase != "match") {
			return;
		}
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
		var _ammo = buffer_read(_buffer, buffer_u8);
		var _reloading = buffer_read(_buffer, buffer_u8) == 1;
		var _fuel = buffer_read(_buffer, buffer_u8);
		var _kills = buffer_read(_buffer, buffer_u16);
		var _deaths = buffer_read(_buffer, buffer_u16);
		var _name = buffer_read(_buffer, buffer_string);

		array_push(_seen, _pid);

		var _player = net_find_player(_pid);
		var _is_local = (_pid == obj_net.local_player_id);
		var _spawned = false;
		if (_player == noone) {
			_player = instance_create_layer(_x, _y, "Instances", obj_player);
			player_setup_net(_player, _pid, _is_local, _name);
			_spawned = true;
		}

		_player.is_local = _is_local;
		_player.display_name = player_name_sanitize(_name);
		_player.hp = _hp;
		_player.ammo = _ammo;
		_player.reloading = _reloading;
		_player.fuel = _fuel;
		_player.kills = clamp(_kills, 0, 999);
		_player.deaths = clamp(_deaths, 0, 999);

		var _was_alive = _player.alive;
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
			if (player_id == _seen[_s]) {
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
		var _bx = buffer_read(_buffer, buffer_f32);
		var _by = buffer_read(_buffer, buffer_f32);
		var _bh = buffer_read(_buffer, buffer_f32);
		var _bv = buffer_read(_buffer, buffer_f32);

		var _bullet = net_find_bullet(_bid);
		if (_bullet == noone) {
			_bullet = instance_create_layer(_bx, _by, "Instances", obj_bullet);
			_bullet.net_id = _bid;
			_bullet.is_ghost = true;
			_bullet.is_predicted = false;
			_bullet.life = -1;
		} else {
			_bullet.x = lerp(_bullet.x, _bx, 0.65);
			_bullet.y = lerp(_bullet.y, _by, 0.65);
		}
		_bullet.hsp = _bh;
		_bullet.vsp = _bv;
		_bullet.net_seen = true;
	}

	with (obj_bullet) {
		if (is_ghost && !is_predicted && !net_seen) {
			instance_destroy();
		}
	}
}
