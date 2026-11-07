persistent = true;

is_host = (global.net_mode == "host");
is_client = (global.net_mode == "client");

socket = -1;
local_player_id = 0;
joined = false;
joining = false; // true only after user picks a lobby and taps Join
join_cooldown = 0;
snapshot_cooldown = 0;
lobby_sync_cooldown = 0;
beacon_cooldown = 0;
discover_cooldown = 0;
bound_port = -1;
host_failed = false;

if (!variable_global_exists("join_ip")) {
	join_ip_load();
}
host_ip = "";
host_port = NET_PORT_MIN;

client_ips = [];
client_ports = [];
client_player_ids = [];
client_names = [];
next_player_id = 2;

// LAN browser (client, pre-join)
discovered = [];
browse_index = 0;

phase = "lobby"; // lobby | match | results
if (!variable_global_exists("player_name")) {
	player_name_load();
}
lobby_name = lobby_name_default();
map_index = 0;
match_time_sec = MATCH_TIME_DEFAULT;
max_players = LOBBY_MAX_PLAYERS_DEFAULT;
match_frames_left = 0;
lobby_roster = [];
results = [];

send_buffer = buffer_create(2048, buffer_grow, 1);
status_text = "";
status_detail = "";

results_btn_lobby = [0, 0, 0, 0];
results_btn_menu = [0, 0, 0, 0];
results_btn_menu_only = [0, 0, 0, 0];
match_back_armed = false;
match_back_timer = 0;

if (is_host) {
	var _bind = net_bind_host_socket();
	socket = _bind[0];
	bound_port = _bind[1];
	if (socket < 0) {
		host_failed = true;
		status_text = "Host failed";
		status_detail = "No free UDP port in " + string(NET_PORT_MIN) + "-" + string(NET_PORT_MAX);
	} else {
		local_player_id = 1;
		host_port = bound_port;
		joined = true;
		status_text = "Hosting on port " + string(bound_port);
		status_detail = "Lobby open";
		array_push(lobby_roster, {
			player_id: 1,
			name: global.player_name,
			is_host: true
		});
		beacon_cooldown = 0;
	}
} else if (is_client) {
	// Must bind with network_create_socket_ext to RECEIVE LAN broadcasts (GM docs).
	discover_port = NET_DISCOVER_PORT;
	socket = network_create_socket_ext(network_socket_udp, NET_DISCOVER_PORT);
	if (socket < 0) {
		// Fallback: unbound socket can still get unicast DISCOVER replies.
		socket = network_create_socket(network_socket_udp);
		discover_port = -1;
	}
	if (socket < 0) {
		status_text = "Client socket failed";
		status_detail = "Could not create UDP socket";
	} else {
		status_text = "Searching LAN";
		status_detail = "Looking for lobbies...";
		discover_cooldown = 0;
		join_cooldown = 0;
	}
}
