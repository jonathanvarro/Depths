# Cave room props · v1

Transparent 128px world art for the abandoned pack (two states), pale idol,
still pool and cold campsite. Full event mapping, transforms, state usage,
sources and review results: [cave-room-prop-art.md](../../../docs/cave-room-prop-art.md).

Load abandoned-pack.tscn, pack-searched.tscn, pale-idol.tscn,
still-pool.tscn or cold-camp.tscn. Pack supports set_searched(bool).
Root is the supporting floor/ledge; keep child transforms intact.
Pool is horizontal; all other props are upright fixed-Y billboards.
No light, collider, loot logic or placement changes are included.

Native sprites: 128 × 128, binary alpha, nearest filter, shaded cutout.
Pack states share a 24-colour palette and pivot (64,120).
Idol is 16 colours; cold camp is 24; pool uses 15.
Do not substitute the water for a descent pit or the cold camp for a
lit/rest-safe recruitment camp.

Issue #75 supplies art; #46 owns visible event placement.
