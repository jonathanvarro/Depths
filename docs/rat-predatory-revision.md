# Rat and great-rat revision after owner review (#294)

Follow-up to merged #293. The owner directed us to Claude's refinement
requests in issue #294 on 2026-11-25. The flying bat and first-person camera
framing are kept; rat identity is revised for the player's front view.

New sibling library: `art/enemies/creatures-predatory-v3`. Earlier libraries
and editable masters remain unchanged. Live rat, great rat and Old Whisker,
plus ambient mice, select the new rats. Combat bats use the sibling whose
grounded fold changes; ambient flying bats retain v2.

- Longer tapered head, smaller round ears behind the eyes and tucked leg
  geometry replace the short-muzzled, high-elbow silhouette.
- Great rat is broader and lower, with prominent incisors and bristle fans
  that survive combat distance; Old Whisker's ash coat and muzzle marks follow.
- Matte fur has restrained grouped variation. Red eye marks restore the earlier
  threat. Transparent fur had been drawing over the eye/nose detail surface;
  drawing those details later fixes the actual render, with depth checking
  enabled and no extra draw or light. Small red emission keeps eye contrast;
  the caller still owns whether the creature is visible.
- Grounded bat wings retain a broader contour instead of folding completely
  behind the body. A modest ground-only albedo lift and 0.34m tag gap keep the
  shape readable and the label clear. Idle flight, attack, airborne hurt and
  fall skin are unchanged; the swoop's later blend enters the new landed pose.

| Model | Triangles | Previous budget | Bones | Skinned draws |
|---|---:|---:|---:|---:|
| Rat | 2,792 | 2,876 | 21 | 3 |
| Great rat | 2,810 | 2,918 | 21 | 3 |
| Cave bat | 1,226 | 1,226 | 13 | 4 |

Whisker's muzzle attachments remain 144 triangles / one draw. Contact ink
remains one low-cost plane. All rigs, clip roles/durations, floor/+Z-front
origins and `play/sample/set_motion/set_opacity` APIs remain. Derived rat
floor corrections are recomputed for the reshaped skin. No tactics, numbers,
encounter counts, reach, camera logic, saves, loot or fallback sprites change.

## Review and verification

Open `E:/GitHub/Depths/build/local-creatures-predatory-v3/inspector.html` for
the retained #293 comparison, new studio front/profile/attack views, actual
first-person fights and landscape phone layouts. `masters/` contains separate
editable Blender files. Tests use isolated profiles/test saves and private
desktops; no foreground preview or owner save is used.

The native test samples every imported clip at nine times for skin bounds,
floor/tile registration, loops, unchanged bone counts, preceding triangle
budgets, material instances, exact still/opacity and grounded reactions. It
compares 36 airborne bat samples to v2 (tolerance 0.00001m), checks four
desktop/phone shapes with Normal/Larger UI and safe areas, mixed rat/goblin
framing, and board/exploration restoration. Grounded tags must clear the skin.
Projected left/right eye regions are checked in the rendered rat/great-rat
images, catching the transparent-surface ordering issue that geometry-only
checks missed. Headless geometry checks do not substitute for these renders.

All 1,196 native checks pass, including against main with merged Field kit
PR #291. Import/parse and gallery-link checks pass too.

The existing enemy-model/fallback/board/stage, mine-life and animation-smoothing
checks also cover the new live bindings. Results and captures remain local.
Owner style acceptance and physical iPhone performance/comfort remain open.

Rebuild with Blender 5.2 using the existing source master:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python tools/creature_refinement/build.py -- --sources E:/GitHub/Depths --predatory
```

Import with Godot 4.7.2 headlessly. Run `check.gd` or `review.gd` through
`tools/testing/background_godot.py`, with user arguments `<absolute-output>
creatures-predatory-v3`. Generate the gallery using `gallery.py --review
E:/GitHub/Depths/build/local-creatures-predatory-v3 --baseline
E:/GitHub/Depths/build/local-creatures-refined-v2 --follow-up`.
