#macro PLAYER_NAME_MAX 16
#macro PLAYER_NAME_DEFAULT "Trooper"
#macro LOBBY_NAME_MAX 24
#macro JOIN_IP_MAX 45
#macro JOIN_IP_DEFAULT_DESKTOP "127.0.0.1"

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

/// @function lobby_name_default()
function lobby_name_default() {
	if (!variable_global_exists("player_name")) {
		player_name_load();
	}
	return global.player_name + "'s lobby";
}

/// @function lobby_name_sanitize(_name)
function lobby_name_sanitize(_name) {
	var _clean = string_replace_all(string(_name), "\n", "");
	_clean = string_replace_all(_clean, "\r", "");
	while (string_length(_clean) > 0 && string_char_at(_clean, 1) == " ") {
		_clean = string_delete(_clean, 1, 1);
	}
	while (string_length(_clean) > 0 && string_char_at(_clean, string_length(_clean)) == " ") {
		_clean = string_delete(_clean, string_length(_clean), 1);
	}
	if (_clean == "") {
		_clean = lobby_name_default();
	}
	if (string_length(_clean) > LOBBY_NAME_MAX) {
		_clean = string_copy(_clean, 1, LOBBY_NAME_MAX);
	}
	return _clean;
}

/// @function join_ip_sanitize(_ip)
function join_ip_sanitize(_ip) {
	var _clean = string_replace_all(string(_ip), " ", "");
	_clean = string_replace_all(_clean, "\n", "");
	_clean = string_replace_all(_clean, "\r", "");
	var _out = "";
	for (var _i = 1; _i <= string_length(_clean); _i++) {
		var _ch = string_char_at(_clean, _i);
		var _ok = (_ch == "." || _ch == ":" || _ch == "-");
		if (!_ok) {
			var _c = ord(_ch);
			_ok = (_c >= ord("0") && _c <= ord("9"))
				|| (_c >= ord("a") && _c <= ord("z"))
				|| (_c >= ord("A") && _c <= ord("Z"));
		}
		if (_ok) {
			_out += _ch;
		}
	}
	if (string_length(_out) > JOIN_IP_MAX) {
		_out = string_copy(_out, 1, JOIN_IP_MAX);
	}
	return _out;
}

/// @function join_ip_load()
function join_ip_load() {
	var _fallback = input_is_mobile_touch() ? "" : JOIN_IP_DEFAULT_DESKTOP;
	var _ip = _fallback;
	if (file_exists("trooper_settings.ini")) {
		ini_open("trooper_settings.ini");
		_ip = ini_read_string("net", "join_ip", _fallback);
		ini_close();
	}
	global.join_ip = join_ip_sanitize(_ip);
	return global.join_ip;
}

/// @function join_ip_save(_ip)
function join_ip_save(_ip) {
	global.join_ip = join_ip_sanitize(_ip);
	ini_open("trooper_settings.ini");
	ini_write_string("net", "join_ip", global.join_ip);
	ini_close();
	return global.join_ip;
}
