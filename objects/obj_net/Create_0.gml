is_host = (global.net_mode == "host");
is_client = (global.net_mode == "client");

socket = -1;
local_player_id = 0;
joined = false;
join_cooldown = 0;
snapshot_cooldown = 0;

host_ip = global.join_ip;
host_port = NET_PORT;

client_ips = [];
client_ports = [];
client_player_ids = [];
next_player_id = 2;

send_buffer = buffer_create(2048, buffer_grow, 1);
status_text = "";

if (is_host) {
	socket = network_create_socket_ext(network_socket_udp, NET_PORT);
	if (socket < 0) {
		status_text = "Host failed to bind port " + string(NET_PORT);
	} else {
		status_text = "Hosting on port " + string(NET_PORT);
		local_player_id = 1;
	}
} else if (is_client) {
	socket = network_create_socket(network_socket_udp);
	if (socket < 0) {
		status_text = "Client socket failed";
	} else {
		status_text = "Joining " + string(host_ip) + ":" + string(host_port);
	}
}
