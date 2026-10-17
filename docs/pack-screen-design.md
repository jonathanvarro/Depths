# Pack screen — Field kit refinement

The owner chose the Pack screen as the next interface design after accepting the title/font pairing (#38), and selected **Field kit** in the navigation comparison (#37). This is an editable Godot design preview for #39. The live Pack remains in `scripts/pack_screen.gd`; this preview is not connected to an expedition.

[Desktop preview](../art/ui/pack-v1/desktop-ration.png) · [Landscape phone](../art/ui/pack-v1/phone-ration.png) · [Treatment detail](../art/ui/pack-v1/phone-dressing.png) · [After use / unavailable](../art/ui/pack-v1/phone-after-use.png)

## Composition and shared roles

Keep the cave behind a quiet dark panel. Thin worn-amber edges, parchment-coloured text and a warm selected row carry the Field kit direction. Reserve rough paper for maps and documents. This pass uses flat surfaces; noisy leather/paper textures should not be added beneath reading text.

The header holds **Pack**, elapsed time and **Back**. Lantern quantity, light band and current burn rate sit above the inventory because supply decisions depend on them. The left column holds image, name and count for the four implemented supplies. The right column shows one item's effect, recipient/condition and one explicit action. There are no speculative equipment tabs, capacity slots, currency or crafting controls.

The reusable proposal is [field-kit-v1/style.gd](../art/ui/field-kit-v1/style.gd). It uses the existing bundled font resources:

| Role | Font / size in this preview | Treatment |
| --- | --- | --- |
| Page title | Cinzel 600 / 34px | Pack and later window titles |
| Item heading | Cinzel 600 / 28px | Short selected-item identity |
| Body / item row | Source Sans 3 400 / 22px | Effects and names |
| Secondary text | Source Sans 3 400 / 20px | Recovery, recipients, feedback |
| Emphasis | Source Sans 3 600 / 22px | Quantity, lantern and recipient |
| Action | Source Sans 3 600 / 24px | Back and item use |

Normal, hover, selected/pressed, disabled and keyboard-focus treatments are real Godot styles. Selection uses a filled row and an amber outline. Keyboard focus uses a separate outline, including a dark inset border on the bright action button. Do not use the widely spaced title wordmark font for item descriptions or numbers.

Desktop buttons are at least 56px tall; phone buttons and item rows are at least 72px. The phone composition reserves 97px at each side, 14px above and 35px below as simulated safe-area review margins. These are study dimensions, not a substitute for the actual device safe area and project scaling.

## Interaction and existing rules

- Opening, selecting and inspecting are free. Selecting a row changes the detail pane; using it requires the explicit action button. Routine use has no added confirmation step.
- The action displays the actual `SupplyItem.use_time`. Availability and item use call `PartyState.cannot_use_reason()` and `PartyState.use_item()`. Quantity, clock and oil refresh from the model.
- Rations feed every living hero and restore health over time; draughts automatically target the most hurt hero. Recovery also finishes at rest or when changing floors. The preview's shorter effect copy reads amount/duration from the item resource.
- Refilling retains unused oil in the open flask. A full lantern explains why refilling is unavailable. A dressing binds an existing injury until camp; it does not heal the injury.
- Depleted rows stay visible and selectable so their effects can still be inspected. The action shows the existing reason, such as **None left**, **Lantern is full**, or **No injury to bind**. After use disables an action, keyboard focus returns to its selected row.
- Back and Escape close the preview and return focus to its opener. Reopening retains selection and focuses Back. Future live integration must return to the real Pack opener and preserve the game's input/modal rules.

## Editable preview and provenance

Open `art/ui/pack-v1/preview.tscn` in Godot and use **F6**. The scene creates a disposable sample party with wounded Mara and the existing four supplies; using an item changes only that sample. F5 still opens the current game title. `preview_host.gd` owns the sample; `pack_view.gd` owns the layout.

The oil, ration and draught icons are the existing `art/items/pack-64-v1` assets. The dressing preview icon is a 64×64 RGBA LANCZOS export of the approved `art/items/starter-v1/clean-dressing.png`; hashes are in the [asset manifest](../art/ui/pack-v1/manifest.json). It is a prototype fallback for dressing only. `data/items/dressing.tres` is unchanged and still needs an icon when the live interface is integrated. No new image generation was needed.

The background reuses `art/title/title-v1/background.png`; the portrait uses Mara's current live layered set. Portrait lighting is still baked into those drawings: this work does not implement the independent lighting requirement in #36.

## Checks and integration boundary

`tools/art/check_pack_design.gd` runs against copied sample parties in Godot 4.7.2 Mobile/D3D12. It checks all four selections at 1280×720, 1278×590 and 1334×750; visible bounds, bottom inset and minimum button heights; mouse/touch event routing; free inspection; real time/count/healing/refill/dressing rules; disabled use; depletion/focus; and Back/reopen/Escape. It verifies that the hero resource is unchanged. The current [validation report](../art/ui/pack-v1/validation.json) has **1087 assertions, zero failures**; most assertions are repeated layout bounds. Desktop and phone captures include every item and the post-use state, and were visually reviewed.

This is simulated phone validation, not a physical-iPhone test. The fixed four-item list and one-Mara sample demonstrate the current start supplies; expanded inventories, a full recruited party's recipient presentation, localization and real device scaling/safe areas need review before general adoption. Add scrolling or a second detail step if future content outgrows the available space.

The shared style factory is opt-in and is not installed as the project theme. Live Pack, combat, events, title/preparation and movement code are unchanged by #39. After this design is accepted, a separate implementation task can adapt the live Pack using these roles, integrate the dressing icon, and check interactions with the actual expedition, other windows and combat input locks. Carry the same frame/type/button roles to one room-choice panel before broadening the theme everywhere.
