draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_set_color(c_ltgray);
draw_text(display_get_gui_width() - 16, 16, status_text);
if (status_detail != "") {
	draw_text(display_get_gui_width() - 16, 36, status_detail);
}

if (is_host && !host_failed) {
	draw_text(display_get_gui_width() - 16, 56, "Clients: " + string(array_length(client_ips)));
}

if (is_host && host_failed) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.45, status_text);
	draw_set_color(c_orange);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.52, status_detail);
	draw_set_color(c_ltgray);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.60, "Press Esc to return to menu");
	draw_set_halign(fa_right);
	draw_set_valign(fa_top);
}

draw_set_halign(fa_left);
draw_set_color(c_white);
