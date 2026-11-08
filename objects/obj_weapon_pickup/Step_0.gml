// Clients mirror via snapshot; only host/offline simulate fall + lifetime.
var _auth = !instance_exists(obj_net) || obj_net.is_host;
if (!_auth) {
	exit;
}

if (instance_exists(obj_net) && obj_net.phase != "match") {
	instance_destroy();
	exit;
}

if (!grounded) {
	vsp = min(vsp + WEAPON_PICKUP_GRAV, WEAPON_PICKUP_MAX_FALL);
	var _hit = move_and_collide(0, vsp, obj_solid);
	if (array_length(_hit) > 0) {
		vsp = 0;
		grounded = true;
	}
}

life -= 1;
if (life <= 0) {
	instance_destroy();
}
