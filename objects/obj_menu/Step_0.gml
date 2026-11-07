if (back_quit_timer > 0) {
	back_quit_timer -= 1;
	if (back_quit_timer <= 0) {
		back_quit_armed = false;
	}
}

if (menu_state == "connecting") {
	connect_timer += 1;

	var _cancel = ui_back_pressed();
	var _cb = btn_cancel_connect;
	if (array_length(_cb) >= 4 && ui_pointer_pressed_in(_cb[0], _cb[1], _cb[2], _cb[3], false)) {
		_cancel = true;
	}

	if (_cancel) {
		if (instance_exists(obj_net)) {
			obj_net.joining = false;
			obj_net.host_ip = "";
			obj_net.host_port = NET_PORT_MIN;
		}
		global.menu_message = "";
		menu_state = "browse";
		connect_timer = 0;
		exit;
	}

	if (!instance_exists(obj_net)) {
		global.net_mode = "offline";
		menu_state = "main";
		connect_timer = 0;
		exit;
	}

	if (obj_net.joined) {
		exit;
	}

	if (connect_timer >= connect_timeout) {
		if (instance_exists(obj_net)) {
			obj_net.joining = false;
			obj_net.host_ip = "";
			obj_net.host_port = NET_PORT_MIN;
		}
		global.menu_message = "";
		menu_state = "browse";
		connect_timer = 0;
	}
	exit;
}

if (menu_state == "browse") {
	if (!instance_exists(obj_net) || !obj_net.is_client) {
		menu_state = "main";
		exit;
	}

	var _net = obj_net;
	var _n = array_length(_net.discovered);

	var _left = keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"));
	var _right = keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"));
	var _join = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
	var _cancel_b = ui_back_pressed();

	if (ui_pointer_pressed_in(browse_arrow_l[0], browse_arrow_l[1], browse_arrow_l[2], browse_arrow_l[3], false)) {
		_left = true;
	}
	if (ui_pointer_pressed_in(browse_arrow_r[0], browse_arrow_r[1], browse_arrow_r[2], browse_arrow_r[3], false)) {
		_right = true;
	}
	if (ui_pointer_pressed_in(btn_join[0], btn_join[1], btn_join[2], btn_join[3], false)) {
		_join = true;
	}
	if (ui_pointer_pressed_in(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], false)) {
		_cancel_b = true;
	}
	var _use_ip = ui_pointer_pressed_in(btn_use_ip[0], btn_use_ip[1], btn_use_ip[2], btn_use_ip[3], false);

	if (_n > 0) {
		if (_left) {
			_net.browse_index = (_net.browse_index - 1 + _n) mod _n;
		}
		if (_right) {
			_net.browse_index = (_net.browse_index + 1) mod _n;
		}
	}

	if (_cancel_b) {
		global.net_mode = "offline";
		net_shutdown();
		menu_state = "main";
		exit;
	}

	if (_use_ip) {
		menu_state = "join_ip";
		customize_blink = 0;
		join_ip_load();
		keyboard_string = global.join_ip;
		if (input_is_mobile_touch()) {
			keyboard_virtual_show(kbv_type_numbers, kbv_returnkey_done, kbv_autocapitalize_none, false);
		}
		exit;
	}

	if (_join && _n > 0) {
		var _pick = _net.discovered[_net.browse_index];
		_net.host_ip = _pick.ip;
		_net.host_port = _pick.port;
		_net.joining = true;
		_net.join_cooldown = 0;
		join_ip_save(_pick.ip);
		menu_state = "connecting";
		connect_timer = 0;
		net_client_send_join();
	}
	exit;
}

if (menu_state == "join_ip") {
	customize_blink += 1;
	if (string_length(keyboard_string) > JOIN_IP_MAX) {
		keyboard_string = string_copy(keyboard_string, 1, JOIN_IP_MAX);
	}

	var _go = keyboard_check_pressed(vk_enter);
	var _cancel_j = keyboard_check_pressed(vk_escape);
	if (input_is_mobile_touch() && !keyboard_virtual_status() && keyboard_check_pressed(vk_backspace)) {
		_cancel_j = true;
	}
	if (ui_pointer_pressed_in(btn_connect[0], btn_connect[1], btn_connect[2], btn_connect[3], false)) {
		_go = true;
	}
	if (ui_pointer_pressed_in(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], false)) {
		_cancel_j = true;
	}
	if (ui_pointer_pressed_in(name_box[0], name_box[1], name_box[2], name_box[3], false)) {
		if (input_is_mobile_touch()) {
			keyboard_virtual_show(kbv_type_numbers, kbv_returnkey_done, kbv_autocapitalize_none, false);
		}
	}

	if (_cancel_j) {
		if (input_is_mobile_touch()) {
			keyboard_virtual_hide();
		}
		menu_state = "browse";
		keyboard_string = "";
		exit;
	}

	if (_go) {
		if (input_is_mobile_touch()) {
			keyboard_virtual_hide();
		}
		join_ip_save(keyboard_string);
		if (!instance_exists(obj_net)) {
			global.net_mode = "client";
			instance_create_layer(0, 0, "Instances", obj_net);
		}
		obj_net.host_ip = global.join_ip;
		obj_net.host_port = NET_PORT_MIN;
		obj_net.joining = true;
		obj_net.join_cooldown = 0;
		menu_state = "connecting";
		connect_timer = 0;
		// Try all ports for typed IP.
		with (obj_net) {
			buffer_seek(send_buffer, buffer_seek_start, 0);
			buffer_write(send_buffer, buffer_u8, NET_MSG_JOIN);
			buffer_write(send_buffer, buffer_string, global.player_name);
			var _size = buffer_tell(send_buffer);
			for (var _p = NET_PORT_MIN; _p <= NET_PORT_MAX; _p++) {
				network_send_udp(socket, host_ip, _p, send_buffer, _size);
			}
		}
	}
	exit;
}

if (menu_state == "customize") {
	customize_blink += 1;

	if (string_length(keyboard_string) > PLAYER_NAME_MAX) {
		keyboard_string = string_copy(keyboard_string, 1, PLAYER_NAME_MAX);
	}

	var _save = keyboard_check_pressed(vk_enter);
	var _cancel_c = keyboard_check_pressed(vk_escape);
	if (input_is_mobile_touch() && !keyboard_virtual_status() && keyboard_check_pressed(vk_backspace)) {
		_cancel_c = true;
	}

	if (ui_pointer_pressed_in(btn_save[0], btn_save[1], btn_save[2], btn_save[3], false)) {
		_save = true;
	}
	if (ui_pointer_pressed_in(btn_cancel[0], btn_cancel[1], btn_cancel[2], btn_cancel[3], false)) {
		_cancel_c = true;
	}
	if (ui_pointer_pressed_in(name_box[0], name_box[1], name_box[2], name_box[3], false)) {
		if (input_is_mobile_touch()) {
			keyboard_virtual_show(kbv_type_default, kbv_returnkey_done, kbv_autocapitalize_words, false);
		}
	}

	if (_cancel_c) {
		if (input_is_mobile_touch()) {
			keyboard_virtual_hide();
		}
		menu_state = "main";
		keyboard_string = "";
		exit;
	}

	if (_save) {
		if (input_is_mobile_touch()) {
			keyboard_virtual_hide();
		}
		player_name_save(keyboard_string);
		global.menu_message = "";
		menu_state = "main";
		keyboard_string = "";
	}
	exit;
}

if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
	menu_index = (menu_index - 1 + menu_count) mod menu_count;
}

if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
	menu_index = (menu_index + 1) mod menu_count;
}

var _clicked = -1;
for (var _i = 0; _i < menu_count; _i++) {
	var _bx1 = menu_x;
	var _by1 = menu_y + _i * (button_h + button_gap);
	var _bx2 = _bx1 + button_w;
	var _by2 = _by1 + button_h;
	if (ui_pointer_pressed_in(_bx1, _by1, _bx2, _by2, false)) {
		_clicked = _i;
		break;
	}
}

var _confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
if (_confirm) {
	_clicked = menu_index;
} else if (_clicked >= 0) {
	menu_index = _clicked;
}

if (ui_back_pressed()) {
	if (back_quit_armed) {
		game_end();
		exit;
	}
	back_quit_armed = true;
	back_quit_timer = 120;
	exit;
}

if (_clicked < 0) {
	exit;
}

global.menu_message = "";
back_quit_armed = false;

switch (_clicked) {
	case 0:
		global.net_mode = "host";
		net_shutdown();
		instance_create_layer(0, 0, "Instances", obj_net);
		room_goto(room_lobby);
		break;
	case 1:
		global.net_mode = "client";
		net_shutdown();
		instance_create_layer(0, 0, "Instances", obj_net);
		menu_state = "browse";
		break;
	case 2:
		menu_state = "customize";
		customize_blink = 0;
		keyboard_string = global.player_name;
		if (input_is_mobile_touch()) {
			keyboard_virtual_show(kbv_type_default, kbv_returnkey_done, kbv_autocapitalize_words, false);
		}
		break;
	case 3:
		game_end();
		break;
}
