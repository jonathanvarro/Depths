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
