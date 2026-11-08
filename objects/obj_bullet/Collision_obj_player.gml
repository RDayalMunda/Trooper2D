if (is_ghost) {
	exit;
}

if (!other.alive) {
	exit;
}

if (other.net_id == owner_player_id) {
	exit;
}

if (other.hurt_cooldown > 0) {
	instance_destroy();
	exit;
}

other.hp -= damage;
other.hurt_cooldown = other.hurt_cooldown_max;
other.hp_idle_timer = 0;
other.hit_bar_timer = PLAYER_HIT_BAR_TIME;

if (other.hp <= 0) {
	other.hp = 0;
	other.alive = false;
	other.deaths += 1;
	other.respawn_timer = other.respawn_time;
	other.hit_bar_timer = 0;
	other.hsp = 0;
	other.vsp = 0;
	other.reloading = false;
	other.reload_timer = 0;

	var _owner = net_find_player(owner_player_id);
	var _killer_name = "Unknown";
	var _killer_id = owner_player_id;
	if (_owner != noone) {
		_owner.kills += 1;
		_killer_name = _owner.display_name;
	} else if (instance_exists(owner)) {
		owner.kills += 1;
		_killer_name = owner.display_name;
		_killer_id = owner.net_id;
	}

	net_host_broadcast_kill(_killer_name, other.display_name, weapon_id, _killer_id, other.net_id);
}

instance_destroy();
