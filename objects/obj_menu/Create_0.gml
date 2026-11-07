if (!variable_global_exists("net_mode")) {
	global.net_mode = "offline";
}
if (!variable_global_exists("join_ip")) {
	global.join_ip = "127.0.0.1";
}
if (!variable_global_exists("menu_message")) {
	global.menu_message = "";
}

menu_labels = ["Host Game", "Join Game", "Quit"];
menu_count = array_length(menu_labels);
menu_index = 0;
menu_state = "main"; // main | connecting
connect_timer = 0;
connect_timeout = 300; // ~5 seconds at 60 fps

button_w = 280;
button_h = 48;
button_gap = 16;
menu_x = (room_width - button_w) * 0.5;
menu_y = room_height * 0.42;

// Leftover net object from a cancelled/failed session.
if (instance_exists(obj_net)) {
	net_shutdown();
}
