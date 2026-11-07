// Clients do not simulate — host is authoritative.
if (instance_exists(obj_net) && (obj_net.is_client || obj_net.phase != "match")) {
	exit;
}

if (hurt_cooldown > 0) {
	hurt_cooldown -= 1;
}

if (!alive) {
	hsp = 0;
	vsp = 0;
	input_left = false;
	input_right = false;
	input_jet = false;
	input_shoot = false;
	input_reload = false;
	respawn_timer -= 1;
	if (respawn_timer <= 0) {
		spawn_point_place_player(id);
		hp = hp_max;
		fuel = fuel_max;
		ammo = ammo_max;
		reloading = false;
		reload_timer = 0;
		shoot_cooldown = 0;
		hurt_cooldown = hurt_cooldown_max;
		alive = true;
	}
	exit;
}

if (is_local) {
	player_gather_input(id);
}

hsp = (input_right - input_left) * move_speed;
vsp = min(vsp + grav, max_fall);

if (input_jet && fuel > 0) {
	vsp -= jet_acc;
	fuel -= 1;
}

move_and_collide(hsp, 0, obj_solid);

var _landed = move_and_collide(0, vsp, obj_solid);
if (array_length(_landed) > 0) {
	if (vsp > 0) {
		fuel = fuel_max;
	}
	vsp = 0;
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
	_bullet.owner_player_id = player_id;
	_bullet.is_ghost = false;
	ammo -= 1;
	shoot_cooldown = shoot_cooldown_max;

	if (ammo <= 0) {
		reloading = true;
		reload_timer = reload_time;
	}
}

// One-shot reload must not stick on remote players.
input_reload = false;
