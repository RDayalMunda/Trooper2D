// Ghost / predicted client bullets never deal damage — host owns hits.
if (is_ghost) {
	exit;
}

if (!other.alive) {
	exit;
}

// No friendly fire against the shooter.
if (other.net_id == owner_player_id) {
	exit;
}

// ---------------------------------------------------------------------------
// Per-projectile damage (no victim i-frames for bullets)
// ---------------------------------------------------------------------------
// Each bullet that collides deals its full damage once, then is destroyed.
// We intentionally do NOT check / set hazard_cooldown here:
//   - Rapid fire (UZI) must register every round for the attacker.
//   - Two players shooting the same target must both deal damage.
// Hazard DoT (lava / void) uses hazard_cooldown separately on the player.
// Balance weapon DPS via damage + fire_cooldown + mag — not immunity frames.
// ---------------------------------------------------------------------------
other.hp -= damage;
other.hp_idle_timer = 0; // pause HP regen after any combat hit
other.hit_bar_timer = PLAYER_HIT_BAR_TIME;

if (other.hp <= 0) {
	other.hp = 0;
	other.alive = false;
	other.deaths += 1;
	other.respawn_timer = other.respawn_time;
	other.hit_bar_timer = 0;
	other.hsp = 0;
	other.vsp = 0;
	weapon_drop_on_death(other);

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
