if (!alive) {
	exit;
}

draw_self();

var _cx = x + sprite_width * 0.5;
var _cy = y + sprite_height * 0.5;
var _dir = aim_dir;
if (is_local) {
	_dir = point_direction(_cx, _cy, mouse_x, mouse_y);
	aim_dir = _dir;
}
draw_line(_cx, _cy, _cx + lengthdir_x(24, _dir), _cy + lengthdir_y(24, _dir));

draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_color(c_white);
draw_text(_cx, y - 4, display_name);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
