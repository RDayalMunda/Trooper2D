if (socket >= 0) {
	network_destroy(socket);
	socket = -1;
}
if (variable_instance_exists(id, "send_buffer") && send_buffer >= 0) {
	buffer_delete(send_buffer);
	send_buffer = -1;
}
