# Handoff Notes

Newest entry at the top. Each assistant adds one at the end of a task.

Format:

```
## YYYY-MM-DD – <who: Claude / ChatGPT / owner>
- Did: what changed
- Next: what should happen next
- Watch out: anything broken, unfinished, or surprising
```

---

## 2026-10-18 – Claude
- Did: #44 goblin fortress and queen with placeholder art: four floors (floor 3 outskirts signs and stakes, floor 4 fortress theme), the barred gate (guards' fight, stays broken across days), the queen's hall (warning, no retreat), goblin archer/guard/queen (summons, shield wall, rage, coin-flip cleaver), victory screen, 50g bounty, contracts stop, camp rumours. Tuned by simulation.
- Next: ChatGPT's #99 art (queen, archer, guard, fortress textures, gate) and #97 research; owner playtest of the full cave.
- Watch out: New enemies are tinted/scaled goblins until #99. The fortress hall is the farthest big room; areas only reachable through it stay shut until the gate breaks.

## 2026-10-18 – ChatGPT
- Did: #92 exports sixteen consistent 64px starter/copper-ore/lantern icons, wires seven live resources, and adds a 20px coin glyph. All 28 live item/gear icons reviewed at 64px/40px. #36 reauthors neutral Mara base/tunic, five registered blink/talk patches, four conditions and paired outfit light masks; original art preserved. PortraitSet/View now support independent neutral/warm/dim light without illuminating backgrounds/UI; all 27 recruit expression resources expose their existing masks through the same fields. #98 gives camp stock/sales actual thumbnails and visible affordability reasons, keyboard focus for Pack/chest, and a shared condition/inventory scroll so full-party details do not hide phone inventory. Full guide: docs/playable-art-pass.md; sources/exact built-in ImageGen prompts and editable Mara ORA preserved.
- Next: Owner can review the desktop/phone captures in art/concepts/inventory-64-v1 and mara-neutral-v1. Continue the unticked #96 backlog; held lantern/status/intent icons, camp variants, leather equipment and sound remain. Portrait illumination is explicit presentation, not automatically tied to fuel. Physical iPhone still needs testing.
- Watch out: Import, asset checks, 222 input/portrait checks, recruit kit 424 + roster 2,413 checks, camp 28, gold 24 and opening escape 30 checks pass. Combined review shutdown retains the unchanged SaveGame static script, independently reproduced with minimal Main/save cleanup and tracked as #100; standalone camp/gold/opening finish cleanly. No saving/gameplay/stat/price changes. Claude's concurrent commits and unrelated untracked script UIDs were preserved.

## 2026-10-18 – Claude
- Did: #77 coin flip: overlay with drawn coin and placeholder sound, a rare rigged strongbox event (floors 2+), goblins' rare killing blow decided by the coin (defending +20%), and the Lucky recruit strength (+10%).
- Next: decisions on #44 (goblin fortress), #83 (what unconscious means); ChatGPT's #97 research.
- Watch out: Coin art and sound are wanted (#96). The killing blow ignores a defender's guard on tails by design.

## 2026-10-18 – Claude
- Did: Owner's batch. Camp clarity (#85/#87/#88), stash-proof charity torches (#86), closed #43, full-party balance with size-aware groups (#49, tools/balance_sim.gd), any hero equips gear with before/after numbers (#67), front/back rows (#72), saving (#45: autosave on floors/camp/camp changes/close/pause, Save & exit in Pack and camp, Continue on the title; opening restarts on Continue). Research brief for ChatGPT on stats/monsters/XP (#97).
- Next: #97 research, #44 goblin fortress objective, #83 unconscious main heroes.
- Watch out: Anything new that must survive a reload needs adding to main.gd _save_now()/_restore(). Fights resumed after loading restart the enemies at full health.

## 2026-10-18 – Claude
- Did: Recruits now get ChatGPT's animated faces (#82, recruit-roster-v1 catalog, three per role, no duplicates among the fire, party and anyone at camp; silhouettes only if a role runs out). Fixed exports: export_presets.cfg now includes *.json, so the camp layout and the face catalog ship in Depths.exe (every exe since the camp was added lacked them).
- Next: rest of the owner's batch (camp clarity, #86, #43, #49, #67, #72).
- Watch out: Any new runtime JSON is exported via the *.json include filter; other non-resource files would need adding too.

## 2026-10-18 – Claude
- Did: Hooked up ChatGPT's treasure art (#90, #91): 14 new treasure items plus icons for the brooch (was "silver trinket") and coin purse; RoomEvents.TREASURE picks valuables by depth for EventOutcome.treasure; pack/stash/goblin stash/old workings use it. The opening's chest uses art/props/tutorial-chest-v1 (closed/empty).
- Next: Icons still missing for copper ore and the smith's four new weapons (#92). The coin-pile world scenes and chest.tscn wait for visible room contents (#46).
- Watch out: Values are my proposal (5-18g, rising with depth); tune by playtest.

## 2026-10-18 – ChatGPT
- Did: #91 adds the eight selected valuables: gold nuggets, silver ingot, pearl necklace, silver locket, military medal, small reliquary, fine cloth and sealed spice pouch. art/items/treasure-extra-v1 has centred 64px icons; art/props/treasure-extra-v1 has matching 128px illustrations with (64,120) contact. Its catalog.json combines all 22 treasure visual IDs, preserving the original fourteen entries/paths. docs/treasure-extra-art.md maps files/scope and links eight preserved built-in generated masters/exact prompts. Same alpha/nearest/32-colour export contract as #90; sixteen new textures total 640 KiB uncompressed RGBA. Godot 4.7.2 import and 131 checks pass with four desktop/phone dark/light renders at 64px/40px, visually reviewed.
- Next: Claude can use catalog icon paths for actual treasure definitions, using SupplyItem's TREASURE/price model and values from game data. New_ids identifies just this expansion; the combined catalog is art/items/treasure-extra-v1/catalog.json. Original #90 catalog and world props remain available. #92's remaining treasure/weapon icon integration is separate from this eight-item art request.
- Watch out: No prices, effects, loot grants, item definitions or live economy/merchant code changed; Claude's completed bbd21ce work was preserved. Medal/reliquary motifs establish no named faction, quest or magic. Locket is closed; fine cloth/spices do not add crafting/food rules. No world scale/pickup scene is assigned to these eight illustrations; use centred 64px icons for UI. Physical iPhone and actual loot assignment remain integration checks.

## 2026-10-18 – Claude
- Did: #42 gold per the owner's decisions. Prices on items/gear; treasure items (copper ore, silver trinket, old coin purse); coins in chest/rest events plus a new "Old workings" event; goblin purses; daily contracts paid at camp; merchant buy/sell and the 40g lantern; smith sells four new weapons plus the iron sword (now 3-5); stash gold; charity torches when broke and dark. The free daily top-up is gone (the free kit after the opening stays). Gold shows in the Pack, the camp and the results.
- Next: ChatGPT: icons for the treasure and new weapons (#92). Armour/shield rules before the smith sells them. Playtest the economy.
- Watch out: Gear can only be equipped by the lead hero in the Pack (recruits fight with their own stats). Iron sword buff (2-4 -> 3-5) also affects the opening; its play-through still passes.

## 2026-10-18 – ChatGPT
- Did: #90 treasure art supplies 14 transparent 64px icons: loose gold/heap, leather purse/cloth sack, three chest states, gold signet ring, amber pendant, silver brooch, garnet, emerald, amethyst and dented silver goblet. Twelve new 128px illustrations and four lit floor-centre pickup scenes live in art/props/treasure-v1. chest.tscn reuses the existing chest script and exact closed/empty textures, adding a registered open treasure drawing. art/items/treasure-v1/catalog.json maps every icon/illustration and available world scene/state; docs/treasure-art.md is the handoff. Preserved twelve built-in generated originals/exact prompts/reference hashes. Native palettes cap at 32 colours (48 for the treasure chest, with gold/red/green reserved). Export/import, hashes and 213 Godot checks pass; 20 desktop/phone inventory/cave captures reviewed, including 40px icons and dim light.
- Next: Claude can assign the catalog's icon paths to #42's actual currency/treasure definitions and room/goblin rewards. Choose the actual amount/value from game data, not the number of coins drawn. Four pickup scenes are ready for #46; chest set_state(closed/open/empty) uses open for treasure remaining. These are visuals, with no collision/collection logic. Recorded gold decisions in 4a861ca and all existing item/tutorial assets remain intact.
- Watch out: No prices, treasure values, drop quantities, stats, starting gold, item definitions or live currency/trading code changed. Jewelry art does not create wearable gear; chest icons do not imply carryable chests. Closed/empty texture paths intentionally point to tutorial-chest-v1. World illustrations keep 128px canvases and pivot (64,120); use centred 64px icons only for UI. Scenes use existing illumination and add no free light. Physical iPhone and actual loot/merchant integration remain implementation checks. New textures total 992 KiB uncompressed RGBA before overhead.

## 2026-10-17 – ChatGPT
- Did: #82 recruit artwork expands #84's shared body/jerkin to nine faces: three Warden, Scout and Brawler each, including seven new heads with mixed ages/genders/looks. art/portraits/recruit-roster-v1/catalog.json maps all nine (old two paths preserved) to flat fallbacks, neutral animated PortraitSets, static worried/exhausted expressions and separate upper-left light masks; every set has blood/dirt/bandage/pallor. All runtime layers stay 192px with origin (0,0). Preserved 28 built-in generated masters/atlases, exact prompts, 14 reference boards and seven editable 19-layer ORA stacks. Corrected generated head enlargement in four animation atlases by measured uniform registration before fixed-region extraction. Godot import and 2,413 checks pass with 24 desktop/phone captures; original kit regression also passes all 424 checks/24 captures. docs/recruit-roster.md and preview.tscn provide mapping and review.
- Next: Claude can replace #41's role silhouettes by choosing one catalog entry per recruit once, assigning hero.portrait and hero.portrait_set, and retaining its visual ID. Use explicit catalog paths: the two original resources remain in data/portraits/recruits-v1, seven new ones are in data/portraits/recruit-roster-v1. Existing PortraitView animates neutral sets without code changes. Optional lit_portrait_view.configure(id, emotion, catalog_entry) enables authored light presets for any roster entry; original two-argument kit calls still work.
- Watch out: Gameplay, recruit assignment, names/stats and Mara resources were not changed; Claude's completed #41 remains intact. Worried/exhausted expressions are static (empty blink/talk arrays). All nine share one validated clothed bust/socket, not the six proposed body families; other outfits/hair need fitting. Old Brawler scars are part of the base face, not injury rules. Authored masks support the supplied upper-left light/outfit only, not arbitrary physical relighting or automatic torch/fuel hookup. Mara migration #36 and physical iPhone verification remain separate.

## 2026-10-17 – Claude
- Did: #41 recruitment. Warden/Scout/Brawler recruits with one strength and one weakness (scripts/recruits.gd), three at the fire with one replaced each day, free hire, dismiss (not Mara), role silhouettes until #82. Heroes recovering with the nurse stay at camp and rejoin; a wipe now continues at camp (fallen and everything carried lost, stash/day/anyone at camp kept). Owner direction: torches first, lantern later as an upgrade: no camp lantern, starting/merchant supplies are 4 torches, one is lit at the cave mouth. Fixed portrait talk/blink tweens touching freed layers when party slots shift.
- Next: #42 gold (the lantern becomes something to buy); #82 portraits from ChatGPT.
- Watch out: Whether Mara can die in a wipe is still open (treated like anyone for now). Oil flasks are useless without a lantern; they're no longer handed out. Installed Pillow for the owner's Python (needed for art tools).

## 2026-10-17 – ChatGPT
- Did: #84 supplies the first reusable recruit portrait kit: distinct Warden/Scout heads on the same shared linen body/socket and padded jerkin; all layers 192px. data/portraits/recruits-v1 contains neutral animated and static worried/exhausted PortraitSets, each with blood/dirt/bandage/pallor. Optional lit_portrait_view.gd applies separate upper-left shadow/highlight masks above character/conditions for neutral/warm/dim review, without modifying existing PortraitView. catalog.json and docs/recruit-portrait-kit.md provide flat/animated mapping. Nine generated masters, exact prompts, registration boards, two editable ORA stacks, animation/condition boards and hashes preserved. Export/import and all 424 Godot checks pass with 24 desktop/phone captures and 192px/96px views.
- Next: Claude can assign the catalog's portrait_set plus flat fallback to Warden/Scout candidates during #41, retaining a stable art ID per recruit. Neutral resources animate in the current PortraitView; use the optional adapter only where separate authored light presets are desired. Expand toward #82's full roster after reviewing this shared-template proof.
- Watch out: Two faces only; #82 (three per role), Brawler and #36 Mara migration remain open. Worried/exhausted are deliberately static, with empty blink/talk arrays; no neutral animation should overwrite their emotion. All canvases/origins stay fixed. Light masks are validated only for the supplied head/outfit and upper-left direction; raw mirrored-right studies are source only. No names/stats, fears, live recruit wiring or recruitment rules changed. Physical iPhone remains untested. Claude's ongoing recruit/party/camp/code changes and silhouettes were left untouched.

## 2026-10-17 – Claude
- Did: #40 first campsite. CampState (day counter; rest = full health/strain, +1 day, cave re-seeded; nurse treats injuries -> hero out for Injury.recovery_days (deep wound 2, limp 1), optional; merchant tops the pack up to starting supplies once a day, free; tent stash) and CampScreen using ChatGPT's cave-camp-v1 clearing, site scenes, NPC portraits and layout.json. Flow: results -> camp -> cave path -> preparation -> floor 1. Removed the automatic camp heal. tools/camp_check.gd covers every place at desktop/phone sizes; opening play-through now passes through the camp.
- Next: Owner playtest of the camp; recruitment at the fire (#41); gold and the merchant/smith (#42).
- Watch out: Wipes still reload the game, so the stash only matters once #41/#45 exist. The smith shows stock only. When recruits exist, recovering heroes must stay at camp while others go (CampState.available()); the cave path only checks that someone is fit.

## 2026-10-17 – ChatGPT
- Did: #78 supplies the cave campsite art: 640x360 empty clearing, six separate 256x192 destination layers/ground-origin 2D scenes and 192px merchant/apprentice/nurse portraits in art/camp/cave-camp-v1. docs/campsite-art.md maps stable IDs, sources, contacts, neutral-lighting scope and integration. Preserved ten generated masters/exact prompts, palettes/hashes and native boards. Export/import checks and all 217 Godot checks pass, with 15 captures at desktop/two phone shapes. Fire reuses #63's flame resource; hidden/reduced-motion presentation is supported. Recorded the owner's disrupted royal deployment story while keeping its cause unresolved.
- Next: Claude's #40 can map each independent layer to its six existing camp anchors and use the portraits in service views. Follow current DESIGN.md #40 decisions for rest/day/treatment/services. Gate site art and its input together under the real camp availability model when #79/#80 is implemented.
- Watch out: Art/isolated review only; no live camp, stock, gold, service or arrival-day logic changed. The review shows all six areas and opens art-only views. NPCs are static neutral character plates, not layered blink/talk rigs or complete directional-lighting sets. Blue/ochre crown cloth and apprentice/nurse appearances are visual proposals; names/final heraldry are open. Physical iPhone remains untested. Claude's current campsite decisions and other work were preserved.

## 2026-10-17 – Claude
- Did: #65 measured the stair trick (same healing for 3 time instead of 21) and, per the owner's choice, made changing floors spend the time remaining on pending effects before finishing them (PartyState.remaining_effect_time()). Stairs now take 22 time against 21 for resting; resting still eases strain.
- Next: Milestone 3 is clear; milestone 4 starts with the campsite (#40).
- Watch out: The waiting happens on the first floor change after drinking; the arrival message mentions it.

## 2026-10-17 – ChatGPT
- Did: #75 supplies abandoned pack / searched pack, pale idol, still pool and cold campsite art. Five transparent 128px exports and reusable scenes are in art/props/cave-room-props-v1; full event/resource mapping and placement/state contract are in docs/cave-room-prop-art.md. Exact built-in image_gen prompts, source masters, palette/registration/hashes, dark/light boards and 20 normal/dim cave captures are preserved. Export checks and all 85 Godot 4.7.2 checks pass at desktop/landscape-phone sizes.
- Next: #46 should choose props by actual event resource identity and wire the pack's set_searched(bool) to a resolved search. Put the small idol on a niche support surface; keep the pool horizontal on the existing floor. Runtime scenes are ready; live placement remains separate.
- Watch out: Cold camp emits no light and is distinct from a lit/recruitment campsite. Pool is opaque water, not a descent pit. No loot, healing, time, collision or event mechanics changed; inspecting/leaving/prodding alone must not mark a pack searched. Source/review folders are excluded from runtime import. Physical iPhone and live placement/visibility still need integration checks. Claude's latest combat commit and notes were preserved.

## 2026-10-17 – Claude
- Did: #60 decisions recorded (DESIGN.md; follow-ups #72 rows, #73 decide before a fight, #74 light as a weapon) and the first combat pass: enemy intentions (action, not target) shown on each enemy's tag; goblin heavy blow (x2, fully blocked by Defend, never twice running); rats show "darting back" before fleeing; spiders may re-web. Retuned rat/spider/goblin to about 2/3/4-5 rounds for lone Mara.
- Next: Owner playtest of fight feel; rows (#72) once recruits (#41) exist.
- Watch out: Intents are planned at fight start; code that changes a foe afterwards (as the opening does for its spider) must call CombatState.plan(foe). Scratch tactics test updated for intents (not in repo).

## 2026-10-17 – ChatGPT
- Did: #70 supplies the requested opening art set: transparent 64px broken knife and damaged padded-armour icons, plus three registered 128px wooden chest states (closed / open with supplies / empty). The knife Equipment resource now uses its broken icon without stat changes. art/props/tutorial-chest-v1 includes state-selectable Godot scenes; docs/opening-tutorial-art.md has the full handoff. Generated masters/exact prompts, native/enlarged comparisons, shared chest palette/registration/hashes and 12 normal/dim cave captures are preserved. All five exports/imports and 51 Godot checks pass on desktop/landscape-phone shapes.
- Next: Replace Main._add_chest's placeholder using scene.tscn/set_state through the visible-contents work. Its existing opened=true means emptied, so select empty; use open explicitly for supplies remaining. Armour has no actual equipment definition yet and stays an art asset. Owner also requested abandoned packs, idol, pool and cold campsite remains as the next prop set.
- Watch out: Three static chest drawings, not a lid-opening animation; shared floor pivot (64,120), one scale and 32-colour maximum. No collider, light, loot or armour mechanics added. Open artwork illustrates the existing draught/dressing rewards rather than exact quantities. Source reference items unchanged; only the broken knife's icon path changes in existing game data. Physical iPhone/actual chest placement remain integration checks. Claude's #69/#71/combat work and its notes were preserved.

## 2026-10-17 – Claude
- Did: #71 bleeding feedback. Each bleed tick: red edge vignette flash (stronger at low health, strongest early on the first) plus a generated heartbeat (tools/make_placeholder_audio.py, heartbeat.wav), more and faster beats as health drops. Below half health while bleeding the edges stay dark between ticks; clears when bleeding stops. Main.screen_flashes turns the flash off (for #52). Play-through checks the ticks, the darkening and that it clears.
- Next: #60 combat design discussion.
- Watch out: The vignette sits under the HUD, so translucent buttons pick up a red tint during a flash. Regenerating placeholder audio leaves the older files byte-identical.

## 2026-10-17 – Claude
- Did: #69 opening polish from the owner's second playtest. Slower wake with lingering blinks; Mara starts 10/20, bleeding (card icon), empty-handed, only her card shown. Bodies/fire/chest are solid (walk into them). Hints are centred cards (act / pack-gated pause / ok pause). The opening maze has a first stretch closed by a second web; fights start after it. A chest after fight 1 (a niche cut beside her if possible, else the nearest dead end ahead; placeholder box) opens a new drag / tap / take-all chest window with a restorative draught + dressing, then a draught card. The torch doesn't burn down in the opening; she trips after fight 2 and relights the spare. The spider's blows glance (no health shown); the throw is taught after a swing and forced at 4 health. Daylight walls off side passages. Many new Mara lines. Camp restocks starting supplies.
- Next: ChatGPT: broken knife icon, broken armour, chest art (see #69). Owner playtest of the rebuilt exe.
- Watch out: The chest window is only used by the opening's chest so far; floor chests still use event choices. The opening no longer gives starting supplies until camp. Old scratch opening tests (step-based fights, burn-out) no longer apply; tools/opening_playthrough.gd is the scripted play-through (args: tag, screenshot dir, seed, optional "force").

## 2026-10-17 – ChatGPT
- Did: #68 generated rough wood/soot-darkened cloth torch art. art/items/pack-64-v1/torch.png is a transparent 64px icon connected to data/items/torch.tres; Pack supply rows now draw their existing optional icons in 40px slots (matching gear), so the torch and earlier supplies appear. art/props/torch-v1 supplies a neutral 128x256 body and reusable Node2D held.tscn with steady/dim/unlit states, sharing the campfire's six-frame/8fps flame resource unchanged. Master/exact prompt, export checks, GIF and desktop/phone cave/Pack captures are preserved in art/source/torch-v1 and art/concepts/torch-v1.
- Next: Claude can instance held.tscn and feed apply_supplies on Supplies.changed through #51/#59. Pack icon integration is live; held-art placement is a review example only, not added to Main/Party. README gives exact paths, canvas/root and source/fallback contracts. Keep world lighting with the existing party light.
- Watch out: No burn time, stock, throw/flee or movement changes. The real model drives dimming and removes held art after burnout/throw/fallback; animation itself consumes no resources. New body/icon textures total 144 KiB uncompressed, plus the shared existing flame texture. Asset checks/import pass; Godot model/UI/capture checks cover two viewport shapes. Phone means a Windows landscape preview, not a physical device test. Pack remains the current labelled-row implementation; the image-slot redesign is separate. Sample screenshot inventory is not a starting grant.

## 2026-10-17 – ChatGPT
- Did: #63 generated a simple maze campfire: neutral stone/log base plus six registered flame frames at 128px, 8 fps (0.75s loop), separate lit/unshaded layers, warm light pulse and a camera-facing Godot scene in art/features/campfire-v1. Sources/exact prompts are in art/source/campfire-v1; GIFs, frame sheet and cave/opening captures are in art/concepts/campfire-v1. Export checks pass; Godot imports cleanly, 8 scene/autoplay checks and 8 live-opening checks pass; 17 renderer captures at desktop/landscape-phone sizes include angled/distant/four-direction views and every flame frame. Corrected the initially dark base by rotating the complete prop and its slightly offset light together.
- Next: The scene is ready and already picked up by Claude's f7c522a Main.fire_scene_path hook in the opening room; no Main edits were needed. Additional maze locations/room-state integration stay with #46, and camp services with #40/#41/#43. README explains the floor pivot, animation, cold-firepit state and rebuild/check steps.
- Watch out: Visual-only asset; no recovery, rest, fuel or checkpoint mechanics added. Base uses 20 colours, all flames share 10; transparent nearest-filtered textures total 448 KiB uncompressed before engine overhead. Shadow-free light may spill through nearby walls, and the opening has Claude's separate room-fill light. Physical iPhone/multiple-light performance remains untested. Cave GIF holds light energy steady to show frame registration; the live scene pulses gently. Existing game scripts/events and Claude's concurrent work were preserved.

## 2026-10-17 – Claude
- Did: #58 + #59 torch tutorial, per the owner's flow on the issues. Equipment resource + data/gear (broken knife, iron sword); Companion.weapon drives attack; Pack has a Gear section with Equip/Drop and a light section for lantern/torch/none. Supplies.Source (lantern/torch/none), torch burn (50 time), light_torch/lose_torch; torch supply item; Throw torch in combat (target flees). Opening: no lantern, fire placeholder (emissive embers + flickering light), searchable bodies (data/events/opening_body_*.tres, min_depth 99 so never random), too-dark gate (Party.step_check/refused), state-driven tutorial hints (search -> equip -> drop -> light), burn-out hint, fight-3 spider bites first (no web) then throw hint, panic when the last light is gone, daylight 10 steps after the last fight. Camp gives a full lantern. New Mara lines (too_dark, search_body, torch_lit, torch_out, throw_torch). Clean dressing got ChatGPT's icon.
- Next: #60 combat discussion; campsite (#40).
- Watch out: Torch art is missing (no icon; the held torch uses the lantern light). The fire uses ChatGPT's art/features/campfire-v1/scene.tscn when present (it was uncommitted when I committed), placed in the room's far corner with a fill light mid-room; otherwise placeholder embers. Fixed-attack tests must clear Companion.weapon now.

## 2026-10-17 – ChatGPT
- Did: #62 simplified standard exploration navigation around the accepted Pack/hero study: backpack icon immediately right of portraits, Settings gear near the map, and one source-aware lantern/torch readout. Lantern shows reservoir/oil; torch shows remaining life/flame; band/percentage stays legible while only the cave darkens. Interactive source/review, six Lucide SVG exports with ISC notice, reused-art/font manifest and normal/low/empty captures are in art/concepts/interface/navigation-v2; guide is docs/exploration-hud-design.md. Browser checks: 419 passing assertions, no runtime errors across desktop, landscape phone, compact/small and narrow review shapes.
- Next: Claude can implement through #51/#52/#59 using actual Supplies.source, current oil/torch values, existing safe areas and input locks. Guide records the new compact HUD light exception to supplies-in-Pack-only, plus opening/no-map and torch fallback requirements. SVG exports can be promoted into the runtime UI library with their licence; the light meter should be a scalable Control.
- Watch out: Design only; no live game scripts/scenes changed. The browser uses a static cave capture and local demonstration data; settings do not write real preferences. Torch values were sampled from Claude's in-progress #59 and are not new tuning decisions; its exhausted-state review does not auto-fallback to a lantern. Actual opening/combat item restrictions and post-torch source changes must come from the live model. Map art is illustrative; Mara's baked lighting still needs #36. Physical iPhone remains untested. Claude's ongoing gear/torch/combat work was preserved.

## 2026-10-17 – Claude
- Did: #56 opening polish from the owner's playtest: opening_generator.gd is now a Prim's maze (about 130 junctions, 100 dead ends, a few loops) around the bodies room, with a web across the doorway; fights by distance walked (20/44/68 steps, a retreat brings it back 8 steps later); daylight after all 3 fights at <= 3 health (or 130 steps); wake-up pan with eyelids; slower movement (Party.move_time/turn_time) and a slower web push (Party.TEAR_TIME); blood/dirt portrait overlays (Companion.appearance) and strain held (Companion.strain_locked) until panic after fight 2 with a hint; "Barely survived" brief results (ResultsScreen.show_brief) then camp; small spider weakened to 3 health. #57 hero dialogue: DialogueLines resource + data/dialogue/mara.tres (12 situations), DialogueBox above the cards, main.gd `_say()` with cooldown and once-only lines, wired to opening beats and general events.
- Next: #58 tutorial weapon, #59 torch, #60 combat discussion.
- Watch out: Fight 3 is still ~7 rounds because panic cuts her hit chance and damage; that's for #60. Dialogue lines are first drafts for the owner to edit.

## 2026-10-17 – ChatGPT
- Did: #61 revised Pack to image-only slots with quantity badges and hover/focus or pinned click/touch details. Added an interactive Equipment/Status hero-window study: Equipment on open, portrait selection switches hero, active tab retained between heroes, explicit use/equip/unequip, Back/Escape and focus return. Source, self-contained review, reused-art/font manifest, 16 captures and validation are in art/concepts/interface/pack-heroes-v2; guide is docs/pack-and-hero-window-design.md. Browser checks pass: 146 assertions, no runtime errors at desktop, landscape phone, compact and narrow review widths. Bundled fonts use lossless WOFF container compression with OFL notices; existing TTFs unchanged.
- Next: Owner reviews the revised Pack and hero window; Claude can integrate through #48/#51 using real inventory/party data, Godot safe areas and existing input/opening restrictions. Current layout decisions are linked in DESIGN.md; the old Pack guide points to the revision.
- Watch out: Design study only; no live Pack/card/model changes. Twelve bag cells/six equipment categories are visual examples, not carrying/equipment rules. Hero II/III are example companions; demo stock is not a starting inventory grant. Browser actions change local counts/loadouts only; health/lantern readouts are fixed samples, not full supply simulation. Narrow stacking is review support, not portrait gameplay; physical phone remains untested. Mara still uses existing baked-lit art (#36). Claude's ongoing opening/camera/party changes were preserved.

## 2026-10-17 – Claude
- Did: #30 opening escape, per owner decisions recorded on the issue. opening_generator.gd: 4x3 bodies room + one winding one-tile hallway (178-225 tiles) with 2 webs and fights at 10/22/34. main.gd "Opening escape" section (floor 0): no minimap/map, Panicking without bolting, faces east with ChatGPT's fallen-a/fallen-b in view (loaded only if present; placeholder otherwise), bleeding 1 per 12 time, min health 2, daylight 4 tiles ahead once health <= 3 and >= 2 fights, just-in-time hints (keyboard vs touch wording), results note "alone", then expedition 2 at generated floor 1. Gentler starved_rat/small_spider data. Companion.min_health added. Simulated 400 escapes to tune; scripted full play-throughs on 4 seeds pass (2-3 fights, 29-42 steps, health never < 2). Updated older tests to set play_opening = false where they test deaths/endings.
- Next: Milestone 4 (campsite #40 etc.).
- Watch out: Bodies use ChatGPT's art/props/opening-bodies-v1 (#55) via `body_scenes`; missing files fall back to a placeholder shape. The bodies read darkly at the lantern's edge; worth a look in play.

## 2026-10-17 – ChatGPT
- Did: #55 supplies the fallen companions needed by #30. art/props/opening-bodies-v1 has two distinct transparent 128px oblique lying-body sprites, a shared 32-colour palette and ready floor-origin Node3D scenes fallen-a.tscn / fallen-b.tscn. One lit, fixed-Y Sprite3D per body; no collision, script or animation. Built-in image_gen studies/final masters/full prompts, deterministic exporter, registration/hashes and cave/phone/dim review captures preserved. Godot 4.7.2 import + 52 scene/material/orientation checks pass; image/palette/hash checks pass.
- Next: Claude can assign res://art/props/opening-bodies-v1/fallen-a.tscn to main.gd body_scene immediately, or choose A/B per index in _add_opening_dressing() to show both. README provides exact paths and scale/pivot/lighting guidance. Check actual initial facing, body yaw, HUD overlap and visibility while completing #30.
- Watch out: Assets only; Claude's current opening code, small enemy resources and main scene were left untouched. Root belongs at floor Y=0; child Sprite3D stays upright and camera-facing with a pre-drawn lying pose, not rotated flat. Shared contact (64,120), pixel_size 0.015625, sprite Y=0.875. Earlier top-down studies are source only; no relief mesh ships. Phone render is simulated; #30 remains open for the tutorial implementation.

## 2026-10-17 – ChatGPT
- Did: #39 refined the owner's selected Field kit direction into an isolated interactive Godot Pack preview at art/ui/pack-v1/preview.tscn, using the accepted Cinzel/Source Sans pairing. Includes four actual supplies, selection/details, lantern quantity/light/burn, recipients, explicit time costs, disabled reasons, feedback and Back/Escape/focus return. Opt-in styles are in art/ui/field-kit-v1; desktop/phone captures, provenance and docs/pack-screen-design.md preserve the design. Existing PartyState rules run on copied sample parties. Godot 4.7.2 import and 1087 layout/interaction assertions pass at desktop and two simulated phone sizes; captures reviewed.
- Next: Owner reviews the Pack; a separate implementation task can adapt scripts/pack_screen.gd, apply the shared roles to one room-choice panel, and connect the dressing icon. Title/type pairing and Field kit selection are now recorded in DESIGN.md and their guides for Claude.
- Watch out: Live Pack and gameplay unchanged; F6 on preview.tscn opens the sample. Clean dressing's 64px RGBA export is a prototype fallback only; data/items/dressing.tres still has no icon. Physical iPhone, expanded inventory/full-party presentation and localization need later checks. Existing portrait lighting still needs #36. Claude's title/preparation and opening-design work was preserved.

## 2026-10-17 – Claude
- Did: Owner playtested the Windows build and met no fights: encounters were one invisible tile per room, crossed by the direct climb on ~12% of floors. Per owner, a fight now fills its room: generated layouts mark room floor with ',' (corridors stay '.'), DungeonMap.room_around()/encounter_zones map every room cell to its fight, and main.gd starts the fight on entering any of them. The survivor's waking room never gets contents; retreat lands outside the fight's room. Direct climb now meets a fight on ~33% (deepest) / ~55% (middle) floors. Zone + all suites pass; rebuilt build/windows/Depths.exe.
- Next: #30 opening; contents still have no visuals (ask ChatGPT for chest/idol/pool/camp props and visible enemies if the owner wants them later).
- Watch out: Hand-drawn layouts using only '.' have no rooms, so their fights stay single-cell (fine for the debug map).

## 2026-10-17 – Claude
- Did: #19 Windows build. export_presets.cfg "Windows Desktop": single embedded-pck build/windows/Depths.exe (~130 MB, ~109 MB of it the engine), excludes art/source and tools. Copied the exe to a folder with no project and ran it: title and dungeon both start on D3D12 with no errors, and room events load (RoomEvents now errors if the folder is empty). Title screen accepts `-- --begin` to skip straight in, for checking builds. Steps in AGENTS.md "Building for Windows".
- Next: #20 iPhone export (needs a Mac), #30 opening.
- Watch out: Unsigned exe → SmartScreen warning for players. Not yet run on a second PC; no Windows icon set (application/icon empty; needs an .ico).

## 2026-10-17 – Claude
- Did: #18. Title screen (scenes/title.tscn, now the main scene) built from ChatGPT's title-v1 study and font roles: Begin expedition (loads main.tscn), Settings disabled ("coming later"), Quit desktop-only, safe-area margins, keyboard focus. Preparation screen (preparation_screen.gd) shown before expeditions 2+ after the placeholder camp stop: party cards, condition and injuries, lantern, pack with item icons, Enter the cave. Moved safe-area maths to scripts/safe_area.gd. Title/prep checks + all suites pass on desktop and simulated iPhone.
- Next: #30 opening escape; campsite. ChatGPT: clean dressing still has no pack icon (data/items/dressing.tres `icon`).
- Watch out: Fonts are applied only to title and preparation screens; a shared theme waits for the owner's typography decision. F5 now opens the title; F6 on main.tscn skips it.

## 2026-10-17 – ChatGPT
- Did: #38 created art/title/title-v1: generated text-free cave title backdrop, optional Godot preview scene, desktop/landscape-phone title captures and a type-role specimen. Proposed actual Cinzel 600 title/headings + Source Sans 3 400/600 body/actions, with unmodified official-distribution fonts, OFL notices, provenance/hashes and reusable FontVariation resources in art/fonts. Direction and integration limits are in docs/title-screen-and-typography.md, linked from DESIGN.md. Godot import and 168 font/glyph/layout/target checks pass.
- Next: Owner reviews title/type pairing; Claude can reuse the four art/fonts/*.tres roles when implementing #18 and a shared interface theme. Preserve the separate backdrop and live text; implement real title/settings/navigation separately. Validate fonts at actual phone size and against all localization strings before general adoption.
- Watch out: Main scene and existing UI fonts/flow unchanged; preview buttons are intentionally inert. Depths remains the working title; no Continue/save system implied. Phone capture is simulated, not physical-device validation. Use numeric wght tag 2003265652 in these FontVariation resources: string keys rendered the wrong weight in this project and were corrected before captures. Existing portrait-lighting migration remains #36.

## 2026-10-17 – ChatGPT
- Did: #37 brainstormed a shared navigation/menu language in docs/navigation-interface-design.md and linked it from DESIGN.md. Supplied two interactive in-chat alternatives: Field kit (floating exploration controls/dark panels) and Field journal (persistent tabs/paper windows), each with Pack/item selection/action window, map, Mara review, menu/Controls and hierarchical Back/Escape. Review stills, reused-art provenance and validation are in art/concepts/interface/navigation-v1; no live game scripts changed.
- Next: Owner compares directions; recommended starting point is Field kit's quiet exploration frame with parchment reserved for maps/documents. Theme exploration, Pack and one room-choice panel together after choosing; guide defines materials/type, reusable window roles, navigation vocabulary, focus return, input and phone checks.
- Watch out: These are code-authored browser concepts using existing project art, not final UI assets or a Godot implementation. All 8 variant/width combinations (1024/736/568/320) passed the visited-screen layout/navigation checks, including Back/Escape/focus and variant switching; no physical-phone test. The narrow stacked review is not portrait gameplay. Party review entry, generic item confirmation and styling remain proposals; samples do not add lore/balance rules. Mara's independent lighting migration remains #36.

## 2026-10-17 – Claude
- Did: #17 expedition outcomes. expedition.gd records each expedition (start snapshot + counters for floors, enemies, retreats, events, loot via RoomEvents.loot_found) and builds gained/lost lines; results_screen.gd shows them. Endings: floor-1 way up asks to leave (RETURNED); last hero falling in combat or outside it (WIPED, "Begin again" reloads); on expeditions 2+, entering the deepest floor's 'S' cell asks to end there (REACHED_BOTTOM). New expedition: placeholder camp stop (full health, strain -40, hunger 0, injuries kept), re-enter floor 1, floors cached. 17 outcome checks + all suites pass at desktop and iPhone sizes; verified restart with the real current scene.
- Next: #18 title screen and preparation, #30 opening, campsite (ChatGPT's design) replacing the placeholder camp stop.
- Watch out: "Reached the bottom" is a stand-in objective. Untracked art/concepts/interface/ is ChatGPT's; left alone.

## 2026-10-17 – Claude
- Did: #16 room events. Data-driven RoomEvent/EventChoice/EventOutcome resources in data/events (8 events: abandoned pack, goblin stash, tripwire, hollow floor, pale idol, still pool, dry alcove, old campsite); room_events.gd picks by kind and depth and resolves outcomes (health, delayed heal, strain, injury, oil, loot, rest, ambush); event_screen.gd shows clue, choices and an automatic "Leave it" (keeps it for later). Replaced the placeholder trap and rest prompt. Generator content mix now varies by depth (walls unchanged). 22 event checks + all earlier suites pass at desktop/iPhone sizes.
- Next: #30 opening escape, or Milestone 3's #17 outcomes.
- Watch out: Outcomes affect the party's first living hero ("whoever acted"); choosing who acts comes with recruits. Rewards are supplies only until gold/treasure exists. Left ChatGPT's uncommitted edits (DESIGN.md, NOTES.md, docs/*, portrait README) unstaged; my doc additions were staged on top of HEAD.

## 2026-10-17 – ChatGPT
- Did: #35 recorded the owner's requirement to separate portrait character art from lighting in docs/portrait-lighting.md; updated DESIGN.md, merchant guidance and Mara's prototype README to remove the assumption of permanently fixed lantern light. Audited the actual PortraitSet/View, PartyCard and Mara resource: character, tunic and expression drawings currently contain baked illumination; no independent lighting pass exists yet.
- Next: #36 tracks reauthoring a neutral aligned Mara master/tunic and neutral blink/talk patches, supplying coordinated shadow/highlight masks, then extending the renderer and verifying neutral/warm/dim composites with conditions/outfits at 192/96px. The guide gives the layer/registration contract, migration sequence and validation criteria for Claude and future art generation.
- Watch out: Design/production rule only; existing PNGs, live portraits and gameplay are unchanged. This is not a claim that lighting was extracted. Preserve local form/occlusion, keep light masks compatible with active expressions/clothing, and retain readable UI in darkness. Automatic lantern-to-portrait mapping remains undecided. Claude's encounter changes remain untouched.

## 2026-10-17 – ChatGPT
- Did: #34 recorded the owner's rough-paper, hero-drawn map direction in docs/hand-drawn-map-design.md, linked from DESIGN.md. Generated art/concepts/map/hero-map-v1.png with the built-in image tool; full prompt/provenance saved beside it. Proposed charcoal contours without visible cell squares, sparse rock hatching/notes, distinct discovery symbols, a quiet parchment centre and a simpler corner-map version. Checked image integrity/source-copy equality and local documentation links.
- Next: Owner reviews the visual direction; a later renderer task can build continuous outlines from explored grid data with stable small line variation, preserving reliable connections, scale, facing and discovery. Guide includes phone readability checks and implementation boundaries.
- Watch out: Concept/design only; scripts/minimap.gd and live UI are unchanged. Mockup is illustrative, not an actual seed or complete symbol set. Labels/Close must be real UI with safe-area/touch sizing; texture and handwriting must not obscure routes. Ongoing Claude encounter changes remain separate.

## 2026-10-17 – Claude
- Did: #15 distinct tactics. EnemyType gained `tactic` and `intro`; combat_state.gd implements darting rats (target weakest, may flee when hurt; all-fled = victory), web-and-venom spiders (opening web -25% next action, 2-turn non-stacking venom ticking at turn start via `events`, ignore defenders), cunning goblins (flank non-defenders, shield when hurt halving damage until their next turn). Combat screen shows intros, venom events, webbed/poisoned in the turn line, [shield] on tags, fades fleeing enemies. ENCOUNTER_GROUPS mix tactics by depth, capped at party size. 18 tactic checks + balance sims pass; all earlier suites pass; in-game fights verified with ChatGPT's new cave-simple-v1 sprites.
- Next: #16 room encounters (chests, traps, strange objects, rest spots with choices and clues) or #30 opening.
- Watch out: A full healthy party of three wins everything; tune when recruitment/equipment arrive. Spiders are the deadliest single enemy for lone Mara (74% win).

## 2026-10-17 – ChatGPT
- Did: #33 completed all nine simpler rat/spider/goblin sprites in art/enemies/cave-simple-v1, using the goblin study's style. Exact 128px transparent canvases, one shared <=32-colour palette per enemy, pivot (64,120), common pose scale and planted ground y=120. Added ready-made SpriteFrames/scenes; changed only the scene paths in data/enemies/{rat,spider,goblin}.tres to connect them to Claude's combat. Full prompts/raw sources in art/source/enemies-simple-v1; exporter, registration/hash report, native/2x sheets and six real combat captures included.
- Next: Claude can use these immediately; art/enemies/README.md and art/enemies/cave-simple-v1/README.md list exact paths and the Sprite/idle/attack/hurt contract. New enemy families should follow docs/enemy-art-direction.md. Continue #15 tactics independently; no art changes to combat rules or stats.
- Watch out: Detailed cave-v1 and the original study are preserved. Godot 4.7.2 import and 63 resource/real combat pose/fade checks pass; desktop and simulated landscape-phone captures reviewed. No full animation cycles or physical-iPhone validation. Claude's ongoing tactic/intro changes in EnemyType and enemy definitions are separate work and must remain untouched by this art commit.

## 2026-10-17 – Claude
- Did: #14 combat prototype using ChatGPT's enemy art and #13 layout study. Rules in combat_state.gd (initiative order, attack with light/strain-adjusted hit chance, defend halves damage and draws attacks, combat-only items, retreat trial, enemy injuries, 1 time per round); UI in combat_screen.gd (log, tappable enemy tags, action panel replacing the pad, gold turn marker on cards); EnemyType data for rat/spider/goblin. Lone-survivor balance: groups capped at party size; injury chances lowered. 13 rule checks, 6000 simulated fights, in-game win/retreat/defeat via buttons at desktop and iPhone sizes, and all earlier suites + ChatGPT's 51 art checks pass.
- Next: #15 distinct enemy tactics (and deeper-floor combinations); ChatGPT's simpler enemy redraw (art/source/enemies-simple-v1, uncommitted, left alone) can replace the sprites via EnemyType.scene.
- Watch out: Goblin is still ~31% lethal for lone wounded Mara; #30's opening should choose its encounters deliberately. No enemy death animation yet (fade out).

## 2026-10-17 – ChatGPT
- Did: #31 art handoff in art/expedition-v1/README.md: aligned 192px Mara blink/talk/condition layers assigned in her PortraitSet; cave-specific 64px surfaces and five transparent 256px feature scenes assigned in the cave theme; three 64px Pack icons assigned to items; nine registered rat/spider/goblin poses with ready-to-use scene/SpriteFrames resources. Added desktop/phone combat presentation studies for #13. Preserved generated masters and full prompts under art/source; deterministic export scripts and validation reports included. Godot import succeeds; 51 resource/live portrait checks pass.
- Next: #32 docs/enemy-art-direction.md records the owner's simpler-enemy direction, proposed 128px/32-colour/three-pose contract and reusable generation rules. Review art/enemies/style-study-v1/comparison.png: new goblin redraw uses 24 colours, exact 128px transparent canvas and pivot (64,120). After review, rebuild the complete enemy pose families to match; Claude can use the current art resources immediately while implementing #14 combat.
- Watch out: Detailed 256px enemies are preserved exploration/integration starters, not the final lower-detail style; the study does not replace them. Numeric style limits await owner review. Combat images are static; no combat logic/stats changed. Texture UV stretching, fine web readability and real-device phone checks remain production follow-up. Claude's strain commit is preserved; pallor now has actual art. Original Mara layers and approved item masters remain unchanged.

## 2026-10-17 – Claude
- Did: #12 strain per owner (time, darkness, lost health, injury, hunger -> panic, lost effectiveness). scripts/strain.gd holds rules/numbers; Companion gained strain + hunger; PartyState ticks them per time unit with the lantern band; rations reset hunger; rest relieves. Panic: party.gd bolts in a random open direction (15%/step). Card: strain bar, state-coloured border, darkening, pallor overlay (uses ChatGPT's new mara-animation-v1 art when its portrait set is committed), tremor. Messages on state changes. All suites pass (strain 20 checks; reran party, cards, injuries, supplies, opening, doors, map).
- Next: #14 combat (attack/defend/item; effectiveness() ready to use). #30 opening should set Mara's opening strain/panic deliberately.
- Watch out: Left ChatGPT's uncommitted art wiring (data/items/*.tres icons, data/portraits/mara.tres frames/overlays, themes/cave.tres, art/*, tools/art) untouched and unstaged.

## 2026-10-17 – ChatGPT
- Did: #29 created art/items/starter-v1: 12 new matching transparent weapon/protection/supply images plus a copy of the approved rough knife, 13 total. Added a labelled preview, full prompt/source manifest, asset map with SupplyItem.icon paths, and validation report. Visually checked all subjects and the preview; all source PNGs decode, have alpha 0–255, square 1254px canvases and exact source-copy hashes.
- Next: Claude can assign oil-flask, party-ration, restorative-draught and clean-dressing textures to the corresponding data/items resources; README lists exact res:// paths. Review in the actual phone inventory, simplify/clean pixel edges and choose optimized export sizes before finalizing the library.
- Watch out: Source art only; no supply/portrait code or item definitions changed. Antivenom/equipment art does not implement those systems. Native 128px icon standard is still unapproved; the preview is not a sprite atlas. Earlier knife variants are preserved.

## 2026-10-17 – Claude
- Did: Recorded owner decisions for #11, #12, #14, #15 (issue comments + DESIGN.md) and created #30 for the opening escape (bodies in the room, panicking Mara, brief tutorial climb). Built #11: Injury resources (deep wound -5 max health, limp +1 time/step), dressing item binds one injury until camp, Companion.treat_injuries() for camp, traps hurt and may injure (placeholder for #16), card icons and Pack listing. 19 checks pass.
- Next: #12 strain (time, darkness, lost health, injury, hunger -> panic and lost effectiveness). Hunger needs a small hunger clock that rations reset.
- Watch out: Portrait overlays "blood"/"bandage" are wired but Mara has no such art yet.

## 2026-10-17 – Claude
- Did: #10 supplies per owner's comment, numbers from ChatGPT's economy research (tunable). Time: 1/step. Lantern: 100 oil, burn 0.5-1.5/step scaling with level, light dims with oil, faint glow when out; messages when low/out. Items as SupplyItem resources (oil flask, ration, restorative draught) with delayed healing via Companion effects; rest spots ask, take 20 time, complete effects, once each (Stay keeps it). Pack screen with Use buttons and reasons when unusable. 25 checks pass (burn ~110 steps/tank, band changes, waste-free refills, healing over time, rest, reasons, in-game pack/lantern/rest) at desktop and iPhone sizes.
- Next: #11 injury (dressings belong there), #12 strain. Pack capacity (8 slots in research) not implemented.
- Watch out: "Outside combat only" isn't enforced yet because there's no combat; add the check in #14.

## 2026-10-17 – Claude
- Did: #9 portrait cards, following ChatGPT's portrait plan (DESIGN.md "Portrait system"). PortraitSet resource = aligned 192px layers in the plan's order + condition overlays + blink/talk frames; PortraitView stacks and animates them by swapping drawings (auto-blink, talk, hurt flash/shake, set_condition). data/portraits/mara.tres uses the mara-layered-v1 PNGs (base as body, tunic as clothing). Party cards bottom-left in the safe area: portrait, name, health bar with numbers, icons (wounded <=50%, healing in progress, down); empty slots faint. Companion now emits `changed` on health/effect changes so cards update and flash. F3 + H/J to hurt/heal for testing. 16 checks pass at desktop and iPhone-15 sizes.
- Next: Art: blink_frames/talk_frames and condition overlays for Mara (ChatGPT's next art pass) will animate without code changes. Then #10 supplies.
- Watch out: Portraits display at 96px (half of 192) with linear filtering; check readability on a real phone. Icons are drawn placeholders.

## 2026-10-17 – ChatGPT
- Did: Refined #28's knife into art/concepts/items/plain-knife-v2.png using the built-in image editor: slightly rougher steel, sparse rust freckles and shallow pitting, retaining a usable edge and the original design. Preserved v1 and recorded the full edit prompt/provenance. Visually checked wear and identity; verified PNG integrity and alpha transparency.
- Next: Owner reviews the rougher finish; use the preferred version for a native-size cleanup and actual inventory-slot check.
- Watch out: Cosmetic concept revision only. No durability/stat penalties, inventory implementation or approved pixel-resolution standard added; the earlier 64/128 comparison still depicts v1.

## 2026-10-17 – ChatGPT
- Did: Inspected #28's knife concept at 64/128 pixels with same-size enlarged views and selectable backgrounds in chat. Verified native display sizes and viewer layout at 736/320 review widths; recorded the comparison in the item-art README. Source art unchanged.
- Next: Owner reviews the comparison. Consider 128 x 128 working art plus simplified 64 x 64 compact icons, then validate in the actual phone inventory before adopting a standard.
- Watch out: These are resampled viewing previews, not hand-authored native icons or exported assets. CSS pixel size is not physical iPhone size. No resolution standard or game UI changed.

## 2026-10-17 – ChatGPT
- Did: #28 drafted a plain starter knife inventory visual with the built-in image tool. Saved art/concepts/items/plain-knife-v1.png and README with the full prompt/provenance. Visually inspected the iron/wood construction and pixel-art direction; verified PNG integrity and real alpha transparency.
- Next: Owner reviews the item style; clean the pixel/alpha edges and check an actual small inventory slot before choosing an export resolution or making more items.
- Watch out: Generated 1254 x 1254 concept only, not a final 64 x 64 icon or implemented inventory item. Faint alpha pixels extend into the margin. No knife stats, starting loadout or game scripts changed.

## 2026-10-17 – Claude
- Did: Owner decided the lone survivor starts on the deepest floor where the companions died and climbs out to camp. Generator now marks 'S' on the deepest floor in the room farthest from the way up (same spot a way down would use, so walls/contents are unchanged); main.gd opens there with `opening_message` and uses an Arrival enum (OPENING/FROM_ABOVE/FROM_BELOW). Debug layout still opens on floor 1. Tested 500 seeds x 6 checks, the opening in-game, and reran door/stairs, party and map tests.
- Next: #9 portrait cards. Owner to decide how the companions' deaths are shown and escape difficulty (open decision 4).
- Watch out: Escaping means climbing 3 generated floors; ChatGPT's economy research suggests the escape be short and gentle, so floors_in_site or opening floor size may need tuning.

## 2026-10-17 – ChatGPT
- Did: #27 recorded the personality/fear/recruit-variation discussion in docs/hero-personality-and-fear.md and linked it from DESIGN.md. Preserved outlooks, values/faults/boundaries, paladin/bandit cooperation, neutral-party trade-offs, pair trust, three proposed fear states and bounded recruit variation. Checked documentation links, consistency and whitespace.
- Next: Owner refines the smallest encounter reactions, fear effects and recruit variation rules before implementation; coordinate with #12/#14 and #25's proposed Resolve attribute.
- Watch out: Proposals only. No stats, saves, resource definitions or gameplay changed. Current one-survivor opening and health-only implementation remain intact; fear's floor-transition behaviour is undecided.

## 2026-10-17 – ChatGPT
- Did: Reconciled #25 research with the just-completed #8 lone-survivor/timed-effect decisions. Separated Mara's wounded opening escape from the later recruited trio, added a proposed first-camp recruitment allowance without double-spending the expedition reserve, and accounted for floor-change completion of timed remedies. Rechecked documentation and budget arithmetic.
- Next: Continue #9. Owner reviews opening placement, initial hiring/funding, loss rules and recovery safeguards before adopting economy values.
- Watch out: All new numbers remain proposals; Mara's implemented 14/20 HP and the confirmed timed-effect rules are unchanged. The 24g worked budget begins after initial hires, with a proposed 48g first-camp grant funding both hires and that reserve. No game scripts changed in this research follow-up.

## 2026-10-17 – Claude
- Did: #8 party data, per the owner's comment: one starting hero (companions died in the dungeon), three slots, state survives floors, timed effects complete on floor change. Added Companion resource (scripts/companion.gd), party_state.gd (3 slots, time per step, effects over time), and data/companions/mara.tres as the placeholder survivor (guide, 14/20 HP, uses ChatGPT's Mara portrait). main.gd owns the party; F3 debug shows party and time. 20 tests pass (effect maths incl. fractions and caps, slot limit, definition files never modified, step = 1 time unit, floor change completes healing).
- Next: #9 portrait cards HUD (portrait field already points at mara-base-192-v2.png). Ask owner where the lone survivor starts (recorded as open decision 4).
- Watch out: Health is the only stat; effects only support "health". Untracked docs/starter-cave-economy-research.md is ChatGPT's work in progress; left alone.

## 2026-10-17 – ChatGPT
- Did: #25 researched the starter cave's connected economy using original developer/designer sources. Added docs/starter-cave-economy-research.md with proposed attributes, shared XP awards/individual talents, three enemy families, basic equipment, supplies, delayed recovery, camp prices, finite rewards, recruitment, a worked budget and owner decisions; linked it from DESIGN.md. Incorporated the newly committed #26 stash/recruitment decisions. Checked arithmetic, reward-range sensitivity, generator probabilities, local links and documentation whitespace.
- Next: Owner reviews individual casualty/loss rules, finite cave persistence and recovery safeguards before adopting the numbers. Continue Milestone 2 at #8; use the report to inform later supplies/combat/encounter work.
- Watch out: Research/paper prototype only; no game mechanics or generator changes, combat simulation or player testing. Current placement has no guaranteed chest/rest. Finite loot cannot fund unlimited retreats/recruits without a recovery fallback or another income rule. Values depend on unresolved combat and actual route lengths; instant combat healing would change the existing outside-combat recovery direction.

## 2026-10-17 – ChatGPT
- Did: #26 recorded campfire recruitment, tent stash/preparation, stored items surviving a full party wipe, and continuation of the same campaign with new recruits. Updated DESIGN.md's persistence decisions and the campsite's activity descriptions and proposed post-wipe flow. Checked documentation consistency and whitespace.
- Next: Define recruitment availability/cost, carried-item outcomes, stash access between sites and a viable recovery path for an impoverished party before implementing #17/#18.
- Watch out: These are design decisions only. No save/inventory/recruitment code added. Do not infer free recruitment, loss of all carried gear, corpse recovery or a dungeon reset; those rules remain open.

## 2026-10-16 – ChatGPT
- Did: #24 recorded the cave-area nurse and village-sent apprentice blacksmith. Established very basic starting equipment and limited quality stock as owner direction; updated the campsite specification to six proposed destinations, with nurse in Treatment and a modest smith lean-to. Checked documentation consistency and whitespace. Included Godot's generated import settings for the earlier merchant v2 concept (Refs #23).
- Next: Choose a small starting equipment list and the two NPC designs. Recompose the clearing for six readable touch targets when the refuge is implemented.
- Watch out: Item examples and repairs/fitting are proposals; no durability, crafting, shop or treatment mechanics added. The original inline campsite study still has five areas. Existing audio/game changes are unrelated and excluded.

## 2026-10-16 – Claude
- Did: #7 placeholder audio, finishing Milestone 1. Sounds are synthesised by tools/make_placeholder_audio.py into audio/placeholder/ (no third-party licences; README explains). EnvironmentTheme gained a Sound group (ambience, footstep_sounds, bump_sound, open_sound); cave uses dripping-cave ambience and a web tear, stone uses a hum and door creak. main.gd plays looping ambience, footsteps through an AudioStreamRandomizer (3 variants, pitch varied), and bump/open effects; party.gd emits `stepped` and `bumped`. Verified in-game that each sound starts at the right moment, and analysed the files: no clipping, inaudible loop seam.
- Next: Milestone 2 (party and combat), starting with #8 party data.
- Watch out: I can't listen to audio; the owner should check the sounds feel right. Volumes are constants at the top of main.gd. No settings/mute option yet.

## 2026-10-16 – ChatGPT
- Did: Refined #23 after owner approval: the original merchant concept's middle figure is the starting build, with less gold/jewellery and wealth increasing location by location. Generated merchant-progression-v2.png from v1 and updated merchant/campsite/design documentation; v1 is preserved. Checked image integrity, links and documentation whitespace.
- Next: Use v2's left figure as the current starter reference. Plan the exact site-to-appearance stages and prepare aligned production portraits; Master Tallow remains a working name.
- Watch out: Character identity is approved, but the revised sheet is still concept art. No shop/progression code added; repeat camp visits and individual purchases are not defined as appearance triggers.

## 2026-10-16 – Claude
- Did: #6 phone layout check. Rendered the HUD, prompt and full map at iPhone SE, 15/16 and Pro Max screen shapes. Touch buttons measure 51–58pt (above Apple's 44pt). Fixed: HUD now lives in a safe-area Control (main.gd `_safe_area`, `_apply_safe_area`) using DisplayServer.get_display_safe_area() on mobile, so the notch/Dynamic Island and home bar can't cover the map or touch pad; `simulate_phone_safe_area` on Main fakes iPhone 15 insets for testing on Windows. Default font size raised to 20 (project.godot gui/theme/default_font_size) because 16 was ~9pt on an SE. Full-map backdrop made opaque.
- Next: #7 placeholder audio finishes Milestone 1.
- Watch out: Real-device safe-area behaviour is untested until the iOS export (#20). Untracked art/concepts/merchant/ belongs to ChatGPT's in-progress work; I left it alone.

## 2026-10-16 – ChatGPT
- Did: #23 recorded the owner's required recurring greedy merchant, following the party between rest locations and growing increasingly obese and gross. Added docs/merchant-design.md, integrated him into the campsite's supply awning, and generated/preserved art/concepts/merchant/merchant-progression-v1.png with full prompt/provenance. Visually reviewed the three-stage concept and checked documentation links/whitespace.
- Next: Owner reviews the identity and progression. Master Tallow, the red cap/gold tooth/moustache/rings, and three-stage structure are proposals. Resolve trading, rest-location coverage and progression triggers before implementation; prepare aligned portrait masters after art approval.
- Watch out: Generated flattened concept only; no shop, follower logic or appearance progression implemented. Name and supernatural backstory are not settled. No game scripts changed in this task.

## 2026-10-16 – Claude
- Did: #5 full-screen map. Tap/click the minimap (mouse or touch) or press M/Tab to open; tap anywhere, M/Tab or Escape closes. Shows the explored floor scaled to fit (zooms to explored area, at least 15 cells across), title with depth, and a legend using the environment theme's names. Party is locked while it's open; it won't open over a Go/Stay prompt. minimap.gd now has a `full_view` mode sharing all drawing code. Recoloured passage bars (webs pale blue-grey, roots near-black) so they read against the floor and don't look like encounters. Tested open/close by mouse, touch, and keys in-game.
- Next: Milestone 1 remaining: #6 HUD at phone resolution, #7 placeholder audio.
- Watch out: No pan/zoom on the full map; at 31x31 it fits a landscape phone, but much larger floors would need it.

## 2026-10-16 – ChatGPT
- Did: #22 designed the cave campsite as one clearing with highlighted, clickable/tappable activity areas. Added docs/campsite-design.md, linked it from DESIGN.md, and made an in-chat interactive pixel layout study with five destinations and activity/Back interaction. Checked the interaction and responsive layout before committing.
- Next: Owner reviews the composition and proposed services. Implement the refuge when scheduled, reusing preparation/results work (#18/#17) and resolving recovery, treatment and cave re-entry rules first.
- Watch out: Only the spatial tent/area interaction is owner-directed; the five-service arrangement is proposed. The study's action buttons explain potential flows and do not implement game state, rest, trading or recovery. No game scripts changed; exploration/party milestone order remains in place.

## 2026-10-16 – Claude
- Did: #3 and #4. Passages: 'D' closed (stepping in clears/opens it; party stays put that press) and 'B' blocked (bump + message). Ways up/down: '<' at the arrival point, '>' in the room farthest on foot; deepest floor (floors_in_site, default 3) has none. Taking either asks Go/Stay; floors are cached so revisits keep explored/opened/used state. New EnvironmentTheme resource (scripts/environment_theme.gd, themes/cave.tres + stone.tres) holds names, messages, placeholder colours, optional art scenes, and surface materials, following ChatGPT's DESIGN.md guidance. level_builder.gd now owns 3D geometry. Minimap draws passage bars and shows stairs once seen. Tested 500 seeds (reachable despite blocked passages, ~5 closed + ~1 blocked per floor, way down always reachable, deepest floor has none, walls unchanged) and an in-game run through web, roots, pit, descend, ascend.
- Next: #5 full-screen map. Art: assign closed/opened/blocked/descent/ascent scenes in themes/cave.tres. Floor 1's way up says "back to camp" until the campsite exists.
- Watch out: Blocked passages can't be unlocked yet (no keys/tools). Placeholders are plain shapes; the web is a translucent sheet. ChatGPT and Claude both worked in E:\GitHub\Depths at the same time today without conflict, but avoid editing the same files simultaneously.

## 2026-10-16 – ChatGPT
- Did: Safely transferred the documentation from retired OneDrive commit c40bb8ed778df488306a8cad0bf0a0df0d1495bd into E:\GitHub\Depths: the environment-specific door/stair section in DESIGN.md and its original handoff below. Preserved the newer working-copy note and existing implementation changes. Checked the documentation diff and whitespace before committing.
- Next: Continue #3/#4 using this visual guidance alongside the current door/stair implementation.
- Watch out: The retired copy was read only to recover this commit; E:\GitHub\Depths remains the single working copy. Script/theme work already in progress is outside this documentation transfer and must not be included in its commit.

## 2026-10-16 – ChatGPT (recovered from c40bb8e)
- Did: Recorded environment-specific door/stair presentation in DESIGN.md: cave webs, roots, dirt obstructions/mounds, pits, and natural passages can use the same barrier and floor-transition roles as built doors/stairs.
- Next: For #3/#4, keep gameplay state and destinations independent of appearance so site themes can be applied later; generic visuals are fine initially.
- Watch out: Owner says differences are mostly visual. This does not add mandatory tools, web-burning costs, one-way pits, or falling damage. Documentation only; did not touch Claude's door/stair implementation.

## 2026-10-16 – Claude
- Did: Made E:\GitHub\Depths the single working copy: it was 7 commits behind, so cleared its duplicate files (identical to GitHub) and fast-forwarded it. Recorded the location in AGENTS.md. Confirmed the game imports and runs from there.
- Next: Owner points Godot and ChatGPT at E:\GitHub\Depths and removes the OneDrive copy and the stray `new-game-project/` folder. Then #3 doors / #4 stairs.
- Watch out: Until `new-game-project/` is deleted it shows as untracked; don't commit it. Godot's project list only contained that empty project, so the owner hadn't yet seen the generator or contents in the editor.

## 2026-10-16 – ChatGPT
- Did: Recorded the owner's site-by-site campaign progression in DESIGN.md and the project summary: cave + campsite first, then dungeon/refuge combinations growing toward a castle and demon portal or similar. Revised the premise, deepest-objective wording, first-playable scope, and open questions so they no longer imply a single dungeon for the entire campaign.
- Next: Design the cave/camp recovery-and-return loop alongside the existing exploration work. Define site completion and persistent party state before implementing campaign travel.
- Watch out: Crypt/chapel, fortress/outpost, and the precise finale are illustrative ideas, not a required content list. Three cave floors, walking back to the entrance, minimal camp activities, and carrying all party history forward remain proposals. Documentation only; no game behaviour changed.

## 2026-10-16 – Claude
- Did: #2 room data model. dungeon_map.gd now has a `Content` enum, per-cell `contents` parsed from layout letters, and `enter(cell)` which returns content once (stairs repeat). Generator puts one random content in ~75% of non-start rooms, placed after corridors so existing seeds keep identical walls. Party emits `entered_cell` when a step finishes; main.gd shows a placeholder on-screen message and prints it. F3 toggles a debug overlay and fully revealed minimap with coloured content markers. Tested 500 seeds (connected, deterministic, walls unchanged vs before, contents never on start/walls), enter() rules, and an in-game run on the debug layout.
- Next: #3 doors and #4 stairs (generator should place '>' in a far room). Real encounter behaviour replaces the placeholder message in later issues (#14, #16).
- Watch out: Contents have no 3D visuals yet; they're only visible via the message and the map. Movement isn't blocked while something triggers.

## 2026-10-16 – ChatGPT
- Did: #21 added art/textures/stone-v1: two 64 x 64 wall variants, floor, ceiling, shared nearest-filtered rough materials, source atlas, actual in-game screenshot, and README. Applied them in scripts/main.gd with deterministic wall variation; recorded the material-library direction in DESIGN.md. Included the earlier owned automatic-commit policy update after verifying its ownership.
- Next: Owner reviews the set in F5; tune seam continuity and physical texel scale before expanding into other environment families.
- Watch out: Textures are generated prototypes; not guaranteed perfectly seamless. Default BoxMesh UVs differ from plane UVs. Godot 4.7.2 normal-access import and actual Windows Mobile-renderer capture passed; iPhone untested. Initial restricted checks had settings-directory errors, resolved by normal-access validation.

## 2026-10-16 – ChatGPT
- Did: Replaced the ask-before-commit rule in AGENTS.md with the owner's standing instruction to check, commit, and push completed tasks automatically, leaving unrelated changes untouched and never force-pushing. CLAUDE.md already imports AGENTS.md.
- Next: The assistant handling the already staged floor-generator work should finish that handoff before this policy change is committed separately.
- Watch out: At task start, unrelated work was already staged in AGENTS.md, NOTES.md, DESIGN.md, game scripts, and other files. This task's policy and handoff edits are unstaged; did not alter the existing index, commit, or push because shared files overlap with that staged work.

## 2026-10-16 – Claude
- Did: #1 procedural floor generator (scripts/floor_generator.gd): 31x31 floors of up to 9 rooms joined by L-shaped corridors plus occasional loops; seeded and deterministic. Tested 500 seeds: all fully connected and deterministic. Minimap now shows a 15x15 window around the party; only walls next to floor are drawn. Committed ChatGPT's portrait work separately. Recorded owner decisions from #6 (landscape only; set handheld orientation to sensor landscape), #10 (time per step, oil trade-off, delayed food/healing, supplies in backpack not HUD), and #13 (enemies in first-person) in DESIGN.md.
- Next: #2 room data model, then #3 doors and #4 stairs.
- Watch out: Owner leaves decisions as comments on issues; check them before starting. #6's HUD-at-phone-resolution check is still open. Godot for headless testing: E:\Red Noon\game\.tools\godot\Godot_v4.7.2-stable_win64_console.exe (owner's own copy location unknown).

## 2026-10-16 – ChatGPT
- Did: Recorded portrait-system direction in DESIGN.md: 192 x 192 working canvas, minimally clothed unhooded bases, fixed per-character pose, individual heads on reusable bodies, clothing layers, condition overlays/face variants, and simple blink/speech animation. Recorded the owner's six-template planning target (three female and three male builds), with build labels and a small validation step marked as proposals. Updated visual direction to the preferred simpler pixel environments.
- Next: Validate one reusable body with two character heads and one outfit, then properly separate the Mara master before expanding animation or template coverage.
- Watch out: Existing ORA remains a wardrobe prototype, not a completed separated animation master. No new art or game code produced in this documentation task. No commits or pushes made.

## 2026-10-16 – ChatGPT
- Did: Added art/concepts/portraits/mara-layered-v1 with a 192 x 192 OpenRaster wardrobe prototype, transparent base and tunic PNGs, neutral eye/mouth replacement patches, preview, and usage/provenance README. Visually checked the composite; clothing toggles independently. Built-in image tool generated the cutout and garment; local export packaged layers.
- Next: Separate hair/body/underlayer and reconstruct hidden pixels before producing final blink/speech frames or hood variants.
- Watch out: This is explicitly not a finished animation master: hair, face, body, and original underlayer remain combined in base.png. Neutral expression patches are editable selections, not animation. Existing v1/v2 portraits preserved. No game code changed or commits/pushes made.

## 2026-10-16 – ChatGPT
- Did: Created art/concepts/portraits/mara-base-192-v2.png at 192 x 192. Built-in image edit prompt: preserve Mara's identity and lighting, remove hood/cloak/equipment, use plain sleeveless underlayer, angle head and gaze slightly toward image right. Exported with nearest-neighbor resizing; v1 retained.
- Next: Review base pose before separating expression and outfit layers.
- Watch out: Flattened concept only, not a cleaned or layered animation master. No code changes, commits, or pushes.

## 2026-10-16 – Claude
- Did: Created GitHub Issues #1–#20 for the first playable, grouped into three milestones with area labels. Added a "Task tracking" section to AGENTS.md.
- Next: Owner grants the GitHub CLI `project` scope so a Project board can be created; then start #1 (procedural floor generator).
- Watch out: Issues labelled `decision needed` (#6, #10, #13) need the owner's call before implementation.

## 2026-10-16 – ChatGPT
- Did: Generated a neutral Mara portrait concept with the built-in image tool and exported art/concepts/portraits/mara-neutral-192-v1.png at exactly 192 x 192 using nearest-neighbor resizing. Prompt direction: frontal weathered female guide, charcoal hood, brown cloak, neutral closed mouth, upper-left lighting, restrained gritty pixel art.
- Next: Owner reviews resolution and character appearance before creating expression or clothing variants.
- Watch out: This is a flattened generated concept, not a hand-cleaned pixel master or separated layer file. No game code changed; nothing committed or pushed.

## 2026-10-16 – Claude
- Did: Built the first grid-movement prototype: placeholder 3D floor from a text layout, lantern-lit first-person party with forward/back/turn movement (W/S/A/D or arrows, held keys repeat), wall bump feedback, explored-cells minimap, and an on-screen touch pad. Verified by running Godot 4.7.2 with simulated inputs.
- Next: Owner playtests (F5). Then candidates: rooms with contents (doors, chests, stairs), or a procedural layout generator to replace the fixed LAYOUT.
- Watch out: Geometry is one mesh per cell — fine for small floors, but switch to MultiMesh or GridMap if floors get large. Strafing is deliberately not implemented.

## 2026-10-16 – Claude
- Did: Owner created the Godot 4.7 project (Mobile renderer). Committed it, restored the fuller .gitignore Godot had overwritten, enabled mouse-to-touch emulation, and updated AGENTS.md with run instructions.
- Next: Build the first scene: a grid-movement prototype (one room, directional moves, simple map). Movement rules are still open in DESIGN.md, so confirm with the owner first.
- Watch out: No main scene yet, so F5 asks to pick one. Phone orientation is undecided.

## 2026-10-16 – Claude
- Did: Recorded the owner's decision: Godot 4, targeting Windows and iPhone (AGENTS.md, DESIGN.md open decision 1). Added Godot .gitignore and .gitattributes (LF line endings). Connected the repo to github.com/jonathanvarro/Depths and pushed.
- Next: Create the Godot project (project.godot) in the repo root and decide touch controls and phone orientation.
- Watch out: iOS export requires a Mac with Xcode and an Apple developer account; Windows-only development can't produce an iPhone build. Repo lives in OneDrive, which can conflict with git.

## 2026-10-16 – ChatGPT
- Did: Added DESIGN.md to record the owner's design discussion, including the core loop, procedural grid exploration, floor scaling, party strain, combat, visual direction, and a proposed first playable. Updated AGENTS.md with a project summary and file guide.
- Next: Review the open decisions in DESIGN.md, especially movement/combat presentation, persistence between expeditions, and engine choice, before implementing a prototype.
- Watch out: Three companions, pixel art, and the three-floor prototype are proposals rather than final requirements. The owner likes Greed & Darkness's art but wants different movement and combat. Concept images are not in the repo. No commits or pushes were made; the repo had no commits at the start of this task.

## 2026-10-16 – Claude
- Did: Created AGENTS.md (shared project context), CLAUDE.md, and this file.
- Next: Owner fills in the "About the project" section of AGENTS.md.
- Watch out: Repo has no commits yet and no GitHub remote.
