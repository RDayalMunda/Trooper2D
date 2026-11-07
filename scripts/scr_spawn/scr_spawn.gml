/// @function fight_zone_contains_point(_x, _y, _margin)
/// @description True if point is inside any fight zone (optional expanded margin).
function fight_zone_contains_point(_x, _y, _margin = 0) {
	with (obj_fight_zone) {
		if (_x >= zone_left - _margin && _x <= zone_right + _margin
			&& _y >= zone_top - _margin && _y <= zone_bottom + _margin) {
			return true;
		}
	}
	return false;
}

/// @function spawn_point_get_random()
/// @description Picks a random arena spawn point instance, or noone if none exist.
function spawn_point_get_random() {
	var _count = instance_number(obj_arena_green_spawn_point);
	if (_count <= 0) {
		return noone;
	}
	return instance_find(obj_arena_green_spawn_point, irandom(_count - 1));
}

/// @function spawn_point_place_player(_player)
/// @param {Id.Instance} _player
/// @description Moves a player to a random spawn point.
function spawn_point_place_player(_player) {
	var _spawn = spawn_point_get_random();
	if (_spawn == noone) {
		return;
	}
	_player.x = _spawn.x;
	_player.y = _spawn.y;
	_player.spawn_x = _spawn.x;
	_player.spawn_y = _spawn.y;
}
