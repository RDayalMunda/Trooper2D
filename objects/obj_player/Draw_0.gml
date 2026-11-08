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

draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_color(image_blend);
draw_text(_cx, y - 4, display_name);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
