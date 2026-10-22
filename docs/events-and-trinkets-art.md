# Worn trinkets and cave encounter states

Delivered 2026-10-22 for #142, following the owner's next-batch approval.
Related gameplay: #133 and #135. The normal elf pair/sprite remain in #131;
finished sound replacements remain in #96/#99.

[Offline review](../art/concepts/events-trinkets-v1/inspector.html) ·
[Overview](../art/concepts/events-trinkets-v1/overview.png) ·
[Actual phone Pack](../art/concepts/events-trinkets-v1/pack-shield-bearers-token-phone.png)

## Connected artwork

Nine designs replace borrowed icons in twelve existing trinket definitions.
Nothing changes their effects, prices, descriptions, tiers, curse discovery,
cleansing, rewards or drop rules.

| Design | Distinguishing feature |
|---|---|
| Bloodstone | Rough red charm, blackened silver claws and a short cord |
| Moth-wing brooch | Broad pewter wings with pale inlay |
| Slinger's thumb-ring | Flared horn guard and open thumb hole |
| Ember ring | Thick coal-dark iron, rusty seam and small dull inset |
| Gambler's knucklebone | Rubbed ivory gaming bone with three pips |
| Shield-bearer's token | Dented tin badge carrying the established forked seal |
| Black pearl ring | Thin silver band and one large dark pearl |
| Bone-white charm | Notched carved bone on frayed cord |
| Goblin gold torc | Heavy open collar and blunt hammered terminals |

Cursed and cleansed versions of the last three share **the same image**.
Their hidden condition is not revealed by a different thumbnail. The six
existing treasure jewellery icons are preserved. `tools/story/build_trinkets.gd`
retains these new bindings on regeneration, with the original treasure-art
fallback for other jewellery.

Runtime catalogue: [`art/items/trinkets-v1/catalog.json`](../art/items/trinkets-v1/catalog.json).
Icons are 128×128, binary alpha and at most 64 RGB colours; direct-source
compact exports are 64×64/32 colours. The inspector also shows them at 40px.
They use the existing lossless/no-mipmap import and nearest UI filtering.

## Three registered encounter pairs

[`art/props/shrine-events-v1/catalog.json`](../art/props/shrine-events-v1/catalog.json)
lists their measured scenes, sources and transforms. Each pair shares one
union crop, reduction, canvas placement, scene transform and palette of at most
64 colours. Every runtime drawing is transparent 128×128; states do not rescale
independently. The ImageGen edits preserve architectural identity, but are not
pixel-identical outside the changed subject.

| Event | Fresh → resolved | Mount |
|---|---|---|
| Defiled shrine | Dark stone and smeared niche → dull fracture, chips and scuffed sill | Wall, 1m wide; centre 0.95m above floor |
| Fouled well | Stagnant olive water → ripples, broken scum and wet rim | Floor, 1.15m wide |
| Buried cache | Closed crate caught under scree → disturbed scree and pried empty crate | Floor, 1.25m wide |

All three event resources and `tools/story/build_shrines.gd` now retain the
new scenes. During generation Claude landed `639d014`, adding `prop_on_wall`
and Main's inward-facing wall placement. This delivery uses that existing
flag for the defiled shrine, without changing Main, generation, collisions or
the ordinary miners' shrine. Both shrine scenes keep their floor origin and
their image centre at 0.95m. Well/cache use the existing Y-billboard floor prop
contract, with one shared foot pivot per pair.

The existing `closed`/`empty` state means unresolved/resolved, rather than
tracking every choice's physical outcome. Therefore the well stays murky, the
shrine is not automatically cleaned or removed, and the crate shows no reward.
The used crate means it has been worked over, including unsuccessful attempts;
it does not certify that every item was collected. More specific cleansing,
smashing or failure states would require separate outcome/state work.

No new light, animation, timer, physics object or gameplay state is introduced.
Existing state restoration handles revisits. The established forked seal is
reused as a native layer on the badge and both crate drawings; no new emblem
or lore was invented.

## Sources and rebuild

All fifteen built-in ImageGen outputs are preserved byte-for-byte in
[`art/source/events-trinkets-v1`](../art/source/events-trinkets-v1).
[`generation.json`](../art/source/events-trinkets-v1/generation.json) stores
the **exact prompt set**, image roles, original output paths and SHA-256 hashes.
The inspector exposes every original and prompt. Native seal layers retain the
original SVG path contours in `native/`; their transforms/colours are authored
by `tools/art/raster_event_trinket_seals.gd`.

The source recorder refuses to change known master hashes. The exporter only
crops, registers, reduces, quantizes and composites the native logo layers;
it never redraws generated subjects. Earlier borrowed artwork is pinned by
`preserved-art.json`; `bindings-before.json` retains the pre-art resources.
Source/review folders carry `.gdignore`.

```text
python tools/art/record_event_trinket_sources.py
Godot --headless --path . --script res://tools/art/raster_event_trinket_seals.gd
python tools/art/build_event_trinket_art.py --wire
Godot --headless --path . --editor --import --quit
python tools/art/validate_event_trinket_art.py
Godot --path . --script res://tools/art/check_event_trinket_art.gd
python tools/art/build_event_trinket_inspector.py
node tools/art/check_event_trinket_inspector.cjs
```

## Verification

- 390 source/export/binding/preservation/import checks pass. They include shared
  curse images and unchanged nonvisual fields in all fifteen definitions.
- 84 Godot checks pass, with eighteen real room/Pack captures at 1280×720
  and 1278×590. Detached Main calls verify production mount/state handling
  and restore a packed resolved map; Main's scene lifecycle and saves never run.
- 39 browser checks cover every design, small sizes, all prop states, paused
  inspection, source links, 44px controls and responsive widths of 844/390px.
- Final Godot import/render logs are clean. An initial sandboxed editor import
  lacked access to its normal editor cache; the permitted retry is clean.
- Runtime PNG canvases, including compact exports, total **1.078 MiB RGBA**
  before engine overhead. Source masters and review screenshots are additional.

Reports sit beside the inspector. Physical iPhone review is still needed.
The isolated rooms also retain the existing cave box-UV texture stretch; this
art pass does not change the world's geometry or texture mapping.
