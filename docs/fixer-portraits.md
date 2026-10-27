# Fixer portraits · #163

The three live recruit portraits now follow the owner's supplied Fixer concepts:
worn burgundy brocade coats, ochre waistcoats, ivory shirts, silver hair streaks
and personable, knowing expressions. The earlier plain padded-jerkin studies
were superseded after the owner clarified the references on 2026-10-27.

[Paused portrait review](../art/concepts/fixer-v1/inspector.html) ·
[All five drawings](../art/concepts/fixer-v1/all-frames.png) ·
[96px review](../art/concepts/fixer-v1/cards-96.png) ·
[Actual phone-size renderer](../art/concepts/fixer-v1/godot-neutral-1278.png)

| Visual ID | Direction | PortraitSet |
| --- | --- | --- |
| fixer-a | Male concept: tousled dark/silver hair, moustache, pointed goatee, crooked smile and neckcloth | `res://data/portraits/fixer-v1/fixer-a.tres` |
| fixer-b | Female concept: loose bun/silver streak, appraising smile, open-neck shirt and ledger | `res://data/portraits/fixer-v1/fixer-b.tres` |
| fixer-c | Additional older male variation: silver forelock, short grey beard and relaxed smile, matching class costume | `res://data/portraits/fixer-v1/fixer-c.tres` |

These are drawing IDs, not fixed names, ages, equipment or story identities.
The existing recruit name/trait/role rules remain authoritative. The coat and
ledger are visual class cues and do not grant equipment or item bonuses.

## Integration and registration

The combined [recruit catalog](../art/portraits/recruit-roster-v1/catalog.json)
now has twelve faces, including `role: "Fixer"` and three stable Fixer IDs.
Existing `Recruits.faces_for()` / `make()` choose these automatically, avoid
faces already in use where possible, and retain the chosen resource in saves.
The Fixer's fallback now points to its own
`art/portraits/recruit-silhouettes-v1/fixer.png`.
No recruiting, prices, combat numbers or save format changed.

Each of the 48 runtime PNGs is a full **192 × 192 RGBA** canvas at `(0,0)`.
The source is registered once by resizing the complete square to 184px with a
4px inset, then reduced to a 48-colour palette without dithering. The complete
registered bust is retained; no old body or padded jerkin is substituted.

These are **Unique art rigs** (`unique-fixer-a-v1`, `unique-fixer-b-v1`,
`unique-fixer-c-v1`), because each owns its head tilt, neckline and garments.
This classification describes art registration; the game still treats them as
ordinary Fixer recruits. They remain separate from the nine reusable
`average-covered-adult-v1` faces and the three main heroes. Elf catalogs remain
independent. The shared portrait registry/paused inspector includes the Fixers.

The native drawing is split losslessly at y135 into a lower clothed `body` and
upper character `head`; this boundary is not a reusable neck socket. Complete
ocular/lip footprints are removed from the upper plate. Neutral eye/mouth
components reconstruct its original pixels exactly. Individually fitted tilted
lid paths and lip seams use the accepted #124 native texture/lip authoring
functions. Half blinks retain lower eye pixels; closed lids replace the complete
eye. Two distinct speaking drawings preserve lip, moustache and beard texture.
No other face's eye or mouth drawing is borrowed. The existing PortraitView
timing, speech pauses and filtering are unchanged.

Each has `blood`, `dirt`, `bandage`, `pallor`, plus separate monochrome
shadow/highlight coverage. The small bandage is fitted above the brows; neutral,
warm and dim presentation work in PortraitView. Masks provide broad image-left
light coverage, not arbitrary physical relighting. No worried/exhausted emotion
variants or removable clothing/underlayer are claimed.

## Sources and rebuilding

Created with built-in **image_gen.imagegen**, followed by registration, palette
export and native face fitting. The two exact owner-supplied concept files are
preserved separately in [references](../art/source/fixer-v1/references).
The owner identified them as previous generated concepts; their original
generation prompts were not supplied. Their original clipboard paths are in
the manifest, not runtime dependencies.

The three unaltered current masters, exact final prompts, input/output hashes,
reference roles and original output paths are preserved in
[generation.json](../art/source/fixer-v1/generation.json) and
[prompts.json](../art/source/fixer-v1/prompts.json). Each has an editable
OpenRaster stack. The first three plain-template masters, their prompts/export
recipe and comparison overview remain explicitly superseded; they are not live.
Both source and browser-review folders have `.gdignore`.

Run with Python/Pillow/NumPy:

```text
python tools/art/build_fixer_portraits.py
python tools/art/build_portrait_registry.py
python tools/art/validate_fixer_portraits.py
python tools/art/validate_portrait_registry.py
```

The original seven-head roster exporter now retains entries owned by later
packs. Its fixed nine-face review/fixture remains historical, with a specific
role filter; the new Fixers have their own current review and coverage.

## Verification and limits

- **768 source checks:** source/copy integrity, true alpha, exact complete-bust
  and neutral reconstruction, fixed full feature mattes, independent faces and
  palette limits. All **498 pre-existing portrait PNGs/resources** remain byte
  identical. The original 31-resource #124 preservation audit also passes.
- **476 Godot checks / 18 captures:** actual Recruits selection, no duplicate
  free face, in-memory save pack/unpack, all three real PortraitViews and party
  cards, timed blink/talk restoration, interrupted playback, four conditions,
  separate light ordering, native192/96px display and phone-shaped margins at
  1280×720 / 1278×590. Renderer/import logs are clean.
- **136 registry ownership checks**, **2,389 original recruit-art regression
  checks**, and **13 existing role-perk assertions** pass. The original capture
  report is preserved; role tests use a private save under ignored build/.
- **82 Fixer browser checks** at desktop, 844px landscape and 390px widths, plus
  **37 shared-inspector regression checks** pass. Inspectors start paused, step
  and hold exact frames, reveal the actual clean face, and decode all captures.

Source/math checks do not replace visual judgment. Owner review and physical
iPhone testing (#66) remain separate. The role/Main regression retains its
existing shutdown warnings (one CanvasItem RID / two ObjectDB instances);
isolated Fixer, original roster and registry checks exit cleanly. No player save
or preferences are changed. Concurrent campaign/story work is outside this art
delivery.
