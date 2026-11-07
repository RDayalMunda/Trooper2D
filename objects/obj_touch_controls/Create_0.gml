stick_radius = TOUCH_STICK_RADIUS;

left_active = false;
left_device = -1;
left_origin_x = 0;
left_origin_y = 0;
left_knob_x = 0;
left_knob_y = 0;
left_nx = 0;
left_ny = 0;

right_active = false;
right_device = -1;
right_origin_x = 0;
right_origin_y = 0;
right_knob_x = 0;
right_knob_y = 0;
right_nx = 0;
right_ny = 0;
right_mag = 0;
right_dir = 0;
shooting = false;

reload_pressed = false;
reload_down = false;
zoom_pressed = false;
zoom_down = false;

// Rest positions (GUI space)
gui_w = display_get_gui_width();
gui_h = display_get_gui_height();
left_rest_x = 110;
left_rest_y = gui_h - 110;
right_rest_x = gui_w - 110;
right_rest_y = gui_h - 110;

var _zoom = match_hud_zoom_rect();
zoom_x1 = _zoom[0];
zoom_y1 = _zoom[1];
zoom_x2 = _zoom[2];
zoom_y2 = _zoom[3];

reload_w = 110;
reload_h = 44;
reload_x1 = zoom_x1;
reload_y1 = zoom_y2 + 8;
reload_x2 = zoom_x2;
reload_y2 = reload_y1 + reload_h;
