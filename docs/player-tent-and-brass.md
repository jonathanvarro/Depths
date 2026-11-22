# Player tent, Reliquary brass and item briefs (#271 / #272)

Owner direction and review, 2026-11-21. The tent painting was approved as
"absolutely perfect"; a simple interaction highlight was requested. The
owner also selected Reliquary brass for menus throughout the game and asked
for fitted equipment art and simpler, consistent item information.

## Player tent

`art/camp/player-tent-v1/interior.png` is the exact approved painting: cot
left, storage chest in the middle, writing table and blank paper right.
`approval.json` pins its SHA-256. The original built-in ImageGen prompt,
reference role and retained generated-file path are in
`art/source/player-tent-v1/generation.json`. No reference-game screenshot
was copied into the asset. The style reference was this project's camp art.

`scripts/tent_interior.gd` draws the painting without stretching or cropping
it. Broad cot/chest targets support mouse, touch and keyboard. Hover/focus
adds a quiet brass outline and tint; a 120ms static press highlight provides
touch feedback before the action. Repeated activation during that brief
interval is ignored. Closing/hiding the view cancels a pending action.

`CampScreen._tent` connects Rest to the existing `CampState.rest` and Store
to the existing stash. Rest still advances exactly one morning and uses the
same healing, hunger, strain, injury, cave and service-arrival rules. Stash
Close returns to the tent, and the header Back returns to camp. The paper
is reserved for later statistics; it does not advertise an unavailable menu.
The painting remains unchanged; highlights are native drawing over it.

## Shared live menu kit

`art/ui/reliquary-brass-v1/style.gd` supplies native `StyleBoxTexture` styles
for normal, hover, pressed, pressed-hover, disabled and focus. Twelve-pixel
horizontal slices preserve the beveled corners at different button sizes.
The focus layer draws the border only. The owner's three placement shapes
are retained: flat left / beveled right, both ends beveled, and beveled left
/ flat right. Title actions use the left variant; right-hand Close/Back
controls use the right variant; other actions use the centre variant.

The exact selected SVG sources are retained in
`art/source/reliquary-brass-v1`. `tools/art/build_reliquary_brass.py` creates
300×66 native variants by changing only the SVG viewport size. The quiet
panel derivative keeps the same contours and palette while removing the
interior decoration, avoiding stretched scratches on tall modal panels.
No raster regeneration is involved. Provenance/hashes are in `catalog.json`.

The shared Field kit / `UiTheme` now styles standard buttons, ItemRow and
PrimaryAction variations, option/check controls, default panels and popups.
Specific title, camp, field-menu, hero-picker, preparation, event, results,
combat-help and inventory-detail overrides use the same family. Pack,
stash, loot, merchant and smith inherit it. The title list scrolls and
follows keyboard focus when all actions cannot fit vertically.

Physical item pockets, equipment art, enemy target tags, speech bubbles,
health/strain bars and rarity/curse frames retain their specific visual
meanings. Their action buttons use the common menu treatment. Future menu
buttons should use the shared theme or `Brass.apply`; duplicate styles as
`StyleBox`, not `StyleBoxFlat`, because the menu frames are now textures.

## Fitted equipment and item cards

The equipment grid now lives within the roll's cloth rectangle, excluding
its shadows, buckles and straps. Icon and parent clipping guard against
spillover; empty-slot glyphs stay small. On very short layouts the outer
roll/shadow is cropped to retain two full touch rows on the cloth. Existing
slot, recipient and drag/drop checks remain model-controlled.

The brief has a consistent order: name, prominent weapon damage/hit chance
or the corresponding armour/back/trinket summary, a smaller equipped-value
comparison when useful, scrollable effects/mastery/description, then actions.
There is no duplicate item picture. The redundant replacement instruction
and "Replaces [name]" line are removed from the prose. The founder-weapon
removal guard remains; its unavailable action has a short tooltip.

Numbers use the existing selected-hero helpers and `GearModel.known`, so
unidentified modifiers remain concealed and resource references are restored
after inspection. Item identities, prices, counts, growth, equipment effects,
founder/cursed-item restrictions and supply-use costs are unchanged.

## Checks and review

- `tools/tent_brass_check.gd`: 137 checks, covering shared frame/state
  contracts, all four landscape sizes at Normal/Larger, cot/chest target
  bounds, no tent scrolling, real mouse/touch input, press highlighting,
  repeated-activation suppression, one-day rest and real stash/Back flow.
- `tools/pack_brief_check.gd`: 176 checks of cloth/rare-frame containment,
  consistent visible stat headers, no duplicate image or replacement prose,
  safe cards, comparisons and preservation of the worn resource.
- Existing contextual Pack: 550 checks; combined Pack: 314 checks. Its old
  "Replaces / arrow" assertion now verifies the actual two stat rows.
- Existing journal/settings: 495 renderer-backed checks, with outputs
  redirected into ignored build output rather than overwriting prior reviews.
- After incorporating the latest main branch, the tent checks still pass;
  the renderer-backed title-fit check keeps all five desktop buttons within
  the 1152×648 window. The title also retains its scrolling fallback.
- The existing complete camp-flow check also passes with the new cot/chest
  targets, short press-feedback delay and Claude's recruitment lineup.

Native Mobile/D3D12 checks and the actual full-menu audit use the owner's
#253 private-desktop launcher. Captures include desktop and larger-text
phone views of the running game. See the review gallery under
`art/concepts/interface/tent-brass-v1`. Test saves/settings are isolated.
Physical iPhone performance and touch reach still require device review.
