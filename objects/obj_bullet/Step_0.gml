x += hsp;
y += vsp;

// Max travel from muzzle — stops map-wide sniping. Host bullets + local prediction only;
// remote ghosts (max_range <= 0) are culled when the host drops them from snapshots.
if (max_range > 0 && point_distance(origin_x, origin_y, x, y) >= max_range) {
	instance_destroy();
	exit;
}

if (is_ghost) {
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

if (instance_number(obj_fight_zone) > 0) {
	if (!fight_zone_contains_point(x, y, 96)) {
		instance_destroy();
	}
} else if (!point_in_rectangle(x, y, -256, -256, room_width + 256, room_height + 256)) {
	instance_destroy();
}
