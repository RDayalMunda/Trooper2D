// End Step: follow after players move this frame.
if (instance_exists(obj_net) && obj_net.phase == "match") {
	var _local = cam_find_local_player();
	if (_local != noone && keyboard_check_pressed(ord("Z"))) {
		cam_cycle_zoom(_local);
	}
	cam_update_follow();
}
