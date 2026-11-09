if (!alive) {
	exit;
}

var _cx = x + sprite_width * 0.5;
var _cy = y + sprite_height * 0.55;

// Aim from aim_dir; desktop mouse can refresh when right stick is not aiming.
var _dir = aim_dir;
if (is_local && !input_is_mobile_touch()) {
	if (!(instance_exists(obj_touch_controls) && obj_touch_controls.right_active)) {
		_dir = point_direction(_cx, _cy, mouse_x, mouse_y);
		aim_dir = _dir;
	}
}

var _moving = (abs(hsp) > 0.35 || abs(move_x) > 0.25);
var _wdef = weapon_def(weapon_id);
var _wspr = (_wdef != undefined) ? _wdef.sprite : -1;
// White body so Customize colors match in-match (team color is name only).
draw_trooper(
	_cx,
	_cy,
	cosmetic_head,
	cosmetic_torso,
	cosmetic_leg,
	cosmetic_hand,
	aim_dir,
	trooper_scale,
	walk_phase,
	_moving,
	c_white,
	_wspr,
	weapon_id
);

// Local aim dashes — length/dash size are gun properties (M9 short, UZI long).
if (is_local && weapon_is_gun(weapon_id)) {
	var _muzzle = trooper_muzzle_pos(_cx, _cy, aim_dir, trooper_scale);
	weapon_draw_aim_dashes(_muzzle[0], _muzzle[1], aim_dir, weapon_id);
}

// Floating HP for other players briefly after they take damage.
if (!is_local && hit_bar_timer > 0) {
	var _bw = 28;
	var _bh = 4;
	var _bx = _cx - _bw * 0.5;
	var _by = y - 8;
	var _fill = clamp(hp / max(1, hp_max), 0, 1) * _bw;
	draw_set_color(c_dkgray);
	draw_rectangle(_bx, _by, _bx + _bw, _by + _bh, false);
	draw_set_color(c_lime);
	draw_rectangle(_bx, _by, _bx + _fill, _by + _bh, false);
	draw_set_color(c_white);
	draw_rectangle(_bx, _by, _bx + _bw, _by + _bh, true);
}
