# Refined passage silk (#274)

Owner feedback, 2026-11-21: the previous spider web was higher quality.
The first 3D replacement had sixteen regular spokes and four sparse rings,
losing the earlier painting's fibrous silk, irregular sag and dense anchors.

`art/features/web-silk-v2/intact.tscn` restores that original painting at its
full 1254×1254 resolution on a fixed, gently bowed mesh. It is not a billboard.
The source pixels are copied byte-for-byte from
`art/source/expedition-v1/web-intact.png`; its original generation provenance
remains in that folder's `generation-addendum.json`. No new image was generated
or retouched. `catalog.json` records the source hash and rebuild script.

The silk spans a 2m passage, with its anchors against the floor, walls and
ceiling. It bows by at most 10cm between fixed edges. A two-sided, lit material
uses the party's existing lantern, full roughness and no specular highlight.
Linear mipmap filtering preserves a quieter silhouette at distance. Alpha
scissoring keeps holes clear and writes opaque silk depth; there are no lights,
particles, shimmer, transparency sorting layers or running animation.

`torn.tscn` uses the same vertices, UVs, texture and outer anchors. Its centre
is physically absent from the mesh; the static material trims a ragged fringe
around the surviving side/top silk. The opening reaches the floor. This is a
presentation of the existing opened passage, without changing tearing costs,
strain, timing, collision, movement, save flags or floor generation.

Both cave and fungal themes now reference these two scenes. The opening also
uses the cave theme. LevelBuilder still owns placement/orientation and chooses
intact/torn from the map's closed/open state. A hacked-away blockage still leaves
an empty way. The previous 3D and painted assets are retained unchanged; corner
and ceiling web dressing is also unchanged.

The intact mesh has 1,344 triangles; the torn mesh has 816, each in one surface.
Both share one lossless texture with mipmaps (about 8MiB decoded). The geometry
is rebuilt with Godot 4.7.2:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/web_silk/build.gd
```

`tools/web_silk/check.gd` passes 91 renderer-backed checks, including shared
registration, budgets/envelopes, both corridor orientations, a genuine torn
aperture, static mode and actual Party tear/traverse plus LevelBuilder restore
and cleared-blockage behavior. Twenty-eight native captures compare the old and
refined webs at the same camera, with cave/fungal materials, both directions,
oblique/rear views, dim/distant light, desktop and 844×390 / 667×375 landscape
phone sizes. Mobile/D3D12 logs are clean. The #253 private-desktop launcher
reports no foreground activation; no personal saves/settings are involved.
Physical iPhone performance still needs device review.

Review: `art/concepts/web-silk-v2/inspector.html`. Full native captures and launch
logs stay local under `build/local-web-silk-v2`. No character animation was added
or changed.
