// Clients mirror via snapshot; only host/offline age the pickup.
var _auth = !instance_exists(obj_net) || obj_net.is_host;
if (!_auth) {
	exit;
}

if (instance_exists(obj_net) && obj_net.phase != "match") {
	instance_destroy();
	exit;
}

life -= 1;
if (life <= 0) {
	instance_destroy();
}
