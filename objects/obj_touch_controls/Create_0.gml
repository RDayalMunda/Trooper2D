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

// Rest positions (GUI space)
gui_w = display_get_gui_width();
gui_h = display_get_gui_height();
left_rest_x = 110;
left_rest_y = gui_h - 110;
right_rest_x = gui_w - 110;
right_rest_y = gui_h - 110;

reload_w = 110;
reload_h = 44;
reload_x1 = gui_w - 16 - reload_w;
reload_y1 = 64;
reload_x2 = reload_x1 + reload_w;
reload_y2 = reload_y1 + reload_h;
