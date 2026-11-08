// Host/offline only — each point runs its own spawn clock.
if (instance_exists(obj_net)) {
	if (!obj_net.is_host || obj_net.phase != "match") {
		exit;
	}
} else {
	exit;
}

if (!weapon_spawn_point_is_free(id)) {
	exit;
}

spawn_timer -= 1;
if (spawn_timer <= 0) {
	weapon_pickup_spawn_at(id);
	spawn_timer = WEAPON_SPAWN_INTERVAL;
}
