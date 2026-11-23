# Sling, bow, wand and staff inventory artwork

The four smith weapons from #260 use new 128 px inventory pictures under
`art/items/ranged-focus-v2`. Each has a compact 64 px sibling made directly
from the same master. Native exports use hard alpha and a 64-colour palette,
with the established item padding.
Both the equipment resources and `data/equipment/bases.json` reference
the new images, so bought, generated and restored equipment use them.

| Item | Silhouette and wear |
|---|---|
| Leather sling | Stone cupped in a worn leather pouch, coiled flax cords and a distinct finger loop. |
| Short bow | Compact yew crescent, taut pale string, stitched handgrip and repaired horn tip. |
| Prayer wand | Crooked blackthorn, light linen grip, small fork and dull pewter votive charm. |
| Oak staff | Heavy knotted head, natural dogleg, two iron split repairs and a battered foot. |

[Compare 128, 64 and 40 px](../art/concepts/ranged-focus-v2/inspector.html).
The exact built-in ImageGen prompts and immutable source hashes are in
[the generation record](../art/source/ranged-focus-v2/generation.json).
The sources are text-prompted illustrations. They are retained alongside the
delivery. Earlier placeholder pictures remain under ranged-focus-v1.

Run `tools/art/export_ranged_focus_icons.py` with the project's Python
art environment to rebuild. `--wire` also sets the four equipment resources'
image paths. It verifies the source hashes, dimensions, alpha and colour
budget, and checks that wiring preserves every non-visual resource field.
The native fixture is `tools/art/check_ranged_focus_icons.gd`, with an
optional output directory after `--` for Pack and smith screenshots.

Native review uses Godot 4.7.2 Mobile at 1278 × 590 on the private test
desktop. The phone screenshots are under
`build/ranged-focus-icons-review`. Physical iPhone review remains open.

Pack inspection and the smith's normal purchase flow passed the native
fixture, including the copied inventory instances. Equipment, magic, save,
named-cast, refuge, story and first-days regression checks also passed on
the combined project.
