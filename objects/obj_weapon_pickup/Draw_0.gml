// Sit on the ground — no float/bob.
draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, 0, c_white, 1);

draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_color(c_white);
draw_text(x, y - 14, weapon_name(weapon_id));
draw_set_halign(fa_left);
draw_set_valign(fa_top);
