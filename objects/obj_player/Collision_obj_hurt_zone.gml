if (instance_exists(obj_net) && (obj_net.is_client || obj_net.phase != "match")) {
	exit;
}

// Hazard DoT tick only — does not make the player immune to bullets.
if (!alive || hazard_cooldown > 0) {
	exit;
}

hp -= hurt_zone_damage;
hazard_cooldown = hazard_cooldown_max;
hp_idle_timer = 0;
if (!is_local) {
	hit_bar_timer = PLAYER_HIT_BAR_TIME;
}

if (hp <= 0) {
	hp = 0;
	alive = false;
	deaths += 1;
	respawn_timer = respawn_time;
	hit_bar_timer = 0;
	hsp = 0;
	vsp = 0;
	weapon_drop_on_death(id);
}
