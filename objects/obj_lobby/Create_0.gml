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

var _s = ui_scale();
row_x1 = 0;
row_y = [];
row_h = round(52 * _s);
row_w = round(460 * _s);
arrow_w = round(56 * _s);
arrow_pad = 8;

// Per-row arrow hitboxes filled in Draw (host settings only)
arrow_left = [];
arrow_right = [];
btn_rects = []; // action buttons (Start / Leave / Back)

host_failed_btn = [0, 0, 0, 0];
