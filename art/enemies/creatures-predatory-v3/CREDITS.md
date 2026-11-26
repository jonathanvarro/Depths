# Rat silhouette / grounded bat revision (#294)

Rat and great rat: derived from **Rat by br-n518 (2018), CC0-1.0**,
https://opengameart.org/content/rat-0 . Original source archives, licence page
and hashes remain in `art/third-party/oga-rat-v1`. Uses the same retained local
source master, 21-bone rig and six animation roles as #292/#293.

Changes from `creatures-refined-v2`: lengthened tapered head, smaller round
ears farther back, tucked leg geometry, low body, matte grouped fur, visible
red eye marks, prominent great-rat incisors and larger bristle fans. Paws,
curved tail and fixed floor origin remain. Old Whisker's rigid muzzle details
are refitted; her ash coat uses the revised base. Geometry is smaller than
the preceding triangle budgets; material draw counts are unchanged.

Cave bat: original Depths geometry/colours and 13-bone rig from #292. Only
grounded wing folds and their landing blend change in this sibling export.
Flight idle/attack/hurt/fall skin is verified against v2 at nine samples per
clip. Grounded tint and tag clearance are presentation-only; no extra lights.
The ambient flying bat still uses the unchanged v2 scene.

Procedural matte fur and detail shaders are project-original. The red eye
marks have restrained emission, with no actual light or visibility-rule change.
Material priority fixes transparent fur drawing over eyes and nose. No raster
texture generation, private human geometry, Mixamo or new external downloads.
CC0 source rights remain CC0; authored additions follow the project's licence.

Build: `tools/creature_refinement/build.py -- --sources <workspace> --predatory`
in Blender. `catalog.json` and `whisker-catalog.json` record exported hashes,
source identity, bounds, clip and triangle counts. Editable copies remain
local in `build/local-creatures-predatory-v3/masters`. Earlier files and
masters are retained. See `docs/rat-predatory-revision.md` for review/limits.
