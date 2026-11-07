if (!instance_exists(obj_net)) {
	global.menu_message = "";
	room_goto(room_main_menu);
	exit;
}

selected_slot = 0;
lobby_ui = "main"; // main | rename
rename_blink = 0;

if (obj_net.is_host) {
	menu_rows = ["Lobby Name", "Map", "Match Time", "Max Players", "Start Match", "Leave Lobby"];
} else {
	menu_rows = ["Leave Lobby"];
}

var _s = ui_scale();
var _pad = round(16 * _s);
var _mid = room_width * 0.5;
col_left_x1 = _pad;
col_left_x2 = _mid - round(8 * _s);
col_right_x1 = _mid + round(8 * _s);
col_right_x2 = room_width - _pad;

row_x1 = col_left_x1;
row_y = [];
row_h = round(44 * _s);
row_w = col_left_x2 - col_left_x1;
arrow_w = round(48 * _s);
arrow_pad = round(6 * _s);
row_gap = round(8 * _s);

arrow_left = [];
arrow_right = [];
btn_rects = [];
host_failed_btn = [0, 0, 0, 0];
name_box = [0, 0, 0, 0];
btn_save = [0, 0, 0, 0];
btn_cancel = [0, 0, 0, 0];

player_scroll = 0;
player_scroll_max = 0;
list_x1 = col_right_x1;
list_y1 = 0;
list_x2 = col_right_x2;
list_y2 = 0;
list_drag = false;
list_drag_y = 0;
list_drag_scroll = 0;
player_row_h = round(40 * _s);
