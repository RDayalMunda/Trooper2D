draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_set_color(c_ltgray);
draw_text(display_get_gui_width() - 16, 16, status_text);
if (is_host) {
	draw_text(display_get_gui_width() - 16, 36, "Clients: " + string(array_length(client_ips)));
}
draw_set_halign(fa_left);
draw_set_color(c_white);
