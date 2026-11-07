if (is_ghost) {
	exit;
}

other.hp -= 1;
if (other.hp <= 0) {
	if (instance_exists(owner)) {
		owner.kills += 1;
	}
	instance_destroy(other);
}
instance_destroy();
