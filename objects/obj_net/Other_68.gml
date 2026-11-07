if (socket < 0) {
	exit;
}

var _type = ds_map_find_value(async_load, "type");
if (_type != network_type_data) {
	exit;
}

var _sock = ds_map_find_value(async_load, "id");
if (_sock != socket) {
	exit;
}

var _ip = ds_map_find_value(async_load, "ip");
var _port = ds_map_find_value(async_load, "port");
var _buffer = ds_map_find_value(async_load, "buffer");
var _size = ds_map_find_value(async_load, "size");

if (_size <= 0) {
	exit;
}

buffer_seek(_buffer, buffer_seek_start, 0);
var _msg = buffer_read(_buffer, buffer_u8);

if (is_host) {
	net_host_handle_message(_msg, _buffer, _ip, _port);
} else if (is_client) {
	net_client_handle_message(_msg, _buffer);
}
