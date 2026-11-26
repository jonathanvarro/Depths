# Quartermaster Garran and departure planning (#296)

Garran is the camp's practical supply keeper and scout contact: an older lean man with iron-grey hair, a grey moustache, an olive-brown campaign coat, keys and a battered ledger. A compact map-table station stands on the mine threshold; the separate portrait speaks through repeatable topic answers. This is an original static service character, not a recruit or an animated named companion.

## Live interface

`CampScreen` preserves the existing `cave` site ID and availability, guide target, hit area, sign, lighting and hover/focus highlight. Its label is now Quartermaster. Clicking opens `scripts/quartermaster_screen.gd`, a FieldMenu with shared reliquary-brass frames, safe-area placement and Back/Escape. No other camp site changes.

- **Supplies:** shows the current standing allowance, its items, the next permanent upgrade, exact existing gold/material costs, missing resources and maximum tier. Calls `CampState.next_issue`, `raise_issue` and `top_up_torches`; pack and tent supplies still count toward the allowance. The four unchanged tiers are Basic, Field, Full and Expedition.
- **Routes:** shows who can go, who stays with the nurse, the current quest brief, the free entrance and floors 2–4 with survey progress or per-trip price. Existing eligibility remains two expeditions reaching that floor; prices remain 20/35/50 gold. Readiness and payment remain CampState-owned.
- **Talk:** answers what Garran does, how the allowance works, how scout routes work and basic preparation advice. Topics can be repeated and add no quest flags or save properties.

The displayed gold is the camp's available pack-plus-stash balance, matching the current `CampState.can_afford`/`pay` behavior. The merchant continues buying and selling; Garran improves the standing allowance.

Choosing a route is now a free plan. Garran emits `departure_requested(depth)` to the existing `CampScreen.cave_chosen` signal. Main opens the normal preparation screen and calls `buy_route` only after **Enter the mine** is accepted. Back costs nothing. Enter rechecks eligibility and funds; if payment fails the party returns to camp with the previous expedition flag restored. This also prevents repeated route-selection fees when changing equipment or backing out. Existing save fields, scout XP, party availability, floor generation and expedition behavior remain authoritative.

## Artwork

Original unchanged PNGs, exact prompts, source output paths, dimensions, SHA-256 hashes and reference roles: `art/camp/quartermaster-v1/generation-manifest.json`. Built-in OpenAI image generation was used; the station uses Garran's portrait as identity reference and the existing merchant as style only. Runtime imports are capped at 1024/512. No source likeness, private model, new animation or external stock was added.

## Validation

Private desktop, Godot 4.7.2 Mobile / D3D12:

- `tools/quartermaster_ui_check.gd`: **205 checks, zero failures**. All four allowance tiers, insufficient gold/materials, pack/stash payment, save persistence, locked routes/progress, repeatable answers, actual mouse/touch tabs, Back/Escape, safe areas and persistent 44-pixel targets. Sizes: 1280×720, 1278×590, 844×390, 667×375, Normal/Larger text. Supply labels have explicit usable line width. Actual Main preparation checks cover cancellation, funds becoming unavailable and exactly-once entry billing from split pack/stash funds.
- Existing `tools/quartermaster_check.gd`: zero failures, including permanent issue, stash costs, opening camp and floor-size rules.
- Existing `tools/camp_check.gd` at 1278×590: zero failures, including return, recovery, services, preparation Back and re-entry.

Review: `build/local-quartermaster-v1/inspector.html`. Native captures/logs are alongside it. Tests use isolated profiles and never become the owner's foreground window. Physical iPhone and owner art review remain; no claim of source-likeness approval or new balance tuning is implied. Existing checks can print shutdown resource-leak notices; the native UI and camp runs complete without script errors.
