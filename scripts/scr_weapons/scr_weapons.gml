#macro WEAPON_NONE 0
#macro WEAPON_M9 1
#macro WEAPON_UZI 2

#macro WEAPON_SPAWN_INTERVAL 3600 // 60s between world drops
#macro WEAPON_SPAWN_FIRST_DELAY 180 // first drop ~3s into match
#macro WEAPON_PICKUP_LIFE 1800 // 30s on the ground
#macro WEAPON_WORLD_SCALE 0.10
#macro BULLET_DRAW_SCALE 0.12
#macro WEAPON_PICKUP_RADIUS 56
#macro WEAPON_PICKUP_GRAV 0.45
#macro WEAPON_PICKUP_MAX_FALL 10
#macro NET_WEAPON_PICKUP_MAX 16

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
				fire_cooldown: 14,
				reload_time: 70,
				bullet_speed: 13,
				damage: 14,
				zoom_levels: [1] // pistol: closest only
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
				damage: 9,
				zoom_levels: [1, 2] // SMG unlocks 2x
			};
	}
	return undefined;
}

/// @function weapon_clamp_id(_weapon_id)
function weapon_clamp_id(_weapon_id) {
	if (_weapon_id == WEAPON_M9 || _weapon_id == WEAPON_UZI) {
		return _weapon_id;
	}
	return WEAPON_NONE;
}

/// @function weapon_starter_ids()
function weapon_starter_ids() {
	return [WEAPON_M9, WEAPON_UZI];
}

/// @function weapon_random_starter_id()
function weapon_random_starter_id() {
	var _ids = weapon_starter_ids();
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
	_weapon_id = weapon_clamp_id(_weapon_id);
	var _def = weapon_def(_weapon_id);
	if (_def == undefined) {
		_weapon_id = weapon_random_starter_id();
		_def = weapon_def(_weapon_id);
	}

	_pickup.weapon_id = _weapon_id;
	_pickup.mag = (_mag == undefined) ? _def.mag_size : clamp(round(_mag), 0, _def.mag_size);
	_pickup.reserve = (_reserve == undefined) ? _def.reserve_max : clamp(round(_reserve), 0, _def.reserve_max);
	_pickup.life = max(0, round(_life));
	_pickup.spawn_point = _spawn_point;
	_pickup.net_id = _net_id;
	_pickup.is_ghost = _is_ghost;
	_pickup.net_seen = true;
	_pickup.sprite_index = _def.sprite;
	_pickup.image_xscale = WEAPON_WORLD_SCALE;
	_pickup.image_yscale = WEAPON_WORLD_SCALE;
	// Small upright mask so scaled gun art doesn't block half the arena.
	_pickup.mask_index = spr_player;
	_pickup.visible = true;
	if (!variable_instance_exists(_pickup, "grounded")) {
		_pickup.grounded = false;
		_pickup.vsp = 0;
	}
}

/// @function weapon_pickup_spawn_at(_spawn, _weapon_id)
/// @description Host/offline: create a timed ground gun at a spawn point.
function weapon_pickup_spawn_at(_spawn, _weapon_id = undefined) {
	if (_spawn == noone || !instance_exists(_spawn)) {
		return noone;
	}
	if (!weapon_spawn_point_is_free(_spawn)) {
		return noone;
	}
	if (_weapon_id == undefined) {
		_weapon_id = weapon_random_starter_id();
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

/// @function weapon_siphon_from_pickup(_player, _pickup)
/// @description Same gun: pull ammo into mag/reserve; destroy if emptied.
function weapon_siphon_from_pickup(_player, _pickup) {
	if (_pickup.weapon_id != _player.weapon_id) {
		return false;
	}
	var _pool = _pickup.mag + _pickup.reserve;
	if (_pool <= 0) {
		instance_destroy(_pickup);
		return true;
	}

	var _need_mag = max(0, _player.mag_size - _player.mag);
	var _take = min(_need_mag, _pool);
	_player.mag += _take;
	_pool -= _take;

	var _need_res = max(0, _player.reserve_max - _player.reserve);
	_take = min(_need_res, _pool);
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
/// @description Different gun: drop current (with ammo), equip ground gun.
function weapon_swap_with_pickup(_player, _pickup) {
	if (_pickup == noone || !instance_exists(_pickup)) {
		return false;
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
	if (_p != noone && _p.weapon_id != WEAPON_NONE && _p.weapon_id != _player.weapon_id) {
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

	// Same-gun ammo siphon (automatic, no button).
	var _near = weapon_pickup_find_near(_player);
	if (_near != noone && !_near.is_ghost && _near.weapon_id == _player.weapon_id) {
		weapon_siphon_from_pickup(_player, _near);
	}

	if (_player.input_want_pickup) {
		var _target = noone;
		if (_player.want_pickup_net_id > 0) {
			_target = weapon_pickup_find(_player.want_pickup_net_id);
		}
		if (_target == noone) {
			_target = weapon_pickup_find_near(_player);
		}
		if (_target != noone && !_target.is_ghost && _target.weapon_id != _player.weapon_id) {
			weapon_swap_with_pickup(_player, _target);
		}
	}

	_player.input_want_pickup = false;
	_player.want_pickup_net_id = 0;
}
