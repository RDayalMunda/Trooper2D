if (!variable_global_exists("net_mode")) {
	global.net_mode = "offline";
}
if (!variable_global_exists("join_ip")) {
	global.join_ip = "127.0.0.1";
}

menu_labels = ["Host Game", "Join Game", "Quit"];
menu_count = array_length(menu_labels);
menu_index = 0;

button_w = 280;
button_h = 48;
button_gap = 16;
menu_x = (room_width - button_w) * 0.5;
menu_y = room_height * 0.42;
