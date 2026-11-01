# Seven salvage and smith-material icons — #196 / #202

[Review gallery](../art/concepts/salvage-v1/inspector.html) ·
[64/40px colour](../art/concepts/salvage-v1/library-colour.png) ·
[Greyscale](../art/concepts/salvage-v1/library-greyscale.png) ·
[Actual phone Pack](../art/concepts/salvage-v1/pack-1278-normal.png).

Owner selected these seven small inventory icons on 2026-11-01. They are bound
to the existing SupplyItem resources, replacing borrowed cloth/spice/ore art.
This is an item-art delivery; equipment-base pictures in #196/#194/#195 and
companion-system brainstorming remain separate.

| Resource in `data/items/` | Icon in `art/items/salvage-v1/` | Distinct construction |
|---|---|---|
| `rat_pelt.tres` | `rat-pelt.png` | Ragged grey-brown fur roll, pale curled inner hide and one twine binding |
| `spider_silk.tres` | `spider-silk.png` | Pale loose hank around a dark crooked stick, a few large loose loops |
| `bat_wing.tres` | `bat-wing.png` | Partly folded dry umber membrane, supporting ribs and scalloped outline |
| `hound_hide.tres` | `hound-hide.png` | Thick hairless slate-grey hide, broad overlapping folds and rough edges |
| `beetle_shell.tres` | `beetle-shell.png` | One curved slate-hard plate, broad growth ridges and chipped rim |
| `black_ore.tres` | `black-ore.png` | Asymmetric dark lump, glassy fracture faces and dull mineral edges |
| `goblin_scrap.tres` | `goblin-scrap.png` | Bent buckle, short iron offcut and crude two-rivet plate, restrained oxidation |

## Art contract and bindings

Runtime PNGs are128×128, matching `refined-v2` and `field-kit-v1`, with a112px
maximum content box, at least8px clear padding, hard alpha and at most64 visible
colours per icon. Each matching `compact64/` PNG is reduced directly from its
same source into a56px content box with at least4px padding, rather than reduced
from the128px export. No dithering, glow, quality badge, text or frame is baked
in. The images use material/shape differences that remain visible without colour.

The seven `.tres` paths, IDs, names, prose and resource script attachments stay
intact. Only their Texture2D URI and the obsolete `Placeholder picture.` note
changed. `bindings-before.json` retains the exact starting files; normalizing
those two presentation edits produces identical resource text. Prices, effects,
use times, stack sizes, `a_name`, drops, tempering costs, inventory capacity and
save identity therefore remain unchanged. The old shared fine-cloth,
spice-pouch and copper-ore PNGs retain their original hashes and other bindings.

The live Pack, loot and merchant widgets read the new `SupplyItem.icon` directly.
No widget/controller code changed. Material sale and smith consumption continue
to use the original resources; these drawings do not grant new uses or bonuses.
All14 runtime/compact textures together occupy0.547MiB decoded RGBA before engine
overhead. Source and review folders have `.gdignore`; no large painted master
is a runtime texture.

## Sources and review

Seven individual built-in ImageGen calls produced these new drawings, without
uploaded reference images. Their immutable masters, exact prompts, original
output locations, hashes and export registrations are in
`art/source/salvage-v1/generation.json`. The source art remains intact; the
exporter only fits/crops, resizes, reduces colours and applies the established
hard-alpha icon contract. No subject is painted by the exporter.

The gallery compares128/64/40/32px, dark/parchment and greyscale, and retains the
old borrowed pictures. Twelve real Godot Mobile captures use current Pack,
ChestScreen and MerchantScreen instances with an isolated copied party:
1280×720 desktop,1278×590 phone Normal/Larger, and1334×750 SE Larger, with phone
safe-area margins. The seven resource pictures are inspected individually in
both Pack and merchant details. The capture party's counts, purse and time stay
unchanged; Main, player settings and saves are never opened.

Rebuild and validation:

- `python -B tools/art/build_salvage_icons.py`:102 source/padding/palette/binding
  invariant checks. Add `--wire` only to apply the two permitted item edits;
  unexpected resource or third-party image changes stop the exporter.
- Godot4.7.2 `--headless --path . --quit-after 2400 --script tools/art/check_salvage_icons.gd`:
  38 resource and real-widget checks pass.
- The same fixture hidden/off-screen with the Mobile renderer:50 checks pass,
  12 actual captures, clean fixture logs. The restricted editor-cache refresh
  emits an editor-preference safe-save warning; resource import and the isolated
  checks complete. Never use `-- --begin` for these captures.
- `python -B tools/art/build_salvage_review.py` builds the file-safe gallery.
  `node tools/art/check_salvage_review.cjs` checks its images, comparisons,
  captures and responsive phone widths;75 checks pass.

Physical iPhone inspection/performance remains separate. All seven requested
icons are delivered and live; no companion artwork, gear-base mapping, pricing,
salvage-drop, smith or save rules were changed.
