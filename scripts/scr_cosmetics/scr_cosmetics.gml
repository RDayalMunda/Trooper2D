#macro COS_PART_HEAD 0
#macro COS_PART_TORSO 1
#macro COS_PART_LEG 2
#macro COS_PART_HAND 3

/// @function cosmetics_ensure_globals()
function cosmetics_ensure_globals() {
	if (!variable_global_exists("cosmetic_head")) {
		global.cosmetic_head = 0;
	}
	if (!variable_global_exists("cosmetic_torso")) {
		global.cosmetic_torso = 0;
	}
	if (!variable_global_exists("cosmetic_leg")) {
		global.cosmetic_leg = 0;
	}
	if (!variable_global_exists("cosmetic_hand")) {
		global.cosmetic_hand = 0;
	}
}

/// @function cosmetics_part_sprites(_part)
/// @description Sprite list for a part slot.
function cosmetics_part_sprites(_part) {
	switch (_part) {
		case COS_PART_HEAD:
			return [spr_player_head_1, spr_player_head_2];
		case COS_PART_TORSO:
			return [spr_player_torso_1, spr_player_torso_2];
		case COS_PART_LEG:
			return [spr_player_leg_1, spr_player_leg_2];
		case COS_PART_HAND:
			return [spr_player_hand_1_grip, spr_player_hand_2_grip];
	}
	return [];
}

/// @function cosmetics_part_count(_part)
function cosmetics_part_count(_part) {
	var _n = array_length(cosmetics_part_sprites(_part));
	return max(1, _n); // at least one selectable slot
}

/// @function cosmetics_part_label(_part)
function cosmetics_part_label(_part) {
	switch (_part) {
		case COS_PART_HEAD: return "Head";
		case COS_PART_TORSO: return "Torso";
		case COS_PART_LEG: return "Legs";
		case COS_PART_HAND: return "Hands";
	}
	return "Part";
}

/// @function cosmetics_clamp_id(_part, _id)
function cosmetics_clamp_id(_part, _id) {
	var _max = cosmetics_part_count(_part) - 1;
	return clamp(round(_id), 0, _max);
}

/// @function cosmetics_get_sprite(_part, _id)
function cosmetics_get_sprite(_part, _id) {
	var _list = cosmetics_part_sprites(_part);
	if (array_length(_list) <= 0) {
		return -1;
	}
	_id = cosmetics_clamp_id(_part, _id);
	if (_id < 0 || _id >= array_length(_list)) {
		return -1;
	}
	return _list[_id];
}

/// @function cosmetics_load()
function cosmetics_load() {
	cosmetics_ensure_globals();
	var _h = 0;
	var _t = 0;
	var _l = 0;
	var _hand = 0;
	if (file_exists("trooper_settings.ini")) {
		ini_open("trooper_settings.ini");
		_h = ini_read_real("cosmetics", "head", 0);
		_t = ini_read_real("cosmetics", "torso", 0);
		_l = ini_read_real("cosmetics", "leg", 0);
		_hand = ini_read_real("cosmetics", "hand", 0);
		ini_close();
	}
	global.cosmetic_head = cosmetics_clamp_id(COS_PART_HEAD, _h);
	global.cosmetic_torso = cosmetics_clamp_id(COS_PART_TORSO, _t);
	global.cosmetic_leg = cosmetics_clamp_id(COS_PART_LEG, _l);
	global.cosmetic_hand = cosmetics_clamp_id(COS_PART_HAND, _hand);
}

/// @function cosmetics_save(_head, _torso, _leg, _hand)
function cosmetics_save(_head, _torso, _leg, _hand) {
	cosmetics_ensure_globals();
	global.cosmetic_head = cosmetics_clamp_id(COS_PART_HEAD, _head);
	global.cosmetic_torso = cosmetics_clamp_id(COS_PART_TORSO, _torso);
	global.cosmetic_leg = cosmetics_clamp_id(COS_PART_LEG, _leg);
	global.cosmetic_hand = cosmetics_clamp_id(COS_PART_HAND, _hand);
	ini_open("trooper_settings.ini");
	ini_write_real("cosmetics", "head", global.cosmetic_head);
	ini_write_real("cosmetics", "torso", global.cosmetic_torso);
	ini_write_real("cosmetics", "leg", global.cosmetic_leg);
	ini_write_real("cosmetics", "hand", global.cosmetic_hand);
	ini_close();
}

#macro TROOPER_PREVIEW_SCALE 0.20
#macro TROOPER_MATCH_SCALE 0.09
/// Radians of walk cycle per frame at full move_speed.
#macro TROOPER_WALK_CYCLE_RATE 0.35
/// Hip height below torso origin (sprite units * scale). Peek under torso.
#macro TROOPER_LEG_BASE_Y 78
/// Resting half-stance width (sprite units * scale).
#macro TROOPER_LEG_HIP 22
/// Forward/back stride amplitude while moving.
#macro TROOPER_LEG_STRIDE 48
/// Small step lift while moving.
#macro TROOPER_LEG_LIFT 10

/// @function draw_trooper(_x, _y, _head, _torso, _leg, _hand, _aim_dir, _scale, _walk_phase, _moving, _blend, _weapon_sprite)
/// @description Match/preview body. Order: legs → torso → head → gun → hand. Art faces right.
function draw_trooper(_x, _y, _head, _torso, _leg, _hand, _aim_dir = 0, _scale = TROOPER_MATCH_SCALE, _walk_phase = 0, _moving = false, _blend = c_white, _weapon_sprite = -1) {
	var _face_left = (lengthdir_x(1, _aim_dir) < 0);
	var _xscale = _face_left ? -_scale : _scale;
	var _yscale = _scale;
	var _sabs = abs(_scale);
	// Gun/hand: flip via yscale so aim_dir rotation stays correct on both sides.
	var _gun_xs = _sabs;
	var _gun_ys = _face_left ? -_sabs : _sabs;
	var _gun_ang = _aim_dir;

	var _leg_spr = cosmetics_get_sprite(COS_PART_LEG, _leg);
	var _torso_spr = cosmetics_get_sprite(COS_PART_TORSO, _torso);
	var _hand_spr = cosmetics_get_sprite(COS_PART_HAND, _hand);
	var _head_spr = cosmetics_get_sprite(COS_PART_HEAD, _head);

	// Neutral hip pose; stride swings opposite legs and restores when idle (_moving false / phase 0).
	var _hip = TROOPER_LEG_HIP * _sabs;
	var _leg_base_y = _y + (TROOPER_LEG_BASE_Y * _sabs);
	var _stride = 0;
	var _lift_l = 0;
	var _lift_r = 0;
	if (_moving) {
		_stride = sin(_walk_phase) * (TROOPER_LEG_STRIDE * _sabs);
		_lift_l = max(0, sin(_walk_phase)) * (TROOPER_LEG_LIFT * _sabs);
		_lift_r = max(0, sin(_walk_phase + pi)) * (TROOPER_LEG_LIFT * _sabs);
	}
	// World left/right stay screen-left/right; stride flips with facing so the lead leg matches motion.
	var _fwd = _face_left ? -1 : 1;
	var _lx = _x - _hip - (_stride * _fwd);
	var _rx = _x + _hip + (_stride * _fwd);
	var _ly = _leg_base_y - _lift_l;
	var _ry = _leg_base_y - _lift_r;

	if (_leg_spr != -1) {
		draw_sprite_ext(_leg_spr, 0, _lx, _ly, _xscale, _yscale, 0, _blend, 1);
		draw_sprite_ext(_leg_spr, 0, _rx, _ry, _xscale, _yscale, 0, _blend, 1);
	}

	if (_torso_spr != -1) {
		draw_sprite_ext(_torso_spr, 0, _x, _y, _xscale, _yscale, 0, _blend, 1);
	}

	if (_head_spr != -1) {
		draw_sprite_ext(_head_spr, 0, _x, _y, _xscale, _yscale, 0, _blend, 1);
	}

	var _reach = max(14, 95 * abs(_scale));
	var _hx = _x + lengthdir_x(_reach, _aim_dir);
	var _hy = _y + lengthdir_y(_reach, _aim_dir);

	if (_weapon_sprite != -1) {
		draw_sprite_ext(_weapon_sprite, 0, _hx, _hy, _gun_xs, _gun_ys, _gun_ang, _blend, 1);
	}

	// Hand grip on top of gun.
	if (_hand_spr != -1) {
		draw_sprite_ext(_hand_spr, 0, _hx, _hy, _gun_xs, _gun_ys, _gun_ang, _blend, 1);
	}
}

/// @function draw_trooper_preview(_x, _y, _head, _torso, _leg, _hand, _aim_dir, _scale, _walk_frame)
function draw_trooper_preview(_x, _y, _head, _torso, _leg, _hand, _aim_dir = 0, _scale = TROOPER_PREVIEW_SCALE, _walk_frame = 0) {
	var _moving = (_walk_frame > 0);
	var _phase = _walk_frame * TROOPER_WALK_CYCLE_RATE;
	draw_trooper(_x, _y, _head, _torso, _leg, _hand, _aim_dir, _scale, _phase, _moving, c_white);
}

/// @function cosmetics_apply_ids(_player, _head, _torso, _leg, _hand)
function cosmetics_apply_ids(_player, _head, _torso, _leg, _hand) {
	_player.cosmetic_head = cosmetics_clamp_id(COS_PART_HEAD, _head);
	_player.cosmetic_torso = cosmetics_clamp_id(COS_PART_TORSO, _torso);
	_player.cosmetic_leg = cosmetics_clamp_id(COS_PART_LEG, _leg);
	_player.cosmetic_hand = cosmetics_clamp_id(COS_PART_HAND, _hand);
}

/// @function cosmetics_apply_local(_player)
function cosmetics_apply_local(_player) {
	cosmetics_ensure_globals();
	cosmetics_apply_ids(_player, global.cosmetic_head, global.cosmetic_torso, global.cosmetic_leg, global.cosmetic_hand);
}

/// @function cosmetics_local_ids()
/// @description Current saved look as [head, torso, leg, hand].
function cosmetics_local_ids() {
	cosmetics_ensure_globals();
	return [
		global.cosmetic_head,
		global.cosmetic_torso,
		global.cosmetic_leg,
		global.cosmetic_hand
	];
}
