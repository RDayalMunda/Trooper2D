hsp = 0;
vsp = 0;
fuse = FRAG_FUSE_FRAMES;
owner = noone;
owner_player_id = 0;
net_id = 0;
is_ghost = false;
net_seen = true;
grounded = false;
spin = 0; // visual roll angle only — never drive collision with this

sprite_index = spr_weapon_frag;
image_index = FRAG_IMAGE_PRIMED;
image_speed = 0;
image_xscale = FRAG_WORLD_SCALE;
image_yscale = FRAG_WORLD_SCALE;
// CRITICAL: keep image_angle at 0 so the collision mask stays axis-aligned.
// Rotating the mask (rectangle-with-rotation) digs into floors and kills bounce/roll.
image_angle = 0;
mask_index = spr_weapon_frag;
