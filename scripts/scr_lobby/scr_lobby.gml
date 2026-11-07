#macro MATCH_TIME_MIN 60
#macro MATCH_TIME_MAX 1800
#macro MATCH_TIME_STEP 30
#macro MATCH_TIME_DEFAULT 180
#macro LOBBY_MAX_PLAYERS_MIN 2
#macro LOBBY_MAX_PLAYERS_MAX 8
#macro LOBBY_MAX_PLAYERS_DEFAULT 4

/// @function arena_room_from_index(_index)
function arena_room_from_index(_index) {
	if (_index == 1) {
		return room_arena_cave;
	}
	return room_arena_green;
}

/// @function arena_name_from_index(_index)
function arena_name_from_index(_index) {
	if (_index == 1) {
		return "Cave";
	}
	return "Green";
}

/// @function arena_index_count()
function arena_index_count() {
	return 2;
}

/// @function is_arena_room(_room = room)
function is_arena_room(_room = room) {
	return (_room == room_arena_green || _room == room_arena_cave);
}

/// @function format_match_time(_seconds)
function format_match_time(_seconds) {
	var _s = max(0, floor(_seconds));
	var _m = _s div 60;
	var _r = _s mod 60;
	var _rs = (_r < 10) ? ("0" + string(_r)) : string(_r);
	return string(_m) + ":" + _rs;
}
