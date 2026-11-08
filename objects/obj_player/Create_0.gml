hsp = 0;
vsp = 0;
grav = 0.35;
move_speed = 4;
jet_acc = 0.5; // Milder thrust — still beats gravity when held
max_fall = 8;
max_rise = 4; // Cap upward speed while jetting
// Ignore small upward stick tilt while strafing (~20°+ needed to engage).
jet_engage_min = 0.35;
fuel = 150;
fuel_max = 150;
fuel_drain = 1.2;
fuel_regen = 1.5;
fuel_regen_delay = 100; // ~1.7s unused before regen starts
fuel_idle_timer = 0;

hp = 100;
hp_max = 100;
hp_regen = 0.1;
hp_regen_delay = 240; // 4s after last hit before regen
hp_idle_timer = 0;
bullet_damage = 10;
bullet_speed = 12;
alive = true;
spawn_x = x;
spawn_y = y;
respawn_timer = 0;
respawn_time = 90;
hurt_cooldown = 0;
hurt_cooldown_max = 30;
hit_bar_timer = 0; // show floating HP when recently damaged (others only)
hurt_zone_damage = 25;
// Outside obj_fight_zone — harder than hurt zones.
void_out_damage = 45;
void_out_interval = 15;

weapon_id = WEAPON_NONE;
mag = 0;
reserve = 0;
mag_size = 0;
reserve_max = 0;
shoot_cooldown = 0;
fire_cooldown_max = 10;
reloading = false;
reload_timer = 0;
reload_time = 75;

kills = 0;
deaths = 0;

net_id = 0;
is_local = true;
display_name = "Trooper";
aim_dir = 0;
move_x = 0; // -1..1 analog strafe
move_y = 0; // -1..1 analog (negative = jet up)
input_shoot = false;
input_reload = false;
input_want_pickup = false;
want_pickup_net_id = 0;
pickup_prompt_net_id = 0;
pickup_prompt_name = "";

// Cosmetics / layered draw (collision still uses spr_player mask)
cosmetic_head = 0;
cosmetic_torso = 0;
cosmetic_leg = 0;
cosmetic_hand = 0;
walk_phase = 0;
trooper_scale = TROOPER_MATCH_SCALE;

// Client net smoothing
net_from_x = x;
net_from_y = y;
net_to_x = x;
net_to_y = y;
net_aim_from = 0;
net_aim_to = 0;
net_interp_t = 1;
net_interp_dur = 3;

// Camera zoom (guns can expand zoom_levels later)
cam_init_player(id);

// Starter gun — host may overwrite remotes; snapshots sync clients.
weapon_give_starter_random(id);
