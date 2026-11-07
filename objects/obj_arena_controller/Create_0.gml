if (!variable_global_exists("net_mode")) {
	global.net_mode = "host";
}
if (!variable_global_exists("join_ip")) {
	global.join_ip = "127.0.0.1";
}

// Host creates net here. Client already created a persistent obj_net on the menu.
if (!instance_exists(obj_net) && global.net_mode == "host") {
	instance_create_layer(0, 0, "Instances", obj_net);
}

if (global.net_mode == "host" || global.net_mode == "offline") {
	if (instance_exists(obj_net) && obj_net.host_failed) {
		// Stay in arena only to show the failure UI from obj_net.
	} else if (net_find_player(1) == noone) {
		player_spawn_at_point(1, true);
	}
}

if (global.net_mode == "client" && instance_exists(obj_net) && obj_net.joined) {
	if (net_find_player(obj_net.local_player_id) == noone) {
		player_spawn_at_point(obj_net.local_player_id, true);
	}
}
