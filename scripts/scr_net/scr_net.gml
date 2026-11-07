#macro NET_PORT 5394
#macro NET_PORT_MIN 5394
#macro NET_PORT_MAX 5403
#macro NET_MSG_JOIN 1
#macro NET_MSG_WELCOME 2
#macro NET_MSG_INPUT 3
#macro NET_MSG_SNAPSHOT 4

/// @function net_bind_host_socket()
/// @description Tries ports NET_PORT_MIN..NET_PORT_MAX. Returns [socket, port] or [-1, -1].
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

/// @function net_find_player(_player_id)
function net_find_player(_player_id) {
	with (obj_player) {
		if (player_id == _player_id) {
			return id;
		}
	}
	return noone;
}

/// @function player_setup_net(_player, _player_id, _is_local)
function player_setup_net(_player, _player_id, _is_local) {
	_player.player_id = _player_id;
	_player.is_local = _is_local;
	if (_player_id == 1) {
		_player.image_blend = make_color_rgb(80, 200, 255);
	} else {
		_player.image_blend = make_color_rgb(255, 160, 60);
	}
}

/// @function player_gather_input(_player)
function player_gather_input(_player) {
	_player.input_left = keyboard_check(ord("A")) || keyboard_check(vk_left);
	_player.input_right = keyboard_check(ord("D")) || keyboard_check(vk_right);
	_player.input_jet = keyboard_check(vk_space);
	_player.input_shoot = mouse_check_button(mb_left);
	_player.input_reload = keyboard_check_pressed(ord("R"));

	var _cx = _player.x + _player.sprite_width * 0.5;
	var _cy = _player.y + _player.sprite_height * 0.5;
	_player.aim_dir = point_direction(_cx, _cy, mouse_x, mouse_y);
}

/// @function player_spawn_at_point(_player_id, _is_local)
function player_spawn_at_point(_player_id, _is_local) {
	var _spawn = spawn_point_get_random();
	var _x = (_spawn != noone) ? _spawn.x : room_width * 0.5;
	var _y = (_spawn != noone) ? _spawn.y : room_height * 0.5;
	var _player = instance_create_layer(_x, _y, "Instances", obj_player);
	player_setup_net(_player, _player_id, _is_local);
	return _player;
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

/// @function net_host_add_client(_ip, _port)
function net_host_add_client(_ip, _port) {
	var _existing = net_host_find_client(_ip, _port);
	if (_existing >= 0) {
		return obj_net.client_player_ids[_existing];
	}

	var _pid = obj_net.next_player_id;
	obj_net.next_player_id += 1;
	array_push(obj_net.client_ips, _ip);
	array_push(obj_net.client_ports, _port);
	array_push(obj_net.client_player_ids, _pid);

	if (net_find_player(_pid) == noone) {
		player_spawn_at_point(_pid, false);
	}

	obj_net.status_text = "Hosting on port " + string(obj_net.bound_port);
	obj_net.status_detail = "Player " + string(_pid) + " joined (" + string(array_length(obj_net.client_ips)) + " client(s))";
	return _pid;
}

/// @function net_client_send_join()
function net_client_send_join() {
	with (obj_net) {
		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_JOIN);
		var _size = buffer_tell(send_buffer);

		if (joined) {
			network_send_udp(socket, host_ip, host_port, send_buffer, _size);
		} else {
			// Probe the host port range until a WELCOME locks the real port.
			for (var _port = NET_PORT_MIN; _port <= NET_PORT_MAX; _port++) {
				network_send_udp(socket, host_ip, _port, send_buffer, _size);
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
		network_send_udp(socket, _ip, _port, send_buffer, buffer_tell(send_buffer));
	}
}

/// @function net_host_send_snapshots()
function net_host_send_snapshots() {
	with (obj_net) {
		if (array_length(client_ips) <= 0) {
			return;
		}

		buffer_seek(send_buffer, buffer_seek_start, 0);
		buffer_write(send_buffer, buffer_u8, NET_MSG_SNAPSHOT);

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
			buffer_write(other.send_buffer, buffer_u16, kills);
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
			if (!is_ghost) {
				buffer_write(other.send_buffer, buffer_f32, x);
				buffer_write(other.send_buffer, buffer_f32, y);
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
	if (_msg == NET_MSG_JOIN) {
		var _pid = net_host_add_client(_ip, _port);
		net_host_send_welcome(_ip, _port, _pid);
		return;
	}

	if (_msg == NET_MSG_INPUT) {
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

/// @function net_client_handle_message(_msg, _buffer, _ip, _port)
function net_client_handle_message(_msg, _buffer, _ip, _port) {
	if (_msg == NET_MSG_WELCOME) {
		var _pid = buffer_read(_buffer, buffer_u8);
		obj_net.local_player_id = _pid;
		obj_net.joined = true;
		obj_net.host_ip = _ip;
		obj_net.host_port = _port;
		obj_net.status_text = "Joined as player " + string(_pid) + " @ " + string(_ip) + ":" + string(_port);

		if (room != room_arena_green) {
			room_goto(room_arena_green);
		} else if (net_find_player(_pid) == noone) {
			player_spawn_at_point(_pid, true);
		} else {
			player_setup_net(net_find_player(_pid), _pid, true);
		}
		return;
	}

	if (_msg == NET_MSG_SNAPSHOT) {
		if (room != room_arena_green) {
			return;
		}
		net_client_apply_snapshot(_buffer);
	}
}

/// @function net_client_apply_snapshot(_buffer)
function net_client_apply_snapshot(_buffer) {
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
		var _kills = buffer_read(_buffer, buffer_u16);

		array_push(_seen, _pid);

		var _player = net_find_player(_pid);
		if (_player == noone) {
			_player = instance_create_layer(_x, _y, "Instances", obj_player);
			player_setup_net(_player, _pid, _pid == obj_net.local_player_id);
		}

		_player.x = _x;
		_player.y = _y;
		_player.aim_dir = _aim;
		_player.hp = _hp;
		_player.alive = _alive;
		_player.ammo = _ammo;
		_player.reloading = _reloading;
		_player.kills = _kills;
		_player.is_local = (_pid == obj_net.local_player_id);
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
		instance_destroy();
	}

	var _bullet_count = buffer_read(_buffer, buffer_u8);
	for (var _b = 0; _b < _bullet_count; _b++) {
		var _bx = buffer_read(_buffer, buffer_f32);
		var _by = buffer_read(_buffer, buffer_f32);
		var _bullet = instance_create_layer(_bx, _by, "Instances", obj_bullet);
		_bullet.is_ghost = true;
		_bullet.hsp = 0;
		_bullet.vsp = 0;
	}
}
