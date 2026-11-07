if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
	menu_index = (menu_index - 1 + menu_count) mod menu_count;
}

if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
	menu_index = (menu_index + 1) mod menu_count;
}

var _clicked = -1;
if (mouse_check_button_pressed(mb_left)) {
	for (var _i = 0; _i < menu_count; _i++) {
		var _bx1 = menu_x;
		var _by1 = menu_y + _i * (button_h + button_gap);
		var _bx2 = _bx1 + button_w;
		var _by2 = _by1 + button_h;
		if (point_in_rectangle(mouse_x, mouse_y, _bx1, _by1, _bx2, _by2)) {
			_clicked = _i;
			break;
		}
	}
}

var _confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
if (_confirm) {
	_clicked = menu_index;
} else if (_clicked >= 0) {
	menu_index = _clicked;
}

if (_clicked < 0) {
	exit;
}

switch (_clicked) {
	case 0:
		global.net_mode = "host";
		global.join_ip = "127.0.0.1";
		room_goto(room_arena_green);
		break;
	case 1:
		global.net_mode = "client";
		global.join_ip = "127.0.0.1";
		room_goto(room_arena_green);
		break;
	case 2:
		game_end();
		break;
}
