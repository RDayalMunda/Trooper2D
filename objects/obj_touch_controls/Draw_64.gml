if (!instance_exists(obj_net) || obj_net.phase != "match") {
	exit;
}

// Left stick
draw_touch_stick(left_origin_x, left_origin_y, left_knob_x, left_knob_y, stick_radius, left_active);

// Right stick (fire ring hint)
draw_touch_stick(right_origin_x, right_origin_y, right_knob_x, right_knob_y, stick_radius, right_active);
var _old_a = draw_get_alpha();
draw_set_alpha(0.25);
draw_set_color(c_red);
draw_circle(right_origin_x, right_origin_y, stick_radius * TOUCH_FIRE_THRESHOLD, true);
if (shooting) {
	draw_set_alpha(0.35);
	draw_circle(right_origin_x, right_origin_y, stick_radius * TOUCH_FIRE_THRESHOLD, false);
}
draw_set_alpha(_old_a);

var _local = cam_find_local_player();
var _zoom_label = cam_zoom_label(_local);

// Zoom button (top-right)
draw_ui_panel(zoom_x1, zoom_y1, zoom_x2, zoom_y2, zoom_down ? 0.55 : 0.40);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text((zoom_x1 + zoom_x2) * 0.5, (zoom_y1 + zoom_y2) * 0.5, _zoom_label);

// Reload button
draw_ui_panel(reload_x1, reload_y1, reload_x2, reload_y2, reload_down ? 0.55 : 0.40);
draw_set_color(c_white);
draw_text((reload_x1 + reload_x2) * 0.5, (reload_y1 + reload_y2) * 0.5, "RELOAD");
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
