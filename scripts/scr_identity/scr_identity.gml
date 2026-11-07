#macro PLAYER_NAME_MAX 16
#macro PLAYER_NAME_DEFAULT "Trooper"

/// @function player_name_sanitize(_name)
function player_name_sanitize(_name) {
	var _clean = string_replace_all(string(_name), "\n", "");
	_clean = string_replace_all(_clean, "\r", "");
	while (string_length(_clean) > 0 && string_char_at(_clean, 1) == " ") {
		_clean = string_delete(_clean, 1, 1);
	}
	while (string_length(_clean) > 0 && string_char_at(_clean, string_length(_clean)) == " ") {
		_clean = string_delete(_clean, string_length(_clean), 1);
	}
	if (_clean == "") {
		_clean = PLAYER_NAME_DEFAULT;
	}
	if (string_length(_clean) > PLAYER_NAME_MAX) {
		_clean = string_copy(_clean, 1, PLAYER_NAME_MAX);
	}
	return _clean;
}

/// @function player_name_load()
function player_name_load() {
	var _name = PLAYER_NAME_DEFAULT;
	if (file_exists("trooper_settings.ini")) {
		ini_open("trooper_settings.ini");
		_name = ini_read_string("player", "name", PLAYER_NAME_DEFAULT);
		ini_close();
	}
	global.player_name = player_name_sanitize(_name);
	return global.player_name;
}

/// @function player_name_save(_name)
function player_name_save(_name) {
	global.player_name = player_name_sanitize(_name);
	ini_open("trooper_settings.ini");
	ini_write_string("player", "name", global.player_name);
	ini_close();
	return global.player_name;
}
