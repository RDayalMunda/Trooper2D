if (is_ghost) {
	exit;
}

x += hsp;
y += vsp;

if (!point_in_rectangle(x, y, -32, -32, room_width + 32, room_height + 32)) {
	instance_destroy();
}
