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
	input_left = false;
	input_right = false;
	input_jet = false;
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
			ammo = ammo_max;
			reloading = false;
			reload_timer = 0;
			shoot_cooldown = 0;
			hurt_cooldown = hurt_cooldown_max;
			alive = true;
		}
	}
	exit;
}

if (is_local) {
	player_gather_input(id);
}

hsp = (input_right - input_left) * move_speed;
vsp = min(vsp + grav, max_fall);

// Up / W / Space = jet thrust (no separate jump).
if (input_jet && fuel > 0) {
	vsp -= jet_acc;
	vsp = max(vsp, -max_rise);
	fuel = max(0, fuel - fuel_drain);
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
		ammo = ammo_max;
		reloading = false;
	}
} else {
	var _want_reload = input_reload || (ammo <= 0);
	if (_want_reload && ammo < ammo_max) {
		reloading = true;
		reload_timer = reload_time;
	}
}

if (input_shoot && !reloading && ammo > 0 && shoot_cooldown <= 0) {
	var _cx = x + sprite_width * 0.5;
	var _cy = y + sprite_height * 0.5;
	var _bullet = instance_create_layer(_cx, _cy, layer, obj_bullet);
	_bullet.hsp = lengthdir_x(12, aim_dir);
	_bullet.vsp = lengthdir_y(12, aim_dir);
	_bullet.owner = id;
	_bullet.owner_player_id = net_id;

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

	ammo -= 1;
	shoot_cooldown = shoot_cooldown_max;

	if (ammo <= 0) {
		reloading = true;
		reload_timer = reload_time;
	}
}

// One-shot reload must not stick on remote players.
input_reload = false;
