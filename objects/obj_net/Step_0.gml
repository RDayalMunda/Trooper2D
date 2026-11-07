if (is_host && host_failed) {
	if (ui_back_pressed()) {
		global.net_mode = "offline";
		global.menu_message = "";
		net_shutdown();
		room_goto(room_main_menu);
	}
	exit;
}

if (socket < 0) {
	exit;
}

// Results touch buttons (GUI space) — layout must match Draw GUI
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _s = ui_scale();
var _btn_w = round(280 * _s);
var _btn_h = round(64 * _s);
var _btn_y1 = _gh - round(110 * _s);
var _btn_y2 = _btn_y1 + _btn_h;
results_btn_lobby = [(_gw * 0.5 - _btn_w - 12), _btn_y1, (_gw * 0.5 - 12), _btn_y2];
results_btn_menu = [(_gw * 0.5 + 12), _btn_y1, (_gw * 0.5 + _btn_w + 12), _btn_y2];
results_btn_menu_only = [(_gw - _btn_w) * 0.5, _btn_y1, (_gw + _btn_w) * 0.5, _btn_y2];

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

		// Periodic LAN advertisement (plus DISCOVER replies).
		beacon_cooldown -= 1;
		if (beacon_cooldown <= 0) {
			beacon_cooldown = 45;
			net_host_send_beacon();
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

		if (match_back_timer > 0) {
			match_back_timer -= 1;
			if (match_back_timer <= 0) {
				match_back_armed = false;
			}
		}
		if (ui_back_pressed()) {
			if (match_back_armed) {
				global.net_mode = "offline";
				global.menu_message = "";
				net_host_notify_left();
				room_goto(room_main_menu);
				exit;
			}
			match_back_armed = true;
			match_back_timer = 120;
			status_detail = "Back again to leave match";
		}
	} else if (phase == "results") {
		status_text = "Match over";
		status_detail = "Return to lobby or menu";

		var _to_lobby = keyboard_check_pressed(vk_enter);
		var _to_menu = ui_back_pressed();
		var _rl = results_btn_lobby;
		var _rm = results_btn_menu;
		if (ui_pointer_pressed_in(_rl[0], _rl[1], _rl[2], _rl[3], true)) {
			_to_lobby = true;
		}
		if (ui_pointer_pressed_in(_rm[0], _rm[1], _rm[2], _rm[3], true)) {
			_to_menu = true;
		}

		if (_to_lobby) {
			net_return_to_lobby();
		} else if (_to_menu) {
			global.net_mode = "offline";
			global.menu_message = "";
			net_shutdown();
			room_goto(room_main_menu);
		}
	}
} else if (is_client) {
	if (!joined) {
		// Browse mode: poll for lobbies. Only JOIN after user confirms.
		if (!joining) {
			discover_cooldown -= 1;
			if (discover_cooldown <= 0) {
				discover_cooldown = 20;
				net_client_send_discover();
			}
			net_client_prune_discovered();
		} else {
			join_cooldown -= 1;
			if (join_cooldown <= 0) {
				join_cooldown = 20;
				net_client_send_join();
			}
		}
	} else if (phase == "match") {
		net_client_send_input();

		if (match_back_timer > 0) {
			match_back_timer -= 1;
			if (match_back_timer <= 0) {
				match_back_armed = false;
			}
		}
		if (ui_back_pressed()) {
			if (match_back_armed) {
				global.net_mode = "offline";
				global.menu_message = "";
				net_shutdown();
				room_goto(room_main_menu);
				exit;
			}
			match_back_armed = true;
			match_back_timer = 120;
			status_detail = "Back again to leave match";
		}
	} else if (phase == "results") {
		status_detail = "Waiting for host...";
		var _client_menu = ui_back_pressed();
		var _rmo = results_btn_menu_only;
		if (ui_pointer_pressed_in(_rmo[0], _rmo[1], _rmo[2], _rmo[3], true)) {
			_client_menu = true;
		}
		if (_client_menu) {
			global.net_mode = "offline";
			global.menu_message = "";
			net_shutdown();
			room_goto(room_main_menu);
		}
	}
}
