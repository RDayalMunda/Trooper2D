if (hurt_cooldown > 0) {
	hurt_cooldown -= 1;
}

if (!alive) {
	hsp = 0;
	vsp = 0;
	respawn_timer -= 1;
	if (respawn_timer <= 0) {
		x = spawn_x;
		y = spawn_y;
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

var _left = keyboard_check(ord("A")) || keyboard_check(vk_left);
var _right = keyboard_check(ord("D")) || keyboard_check(vk_right);
hsp = (_right - _left) * move_speed;

vsp = min(vsp + grav, max_fall);

var _jet = keyboard_check(vk_space);
if (_jet && fuel > 0) {
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
	var _want_reload = keyboard_check_pressed(ord("R")) || (ammo <= 0);
	if (_want_reload && ammo < ammo_max) {
		reloading = true;
		reload_timer = reload_time;
	}
}

if (mouse_check_button(mb_left) && !reloading && ammo > 0 && shoot_cooldown <= 0) {
	var _cx = x + sprite_width * 0.5;
	var _cy = y + sprite_height * 0.5;
	var _dir = point_direction(_cx, _cy, mouse_x, mouse_y);
	var _bullet = instance_create_layer(_cx, _cy, layer, obj_bullet);
	_bullet.hsp = lengthdir_x(12, _dir);
	_bullet.vsp = lengthdir_y(12, _dir);
	_bullet.owner = id;
	ammo -= 1;
	shoot_cooldown = shoot_cooldown_max;

	if (ammo <= 0) {
		reloading = true;
		reload_timer = reload_time;
	}
}
