var _bob = sin((current_time * 0.006) + bob_phase) * 3;
var _yx = y + _bob;

draw_sprite_ext(sprite_index, 0, x, _yx, image_xscale, image_yscale, 0, c_white, 1);

draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_color(c_white);
draw_text(x, _yx - 18, weapon_name(weapon_id));
draw_set_halign(fa_left);
draw_set_valign(fa_top);
