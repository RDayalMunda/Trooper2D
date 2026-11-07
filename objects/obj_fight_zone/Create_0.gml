// Safe play AABB for void checks. No collision mask so bullets/players
// never interact with this volume through GM's collision system.
visible = false;
image_alpha = 0;

zone_left = bbox_left;
zone_top = bbox_top;
zone_right = bbox_right;
zone_bottom = bbox_bottom;

mask_index = -1;
