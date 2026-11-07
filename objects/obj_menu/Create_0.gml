if (!variable_global_exists("net_mode")) {
	global.net_mode = "offline";
}
if (!variable_global_exists("join_ip")) {
	global.join_ip = "127.0.0.1";
}
if (!variable_global_exists("menu_message")) {
	global.menu_message = "";
}
global.menu_message = "";

player_name_load();

menu_labels = ["Host Game", "Join Game", "Customize", "Quit"];
menu_count = array_length(menu_labels);
menu_index = 0;
menu_state = "main"; // main | connecting | customize
connect_timer = 0;
connect_timeout = 300; // ~5 seconds at 60 fps
customize_blink = 0;
back_quit_armed = false;
back_quit_timer = 0;

var _s = ui_scale();
button_w = round(340 * _s);
button_h = round(64 * _s);
button_gap = round(20 * _s);
menu_x = (room_width - button_w) * 0.5;
// Higher stack = more bottom margin (avoids accidental Quit from system swipe-up).
menu_y = room_height * 0.28;

name_box = [0, 0, 0, 0];
btn_save = [0, 0, 0, 0];
btn_cancel = [0, 0, 0, 0];
btn_cancel_connect = [0, 0, 0, 0];

if (instance_exists(obj_net)) {
	net_shutdown();
}
