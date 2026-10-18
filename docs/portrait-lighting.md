# Separate portrait character art and lighting

**Owner direction, 2026-10-17 (#35):** lighting implied by the current portraits may not exist in the scene. Author the character and the illumination separately, so a warm lantern highlight is not permanently part of a face, hair or garment.

## Production contract

| Part | Contains | Does not contain |
| --- | --- | --- |
| Neutral character layers | Skin/hair/fabric colours, anatomy, readable form shading, local occlusion in creases and overlaps | A specific lamp's warm colour, bright rim, directional highlight or deep cast shadow |
| Directional shadow pass | Shadows from a particular light direction, including outfit-specific hood/collar shadows where needed | Identity, expression drawings, dirt or permanent scars |
| Highlight / colour-light pass | Incident light colour, lit planes and restrained highlights | Permanent material colour or facial features |
| Conditions and feedback | Blood, dirt, bandages, pallor; separate hurt feedback | Substitute lighting that makes a healthy character look sick or a dark room look illuminated |

Keep the existing **192 × 192 canvas and origin (0,0)** for every component and mask. No independent trimming/resizing. Preserve character identity, pose and facial registration while changing illumination. The neutral portrait should still look like the same person and have readable volume; “neutral” does not mean erasing all facial modelling.

An authored lighting set may need both highlights and shadows. A single translucent orange overlay cannot remove warm highlights or hard shadows already painted into a base. Merely darkening the final portrait also retains their direction and changes material colours indiscriminately.

PortraitSet now supports optional `light_shadow` and `light_highlight` textures. PortraitView's `set_illumination("neutral" | "warm" | "dim")` controls them independently; neutral is the default. Each pass is a full 192px canvas. Broad black/white coverage is stored in alpha, then tinted by the renderer. Descriptive authoring folders may differ, but the character/illumination split is required.

## Expressions, clothing and layer order

- Blink and talk drawings must also use neutral lighting. Replacing an eye or mouth must not restore a baked-in patch of lantern light.
- Lighting follows the active face and outfit silhouettes. Reusing a body template does not guarantee one mask fits every head, hair shape, hood or garment. Coordinate masks per component or validated outfit set; cast shadows must not float outside a changed collar.
- Avoid painting eyes, lips or other identity details into light masks. Prefer broad light shapes where possible; supply expression-specific corrections only where a shared mask visibly fails.
- Compose neutral character/outfit/condition layers, apply their coordinated illumination, then draw temporary hurt feedback. Keep portrait backgrounds, health bars, labels and other UI outside the character lighting treatment. Blood and bandages should receive the same illumination as the skin/clothes they cover.
- Keep strain pallor/darkening and lighting controls independent. A warm/cool light must not toggle a medical condition, and an illumination update must not erase an active condition or expression.

## Lighting states

One neutral character should support a warm lantern treatment, a subdued low-light treatment and a neutral daylight/camp treatment through separately controlled light passes. Maintain a readable ambient floor for the portrait cards so the player can still recognize faces and conditions when the world is dark.

Whether HUD lighting follows lantern oil automatically, which direction the portrait light comes from, and how camp lighting is chosen remain presentation decisions. Do not assume the 3D camera light maps directly onto a face looking slightly to one side. Start with authored lighting presets/intensity, rather than claiming arbitrary physically accurate relighting from a single 2D image. Other light directions may require their own masks.

## Existing art audit and migration

**Completed 2026-10-18 (#36):** `data/portraits/mara.tres` uses the new neutral character/tunic, neutral facial animation, conditions and coordinated masks in `art/portraits/mara-neutral-v1`. Its flat fallback is neutral too. All 27 recruit expression resources now expose their existing light masks through the same canonical fields. Originals in `mara-layered-v1` and `mara-animation-v1` are preserved. See [the implementation and visual review](playable-art-pass.md).

The renderer isolates character/outfit/conditions from the background, applies illumination, then draws hurt feedback. Reconfiguring a portrait cancels old animation callbacks. PartyCard's existing strain modulation remains a separate gameplay condition effect; it is not the illumination preset. Merchant progression sheets retain fixed warm lighting as historical concepts; camp NPC plates are neutral static art, outside this animated rig.

The source-art and renderer migration is tracked in [#36](https://github.com/jonathanvarro/Depths/issues/36). Its validation requirements were:

1. Reauthor one aligned neutral Mara master and tunic, with the baked warm highlights/cast shadows removed while retaining identity and form.
2. Bring neutral eyes, blink and talk patches into the same master; validate all replacement regions and conditions together.
3. Author matching shadow/highlight masks. Demonstrate neutral, warm and dim composites at 192px and the actual 96px card size, including a blink, talk, bandage and pallor.
4. Extend PortraitSet/PortraitView with independently controllable lighting data and composition, keeping older resources usable until migrated. Choose blends after checking the masks in the actual renderer; do not treat a filled-but-unconnected property as finished separation.
5. Verify alpha, unchanged registration, no residual bright rim in the neutral/dim view, no feature ghosts, outfit clipping, and desktop/landscape-phone readability. Connect Mara's new resource only once the complete expression/condition set works.

The original PNGs remain historical baked-light references. New resources use reauthored neutral drawings. Illumination still does not automatically follow lantern oil, camera direction or camp time. Mara supplies validated tunic and underlayer masks; arbitrary outfits or additional light directions require coordinated artwork.
