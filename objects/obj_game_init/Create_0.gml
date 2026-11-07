persistent = true;

if (instance_number(obj_game_init) > 1) {
	instance_destroy();
	exit;
}

if (input_is_mobile_touch()) {
	// Keeps the screen from timing out while the game is in the foreground.
	// This is our responsibility — Android will otherwise sleep during play.
	os_powersave_enable(false);
}
