# Recruit portrait starter kit · v1

[Artwork #84](https://github.com/jonathanvarro/Depths/issues/84), first
two-character production bundle for [#82](https://github.com/jonathanvarro/Depths/issues/82)
and [recruitment #41](https://github.com/jonathanvarro/Depths/issues/41).
This proves one reusable body/outfit with two individual heads before
expanding the six-template plan.

## Delivered characters and resources

| Visual ID | Appearance proposal | Neutral PortraitSet | Flat fallback |
| --- | --- | --- | --- |
| warden-a | Older adult woman, cropped greying hair, steady watchful face | res://data/portraits/recruits-v1/warden-a.tres | res://art/portraits/recruit-kit-v1/warden-a/preview.png |
| scout-a | Younger adult man, short dark curls, angular freckled face | res://data/portraits/recruits-v1/scout-a.tres | res://art/portraits/recruit-kit-v1/scout-a/preview.png |

These IDs identify drawings, not fixed names or Companion definitions.
Stats, names, roles, strengths, weaknesses, hiring and wipe rules belong
to Claude's recruit model. No live recruitment files or Mara resources
were edited in this art task.

[catalog.json](../art/portraits/recruit-kit-v1/catalog.json) lists the role,
flat image, PortraitSet and light-mask paths. Use it to assign art during
recruit creation, keeping that choice stable with the hero. Rendering or
reopening a screen should not reroll a face. Save the chosen ID when
persistent recruits are implemented.

The current flat silhouette integration can use the preview paths above.
For animated party cards, assign the corresponding resource to
`hero.portrait_set` and retain `hero.portrait` as the flat fallback.
Existing PortraitView understands these resources without changes.
The current in-progress recruitment implementation was left untouched.

## Reuse and canvas contract

Every exported layer is **192 × 192 RGBA with origin (0,0)**. Always stack
complete canvases at one scale. Do not trim or fit each head, eye, mouth,
condition or mask independently at runtime.

Both characters and all six expression resources point to the **same**
textures:

- `art/portraits/recruit-kit-v1/shared/body.png`: complete modest linen
  undershirt with a shared neck/collar socket.
- `art/portraits/recruit-kit-v1/shared/jerkin.png`: removable plain
  padded outer jerkin, fitted to that socket and shoulder silhouette.

The template is called `average-covered-adult-v1`. It is a clothed bust
fit test usable by these two heads, not a universal anatomical template
or a replacement for the planned male/female build families.

The individual head plates contain face, short hair and exposed neck.
The shared shirt supplies the collar/shoulders beneath the jerkin.
Hidden undershirt pixels were authored in the original master, so removing
the jerkin exposes a complete garment. Long hair, hoods, other neck angles,
skin families and differently shaped bodies require another fitting pass.

Neutral character drawings share a maximum 48-colour palette. Conditions
use at most eight RGB colours each; dirt/pallor retain controlled partial
alpha. The two light masks are monochrome coverage. All new textures use
lossless imports, nearest display and no mipmaps.

## Expressions and animation

Neutral resources provide:

- `eyes-neutral.png`, `eyes-half.png`, `eyes-closed.png`: registered
  eye/brow replacement patches, with skin coverage to remove the old eyes.
- `mouth-neutral.png`, `mouth-small.png`, `mouth-open.png`: neutral
  and two speaking drawings.
- PortraitSet blink_frames/talk_frames wired to those files.

Blinking and talking use actual PortraitView drawing swaps, not mesh
deformation or full lip-sync. Calls are `blink()` and `talk(seconds)`;
automatic blinking already exists in PortraitView.

Each character also has `-worried.tres` and `-exhausted.tres`, using its
paired eye/brow and mouth drawings. These are **static expressions**:
their blink/talk arrays are deliberately empty. Neutral blink drawings
must not restore calm brows during a worried expression. Animated
emotion-specific lids and mouths remain a later expansion.

Only the fixed eye region (78,53)-(135,80) and mouth region
(89,91)-(125,108) change during neutral face animation. Neither the head,
body nor outfit is replaced. Source-atlas registration measurements are
recorded in asset-validation.json; all measured translations are zero.

## Conditions

Each PortraitSet exposes `blood`, `dirt`, `bandage` and `pallor`.
Call `set_condition(name,shown)` through the existing view.

Blood is sparse temple/cheek staining; dirt uses restrained mud pigment.
The bandage is a small forehead dressing placed above the brows. Pallor
is a partial-alpha skin wash, avoiding hair/linen and preserving features.
These are visual states, not new injury, disease or fear rules.
Overlays are clipped to the character silhouette and can remain active
while changing lighting. Check readability before combining many marks.

## Separate illumination

Neutral heads, clothing, expression patches and conditions contain local
form/material shading without a painted orange lamp or rim highlight.
Each character has separately exported `shadow-left.png` and
`highlight-left.png` coverage masks for an **upper image-left** light.

The optional [lit_portrait_view.gd](../art/portraits/recruit-kit-v1/lit_portrait_view.gd)
extends the existing PortraitView for this kit:

1. `configure("warden-a")` or `configure("scout-a","worried")`.
2. `set_illumination("neutral" | "warm" | "dim")`.
3. `set_condition("bandage",true)`, and optionally `set_outfit(false)`.

It composes neutral character/expression/condition layers, then shade and
tinted highlight, keeping temporary hurt feedback outside that treatment.
Dim uses an ambient floor plus the directional masks; global tint is not
the only lighting operation. It cancels pending expression animation when
reconfigured so an old callback cannot restore neutral eyes/mouth.

These are authored presets, not arbitrary physical relighting or automatic
lantern-oil integration. The raw mirrored-right mask studies were rejected
for this delivery; only the registered top-row left-light pair is exported.
Mask normalization keeps broad 6px coverage clusters rather than tracing
material detail into light. Different outfits or head geometry need
matching masks. Mara's separate-light migration **#36 remains open**.

## Review and editable sources

Open `art/portraits/recruit-kit-v1/preview.tscn` and press F6.
It compares both recruits at 192px and 96px, with Light, Expression,
Condition, Outfit, Blink and Talk controls. Static expressions disable the
animation controls. This isolated review has no campaign or recruitment
logic; its phone margins are for inspection.

[Overview](../art/concepts/recruit-kit-v1/overview.png),
[animation review](../art/concepts/recruit-kit-v1/animation-preview.gif) and
[condition board](../art/concepts/recruit-kit-v1/conditions.png) are preserved.
GIF timing is rounded for review; runtime timing comes from PortraitView.

The source folder contains nine unmodified built-in **image_gen.imagegen**
masters/atlases, four exact repeated registration reference boards, and
[exact prompts/provenance](../art/source/recruit-kit-v1/generation-manifest.json).
`warden-a.ora` and `scout-a.ora` are editable OpenRaster stacks containing
the shared body/outfit, neutral head/features and hidden animation,
expression, condition and light-pass layers. Toggle one eye/mouth state
at a time; raw light masks need the documented blend strengths.

Rebuild with `tools/art/build_recruit_portraits.py` and Pillow.
It applies one common 184px full-square resize plus (4,4) inset, splits the
shared linen/neck socket, slices fixed facial regions and registers the
generated forehead dressing. Mud pigment, pallor coverage, palette and
lighting coverage are normalized during export; no replacement facial
drawings are painted by the exporter.
[asset-validation.json](../art/concepts/recruit-kit-v1/asset-validation.json)
records transforms, palettes, registration and SHA-256 hashes.

Godot 4.7.2 Mobile/D3D12 imported the resources cleanly.
`tools/art/check_recruit_portraits.gd -- --capture` verifies **424 checks**
with **24 captures**: real shared texture identity, full canvases, condition
keys, expression coverage, blink/talk playback/restoration, animation
interruption, lighting order and bounds at 1280 × 720 and 1278 × 590.
[godot-validation.json](../art/concepts/recruit-kit-v1/godot-validation.json)
records zero failures. Native and 96px views were visually reviewed.

Physical iPhone and live generated-recruit integration remain checks for
their implementation tasks. This is two faces, not #82's three per role:
Brawler portraits and additional Warden/Scout faces remain outstanding.
