hsp = 0;
vsp = 0;
damage = 10;
weapon_id = WEAPON_NONE;
owner = noone;
owner_player_id = 0;
is_ghost = false;
is_predicted = false;
net_id = 0;
net_seen = true;
life = -1;
// Range cull: set at spawn (origin + max_range). Network ghosts leave max_range <= 0
// and rely on the host removing them from the snapshot when they expire.
origin_x = x;
origin_y = y;
max_range = 0;
image_xscale = BULLET_DRAW_SCALE;
image_yscale = BULLET_DRAW_SCALE;
