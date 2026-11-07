if (!is_local) {
	exit;
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);

var _hud_x = 16;
var _hud_y = 16;

draw_text(_hud_x, _hud_y, display_name);
draw_text(_hud_x, _hud_y + 20, "HP: " + string(hp) + " / " + string(hp_max));

var _bar_x = _hud_x;
var _bar_y = _hud_y + 44;
var _bar_w = 160;
var _bar_h = 12;
draw_set_color(c_dkgray);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
draw_set_color(c_lime);
var _fill = (hp / hp_max) * _bar_w;
draw_rectangle(_bar_x, _bar_y, _bar_x + _fill, _bar_y + _bar_h, false);
draw_set_color(c_white);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, true);

var _ammo_text;
if (reloading) {
	_ammo_text = "Ammo: RELOADING...";
} else {
	_ammo_text = "Ammo: " + string(ammo) + " / " + string(ammo_max) + "  [R]";
}
draw_text(_hud_x, _bar_y + 24, _ammo_text);

draw_text(_hud_x, _bar_y + 48, "Kills: " + string(kills) + "   Deaths: " + string(deaths));

// Simple roster
var _roster_y = _bar_y + 80;
draw_set_color(c_ltgray);
draw_text(_hud_x, _roster_y, "Players");
_roster_y += 20;
with (obj_player) {
	draw_set_color(is_local ? c_lime : c_white);
	draw_text(_hud_x, _roster_y, display_name + "  K:" + string(kills) + " D:" + string(deaths));
	_roster_y += 18;
}

if (!alive) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.5, "Respawning...");
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

draw_set_color(c_white);
