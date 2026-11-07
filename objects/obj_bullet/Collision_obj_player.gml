if (is_ghost) {
	exit;
}

if (!other.alive) {
	exit;
}

if (other.player_id == owner_player_id) {
	exit;
}

if (other.hurt_cooldown > 0) {
	instance_destroy();
	exit;
}

other.hp -= 25;
other.hurt_cooldown = other.hurt_cooldown_max;

if (other.hp <= 0) {
	other.hp = 0;
	other.alive = false;
	other.respawn_timer = other.respawn_time;
	other.hsp = 0;
	other.vsp = 0;
	other.reloading = false;
	other.reload_timer = 0;

	var _owner = net_find_player(owner_player_id);
	if (_owner != noone) {
		_owner.kills += 1;
	} else if (instance_exists(owner)) {
		owner.kills += 1;
	}
}

instance_destroy();
