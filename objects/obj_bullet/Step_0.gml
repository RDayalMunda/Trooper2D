if (is_ghost) {
	x += hsp;
	y += vsp;
	if (is_predicted && life >= 0) {
		life -= 1;
		if (life <= 0) {
			instance_destroy();
			exit;
		}
	}
	if (!point_in_rectangle(x, y, -32, -32, room_width + 32, room_height + 32)) {
		instance_destroy();
	}
	exit;
}

x += hsp;
y += vsp;

if (!point_in_rectangle(x, y, -32, -32, room_width + 32, room_height + 32)) {
	instance_destroy();
}
