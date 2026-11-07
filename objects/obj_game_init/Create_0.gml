persistent = true;

if (instance_number(obj_game_init) > 1) {
	instance_destroy();
	exit;
}

if (input_is_mobile_touch()) {
	// Keeps the screen from timing out while the game is in the foreground.
	os_powersave_enable(false);
}

// Android 13+ nearby/Wi-Fi devices (no prompt for INTERNET — that is install-time).
if (os_type == os_android) {
	if (os_check_permission("android.permission.NEARBY_WIFI_DEVICES") != os_permission_granted) {
		os_request_permission("android.permission.NEARBY_WIFI_DEVICES");
	}
}
