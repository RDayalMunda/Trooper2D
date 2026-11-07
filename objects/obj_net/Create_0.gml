persistent = true;

is_host = (global.net_mode == "host");
is_client = (global.net_mode == "client");

socket = -1;
local_player_id = 0;
joined = false;
join_cooldown = 0;
snapshot_cooldown = 0;
bound_port = -1;
host_failed = false;

host_ip = global.join_ip;
host_port = NET_PORT_MIN;

client_ips = [];
client_ports = [];
client_player_ids = [];
next_player_id = 2;

send_buffer = buffer_create(2048, buffer_grow, 1);
status_text = "";
status_detail = "";

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
		status_text = "Hosting on port " + string(bound_port);
		status_detail = "Waiting for players...";
	}
} else if (is_client) {
	socket = network_create_socket(network_socket_udp);
	if (socket < 0) {
		status_text = "Client socket failed";
		status_detail = "Could not create UDP socket";
	} else {
		status_text = "Searching for host";
		status_detail = string(host_ip) + " ports " + string(NET_PORT_MIN) + "-" + string(NET_PORT_MAX);
		join_cooldown = 0;
	}
}
