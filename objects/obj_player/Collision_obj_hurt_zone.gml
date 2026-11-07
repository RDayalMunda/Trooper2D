if (!alive || hurt_cooldown > 0) {
	exit;
}

hp -= hurt_zone_damage;
hurt_cooldown = hurt_cooldown_max;

if (hp <= 0) {
	hp = 0;
	alive = false;
	respawn_timer = respawn_time;
	hsp = 0;
	vsp = 0;
	reloading = false;
	reload_timer = 0;
}
