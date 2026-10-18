# Exploration HUD — portraits, icons and held light

Owner direction, 2026-10-17 (#62), following approval of the [Pack/hero-window study](pack-and-hero-window-design.md): replace the standard navigation's labelled Pack button with a **backpack icon just to the right of the portraits**, add a **gear icon for Settings**, and make dwindling light visible through a torch or lantern graphic.

[Standard HUD](../art/concepts/interface/navigation-v2/desktop-hud.png) · [Landscape phone](../art/concepts/interface/navigation-v2/phone-hud.png) · [Dim lantern](../art/concepts/interface/navigation-v2/desktop-oil-12.png) · [Empty lantern](../art/concepts/interface/navigation-v2/desktop-oil-0.png) · [Dwindling torch](../art/concepts/interface/navigation-v2/desktop-torch-9.png)

## Placement and interaction

The cave remains the dominant view. Keep three portrait slots low left and the existing four movement actions low right. The backpack sits immediately after the portrait group, in the same visual cluster. It opens the shared image-slot Pack directly. Clicking Mara's portrait opens Equipment; Status remains a tab in that same hero window. Empty party slots are inert and do not offer recruitment inside the cave.

Put the Settings gear in the upper-right control area beside the small map, clear of the main scene. Keep the map's familiar corner location. This study represents **ordinary cave exploration**, not the special tutorial: the opening still hides the map under #30. Do not make map availability depend only on whether the party holds a torch; torches can also be used later.

The permanent HUD backpack/gear have no text printed beside them. They retain accessible names, hover/focus labels and large touch areas. One tap opens the destination; a long press or a second tap is not required to identify it. Preserve keyboard Pack bindings (I/B) and Back/Escape. Inside a window, a short labelled Back or local destination remains useful; the owner's icon request concerns the standard exploration navigation.

Closing Pack, a hero window, Settings or Map returns focus to its actual opener. Controls is nested under Settings, so Back/Escape returns there first. Inspecting light is a small nonmodal readout; Escape dismisses that readout before opening Settings. A full window hides/disables the movement controls and ignores movement keys behind it. Settings is entered directly from the gear; this does not add a separate permanent Menu button.

## One source-aware light indicator

Use **one compact light indicator**, high left in this study, rather than separate persistent oil and torch dashboards:

| Held light | Graphic | Quantity / condition |
| --- | --- | --- |
| Lantern | Lantern frame, visible reservoir fill and flame | Oil percentage, plus Bright / Steady / Dim / Out |
| Torch | Wrapped wooden torch and dwindling flame | Remaining-life percentage, plus Steady / Dim / Out |
| None / exhausted | Unlit last-source glyph or a clear unlit state | 0% / Out; do not leave a bright flame visible |

The visible percentage makes a nearly empty source unambiguous. The physical graphic and band label also prevent colour from carrying the meaning alone. Keep the layout stable when the source changes. Lantern oil and torch life are different resources; never show a torch with an oil reservoir or imply a torch can be topped up with oil.

Tap the lantern to see oil quantity, light band and burn rate. Its **Find oil in Pack** action opens Pack with the oil flask inspected; a separate explicit use action is still required. Torch details show remaining time; the study does not add an oil-refill action to that readout. More complete light/throw/replacement actions belong to the real item flow.

For implementation, bind to **`Supplies.source`**, `oil / LANTERN_CAPACITY` or `torch_left / TORCH_BURN_TIME`, and the actual `light_band()` / `light_fraction()` values. The study sampled the existing lantern bands at one-third/two-thirds and its 0.5–1.5 oil/time burn rate. Claude's in-progress #59 adds a 50-time torch, dim below 10 remaining, steady fraction 0.55 and dim fraction 0.33; those numbers are **reference values from that implementation, not new design decisions**. A source change after throwing/burning out a torch must follow the actual fallback: lantern if carried, otherwise no light. The review can hold an exhausted torch state to compare its appearance; it does not simulate that full fallback/throw sequence.

Darken the **world view**, not the interface. Portrait frames, controls, focus rings, labels and oil/torch readouts remain legible at empty light; the cave retains a faint navigable view. The study's CSS veil illustrates the distinction rather than replacing Godot lighting. Mara's portrait still uses existing baked-lit artwork; this is not the independent character-lighting work in #36. Keep flicker restrained or omit it, and honour reduced-motion preferences. No flashing low-oil alarm is proposed.

This compact held-light readout is the owner's explicit update to the earlier supplies-in-Pack-only direction. Item stocks, food and treatment still belong in Pack.

## Review, icons and limits

The [editable interactive study](../art/concepts/interface/navigation-v2/README.md) starts in exploration and reuses the accepted Pack/Equipment/Status layout. Its optional review controls switch Lantern/Torch and adjust oil or torch life. These controls are outside the depicted game; the player does not get a fuel slider. The movement buttons demonstrate local fuel use on steps and free turns against a static captured backdrop; they do not navigate an actual floor.

Backpack, Settings and movement glyphs use the provided Lucide family. Six 32px SVG exports and an ISC notice are included for the implementation handoff; the paths are library output, with parchment stroke colour and consistent width, rather than newly drawn icon artwork. The lamp/torch meter is authored from simple CSS shapes and dynamic fill/flame state; it should become a Godot Control or equivalent component, not many large raster animation frames. The new SVGs are inside the ignored design folder: copy selected assets into the runtime UI library with the licence when integrating.

The cave is the existing #37 game capture, the rough map is the earlier illustrative map, and Mara/items/fonts are the existing project assets. The map image is not an accurate map of this captured corridor. Source paths/hashes, sources and conversion details are recorded in the study manifest. No new generated art was needed.

**419 browser assertions pass** at 1024×720, 1278×590, 736×590, 568×590 and 320×900. They cover slot/icon order, icon sizes/labels, touch targets, bounds, phone height, Pack/hero/settings/map navigation, modal movement blocking, Back/Escape/focus, lantern/refill/step readouts, all lantern bands, torch life/bands/glyph replacement, empty flames and stable UI contrast. Normal, low and empty captures were visually reviewed. The narrow stacked layout is review support, not portrait gameplay. Physical iPhone readability/performance and actual Godot integration remain to be checked.

Settings Sound and the Controls page are local presentation examples; no real audio preference is written. Hero health/status and most item logic remain demonstration data. The lantern preview copies basic burn/refill behaviour for coherent visual feedback, but is not the game's authoritative supplies implementation. Live integration stays with #51/#52/#59 and must use real party data, current item/gear definitions, safe areas, combat/input locks and the tutorial's special restrictions. This task changes no live game scripts or scenes.
