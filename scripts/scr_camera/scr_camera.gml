#macro CAM_VIEW_INDEX 0
/// World coverage vs a "fit whole room" view. Lower = more zoomed in.
#macro CAM_ZOOM_1_COVERAGE 0.32
/// 2x sits between 1x and a wider pullback.
#macro CAM_ZOOM_2_COVERAGE 0.48
#macro CAM_FOLLOW_LERP 0.22

/// @function cam_default_zoom_levels()
/// @description Fallback before a gun is equipped (closest only).
function cam_default_zoom_levels() {
	return [1];
}

/// @function cam_init_player(_player)
function cam_init_player(_player) {
	_player.zoom_levels = cam_default_zoom_levels();
	_player.zoom_index = 0;
	_player.zoom_level = _player.zoom_levels[0];
}

/// @function cam_set_zoom_levels(_player, _levels)
/// @description Future guns call this, e.g. [1, 2, 4, 6, 8].
function cam_set_zoom_levels(_player, _levels) {
	if (!is_array(_levels) || array_length(_levels) <= 0) {
		_levels = cam_default_zoom_levels();
	}
	// Keep current zoom value if the new gun still supports it; else snap to closest.
	var _want = variable_instance_exists(_player, "zoom_level") ? _player.zoom_level : _levels[0];
	var _idx = 0;
	for (var _i = 0; _i < array_length(_levels); _i++) {
		if (_levels[_i] == _want) {
			_idx = _i;
			break;
		}
	}
	_player.zoom_levels = _levels;
	_player.zoom_index = _idx;
	_player.zoom_level = _levels[_idx];
}

/// @function cam_cycle_zoom(_player)
function cam_cycle_zoom(_player) {
	if (!instance_exists(_player)) {
		return;
	}
	if (!is_array(_player.zoom_levels) || array_length(_player.zoom_levels) <= 0) {
		cam_init_player(_player);
	}
	_player.zoom_index = (_player.zoom_index + 1) mod array_length(_player.zoom_levels);
	_player.zoom_level = _player.zoom_levels[_player.zoom_index];
}

/// @function cam_zoom_label(_player)
function cam_zoom_label(_player) {
	if (!instance_exists(_player) || !variable_instance_exists(_player, "zoom_level")) {
		return "1x";
	}
	return string(_player.zoom_level) + "x";
}

/// @function cam_find_local_player()
function cam_find_local_player() {
	with (obj_player) {
		if (is_local) {
			return id;
		}
	}
	return noone;
}

/// @function cam_ensure()
/// @description Enable view 0 and create a camera if needed.
function cam_ensure() {
	view_enabled = true;
	view_visible[CAM_VIEW_INDEX] = true;

	var _cam = view_camera[CAM_VIEW_INDEX];
	if (_cam == -1) {
		_cam = camera_create_view(0, 0, room_width, room_height, 0, -1, -1, -1, 0, 0);
		view_camera[CAM_VIEW_INDEX] = _cam;
	}
	return _cam;
}

/// @function cam_window_aspect()
function cam_window_aspect() {
	var _w = window_get_width();
	var _h = window_get_height();
	if (_w <= 0 || _h <= 0) {
		_w = display_get_width();
		_h = display_get_height();
	}
	if (_w <= 0 || _h <= 0) {
		return room_width / max(1, room_height);
	}
	return _w / _h;
}

/// @function cam_fit_size()
/// @description Smallest view that can show the whole room at the window aspect.
function cam_fit_size() {
	var _asp = cam_window_aspect();
	var _fit_w;
	var _fit_h;
	if ((room_width / max(1, room_height)) >= _asp) {
		_fit_w = room_width;
		_fit_h = room_width / _asp;
	} else {
		_fit_h = room_height;
		_fit_w = room_height * _asp;
	}
	return [_fit_w, _fit_h];
}

/// @function cam_view_size_for_zoom(_zoom_level)
/// @description Higher zoom_level = wider FOV (more map visible).
function cam_view_size_for_zoom(_zoom_level) {
	var _fit = cam_fit_size();
	var _mul = CAM_ZOOM_1_COVERAGE;
	if (_zoom_level >= 2) {
		_mul = CAM_ZOOM_2_COVERAGE;
	}
	return [_fit[0] * _mul, _fit[1] * _mul];
}

/// @function cam_update_follow()
/// @description Follow local player; size from their zoom_level.
function cam_update_follow() {
	if (!is_arena_room()) {
		return;
	}
	if (instance_exists(obj_net) && obj_net.phase != "match") {
		return;
	}

	var _cam = cam_ensure();
	var _player = cam_find_local_player();
	var _zoom = 1;
	if (_player != noone) {
		if (!variable_instance_exists(_player, "zoom_level")) {
			cam_init_player(_player);
		}
		_zoom = max(1, _player.zoom_level);
	}

	var _size = cam_view_size_for_zoom(_zoom);
	var _vw = _size[0];
	var _vh = _size[1];
	var _old_vw = camera_get_view_width(_cam);
	var _old_vh = camera_get_view_height(_cam);
	var _zoom_changed = (abs(_old_vw - _vw) > 0.5 || abs(_old_vh - _vh) > 0.5);
	camera_set_view_size(_cam, _vw, _vh);

	var _tx = room_width * 0.5;
	var _ty = room_height * 0.5;
	if (_player != noone) {
		_tx = _player.x + _player.sprite_width * 0.5;
		_ty = _player.y + _player.sprite_height * 0.5;
	}

	// Always center on the player — no room-edge clamp (void outside is fine).
	var _desired_x = _tx - _vw * 0.5;
	var _desired_y = _ty - _vh * 0.5;

	var _cur_x = camera_get_view_x(_cam);
	var _cur_y = camera_get_view_y(_cam);
	var _nx;
	var _ny;
	// Zoom change / respawn: snap so the player stays frame-center (no slide).
	if (_zoom_changed || point_distance(_cur_x, _cur_y, _desired_x, _desired_y) > 280) {
		_nx = _desired_x;
		_ny = _desired_y;
	} else {
		_nx = lerp(_cur_x, _desired_x, CAM_FOLLOW_LERP);
		_ny = lerp(_cur_y, _desired_y, CAM_FOLLOW_LERP);
	}
	camera_set_view_pos(_cam, _nx, _ny);
}

/// @function cam_shutdown()
function cam_shutdown() {
	view_visible[CAM_VIEW_INDEX] = false;
	view_enabled = false;
}
