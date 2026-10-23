# Five reference-led creature studies

2026-10-22 · #153 · Exploratory concepts requested by the owner.

[Review gallery](../art/concepts/reference-creatures-v1/inspector.html) ·
[Five-direction comparison](../art/concepts/reference-creatures-v1/comparison.png) ·
[Exact built-in ImageGen prompts and provenance](../art/source/reference-creatures-v1/generation.json)

Five supplied images were reimagined as individual full-body paintings using
built-in ImageGen. Their dominant silhouettes and character cues are retained,
with aged materials, broad shadows and the project's dark, gritty treatment.
These are new concept studies alongside #150–#152's existing set. Their working
labels identify the files; they establish no names, factions, story roles,
floor assignments, powers or final bosses.

| Working label | Cues explored | Review focus |
|---|---|---|
| [Veiled Sovereign](../art/concepts/reference-creatures-v1/veiled-sovereign.png) | Empty black veil, pale articulated armour, thin thorn halo and restrained raised hand | Crown/armour relationship and mantle silhouette; fine cloth webs would need simplification |
| [Thorn Regent](../art/concepts/reference-creatures-v1/thorn-regent.png) | Sinewy torso, crown, raised palms, fibrous train and segmented tail | Distinguishing tail from train; deliberate crown and hand shapes |
| [Cinder Eye](../art/concepts/reference-creatures-v1/cinder-eye.png) | One red eye-ring within a heavy horned carapace and four-arm silhouette | Plate/horn density and preservation of the singular focal point |
| [Pale Hollow](../art/concepts/reference-creatures-v1/pale-hollow.png) | Blank head, throat opening, hollow torso, four uneven arms and pointed supports | Torso gap and clear arm spacing; locomotion remains undefined |
| [Ribbound Wraith](../art/concepts/reference-creatures-v1/ribbound-wraith.png) | Suspended skull inside an oversized rib canopy, hooked limbs and fibrous strands | Dorsal peak reaches the upper canvas edge; production framing would need margin and simplified web/rib detail |

The gallery switches between all five paintings and can show the corresponding
supplied reference alongside each. Original paintings are also linked directly.
References are user-supplied visual inputs; creator/licence details were not
provided. Their source records retain that provenance without claiming the
inputs are project-authored or CC0. The earlier vampire-queen image was a separate
playful preview and is not one of these five studies. The owner subsequently
selected its crown-free gothic revision as a concept; see the separate
[vampire queen concept](../art/concepts/vampire-queen-v1/README.md) (#154).

## Scope and preservation

All owner selections are open. Concept detail is not a new runtime budget.
No native128 sprites, transparent cutouts, animation frames, portrait rigs,
enemy definitions, combat rules, sound, encounters or lore were added. Before
production, selected shapes would need their own readability, palette, framing
and pose work against the existing game contract. The paintings do not establish
world height or a common creature family merely by sharing a review page.

- `art/concepts/reference-creatures-v1/`: five 1024×1536 paintings, catalogue,
  gallery, comparison and responsive review captures.
- `art/source/reference-creatures-v1/`: five unaltered generated masters,
  supplied references, exact prompts, input roles, original output locations
  and SHA-256 hashes.
- `tools/art/record_reference_creatures.py`: preserves sources and verifies
  copies/previously recorded hashes without repainting or resampling.
- `tools/art/build_reference_creature_review.py`: rebuilds the catalogue/page.
- `tools/art/check_reference_creature_review.cjs`: checks decoded images,
  correct reference pairing, navigation, comparison and responsive controls.

Both art folders have `.gdignore`, keeping these outside game imports. All five
master/review copies and supplied references were decoded and hash-checked.
The browser review passes **24 checks** at desktop, 844px landscape and 390px
widths. Screenshots show this review page, not the live game or a physical phone.
No game import or gameplay test is warranted by this concept-only change.
