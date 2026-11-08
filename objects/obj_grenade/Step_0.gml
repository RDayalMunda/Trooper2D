// Clients mirror host position via snapshot; spin is local visual only.
if (is_ghost) {
	x += hsp;
	y += vsp;
	spin += hsp * FRAG_SPIN_RATE;
	image_angle = 0;
	image_index = FRAG_IMAGE_PRIMED;
	exit;
}

if (instance_exists(obj_net) && obj_net.phase != "match") {
	instance_destroy();
	exit;
}

fuse -= 1;
if (fuse <= 0) {
	grenade_explode(id);
	exit;
}

// Lock collision orientation every frame (Draw uses `spin` instead).
image_angle = 0;

vsp = min(vsp + FRAG_GRAV, FRAG_MAX_FALL);

// --- Horizontal ---
var _hit_h = move_and_collide(hsp, 0, obj_solid);
if (array_length(_hit_h) > 0) {
	hsp = -hsp * FRAG_BOUNCE;
}

// --- Vertical ---
var _was_falling = (vsp > 0);
var _impact_v = abs(vsp);
var _hit_v = move_and_collide(0, vsp, obj_solid);
if (array_length(_hit_v) > 0) {
	if (_was_falling) {
		// Floor hit. Low-angle throws often have small vsp but big hsp —
		// still give a little hop so they don't glue, then keep rolling.
		if (_impact_v >= FRAG_BOUNCE_MIN) {
			vsp = -_impact_v * FRAG_BOUNCE;
		} else if (abs(hsp) > 2.5) {
			vsp = -min(3.2, abs(hsp) * 0.22); // glancing bounce → roll
			hsp *= 0.96;
		} else {
			vsp = 0;
		}
	} else {
		// Ceiling
		vsp = _impact_v * FRAG_BOUNCE;
	}
}

grounded = place_meeting(x, y + 1, obj_solid);
if (grounded && vsp >= 0) {
	vsp = 0;
	// Roll along the floor — preserve horizontal speed.
	hsp *= FRAG_ROLL_FRICTION;
	if (abs(hsp) < 0.06) {
		hsp = 0;
	}
}

spin += hsp * FRAG_SPIN_RATE;
image_index = FRAG_IMAGE_PRIMED;
