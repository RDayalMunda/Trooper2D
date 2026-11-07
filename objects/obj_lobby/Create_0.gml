if (!instance_exists(obj_net)) {
	global.menu_message = "Network session missing";
	room_goto(room_main_menu);
	exit;
}

selected_slot = 0;

if (obj_net.is_host) {
	menu_rows = ["Map", "Match Time", "Max Players", "Start Match", "Leave Lobby"];
} else {
	menu_rows = ["Leave Lobby"];
}

// Row hitboxes filled each Draw for mouse clicks
row_x1 = 0;
row_y = [];
row_h = 34;
row_w = 420;
