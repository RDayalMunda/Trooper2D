if (is_host && host_failed) {
	if (keyboard_check_pressed(vk_escape)) {
		global.net_mode = "offline";
		global.menu_message = status_detail;
		net_shutdown();
		room_goto(room_main_menu);
	}
	exit;
}

if (socket < 0) {
	exit;
}

if (is_host) {
	if (array_length(client_ips) <= 0) {
		status_text = "Hosting on port " + string(bound_port);
		status_detail = "Waiting for players...";
	}

	snapshot_cooldown -= 1;
	if (snapshot_cooldown <= 0) {
		snapshot_cooldown = 2;
		net_host_send_snapshots();
	}
} else if (is_client) {
	if (!joined) {
		join_cooldown -= 1;
		if (join_cooldown <= 0) {
			join_cooldown = 20;
			net_client_send_join();
		}
	} else {
		net_client_send_input();
	}
}
