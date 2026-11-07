if (!variable_global_exists("net_mode")) {
	global.net_mode = "host";
}
if (!variable_global_exists("join_ip")) {
	global.join_ip = "127.0.0.1";
}

// Match play only. Lobby creates obj_net before arenas.
if (!instance_exists(obj_net)) {
	if (global.net_mode == "host") {
		instance_create_layer(0, 0, "Instances", obj_net);
		obj_net.phase = "match";
		obj_net.match_frames_left = obj_net.match_time_sec * 60;
	} else {
		room_goto(room_main_menu);
		exit;
	}
}

if (obj_net.host_failed) {
	exit;
}

if (obj_net.phase != "match") {
	exit;
}

if (!instance_exists(obj_touch_controls)) {
	instance_create_layer(0, 0, "Instances", obj_touch_controls);
}

net_spawn_match_players();
