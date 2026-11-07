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
		net_shutdown();
		global.net_mode = "offline";
		global.menu_message = "Join cancelled";
		menu_state = "main";
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
		net_shutdown();
		global.net_mode = "offline";
		global.menu_message = "No host found on " + global.join_ip + " (ports " + string(NET_PORT_MIN) + "-" + string(NET_PORT_MAX) + ")";
		menu_state = "main";
		connect_timer = 0;
	}
	exit;
}

if (menu_state == "customize") {
	customize_blink += 1;

	if (string_length(keyboard_string) > PLAYER_NAME_MAX) {
		keyboard_string = string_copy(keyboard_string, 1, PLAYER_NAME_MAX);
	}

	var _save = keyboard_check_pressed(vk_enter);
	// Do not use vk_backspace while typing — it deletes characters.
	var _cancel_c = keyboard_check_pressed(vk_escape);
	if (input_is_mobile_touch() && !keyboard_virtual_status() && keyboard_check_pressed(vk_backspace)) {
		_cancel_c = true;
	}

	var _bs = btn_save;
	var _bc = btn_cancel;
	if (array_length(_bs) >= 4 && ui_pointer_pressed_in(_bs[0], _bs[1], _bs[2], _bs[3], false)) {
		_save = true;
	}
	if (array_length(_bc) >= 4 && ui_pointer_pressed_in(_bc[0], _bc[1], _bc[2], _bc[3], false)) {
		_cancel_c = true;
	}

	// Tap name box again to re-show virtual keyboard
	var _nb = name_box;
	if (array_length(_nb) >= 4 && ui_pointer_pressed_in(_nb[0], _nb[1], _nb[2], _nb[3], false)) {
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
		global.menu_message = "Name set to \"" + global.player_name + "\"";
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

// Android back: arm quit confirmation instead of system "swipe again"
if (ui_back_pressed()) {
	if (back_quit_armed) {
		game_end();
		exit;
	}
	back_quit_armed = true;
	back_quit_timer = 120;
	global.menu_message = "Press back again to quit";
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
		global.join_ip = "127.0.0.1";
		net_shutdown();
		instance_create_layer(0, 0, "Instances", obj_net);
		room_goto(room_lobby);
		break;
	case 1:
		global.net_mode = "client";
		global.join_ip = "127.0.0.1";
		menu_state = "connecting";
		connect_timer = 0;
		net_shutdown();
		instance_create_layer(0, 0, "Instances", obj_net);
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
