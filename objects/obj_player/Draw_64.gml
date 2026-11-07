if (!is_local) {
	exit;
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);

// Nudge right so the top bar stays clear of the zoom/map cluster visually.
var _s = ui_scale();
var _hud_x = round(24 * _s);
var _hud_y = round(16 * _s);
var _bar_w = round(160 * _s);
var _bar_h = round(12 * _s);
var _panel_w = round(200 * _s);
var _panel_h = round(148 * _s);

draw_ui_panel(_hud_x - round(8 * _s), _hud_y - round(8 * _s), _hud_x - round(8 * _s) + _panel_w, _hud_y - round(8 * _s) + _panel_h, 0.40);

draw_set_color(c_white);
draw_text(_hud_x, _hud_y, display_name);

var _bar_x = _hud_x;
var _bar_y = _hud_y + 24;
draw_set_color(c_dkgray);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
draw_set_color(c_lime);
var _fill = (hp / hp_max) * _bar_w;
draw_rectangle(_bar_x, _bar_y, _bar_x + _fill, _bar_y + _bar_h, false);
draw_set_color(c_white);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, true);

draw_set_color(c_white);
draw_text(_hud_x, _bar_y + 20, "Jet");
var _fuel_y = _bar_y + 40;
draw_set_color(c_dkgray);
draw_rectangle(_bar_x, _fuel_y, _bar_x + _bar_w, _fuel_y + _bar_h, false);
var _fuel_col = (fuel / fuel_max > 0.25) ? c_aqua : c_orange;
draw_set_color(_fuel_col);
var _fuel_fill = (fuel / fuel_max) * _bar_w;
draw_rectangle(_bar_x, _fuel_y, _bar_x + _fuel_fill, _fuel_y + _bar_h, false);
draw_set_color(c_white);
draw_rectangle(_bar_x, _fuel_y, _bar_x + _bar_w, _fuel_y + _bar_h, true);

var _ammo_text;
if (reloading) {
	_ammo_text = "Ammo: RELOADING...";
} else {
	_ammo_text = "Ammo: " + string(ammo) + " / " + string(ammo_max);
}
draw_text(_hud_x, _fuel_y + 24, _ammo_text);

draw_text(_hud_x, _fuel_y + 48, "Kills: " + string(kills) + "   Deaths: " + string(deaths));

if (!alive) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text(display_get_gui_width() * 0.5, display_get_gui_height() * 0.5, "Respawning...");
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

draw_set_color(c_white);
