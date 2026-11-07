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
	if (phase == "lobby") {
		status_text = "Hosting on port " + string(bound_port);
		if (array_length(client_ips) <= 0) {
			status_detail = "Waiting for players...";
		} else {
			status_detail = string(net_lobby_player_count()) + "/" + string(max_players) + " in lobby";
		}

		lobby_sync_cooldown -= 1;
		if (lobby_sync_cooldown <= 0) {
			lobby_sync_cooldown = 30;
			net_host_send_lobby_state();
		}
	} else if (phase == "match") {
		match_frames_left -= 1;
		status_text = "Match " + format_match_time(ceil(match_frames_left / 60));
		status_detail = arena_name_from_index(map_index);

		snapshot_cooldown -= 1;
		if (snapshot_cooldown <= 0) {
			snapshot_cooldown = 2;
			net_host_send_snapshots();
		}

		if (match_frames_left <= 0) {
			net_end_match();
		}
	} else if (phase == "results") {
		status_text = "Match over";
		status_detail = "Enter: lobby for all   Esc: menu";
		if (keyboard_check_pressed(vk_enter)) {
			net_return_to_lobby();
		} else if (keyboard_check_pressed(vk_escape)) {
			global.net_mode = "offline";
			global.menu_message = "";
			net_shutdown();
			room_goto(room_main_menu);
		}
	}
} else if (is_client) {
	if (!joined) {
		join_cooldown -= 1;
		if (join_cooldown <= 0) {
			join_cooldown = 20;
			net_client_send_join();
		}
	} else if (phase == "match") {
		net_client_send_input();
	} else if (phase == "results") {
		status_detail = "Waiting for host...  Esc: menu";
		if (keyboard_check_pressed(vk_escape)) {
			global.net_mode = "offline";
			global.menu_message = "";
			net_shutdown();
			room_goto(room_main_menu);
		}
	}
}
