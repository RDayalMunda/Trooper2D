if (!variable_global_exists("net_mode")) {
	global.net_mode = "host";
}
if (!variable_global_exists("join_ip")) {
	global.join_ip = "127.0.0.1";
}

if (!instance_exists(obj_player)) {
	var _spawn = spawn_point_get_random();
	var _x = (_spawn != noone) ? _spawn.x : room_width * 0.5;
	var _y = (_spawn != noone) ? _spawn.y : room_height * 0.5;
	instance_create_layer(_x, _y, "Instances", obj_player);
}
