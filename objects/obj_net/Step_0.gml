if (socket < 0) {
	exit;
}

if (is_host) {
	snapshot_cooldown -= 1;
	if (snapshot_cooldown <= 0) {
		snapshot_cooldown = 2;
		net_host_send_snapshots();
	}
} else if (is_client) {
	if (!joined) {
		join_cooldown -= 1;
		if (join_cooldown <= 0) {
			join_cooldown = 30;
			net_client_send_join();
		}
	} else {
		net_client_send_input();
	}
}
