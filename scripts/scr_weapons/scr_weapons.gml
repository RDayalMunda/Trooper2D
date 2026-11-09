#macro WEAPON_NONE 0
#macro WEAPON_M9 1
#macro WEAPON_UZI 2
#macro WEAPON_FRAG 3 // ground loot / throwable slot — never replaces the gun

#macro WEAPON_SPAWN_INTERVAL 3600 // 60s between world drops
#macro WEAPON_SPAWN_FIRST_DELAY 180 // first drop ~3s into match
#macro WEAPON_PICKUP_LIFE 1800 // 30s on the ground
#macro WEAPON_WORLD_SCALE 0.08
#macro BULLET_DRAW_SCALE 0.10
#macro WEAPON_PICKUP_RADIUS 56
#macro WEAPON_PICKUP_GRAV 0.45
#macro WEAPON_PICKUP_MAX_FALL 10
#macro NET_WEAPON_PICKUP_MAX 16
#macro NET_GRENADE_MAX 24

// ---------------------------------------------------------------------------
// Frag grenade (separate inventory slot — see player.grenades)
// ---------------------------------------------------------------------------
#macro FRAG_PICKUP_COUNT 3 // nades granted per ground pickup
#macro FRAG_MAX_CARRY 6
#macro FRAG_FUSE_FRAMES 180 // 3 seconds @ 60fps
#macro FRAG_THROW_SPEED 9.5
#macro FRAG_THROW_LOB 2.5 // extra upward kick on throw
#macro FRAG_GRAV 0.42
#macro FRAG_MAX_FALL 11
#macro FRAG_BOUNCE 0.58 // velocity kept after wall/floor hit
#macro FRAG_BOUNCE_MIN 1.6 // below this vertical impact, prefer roll over hop
#macro FRAG_ROLL_FRICTION 0.965 // middle ground: rolls, but slows sooner than ice-smooth
#macro FRAG_SPIN_RATE 3.0 // visual roll only (spin var — NOT image_angle)
#macro FRAG_DAMAGE_CENTER 100
#macro FRAG_DAMAGE_RADIUS 150 // zero damage at/beyond this distance
#macro FRAG_THROW_COOLDOWN 25
// Match ground-gun scale so the nade sits with M9/UZI world size.
#macro FRAG_WORLD_SCALE WEAPON_WORLD_SCALE
#macro FRAG_EXPLOSION_SCALE 0.45
#macro FRAG_IMAGE_IDLE 0 // spr_weapon_frag subimage — safe / ground loot
#macro FRAG_IMAGE_PRIMED 1 // spr_weapon_frag subimage — thrown fuse lit

/// @function weapon_def(_weapon_id)
/// @description Lookup table for equipped guns. Returns undefined for unknown ids.
function weapon_def(_weapon_id) {
	switch (_weapon_id) {
		case WEAPON_M9:
			return {
				id: WEAPON_M9,
				name: "M9",
				sprite: spr_weapon_m9,
				bullet_sprite: spr_weapon_m9_bullet,
				mag_size: 12,
				reserve_max: 36,
				fire_cooldown: 20,
				reload_time: 70,
				bullet_speed: 13,
				damage: 10,
				// Half-angle of random aim cone (±deg). Lower = more stable.
				spread_deg: 2.5,
				// Max travel = this × view width at 1x zoom (see weapon_bullet_max_range).
				// Shorter than UZI — pistol is the close-range option.
				range_mul: 0.65,
				zoom_levels: [1], // pistol: closest only
				// Hand vs nozzle origin (sprite px, art faces right: -x = toward grip).
				hand_ox: -130,
				hand_oy: 40
			};
		case WEAPON_UZI:
			return {
				id: WEAPON_UZI,
				name: "UZI",
				sprite: spr_weapon_uzi,
				bullet_sprite: spr_weapon_uzi_bullet,
				mag_size: 25,
				reserve_max: 75,
				fire_cooldown: 5,
				reload_time: 85,
				bullet_speed: 12,
				damage: 6,
				// Wider cone than M9 — SMG spray / recoil feel.
				spread_deg: 7.5,
				// Same reach the M9 used to have (~1× 1x-zoom screen width).
				range_mul: 1.0,
				zoom_levels: [1, 2], // SMG unlocks 2x
				// Grip sits left + down from nozzle when facing right.
				hand_ox: -110,
				hand_oy: 32
			};
		case WEAPON_FRAG:
			// Not a gun — inventory throwable. Spawned as world loot only.
			return {
				id: WEAPON_FRAG,
				name: "Frag",
				sprite: spr_weapon_frag,
				bullet_sprite: -1,
				mag_size: FRAG_PICKUP_COUNT,
				reserve_max: 0,
				fire_cooldown: 0,
				reload_time: 0,
				bullet_speed: 0,
				damage: FRAG_DAMAGE_CENTER,
				spread_deg: 0,
				range_mul: 0,
				zoom_levels: [1],
				hand_ox: 0,
				hand_oy: 0
			};
	}
	return undefined;
}

/// @function weapon_is_gun(_weapon_id)
function weapon_is_gun(_weapon_id) {
	return (_weapon_id == WEAPON_M9 || _weapon_id == WEAPON_UZI);
}

/// @function weapon_is_frag(_weapon_id)
function weapon_is_frag(_weapon_id) {
	return (_weapon_id == WEAPON_FRAG);
}

/// @function weapon_clamp_id(_weapon_id)
/// @description Guns only — FRAG never becomes weapon_id.
function weapon_clamp_id(_weapon_id) {
	if (weapon_is_gun(_weapon_id)) {
		return _weapon_id;
	}
	return WEAPON_NONE;
}

/// @function weapon_pickup_clamp_id(_weapon_id)
/// @description Ground loot ids (guns + frag packs).
function weapon_pickup_clamp_id(_weapon_id) {
	if (weapon_is_gun(_weapon_id) || weapon_is_frag(_weapon_id)) {
		return _weapon_id;
	}
	return WEAPON_NONE;
}

/// @function weapon_bullet_max_range(_weapon_id)
/// @description Despawn distance in world px (mul × view width at 1x zoom).
function weapon_bullet_max_range(_weapon_id) {
	var _def = weapon_def(_weapon_id);
	var _mul = (_def != undefined && variable_struct_exists(_def, "range_mul")) ? _def.range_mul : 1.0;
	var _size = cam_view_size_for_zoom(1);
	return max(64, _size[0] * _mul);
}

/// @function weapon_bullet_spread_deg(_weapon_id)
/// @description Random aim cone half-angle in degrees (0 = laser accurate).
function weapon_bullet_spread_deg(_weapon_id) {
	var _def = weapon_def(_weapon_id);
	if (_def == undefined || !variable_struct_exists(_def, "spread_deg")) {
		return 0;
	}
	return max(0, _def.spread_deg);
}

/// @function weapon_play_fire_sfx(_weapon_id)
/// @description Per-bullet gunfire: short shot body + quieter trail.
function weapon_play_fire_sfx(_weapon_id) {
	// Slight pitch variance so rapid fire doesn't sound identical.
	var _pitch = random_range(0.96, 1.04);
	if (_weapon_id == WEAPON_M9) {
		audio_play_sound(snd_weapon_m9_bullet_shot, 10, false, 1.0, 0, _pitch);
		// Trail is ambience — keep it quieter so overlaps don't muddy the mix.
		audio_play_sound(snd_weapon_m9_bullet_trail, 5, false, 0.4, 0, _pitch);
	} else if (_weapon_id == WEAPON_UZI) {
		audio_play_sound(snd_weapon_uzi_bullet_shot, 10, false, 1.0, 0, _pitch);
		audio_play_sound(snd_weapon_uzi_bullet_trail, 5, false, 0.35, 0, _pitch);
	}
}

/// @function weapon_starter_ids()
/// @description Guns a player can spawn holding (never FRAG).
function weapon_starter_ids() {
	return [WEAPON_M9, WEAPON_UZI];
}

/// @function weapon_random_starter_id()
function weapon_random_starter_id() {
	var _ids = weapon_starter_ids();
	return _ids[irandom(array_length(_ids) - 1)];
}

/// @function weapon_world_loot_ids()
/// @description Random ground spawn table — guns + frag packs.
function weapon_world_loot_ids() {
	return [WEAPON_M9, WEAPON_UZI, WEAPON_FRAG];
}

/// @function weapon_random_loot_id()
function weapon_random_loot_id() {
	var _ids = weapon_world_loot_ids();
	return _ids[irandom(array_length(_ids) - 1)];
}

/// @function weapon_apply(_player, _weapon_id, _mag, _reserve)
/// @description Equip a weapon and set mag/reserve. Pass undefined mag/reserve for full load.
function weapon_apply(_player, _weapon_id, _mag = undefined, _reserve = undefined) {
	_weapon_id = weapon_clamp_id(_weapon_id);
	var _def = weapon_def(_weapon_id);

	_player.weapon_id = _weapon_id;
	_player.reloading = false;
	_player.reload_timer = 0;
	_player.shoot_cooldown = 0;

	if (_def == undefined) {
		_player.mag = 0;
		_player.reserve = 0;
		_player.mag_size = 0;
		_player.reserve_max = 0;
		_player.fire_cooldown_max = 10;
		_player.reload_time = 75;
		_player.bullet_damage = 10;
		_player.bullet_speed = 12;
		cam_set_zoom_levels(_player, cam_default_zoom_levels());
		return;
	}

	_player.mag_size = _def.mag_size;
	_player.reserve_max = _def.reserve_max;
	_player.fire_cooldown_max = _def.fire_cooldown;
	_player.reload_time = _def.reload_time;
	_player.bullet_damage = _def.damage;
	_player.bullet_speed = _def.bullet_speed;

	if (_mag == undefined) {
		_player.mag = _def.mag_size;
	} else {
		_player.mag = clamp(round(_mag), 0, _def.mag_size);
	}
	if (_reserve == undefined) {
		_player.reserve = _def.reserve_max;
	} else {
		_player.reserve = clamp(round(_reserve), 0, _def.reserve_max);
	}

	cam_set_zoom_levels(_player, _def.zoom_levels);
}

/// @function weapon_give_starter_random(_player)
function weapon_give_starter_random(_player) {
	weapon_apply(_player, weapon_random_starter_id());
}

/// @function weapon_restore_loadout(_player)
/// @description Full mag + full reserve for current gun (respawn / top-off).
function weapon_restore_loadout(_player) {
	var _def = weapon_def(_player.weapon_id);
	if (_def == undefined) {
		weapon_give_starter_random(_player);
		return;
	}
	weapon_apply(_player, _player.weapon_id, _def.mag_size, _def.reserve_max);
}

/// @function weapon_try_begin_reload(_player)
function weapon_try_begin_reload(_player) {
	if (_player.reloading) {
		return false;
	}
	if (_player.mag >= _player.mag_size) {
		return false;
	}
	if (_player.reserve <= 0) {
		return false;
	}
	_player.reloading = true;
	_player.reload_timer = _player.reload_time;
	return true;
}

/// @function weapon_finish_reload(_player)
function weapon_finish_reload(_player) {
	var _need = _player.mag_size - _player.mag;
	if (_need > 0 && _player.reserve > 0) {
		var _take = min(_need, _player.reserve);
		_player.mag += _take;
		_player.reserve -= _take;
	}
	_player.reloading = false;
	_player.reload_timer = 0;
}

/// @function weapon_name(_weapon_id)
function weapon_name(_weapon_id) {
	var _def = weapon_def(_weapon_id);
	if (_def == undefined) {
		return "None";
	}
	return _def.name;
}

/// @function weapon_spawn_point_is_free(_spawn)
function weapon_spawn_point_is_free(_spawn) {
	if (_spawn == noone || !instance_exists(_spawn)) {
		return false;
	}
	with (obj_weapon_pickup) {
		if (spawn_point == _spawn) {
			return false;
		}
	}
	return true;
}

/// @function weapon_spawn_point_get_free_random()
function weapon_spawn_point_get_free_random() {
	var _free = [];
	with (obj_weapon_spawn_point) {
		if (weapon_spawn_point_is_free(id)) {
			array_push(_free, id);
		}
	}
	var _n = array_length(_free);
	if (_n <= 0) {
		return noone;
	}
	return _free[irandom(_n - 1)];
}

/// @function weapon_pickup_find(_net_id)
function weapon_pickup_find(_net_id) {
	with (obj_weapon_pickup) {
		if (net_id == _net_id) {
			return id;
		}
	}
	return noone;
}

/// @function weapon_pickup_clear_all()
function weapon_pickup_clear_all() {
	with (obj_weapon_pickup) {
		instance_destroy();
	}
}

/// @function weapon_pickup_setup(_pickup, _weapon_id, _mag, _reserve, _life, _spawn_point, _net_id, _is_ghost)
function weapon_pickup_setup(_pickup, _weapon_id, _mag = undefined, _reserve = undefined, _life = WEAPON_PICKUP_LIFE, _spawn_point = noone, _net_id = 0, _is_ghost = false) {
	_weapon_id = weapon_pickup_clamp_id(_weapon_id);
	var _def = weapon_def(_weapon_id);
	if (_def == undefined) {
		_weapon_id = weapon_random_loot_id();
		_def = weapon_def(_weapon_id);
	}

	_pickup.weapon_id = _weapon_id;
	if (weapon_is_frag(_weapon_id)) {
		// mag stores how many nades this pack grants on collect.
		_pickup.mag = (_mag == undefined) ? FRAG_PICKUP_COUNT : clamp(round(_mag), 1, FRAG_MAX_CARRY);
		_pickup.reserve = 0;
		_pickup.image_xscale = FRAG_WORLD_SCALE;
		_pickup.image_yscale = FRAG_WORLD_SCALE;
		_pickup.image_index = FRAG_IMAGE_IDLE;
		_pickup.image_speed = 0;
		_pickup.mask_index = spr_weapon_frag;
	} else {
		_pickup.mag = (_mag == undefined) ? _def.mag_size : clamp(round(_mag), 0, _def.mag_size);
		_pickup.reserve = (_reserve == undefined) ? _def.reserve_max : clamp(round(_reserve), 0, _def.reserve_max);
		_pickup.image_xscale = WEAPON_WORLD_SCALE;
		_pickup.image_yscale = WEAPON_WORLD_SCALE;
		_pickup.image_index = 0;
		// Small upright mask so scaled gun art doesn't block half the arena.
		_pickup.mask_index = spr_player;
	}
	_pickup.life = max(0, round(_life));
	_pickup.spawn_point = _spawn_point;
	_pickup.net_id = _net_id;
	_pickup.is_ghost = _is_ghost;
	_pickup.net_seen = true;
	_pickup.sprite_index = _def.sprite;
	_pickup.visible = true;
	if (!variable_instance_exists(_pickup, "grounded")) {
		_pickup.grounded = false;
		_pickup.vsp = 0;
	}
}

/// @function weapon_pickup_spawn_at(_spawn, _weapon_id)
/// @description Host/offline: create a timed ground loot drop at a spawn point.
function weapon_pickup_spawn_at(_spawn, _weapon_id = undefined) {
	if (_spawn == noone || !instance_exists(_spawn)) {
		return noone;
	}
	if (!weapon_spawn_point_is_free(_spawn)) {
		return noone;
	}
	if (_weapon_id == undefined) {
		_weapon_id = weapon_random_loot_id();
	}

	var _pickup = instance_create_layer(_spawn.x, _spawn.y, _spawn.layer, obj_weapon_pickup);
	weapon_pickup_setup(_pickup, _weapon_id, undefined, undefined, WEAPON_PICKUP_LIFE, _spawn, weapon_pickup_alloc_net_id(), false);
	return _pickup;
}

/// @function weapon_world_tick()
/// @description Legacy hook — each obj_weapon_spawn_point now ticks itself.
function weapon_world_tick() {
	// no-op
}

/// @function weapon_pickup_alloc_net_id()
function weapon_pickup_alloc_net_id() {
	if (!instance_exists(obj_net)) {
		return 1;
	}
	var _id = obj_net.next_weapon_pickup_id;
	obj_net.next_weapon_pickup_id += 1;
	if (obj_net.next_weapon_pickup_id > 65000) {
		obj_net.next_weapon_pickup_id = 1;
	}
	return _id;
}

/// @function weapon_pickup_drop(_x, _y, _weapon_id, _mag, _reserve)
/// @description Host/offline: throw current gun on the ground (no spawn-point claim).
function weapon_pickup_drop(_x, _y, _weapon_id, _mag, _reserve) {
	_weapon_id = weapon_clamp_id(_weapon_id);
	if (_weapon_id == WEAPON_NONE) {
		return noone;
	}
	var _pickup = instance_create_layer(_x, _y, "Instances", obj_weapon_pickup);
	weapon_pickup_setup(_pickup, _weapon_id, _mag, _reserve, WEAPON_PICKUP_LIFE, noone, weapon_pickup_alloc_net_id(), false);
	return _pickup;
}

/// @function weapon_drop_on_death(_player)
/// @description Host/offline: leave the held gun on the ground for others to pick up.
function weapon_drop_on_death(_player) {
	if (!instance_exists(_player)) {
		return noone;
	}
	if (instance_exists(obj_net) && obj_net.is_client) {
		return noone;
	}
	var _wid = _player.weapon_id;
	if (_wid == WEAPON_NONE) {
		return noone;
	}

	var _c = weapon_player_center(_player);
	var _pickup = weapon_pickup_drop(_c[0], _c[1], _wid, _player.mag, _player.reserve);
	weapon_apply(_player, WEAPON_NONE);
	_player.reloading = false;
	_player.reload_timer = 0;
	return _pickup;
}

/// @function weapon_player_center(_player)
function weapon_player_center(_player) {
	return [
		_player.x + _player.sprite_width * 0.5,
		_player.y + _player.sprite_height * 0.5
	];
}

/// @function weapon_pickup_in_range(_player, _pickup, _radius)
function weapon_pickup_in_range(_player, _pickup, _radius = WEAPON_PICKUP_RADIUS) {
	if (_pickup == noone || !instance_exists(_pickup)) {
		return false;
	}
	var _c = weapon_player_center(_player);
	return point_distance(_c[0], _c[1], _pickup.x, _pickup.y) <= _radius;
}

/// @function weapon_pickup_find_near(_player, _radius)
function weapon_pickup_find_near(_player, _radius = WEAPON_PICKUP_RADIUS) {
	var _c = weapon_player_center(_player);
	var _best = noone;
	var _best_d = _radius;
	with (obj_weapon_pickup) {
		var _d = point_distance(_c[0], _c[1], x, y);
		if (_d <= _best_d) {
			_best_d = _d;
			_best = id;
		}
	}
	return _best;
}

/// @function grenade_try_collect_pickup(_player, _pickup)
/// @description Frag packs fill the grenade slot (not the gun). Default pack = +3.
function grenade_try_collect_pickup(_player, _pickup) {
	if (_pickup == noone || !instance_exists(_pickup) || _pickup.is_ghost) {
		return false;
	}
	if (!weapon_is_frag(_pickup.weapon_id)) {
		return false;
	}
	if (!weapon_pickup_in_range(_player, _pickup)) {
		return false;
	}
	if (_player.grenades >= FRAG_MAX_CARRY) {
		return false;
	}

	var _add = max(1, _pickup.mag);
	_player.grenades = min(FRAG_MAX_CARRY, _player.grenades + _add);
	instance_destroy(_pickup);
	return true;
}

/// @function grenade_alloc_net_id()
function grenade_alloc_net_id() {
	if (!instance_exists(obj_net)) {
		return 1;
	}
	var _id = obj_net.next_grenade_id;
	obj_net.next_grenade_id += 1;
	if (obj_net.next_grenade_id > 65000) {
		obj_net.next_grenade_id = 1;
	}
	return _id;
}

/// @function grenade_throw(_player)
/// @description Host/offline: spend one nade, spawn primed throwable along aim.
function grenade_throw(_player) {
	if (!instance_exists(_player) || !_player.alive) {
		return noone;
	}
	if (instance_exists(obj_net) && obj_net.is_client) {
		return noone; // host owns thrown grenades
	}
	if (_player.grenades <= 0 || _player.nade_cooldown > 0) {
		return noone;
	}

	_player.grenades -= 1;
	_player.nade_cooldown = FRAG_THROW_COOLDOWN;

	var _c = weapon_player_center(_player);
	var _dir = _player.aim_dir;
	var _g = instance_create_layer(_c[0], _c[1], "Instances", obj_grenade);
	_g.hsp = lengthdir_x(FRAG_THROW_SPEED, _dir);
	_g.vsp = lengthdir_y(FRAG_THROW_SPEED, _dir) - FRAG_THROW_LOB;
	_g.owner = _player;
	_g.owner_player_id = _player.net_id;
	_g.fuse = FRAG_FUSE_FRAMES;
	_g.is_ghost = false;
	_g.net_id = (instance_exists(obj_net) && obj_net.is_host) ? grenade_alloc_net_id() : 0;
	_g.sprite_index = spr_weapon_frag;
	_g.image_index = FRAG_IMAGE_PRIMED;
	_g.image_speed = 0;
	_g.image_xscale = FRAG_WORLD_SCALE;
	_g.image_yscale = FRAG_WORLD_SCALE;
	_g.image_angle = 0;
	_g.spin = 0;
	return _g;
}

/// @function grenade_has_los(_x1, _y1, _x2, _y2)
/// @description True if no obj_solid blocks the blast ray between two points.
function grenade_has_los(_x1, _y1, _x2, _y2) {
	// collision_line returns the first solid instance hit, or noone if clear.
	return (collision_line(_x1, _y1, _x2, _y2, obj_solid, false, true) == noone);
}

/// @function grenade_damage_at(_x, _y, _owner_player_id)
/// @description Radial blast: FRAG_DAMAGE_CENTER at epicenter → 0 at FRAG_DAMAGE_RADIUS.
/// Walls block damage — LoS must be clear (no obj_solid on the ray).
function grenade_damage_at(_x, _y, _owner_player_id) {
	with (obj_player) {
		if (!alive) {
			continue;
		}
		var _pc = weapon_player_center(id);
		var _dist = point_distance(_x, _y, _pc[0], _pc[1]);
		if (_dist >= FRAG_DAMAGE_RADIUS) {
			continue;
		}
		// Cover: solid between nade and player → no damage (blast can't pass walls).
		if (!grenade_has_los(_x, _y, _pc[0], _pc[1])) {
			continue;
		}
		var _falloff = 1 - (_dist / FRAG_DAMAGE_RADIUS);
		var _dmg = max(1, round(FRAG_DAMAGE_CENTER * _falloff));
		hp -= _dmg;
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

			var _killer_name = "Unknown";
			var _killer = net_find_player(_owner_player_id);
			if (_killer != noone) {
				if (_killer != id) {
					_killer.kills += 1;
				}
				_killer_name = _killer.display_name;
			}
			net_host_broadcast_kill(_killer_name, display_name, WEAPON_FRAG, _owner_player_id, net_id);
		}
	}
}

/// @function grenade_explode(_grenade)
/// @description Host: apply blast, FX, notify clients, destroy throwable.
function grenade_explode(_grenade) {
	if (!instance_exists(_grenade) || _grenade.is_ghost) {
		return;
	}
	var _x = _grenade.x;
	var _y = _grenade.y;
	var _oid = _grenade.owner_player_id;
	grenade_damage_at(_x, _y, _oid);
	grenade_spawn_explosion_fx(_x, _y);
	net_host_broadcast_frag_boom(_x, _y);
	instance_destroy(_grenade);
}

/// @function grenade_spawn_explosion_fx(_x, _y)
function grenade_spawn_explosion_fx(_x, _y) {
	var _fx = instance_create_layer(_x, _y, "Instances", obj_frag_explosion);
	var _pitch = random_range(0.94, 1.06);
	audio_play_sound(snd_weapon_frag_explosion, 12, false, 1.0, 0, _pitch);
	return _fx;
}

/// @function weapon_siphon_from_pickup(_player, _pickup)
/// @description Same gun: ammo goes to reserve only (never tops off mag); destroy if emptied.
function weapon_siphon_from_pickup(_player, _pickup) {
	if (weapon_is_frag(_pickup.weapon_id)) {
		return false;
	}
	if (_pickup.weapon_id != _player.weapon_id) {
		return false;
	}
	var _pool = _pickup.mag + _pickup.reserve;
	if (_pool <= 0) {
		instance_destroy(_pickup);
		return true;
	}

	var _need_res = max(0, _player.reserve_max - _player.reserve);
	var _take = min(_need_res, _pool);
	_player.reserve += _take;
	_pool -= _take;

	var _def = weapon_def(_pickup.weapon_id);
	var _mag_cap = (_def != undefined) ? _def.mag_size : _pool;
	_pickup.mag = min(_pool, _mag_cap);
	_pickup.reserve = max(0, _pool - _pickup.mag);

	if (_pickup.mag + _pickup.reserve <= 0) {
		instance_destroy(_pickup);
	}
	return true;
}

/// @function weapon_swap_with_pickup(_player, _pickup)
/// @description Different gun: drop current (with ammo), equip ground gun. Frag → collect.
function weapon_swap_with_pickup(_player, _pickup) {
	if (_pickup == noone || !instance_exists(_pickup)) {
		return false;
	}
	if (weapon_is_frag(_pickup.weapon_id)) {
		return grenade_try_collect_pickup(_player, _pickup);
	}
	if (_pickup.weapon_id == WEAPON_NONE || _pickup.weapon_id == _player.weapon_id) {
		return false;
	}
	if (!weapon_pickup_in_range(_player, _pickup)) {
		return false;
	}

	var _c = weapon_player_center(_player);
	var _old_id = _player.weapon_id;
	var _old_mag = _player.mag;
	var _old_res = _player.reserve;
	var _new_id = _pickup.weapon_id;
	var _new_mag = _pickup.mag;
	var _new_res = _pickup.reserve;

	instance_destroy(_pickup);

	if (_old_id != WEAPON_NONE) {
		weapon_pickup_drop(_c[0], _c[1], _old_id, _old_mag, _old_res);
	}
	weapon_apply(_player, _new_id, _new_mag, _new_res);
	_player.pickup_prompt_net_id = 0;
	_player.pickup_prompt_name = "";
	return true;
}

/// @function weapon_prompt_button_rect()
/// @description Centered under the match timer (timer panel bottom ~44*ui_scale).
function weapon_prompt_button_rect() {
	var _gw = display_get_gui_width();
	var _s = ui_scale();
	var _bw = round(260 * _s);
	var _bh = round(48 * _s);
	var _x1 = round((_gw - _bw) * 0.5);
	var _y1 = round(52 * _s); // just below match timer
	return [_x1, _y1, _x1 + _bw, _y1 + _bh];
}

/// @function weapon_update_local_prompt(_player)
function weapon_update_local_prompt(_player) {
	var _p = weapon_pickup_find_near(_player);
	if (_p != noone && weapon_is_frag(_p.weapon_id)) {
		if (_player.grenades < FRAG_MAX_CARRY) {
			_player.pickup_prompt_net_id = _p.net_id;
			_player.pickup_prompt_name = "Frag (+" + string(max(1, _p.mag)) + ")";
		} else {
			_player.pickup_prompt_net_id = 0;
			_player.pickup_prompt_name = "";
		}
	} else if (_p != noone && weapon_is_gun(_p.weapon_id) && _p.weapon_id != _player.weapon_id) {
		_player.pickup_prompt_net_id = _p.net_id;
		_player.pickup_prompt_name = weapon_name(_p.weapon_id);
	} else {
		_player.pickup_prompt_net_id = 0;
		_player.pickup_prompt_name = "";
	}
}

/// @function weapon_local_prompt_pressed(_player)
function weapon_local_prompt_pressed(_player) {
	if (_player.pickup_prompt_net_id <= 0) {
		return false;
	}
	if (keyboard_check_pressed(ord("E"))) {
		return true;
	}
	var _r = weapon_prompt_button_rect();
	return ui_pointer_pressed_in(_r[0], _r[1], _r[2], _r[3], true);
}

/// @function weapon_player_auth_pickups(_player)
/// @description Host/offline: same-gun siphon + requested swap.
function weapon_player_auth_pickups(_player) {
	if (!_player.alive) {
		_player.input_want_pickup = false;
		_player.want_pickup_net_id = 0;
		return;
	}

	// Auto: frag packs + same-gun ammo siphon.
	var _near = weapon_pickup_find_near(_player);
	if (_near != noone && !_near.is_ghost) {
		if (weapon_is_frag(_near.weapon_id)) {
			grenade_try_collect_pickup(_player, _near);
		} else if (_near.weapon_id == _player.weapon_id) {
			weapon_siphon_from_pickup(_player, _near);
		}
	}

	if (_player.input_want_pickup) {
		var _target = noone;
		if (_player.want_pickup_net_id > 0) {
			_target = weapon_pickup_find(_player.want_pickup_net_id);
		}
		if (_target == noone) {
			_target = weapon_pickup_find_near(_player);
		}
		if (_target != noone && !_target.is_ghost) {
			if (weapon_is_frag(_target.weapon_id) || _target.weapon_id != _player.weapon_id) {
				weapon_swap_with_pickup(_player, _target);
			}
		}
	}

	_player.input_want_pickup = false;
	_player.want_pickup_net_id = 0;
}

/// @function match_hud_nade_rect()
/// @description Throw-frag button sits under the reload control.
function match_hud_nade_rect() {
	var _s = ui_scale();
	if (instance_exists(obj_touch_controls)) {
		var _t = obj_touch_controls;
		var _h = round(52 * _s);
		var _y1 = _t.reload_y2 + 8;
		return [_t.reload_x1, _y1, _t.reload_x2, _y1 + _h];
	}
	var _z = match_hud_zoom_rect();
	var _w = round(max(120 * _s, _z[2] - _z[0]));
	var _h = round(52 * _s);
	var _x2 = _z[2];
	var _x1 = _x2 - _w;
	var _y1 = _z[3] + 8 + round(52 * _s) + 8;
	return [_x1, _y1, _x2, _y1 + _h];
}
