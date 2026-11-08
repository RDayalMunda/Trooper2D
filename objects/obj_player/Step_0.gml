var _net = instance_exists(obj_net);
var _client_match = _net && obj_net.is_client && obj_net.phase == "match";
var _host_match = _net && obj_net.is_host && obj_net.phase == "match";

// Lobby / results: no combat sim.
if (_net && obj_net.phase != "match") {
	exit;
}

// Remote players on clients: interpolate toward latest auth snapshot.
if (_client_match && !is_local) {
	if (net_interp_t < 1) {
		net_interp_t = min(1, net_interp_t + (1 / max(1, net_interp_dur)));
		var _t = net_interp_t;
		x = lerp(net_from_x, net_to_x, _t);
		y = lerp(net_from_y, net_to_y, _t);
		aim_dir = net_aim_from + angle_difference(net_aim_to, net_aim_from) * _t;
	} else {
		x = net_to_x;
		y = net_to_y;
		aim_dir = net_aim_to;
	}
	// Approximate walk anim from snapshot motion.
	var _rdx = abs(net_to_x - net_from_x);
	if (_rdx > 1) {
		walk_phase += TROOPER_WALK_ANIM_SPEED;
		hsp = net_to_x - net_from_x; // for draw moving check
	} else {
		walk_phase = 0;
		hsp = 0;
	}
	exit;
}

if (hurt_cooldown > 0) {
	hurt_cooldown -= 1;
	hp_idle_timer = 0;
} else if (alive && hp < hp_max) {
	hp_idle_timer += 1;
	if (hp_idle_timer >= hp_regen_delay) {
		hp = min(hp_max, hp + hp_regen);
	}
}

if (!alive) {
	hsp = 0;
	vsp = 0;
	move_x = 0;
	move_y = 0;
	input_shoot = false;
	input_reload = false;
	// Only host / offline own respawn timing; clients wait for auth.
	if (!_client_match) {
		respawn_timer -= 1;
		if (respawn_timer <= 0) {
			spawn_point_place_player(id);
			hp = hp_max;
			fuel = fuel_max;
			fuel_idle_timer = 0;
			hp_idle_timer = 0;
			weapon_restore_loadout(id);
			hurt_cooldown = hurt_cooldown_max;
			alive = true;
		}
	}
	exit;
}

if (is_local) {
	player_gather_input(id);
}

// Analog move: stick/keyboard vector drives strafe + proportional jet.
hsp = clamp(move_x, -1, 1) * move_speed;
vsp = min(vsp + grav, max_fall);

// Only upward tilt can jet; require clear up-intent so slight strafe wobble is free.
var _jet_raw = clamp(-move_y, 0, 1);
var _jet = 0;
if (_jet_raw > jet_engage_min) {
	_jet = (_jet_raw - jet_engage_min) / max(0.001, 1 - jet_engage_min);
}
if (_jet > 0.01 && fuel > 0) {
	vsp -= jet_acc * _jet;
	vsp = max(vsp, -max_rise);
	fuel = max(0, fuel - fuel_drain * _jet);
	fuel_idle_timer = 0;
} else {
	fuel_idle_timer += 1;
	if (fuel_idle_timer >= fuel_regen_delay && fuel < fuel_max) {
		fuel = min(fuel_max, fuel + fuel_regen);
	}
}

move_and_collide(hsp, 0, obj_solid);

var _landed = move_and_collide(0, vsp, obj_solid);
if (array_length(_landed) > 0) {
	vsp = 0;
}

// Walk cycle for layered legs
var _walk_mag = max(abs(hsp) / max(0.001, move_speed), abs(move_x));
if (_walk_mag > 0.2) {
	walk_phase += TROOPER_WALK_ANIM_SPEED * clamp(_walk_mag, 0.2, 1.5);
} else {
	walk_phase = 0;
}

// Out of fight zone: host/offline drain HP fast (clients get auth via snapshot).
if (!_client_match && alive && instance_number(obj_fight_zone) > 0) {
	var _pcx = x + sprite_width * 0.5;
	var _pcy = y + sprite_height * 0.5;
	if (!fight_zone_contains_point(_pcx, _pcy) && hurt_cooldown <= 0) {
		hp -= void_out_damage;
		hurt_cooldown = void_out_interval;
		hp_idle_timer = 0;
		if (hp <= 0) {
			hp = 0;
			alive = false;
			deaths += 1;
			respawn_timer = respawn_time;
			hsp = 0;
			vsp = 0;
			reloading = false;
			reload_timer = 0;
			exit;
		}
	}
}

if (shoot_cooldown > 0) {
	shoot_cooldown -= 1;
}

if (reloading) {
	reload_timer -= 1;
	if (reload_timer <= 0) {
		weapon_finish_reload(id);
	}
} else {
	var _want_reload = input_reload || (mag <= 0);
	if (_want_reload) {
		weapon_try_begin_reload(id);
	}
}

if (input_shoot && !reloading && mag > 0 && shoot_cooldown <= 0 && weapon_id != WEAPON_NONE) {
	var _cx = x + sprite_width * 0.5;
	var _cy = y + sprite_height * 0.5;
	var _spd = bullet_speed;
	var _bullet = instance_create_layer(_cx, _cy, layer, obj_bullet);
	_bullet.hsp = lengthdir_x(_spd, aim_dir);
	_bullet.vsp = lengthdir_y(_spd, aim_dir);
	_bullet.damage = bullet_damage;
	_bullet.owner = id;
	_bullet.owner_player_id = net_id;
	_bullet.image_angle = aim_dir;

	var _wdef = weapon_def(weapon_id);
	if (_wdef != undefined) {
		_bullet.sprite_index = _wdef.bullet_sprite;
	}

	if (_client_match) {
		// Local muzzle flash only — host owns damage bullets.
		_bullet.is_ghost = true;
		_bullet.is_predicted = true;
		_bullet.net_id = 0;
		_bullet.net_seen = true;
		_bullet.life = 14;
	} else {
		_bullet.is_ghost = false;
		_bullet.is_predicted = false;
		_bullet.life = -1;
		if (_host_match) {
			_bullet.net_id = obj_net.next_bullet_id;
			obj_net.next_bullet_id += 1;
			if (obj_net.next_bullet_id > 65000) {
				obj_net.next_bullet_id = 1;
			}
		} else {
			_bullet.net_id = 0;
		}
	}

	mag -= 1;
	shoot_cooldown = fire_cooldown_max;

	if (mag <= 0) {
		weapon_try_begin_reload(id);
	}
}

// Pickup prompt (local) + same-gun siphon / swap (host/offline).
if (alive) {
	if (is_local) {
		weapon_update_local_prompt(id);
		if (pickup_prompt_net_id > 0) {
			var _pr = weapon_prompt_button_rect();
			if (ui_pointer_pressed_in(_pr[0], _pr[1], _pr[2], _pr[3], true)) {
				input_shoot = false;
			}
		}
		if (weapon_local_prompt_pressed(id)) {
			if (_client_match) {
				net_client_send_want_pickup(pickup_prompt_net_id);
			} else {
				var _swap = weapon_pickup_find(pickup_prompt_net_id);
				if (_swap == noone) {
					_swap = weapon_pickup_find_near(id);
				}
				weapon_swap_with_pickup(id, _swap);
			}
		}
	}

	if (!_client_match) {
		// Host/offline: auto ammo siphon for same gun (all players).
		var _near = weapon_pickup_find_near(id);
		if (_near != noone && !_near.is_ghost && _near.weapon_id == weapon_id) {
			weapon_siphon_from_pickup(id, _near);
		}
	}
}

// One-shot reload must not stick on remote players.
input_reload = false;
input_want_pickup = false;
