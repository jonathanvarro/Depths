# Damp Caves art integration: concrete Claude handoff

Owner requested integration on 2026-11-26 and explicitly allowed it to be a
Claude action. Claude already owns the live area graph, water, new creature
definitions, named pack, Rest Area route and challenge families, and is editing
core exploration files concurrently. This handoff avoids competing changes to
those files. **Art production is PR #303; it is not yet integrated merely because
the files exist on that branch.** Use its `docs/damp-caves.md` and catalogues.

## Merge and choose by area identity

Reconcile PR #303 with current main, preserving both assistants' notes and all
new area/challenge/gate/city work. Do not replace main with the older art branch.
Keep the current `damp` area's key/tier, paired exits, daily seed, save/restore
and site guards. Fungal Hollows/Grove keep their own fungal theme; choose the
Damp theme by `_area == "damp"`, never every depth-2/fungal instance.

## Theme and dressing

- Build `themes/damp-caves.tres` from `art/textures/damp-caves-v1` materials,
  using full-face wall UVs and the kit's root curtain/siltfall states. The wall
  variant is ShaderMaterial; do not cast it as StandardMaterial3D.
- Follow `art/dressing/damp-dressing-v1/catalog.json`'s 29 dispositions and
  `docs/damp-caves.md`. New solid pieces use metric floor/wall/roof origins,
  not old Sprite3D pixel scales. Dry mine siblings also replace early mine
  leftovers where appropriate, without changing their rule/placement authority.
- Concentrate mushroom/mold cues in the **Fungal Hollows exit room**. Preserve
  the main Damp Caves' wet limestone identity. Glow is mood only.
- Existing mine/bone/growth/mist libraries remain. Pass motion/visibility
  preferences; stop hidden drips and retain exact still resets.

## Destination-specific exits

Use `art/features/damp-passages-v1/catalog.json` and six route SVGs for Cavern
shaft/rope return and Hollows crawl/return. Bind from the **actual destination
and incoming pair**, not a single depth-based descent scene. Show the canonical
destination label before commitment. Preserve Areas/arrival authority.

Shaft supplies an open apron; onward crawl supplies full floor; returns retain
the caller floor. Respect ceiling-tagged return caps and avoid duplicate floors.
Existing game-owned way-up/down lights remain.

## Landmarks and interactive states

Use the six landmark compositions and five appearance sets in
`art/props/damp-sites-v1`. Most landmarks reserve 3x3 cells; drowned drift 1x3.
Preserve mandatory quest footprints and the royal cache's real buried-cache
event. Do not squeeze full scenes into single event cells.

The seep requires a real wall. Slick ledge requires an omitted caller floor
and the actual **ready / slipped / passed** outcome: generic `empty` is rejected.
Other two-state props accept documented legacy aliases. Fish bodies are opaque;
only their small viewing water uses alpha. Appearance does not choose outcomes,
odds, loot, cooldowns, discovery or new NPC identities.

## Creatures and sound

Replace the current rat/beetle/spider stand-ins in `pale_newt.tres`,
`blind_crawler.tres`, `leech_swarm.tres` with the wrappers in
`art/enemies/damp-creatures-v1`. Retain DARTING / GRABBER / venom-fire responses,
current health/aim/row/loot values and encounter weights. Bind the Drowned
Mother's separate model privately in the existing elite-model dispatcher.

Wrappers provide play/sample/set_motion/set_opacity/framing_bounds. `sample`
takes seconds; grab enters hold, fall/submerge hold their terminal frame.
Submerge compresses below caller water, not a new targeting immunity. Normal
materials never write ALPHA; fades use the cached explicit sibling. Do not
raise detail priority to force eyes/claws over bodies. Named glow stays on map.

Assign `audio/damp-caves-v1`'s bed/steps/bump/passages/drips/reactions through
existing theme and Sounds APIs. Effects bus; existing ambience player −10dB
**once**. Explicit WAV loops, no normalization/trim. Existing approved music
and 117 earlier sounds stay unchanged. Human listening/mix review still matters.

## Verify the actual hookup

Run current area-network, quest-site, Damp/rest, enemy-model, wildlife, sound and
save/restore checks after integration. Add actual seeded Damp exploration and
combat views, including mixed creatures, ordinary/leader newt, grabs, still mode,
both paired returns, full room landmarks and resolved states. Check desktop and
landscape phones, then a real exported game with a private test save. Existing
art-only checks in #303 do not replace these. Use isolated profiles and the
private-desktop capture helper; never use the owner's active save or screen.

## Separate follow-up

The Cavern/Rest Area art in #308 is separate. Its compact refuge marker changes
only `refuge_scouts.prop`; the full 4x4 approach and tall rift need deliberate
room/roof reservation. The small playable elevation prototype remains deferred
at the owner's request. No slopes or stacked map layers are commissioned here.
