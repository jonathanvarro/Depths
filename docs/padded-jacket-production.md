# Padded expedition jacket · #220

The draft is now a swappable garment on the current female-v1 and approved
male-tpose-v1 bodies. The isolated local library is
`E:/GitHub/Depths/build/local-padded-jacket-v2/`; the older draft, assemblies,
source masters and Claude's working tree are preserved.

Open `review/inspector.html` for the two fits, tunic comparison, four angles,
close-up and paused movement views. Run `START_REVIEW.cmd` for actual playback,
Tunic/Jacket switching, independent garment toggles, the current chair sequence,
paused frame stepping and the phone layout. “Garment detail” enlarges the torso;
“Controls” folds the tools on smaller screens. No game or player save is loaded.

## Construction

Muted olive/dun canvas, broad vertical torso channels, quilted sleeves, low
padded collar, overlapping front, three leather tabs/round wooden toggles and
one stitched elbow repair. A hip-length hem has short side splits for sitting.
The finish includes irregular running stitches, dye variation, cloth grain,
slight edge irregularity and lower-hem dirt. Materials describe neutral surface
colour; lighting remains the caller's responsibility.

The draft's fragmented body-derived tunic shell was replaced by continuous
torso panels and separately sewn, capped sleeve panels. Shoulder and hip ease
clear the source body and trousers. The original tunic is an independent
alternative. The jacket-specific belt and buckle clear the padding and follow
the jacket's waist skinning. Existing tunic, trousers, boots and belt remain
unchanged. These are skinned low-poly meshes, not cloth simulation.

Each jacket has one packed 512×512 base-colour texture (1 MiB RGBA8 base level
before GPU compression/mips); the editable procedural authoring shader remains
in its Blender master. Collar/placket, patch, thread, wood and leather use
neutral material swatches. Quilting fullness is shallow geometry. Construction
details are joined by material rather than making a draw call per stitch.

## Files and switching contract

- `editable/{female,male}_padded-jacket.blend`: editable unpartitioned bodies,
  original garments/Actions and separately named jacket collection. This is the
  authoring copy; source masters are never written.
- `masters/{female,male}_review.blend`: matching exported review masters.
- `assets/{female,male}.glb`: one rig, all existing Actions, disjoint reversible
  body regions and both outfit alternatives.
- `assets/{female,male}-jacket-only.glb`: jacket, construction and fitted
  belt/buckle on the exact fit skeleton; no body, old tunic or animations.
- `construction.json`, `manifest.json`, `lineage-validation.json`: fit identity,
  source hashes, component names, weights/export evidence and source lineage.

`record.fit_id` is the real family (`female-v1` / `male-tpose-v1`). The legacy
Blender object/coverage namespace remains `*.male.v1` and `fit_id=male-v1` for
existing tools; new components also record `base_fit_id=male-tpose-v1`. Never
bind the new male jacket to the retired lowered-arm male base just because
names match. Male and female share a design, not vertex/weight arrays.

The existing five logical visibility bits remain upper, belt, trousers, left
boot and right boot. The upper bit retains its internal name `tunic`; it is
not a new gameplay slot. `outfit` is `jacket`, `tunic` or `both` on each garment
entry. The actor first applies the existing body coverage, then suppresses the
other outfit's upper and belt meshes. Only one upper garment is visible.
Removing upper clothing restores all corresponding original body faces.

`tools/padded_jacket/actor.gd` and `review.gd` extend local snapshots of the
existing reviewer. `visibility.py` provides the equivalent Blender helper.
Changing outfit retains the actor, skeleton, motion, exact paused bone poses,
other clothing toggles and source time. Later live equipment integration should
use the same explicit fit identity and mutually exclusive upper selection.
No live equipment, armour rules, faces, camp, HUD or save schema changed here.

## Rebuild and checks

Run in the isolated tools checkout, with `--workspace E:/GitHub/Depths`:

1. Blender `build_jacket.py`: creates the two editable fits, original packed
   textures and actual Blender views from pinned assembly-v6 inputs. The male
   still uses the approved T-pose base; v6 supplies Claude's newer female
   hand-rest Actions. `--source-assembly assembly-v5` remains an explicit option.
2. Blender `export_jacket.py`: uses the existing reversible-body exporter and
   its independent reimport/motion/coverage comparisons. It records hashes of
   the reused tools and adds outfit-aware native review/checks.
3. Godot headless editor import, then `--headless --script check.gd` and a real
   Windows Mobile-renderer `--script check.gd` in the generated project.
4. Blender `validate_jacket.py`: independently reopens inputs/outputs, compares
   full source body/UV/weights, original garments, rest rig and every Action
   key/handle/slot; checks weights/UVs and exports/reimports jacket-only GLBs.
5. Python `package_review.py`, then Node `check_gallery.cjs` with the workspace
   argument: verify evidence/assets and inspect every gallery state and link.

Use Blender's `--python-exit-code 1` before `--python`. The builder refuses to
replace an edited master; `--rebuild` only permits replacement when its saved
hash still matches. All generated media stay in ignored `build/`. Only generic
tools and this non-asset handoff belong in Git.

Native checks exercise all 32 clothing selections for both outfit alternatives,
repeated swaps between frames, mouse/touch popup selection, current motions and
chair joins, front/side/back views, native 96/192 cards and four desktop/phone
window shapes down to 852×393. Actual counts and render evidence are in the
local reports; these are correctness checks, not an iPhone performance claim.

Final checked snapshot: 2,528 construction vertex-weight checks, 972 independent
Blender export/reimport checks, 5,128 reopened lineage/component checks, 6,488
native and 4,082 headless checks, 671 artifact checks and 162 browser checks;
no failures. The review contains 328 actual native captures and 14 Blender
captures. Fully dressed jacket outfits show 6,922 triangles on the female and
5,680 on the male, with 16 surfaces / 12 materials each. The female retains
her existing body texture in addition to the jacket's new texture; the male
has only the new jacket texture. Source motion/contact limitations below remain.

Source hand/seat/floor contacts and loop acceptance remain open under
#214/#215/#218. This garment adopts assembly-v6's existing female hand-rest
Action and male T-pose conversions without changing their keys, timing, root
travel, floor reference or sequence policy. Walk playback stops at the real
endpoint. No claim of final source-animation acceptance is made.
