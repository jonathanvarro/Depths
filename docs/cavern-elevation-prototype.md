# Playable Cavern walking study (#311)

The Cavern can now be walked with actual changes in elevation in an isolated
prototype. Open `scenes/prototypes/cavern_walk.tscn` and press F6. The normal
title/campaign entry remains unchanged. This builds on the Cavern art/rest
approach delivery in PR #309; it is not a full production floor integration.

## Owner approval

The owner played the prototype and accepted it as successful: "I've played the
prototype and I think that looks great - it's a success." This approves the
playable Cavern direction and slope/bridge/reconnecting-route experiment as the
basis for production integration. The tested device was not specified; this
does not establish physical iPhone performance or comfort approval, final art
acceptance, or completion of campaign-wide elevation support.

## What to try

Start on the upper western ledge, arriving from the Damp Caves. Walk north to
the junction. Continue north and turn east to cross the timber bridge, or turn
east at the junction to descend the western side. Both routes reconnect via the
lower ledge and eastern slope. The lower landing is 2.4m below the bridge.
The short northern tail beyond the eastern bridgehead reaches the Rest Area
threshold. It is the endpoint of this walking study, not a campaign transition.

W/S or Up/Down move; A/D or Left/Right turn. Mouse/touch movement buttons can
be held. M opens the explored route map. Escape closes the map first, then
opens Continue / Start again / Quit prototype. The menu freezes movement even
halfway down a slope; Continue resumes that step. Start again resets only the
study. It never reads/writes expedition saves or player settings.

## Technical boundary

`scripts/prototypes/cavern_height_map.gd` extends DungeonMap for an authored
27-cell route with one height per cell and reciprocal cardinal connections.
Adjacent ledges are not automatically neighbours for movement: the two western
routes run beside one another at different heights without allowing a step
across the drop. There is one loop and two approach tails. No walkable route
passes over another route in the same X/Z cell.

Each 2m grid link has a level 1.2m landing around the cell centre and an 0.8m
ramp between landing edges. The 0.4m maximum rise gives a maximum physical ramp
angle of about 26.6 degrees, with an average rise across the grid step of about
11.3 degrees. `step_position()` supplies the same piecewise profile to the
camera adapter and physical floor construction; turns remain on flat pads.
Movement uses the existing Party input, turns, camera and lantern, with a
prototype subclass overriding height conversion and successful step tweens.
Forward/backward and both travel directions follow the surface. View pitch
stays level, with the existing 1.2m eye clearance and no added head bob.

Terrain uses two batched surfaces, stone and timber, plus supporting sides and
a real physics floor for verification. The bridge has solid planks, supplied
dark vertex colours, shared grain and rails. New box geometry has metre UVs,
avoiding stretched wall textures. Existing Cavern rocks, columns, pendants,
totem, glyph, threshold and standing lanterns are reused without changing their
sources. Lanterns stand on supported plinths outside the walking lane. Scenery
extends below/above the paths, with a genuine opening at the Rest threshold.
All motion is still by default. No new character, model animation, downloaded
source, raster generation or gameplay light/fuel rule is introduced.

The shared Reliquary Brass theme supplies actions and panels. Controls use
screen-space touch bounds, real/simulated safe areas and a 648px reference scale
on taller/Retina windows. Small landscape windows retain 48px or larger actions.
Movement controls and heading disappear behind the map/menu to keep them clean.
The map distinguishes upper stone, lower/sloping stone and timber, with only
explored nodes and actual links drawn. No new colour meanings affect the
campaign inventory or rarity system.

## Validation and local review

`tools/cavern_walk_check.gd` runs the real standalone scene. It walks the whole
loop and reverse route with the actual tween, checks a floor ray at each motion
sample, tests nine swept rays at foot/body/eye heights against the visible
scenery, and verifies all authored landing/ramp support samples. Additional
checks cover reciprocal connected topology, refused drops, backwards descent,
keyboard turns, actual in-viewport mouse and touch dispatch, pause/resume,
map/Escape precedence and a real scene restart. Native captures cover desktop,
1278×590, 844×390, 667×375 and 2556×1179 with safe areas. The final JSON report is
authoritative; per-frame check counts vary slightly with rendering cadence.

Local gallery: `E:/GitHub/Depths/build/local-cavern-walk-v1/inspector.html`.
Final native run: **11,420 checks, 24 captures, zero failures**, with 908 actual
tween-motion samples and clean stdout/stderr apart from the expected report.
`START_WALK.cmd` beside it launches an interactive run only when chosen by the
owner. Native GPU checks use `tools/testing/background_godot.py` on a private
desktop/profile, never the owner's active screen. The owner's subsequent
successful playtest is recorded above; physical iPhone validation remains.

Reproduce after a headless import:

```powershell
$env:APPDATA='E:/GitHub/Depths/build/local-cavern-walk-v1/profile'
python tools/testing/background_godot.py --godot E:/GitHub/Depths/build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --project . --output E:/GitHub/Depths/build/local-cavern-walk-v1/native-launch --timeout 120 -- --resolution 1280x720 --script res://tools/cavern_walk_check.gd -- E:/GitHub/Depths/build/local-cavern-walk-v1/native
python tools/package_cavern_walk.py --workspace . --output E:/GitHub/Depths/build/local-cavern-walk-v1 --godot E:/GitHub/Depths/build/research-godot-4.7.2/Godot_v4.7.2-stable_win64.exe
```

## Before campaign adoption

The owner has accepted the walking study. Next agree on authored versus
generated height layouts and verify physical phone readability. Production
adoption must
make Main's enemy/party/combat/prop/wanderer positions, wall lights, passages,
water planes and dressing height-aware; provide traversable-edge checks to
pathfinding; persist heights/links compatibly; and prove incoming/outgoing
returns, mandatory quest placement and combat framing on elevated floors.
Stacked bridge-over-path cells require a later map-layer decision. Current
save schemas, campaign generators, tactical stage, enemy rules and Claude's
ongoing Damp Caves/City integration are untouched by this prototype.

The current paths are clear geometric strips for movement review; final
irregular rock silhouettes, additional site dressing and the complete Rest
Area composition are separate from proving slope traversal.
