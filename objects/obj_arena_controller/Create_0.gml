if (!variable_global_exists("net_mode")) {
	global.net_mode = "host";
}
if (!variable_global_exists("join_ip")) {
	global.join_ip = "127.0.0.1";
}

if (!instance_exists(obj_net) && (global.net_mode == "host" || global.net_mode == "client")) {
	instance_create_layer(0, 0, "Instances", obj_net);
}

if (global.net_mode == "host" || global.net_mode == "offline") {
	if (net_find_player(1) == noone) {
		player_spawn_at_point(1, true);
	}
}
// Clients wait for WELCOME before spawning their local player.
