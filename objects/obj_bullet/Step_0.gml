if (is_ghost) {
	x += hsp;
	y += vsp;
	if (is_predicted && life >= 0) {
		life -= 1;
		if (life <= 0) {
			instance_destroy();
			exit;
		}
	}
	if (instance_number(obj_fight_zone) > 0) {
		// Allow a little travel past the safe zone before culling.
		if (!fight_zone_contains_point(x, y, 96)) {
			instance_destroy();
		}
	} else if (!point_in_rectangle(x, y, -256, -256, room_width + 256, room_height + 256)) {
		instance_destroy();
	}
	exit;
}

x += hsp;
y += vsp;

if (instance_number(obj_fight_zone) > 0) {
	if (!fight_zone_contains_point(x, y, 96)) {
		instance_destroy();
	}
} else if (!point_in_rectangle(x, y, -256, -256, room_width + 256, room_height + 256)) {
	instance_destroy();
}
