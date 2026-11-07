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

if (mouse_check_button(mb_left) && shoot_cooldown <= 0) {
	var _cx = x + sprite_width * 0.5;
	var _cy = y + sprite_height * 0.5;
	var _dir = point_direction(_cx, _cy, mouse_x, mouse_y);
	var _bullet = instance_create_layer(_cx, _cy, layer, obj_bullet);
	_bullet.hsp = lengthdir_x(12, _dir);
	_bullet.vsp = lengthdir_y(12, _dir);
	shoot_cooldown = shoot_cooldown_max;
}
