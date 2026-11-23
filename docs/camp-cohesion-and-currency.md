# Cohesive campsite and inventory gold (#286, #289)

The camp keeps its mountain clearing, cave entrance, paths and service sites.
Three new built-in ImageGen paintings replace the empty terrain, player-tent
exterior and cooking hearth in `art/camp/cohesive-v5`. All three share the
terrain's muted grey/brown, worn illustrated finish. The tent has a compacted
earth pad beneath its pegs; ropes, wood and patched canvas are weathered. Its
approved interior painting and cot/chest interactions remain unchanged.

The hearth has two low log seats and a real stump table. Bowl, bread and cup
are painted onto that tabletop, replacing the loose meal overlay. Existing
anonymous ambient figures use corrected seat contacts. Their visibility still
follows actual candidate availability; no names, recruits or service arrivals
are baked into the paintings. Other stations and portraits retain the original
highres-v4 assets and story-controlled visibility.

The fire's six-frame burn loop, restrained warmth and independent site lighting
are retained. Main passes the existing effects preference when opening camp
and after Settings closes, freezing the fire at frame zero and its lights at
their base energy when disabled. No food, fuel or resource mechanics change.

## Stable HUD and image registration

Pack now sits at the same top-right safe-area position and screen size in camp
and exploration. The map is below that button in exploration, so showing or
hiding it does not move Pack. Camp's Pack lives outside the scaled landscape;
the day and gold readout move left to leave it clear. Brass styling, sound,
keyboard focus, touch target and existing open-pack signal remain.

Landscape artwork still uses the 640 × 360 scene contract. Tent/fire textures
are imported with a 1024-pixel limit; `cohesive-v5/site.gd` derives their scale
from the actual imported width, preserving the 196/181-unit footprints and
registered flame/seat/light contacts. Do not use their full-source pixel width
to calculate runtime scale after texture limiting.

## Sharp gold picture

The blurry item was the stash's 20-pixel HUD coin symbol enlarged into a bag
compartment. `art/items/currency-v2/gold.png` is a new transparent illustration:
an irregular hammered gold coin with the established branching currency crest,
chipped rim and recessed relief. Its original is 1254 × 1254; Godot imports a
512-pixel runtime texture. `StashScreen.COIN_ICON` uses it for both stored and
carried gold pictures. Compact currency glyphs, gold amounts, prices, storage
and transfer rules remain unchanged. No new SupplyItem or currency is created.

## Sources, prompts and review

Generated with the built-in **image_gen** tool. Exact prompts, reference roles,
generated source filenames, hashes and dimensions are retained in:

- `art/camp/cohesive-v5/generation-manifest.json`
- `art/items/currency-v2/generation-manifest.json`

The new PNGs are the unchanged generated outputs; source resolution remains
available in the repository. Transparency is preserved, and texture size
limits are importer settings. Reference images are the project's own previous
terrain and tent/fire art. Earlier artwork is retained as siblings.

Native review: `build/local-camp-cohesion-v5/inspector.html`, with actual desktop,
phone-shaped and Larger-text images and validation logs. All GPU checks used
the private desktop; no test became foreground. No physical iPhone test.

- `tools/camp_cohesion_check.gd`: scene/texture registration, live still mode,
  candidate visibility, hidden unearned services, matching Pack position/size,
  actual mouse/touch presses at 1280×720, 1278×590, 844×390 and 667×375 with
  Normal/Larger text, and real gold take/store totals.
- `tools/first_days_check.gd`: zero failures, including arrivals and recruitment.
- `tools/camp_check.gd`: zero failures; services, stash and return to exploration.
- `tools/tent_brass_check.gd`: 137 checks, zero failures; original tent targets,
  highlights, cot/rest, chest/stash, Back, safe areas and brass styles.

Run captures through `tools/testing/background_godot.py`, as documented in
`docs/background-asset-checks.md`.
