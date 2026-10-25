# Depths

Shared context for AI assistants working on this project (Claude Code reads
this via CLAUDE.md; ChatGPT Codex reads AGENTS.md directly). Keep it current.

## About the project

- **What it is:** A dark, first-person grid dungeon crawler about party strain and dangerous discoveries. The story stays at one cave and its campsite: the party descends deeper into the same cave toward a relic the king wants found (DESIGN.md "Story direction", #122). See `DESIGN.md` for current direction, proposals, and open decisions.
- **Language / engine / framework:** Godot 4.7, GDScript, Mobile renderer
  (chosen for iPhone performance). Don't upgrade the Godot version without
  the owner's OK.
- **Target platforms:** Windows and iPhone (iOS), landscape only. Design every screen for
  both mouse/keyboard and touch from the start; keep UI readable on a phone.
  iOS builds must be exported and signed on a Mac with Xcode.
- **How to run it:** Open `project.godot` in the Godot editor and press F5.
  The game starts on the title screen (`scenes/title.tscn`); to jump
  straight into the dungeon, open `scenes/main.tscn` and press F6. Mouse clicks emulate touch
  (`input_devices/pointing/emulate_touch_from_mouse`) so touch input can be
  tested on Windows.
- **How to test it:** No automated test suite yet. Press **F3** in-game for
  the debug overlay (seed, cell, contents) and a fully revealed minimap.
  On the Main node, `use_debug_layout` loads a small hand-drawn floor with
  known contents; `show_debug` starts with the overlay on;
  `simulate_phone_safe_area` reserves an iPhone's notch/home-bar margins.
  To preview phone shapes, run with e.g. `--resolution 1278x590` (iPhone 15)
  or `1334x750` (iPhone SE). HUD controls go inside `_safe_area` in main.gd
  so they stay clear of the notch on real phones.

- **Where the repo lives:** on the owner's PC the one working copy is
  `E:\GitHub\Depths`. An older copy under OneDrive is retired; don't use it.

## Building for Windows (#19)

The `Windows Desktop` preset in `export_presets.cfg` makes one self-contained
`build/windows/Depths.exe` (game data embedded; `build/` is git-ignored).
It needs Godot's 4.7.2 export templates (editor: Editor > Manage Export
Templates > Download and Install; already installed on the owner's PC).

- **In the editor:** Project > Export > Windows Desktop > Export Project.
- **From a terminal:** `Godot_v4.7.2-stable_win64_console.exe --headless
  --path . --export-release "Windows Desktop" build/windows/Depths.exe`
- **Share it:** send `Depths.exe` (zip it if needed). No Godot install is
  needed to play. It's unsigned, so Windows SmartScreen may warn on first
  launch ("More info" > "Run anyway").
- **Check a build:** `Depths.exe --quit-after 400 -- --begin` skips the
  title and runs the dungeon briefly; errors print to the console.
- The preset leaves out `art/source/` and `tools/`. Everything else under
  `res://` is included (data/events is loaded by folder listing, so a
  "selected scenes only" export would drop it).

## Project structure

- `DESIGN.md` – living design direction and proposed first playable scope.
- `docs/cave-descent-and-quests.md` – proposed twelve-floor cave campaign and 48 activity concepts (#125), including quest packages, camp projects and story persistence. Read alongside #122/#123; floor count, lore and new mechanics are not approved or implemented.
- `docs/boons-curses-and-gambling-review.md` – #134 audit of the #133 shrine system, costs/odds/durations, research and proposed improvements; recorded probes in `docs/boons-curses-review-data.json`. Reward bugs are #136/#137; #135 trinkets were in progress during review. Recommendations do not change live rules.
- `AGENTS.md` / `CLAUDE.md` – shared assistant instructions and entry point.
- `NOTES.md` – handoff history between assistants.
- `project.godot` – Godot project settings. Prefer changing settings in the
  editor; if editing by hand, keep changes minimal.
- `.godot/` – Godot's local cache; ignored by git, never commit it.
- `scenes/main.tscn` – entry scene; everything else is built in code by
  `scripts/main.gd` while we're prototyping.
- `scripts/main.gd` – runs a site: opens on the deepest floor at the
  survivor's start ('S'; floor 1 when `use_debug_layout`), generates and
  caches each floor, moves between floors via the yes/no prompt
  (`Arrival`: OPENING / FROM_ABOVE / FROM_BELOW),
  builds lighting, UI,
  touch pad, and the input actions (`move_forward`, `move_back`,
  `turn_left`, `turn_right`).
- `scripts/party.gd` – first-person party: grid cell, facing, step/turn tweens;
  opens closed passages and bumps on blocked ones.
- `scripts/level_builder.gd` – turns a map plus an EnvironmentTheme into 3D
  geometry; theme scenes replace the placeholder shapes when assigned.
- `scripts/environment_theme.gd` + `themes/*.tres` – per-environment look,
  wording and sound for passages and ways up/down (cave: webs, roots, pit,
  hanging roots; stone: doors, stairs), plus ambience, footsteps, bump and
  open sounds. Picked via `environment_theme` on Main.
  Six standalone deeper-cave wall families (#126) are available in
  `art/textures/descent-walls-v1`; sources, previews and integration notes:
  `docs/descent-wall-library.md`. They are not assigned to live floors yet.
  Matching floors/ceilings for all six families and twenty remaining dressing
  entries (#139) are ready in `docs/descent-surfaces-and-dressing.md`; optional
  glow is separate and mood only. Preserve live themes/wall files; new placement
  and later floor/lore assignment remain separate work.
  Roots, collapsed royal cache scenery and a miners' shrine with fresh/resolved
  states (#132/#133) are ready in `art/dressing/landmarks-v1`;
  `docs/landmark-art.md` records mounts and the shrine's required wall anchor.
  The new cairn glyph is live on the map; these scenes await placement.
- `scripts/companion.gd` + `data/companions/*.tres` – hero definitions
  (Companion resource: identity, health, effects over time). The game
  plays with copies, never the .tres itself.
- `scripts/party_state.gd` – the party: up to 3 heroes, time elapsed
  (1 unit per step), completes timed effects on floor changes. Owned by
  main.gd (`_party_state`); starts with `starting_hero` (Mara).
- `scripts/portrait_set.gd` + `data/portraits/*.tres` – a character's
  layered portrait (aligned 192x192 layers, condition overlays, blink/talk
  frames). Companion.portrait_set points at one.
  `data/portraits/catalog.json` separates reusable body-template families from
  unique hero rigs (`rig_kind`/`rig_family`/`face_id`); facial drawings are never
  shared across heads. Complete native eye/mouth separation and paused inspection:
  `docs/portrait-rig-families.md`; preserve `frames-pixel-v3` clean/neutral
  components and `frames-pixel-v4` animation on re-export (#124).
  V2 left baked features visible; v3 animation was too flat. Timing is unchanged.
  The first two unique dark elf rigs (#131), their separate lighting and one
  combat pose family are ready in `docs/results-and-rivals-art.md`; their
  catalogue stays separate from human/recruit exporters and has no story assignment.
  The ordinary elf man/woman complete #131 in `art/portraits/elves-v1` and
  `data/portraits/elves-v1`, with fitted native animation, separate lighting and
  a swordswoman's three combat poses. Handoff: `docs/elves-and-sound-art.md`.
  These Unique rigs have no character/encounter assignment yet.
- `scripts/portrait_view.gd` – draws a PortraitSet; blink(), talk(), hurt(),
  set_condition().
- `scripts/party_card.gd` – HUD card per party slot (portrait, name, health
  bar, condition icons); main.gd builds three bottom-left. With F3 open,
  H hurts and J heals the first hero, to see the cards react.
- `scripts/supplies.gd` – lantern oil (burn scales with level, light
  bands, waste-free refills) and supply counts; owned by PartyState.
- `scripts/supply_item.gd` + `data/items/*.tres` – supply definitions
  (refill lantern / feed party / heal one, amounts, durations, use time).
  Tools/treatments and the four back-slot items use `art/items/field-kit-v1`;
  eleven specific boon/bane glyphs are in `art/ui/boons-v2` (#138).
  Sources, builder bindings and native/display-size review: `docs/field-kit-art.md`.
- `scripts/injury.gd` + `data/injuries/*.tres` – lasting injuries (max
  health penalty, extra step time, portrait overlay names). Companion holds
  `injuries` and `dressed`; F3 + K injures the first hero for testing.
- `scripts/strain.gd` – strain rules and tuning numbers (states,
  effectiveness, per-time gains, event spikes, panic chance). Companion has
  `strain` and `hunger`; F3 + L adds strain for testing.
- `scripts/enemy_type.gd` + `data/enemies/*.tres` – enemy numbers, `tactic`
  (BASIC / DARTING / WEB_AND_VENOM / CUNNING, rules in combat_state.gd),
  `intro` hint, and the art scene (Node3D with AnimatedSprite3D "Sprite":
  idle/attack/hurt).
  #141's eleven new monster art families (46 drawings, special state poses,
  separate FX/symbols) are in `art/enemies/monsters-v1`; four live definitions
  and their builder are connected. `docs/new-monster-art.md` covers the remaining
  state/FX integration, pose-aware tag bounds and bat mounting/clearance.
  New deeper-creature concept requests #150–#152 follow the owner's 2026-10-22
  direction: dark/gritty throughout, increasingly grotesque and disconnected
  from reality toward the final floor. Read `docs/enemy-art-direction.md`
  before generating them. Preserve phone readability and existing production
  budgets; concept paintings do not assign lore, floors or a final boss.
  Ten current draft sheets and three retained earlier variants are ready in
  `art/concepts/descent-horror-v1/inspector.html`; handoff, selection ledger and
  presentation proposals: `docs/descent-horror-concepts.md`. Owner feedback
  prompted a single-clapper Bell and broad folded-vault Sleeper revision; compare
  Revised/Previous in the gallery. Revised review and production choices remain
  open. Preserve these as concepts; no runtime exports or assignments.
  Five further reference-led sovereign/creature studies (#153) are in
  `art/concepts/reference-creatures-v1/inspector.html`; prompts/provenance and
  review notes: `docs/reference-creature-concepts.md`. Supplied references and
  generated masters are retained separately. These remain exploratory concepts.
  The owner-approved crown-free gothic vampire queen concept (#154) is separate:
  `art/concepts/vampire-queen-v1/README.md`. Its selected painting and exact edit
  lineage are preserved; no story role or runtime portrait is assigned.
- `scripts/combat_state.gd` – combat rules without visuals (turn order,
  attack/defend/item/retreat, enemy attacks, results); testable directly.
- `scripts/combat_screen.gd` – combat UI: turn text, log, tappable enemy
  tags, action panel. main.gd `_start_combat()` spawns foes, hides the
  movement pad, and handles victory/retreat/defeat. Encounter groups by
  depth are `ENCOUNTER_GROUPS` in main.gd.
- `scripts/room_event.gd`, `event_choice.gd`, `event_outcome.gd` +
  `data/events/*.tres` – room events (#16). Add an event by writing a new
  .tres (kind 2 chest / 3 trap / 4 strange object / 5 rest spot, clue,
  choices, depth range); `room_events.gd` loads every file in the folder.
- `scripts/room_events.gd` – picks events per cell by kind and depth,
  resolves choices; `scripts/event_screen.gd` shows them.
  #142 connects dedicated defiled-shrine, fouled-well and buried-cache state
  pairs, plus nine designs across twelve trinket definitions. Catalogue/review
  and exact source prompts: `docs/events-and-trinkets-art.md`. Preserve shared
  icons for cursed/cleansed pairs and Claude's existing shrine wall anchor.
- `scripts/expedition.gd` – one expedition's record (start snapshot plus
  counters) and its gained/lost lines; `Ending` RETURNED / WIPED /
  REACHED_BOTTOM.
- `scripts/results_screen.gd` – end-of-expedition screen. main.gd
  `_end_expedition()` shows it; `_start_new_expedition()` is the placeholder
  camp stop and re-entry from floor 1.
  Spoils/results art (#130), paired cave-mouth backgrounds and arrival sheets
  are connected; handoff and paused art review: `docs/results-and-rivals-art.md`.
- `scripts/title_screen.gd` + `scenes/title.tscn` – title screen (#18) built
  from ChatGPT's title study: Begin expedition, Settings (disabled until
  settings exist), Quit (desktop only). Uses art/fonts roles.
- `scripts/preparation_screen.gd` – party, condition, lantern and pack before
  expeditions 2+ (the opening skips it). `scripts/safe_area.gd` – shared
  notch/home-bar insets for every screen.
- `scripts/opening_generator.gd` – the opening escape's bodies room and
  branching maze (#30, #56). main.gd's "Opening escape" section runs it as floor
  0: bleeding, health floor, daylight exit, bodies (`body_scenes`), hints.
  `play_opening` on Main turns it off (tests that aren't about the opening
  should); `data/enemies/starved_rat.tres` / `small_spider.tres` are its
  gentler enemies.
- `scripts/dialogue_lines.gd` + `data/dialogue/*.tres` – a hero's lines by
  situation (Companion.dialogue); `scripts/dialogue_box.gd` shows them above
  the cards. main.gd `_say(situation)` picks and shows one (#57). Add lines
  or situations in the .tres without code.
- `scripts/equipment.gd` + `data/gear/*.tres` – weapons (#58). Companion
  `weapon` sets attack range/accuracy; PartyState.equip()/drop(); carried gear
  is `Supplies.gear`. RoomEvent outcomes can give `gear`.
- Light sources (#59): `Supplies.source` is LANTERN, TORCH (held, burns
  `torch_left`, `torch_burnt_out` signal) or NONE; `has_lantern`. Torch
  supply effect LIGHT_TORCH; CombatState.hero_throw_torch() scares a foe off.
  Party.step_check can refuse a step (the opening's too-dark gate).
- Opening polish (#69): `DungeonMap.solid` cells block movement and
  `Party.interacted` fires when walked into (bodies, fire, chests);
  `DungeonMap.set_symbol()` edits a cell (niches, sealing the way to
  daylight; rebuild the level after); `walking_path()`. Tutorial cards are
  main.gd `_show_hint(text, key, mode, inside)` with modes act / pack / ok;
  `Party.paused` is the card's hold, separate from `locked`. Opening steps
  are state-driven in `_refresh_tutorial_hint()`. `Foe.glancing` (0-1
  damage, never falls, no health shown); `CombatScreen.only_action`
  ("throw") and `hero_acted` signal. `Companion.bleeding` shows an icon.
  `Supplies.torch_burns` false stops torches burning down.
- Bleeding feedback (#71): main.gd `_bleed_pulse()` (red edge flash + heartbeat,
  `audio/placeholder/heartbeat.wav`) and `_update_wound_dim()` (a vignette
  shader under the HUD); `screen_flashes` export disables the flash.
- Enemy intentions (#60): `CombatState.Intent`, `Foe.intent`, `plan(foe)`
  (call again after changing a foe from outside), `intent_text()`;
  `enemy_act()` carries out the shown intent, then plans the next one.
- Campsite (#40): `scripts/camp_state.gd` (day, `stash` as a Supplies,
  `recovering`, rest/treat/restock; `day_passed` re-seeds the cave in
  main.gd) and `scripts/camp_screen.gd` (`art/camp/highres-v4` terrain,
  independent site scenes/local lights + layout.json; one activity per site).
  CampState `site_presence` / `set_site_present()` controls availability;
  absent keys default present for older saves. New story starts use #80's
  `begin_arrivals()`: unloading merchant opens after the first post-tutorial
  expedition return; smith appears after the first camp rest.
  `Injury.recovery_days`.
  `tools/camp_check.gd` drives every place (args: desk|phone, screenshot dir).
  Higher-resolution camp/items, shared seal, focused live interface cleanup and
  portrait animation handoff: `docs/visual-refinement.md` (#112/#120).
- Recruitment (#41): `scripts/recruits.gd` (roles, traits, names; `make(rng)`),
  CampState `candidates` / `hire` / `dismiss` / `leave_behind` / `rejoin`;
  Companion `guard_factor`, `toughness`, `strength`, `weakness`, `founder`.
  Placeholder portraits: `tools/art/build_recruit_silhouettes.py` (Pillow).
  `tools/recruit_check.gd` covers the fire, staying behind, a wipe and torches.
- Gold (#42): `Supplies.gold` (stash has its own); `SupplyItem.price` and
  effect TREASURE; `Equipment.price`; `EnemyType.purse`; `EventOutcome.gold`
  (RoomEvents `gold_found`); CampState buy/sell/buy_gear/buy_lantern,
  `MERCHANT_STOCK`, `SMITH_STOCK`, contracts (`post_contract`, `count_kill`,
  `collect_contract`), charity torches. `tools/gold_check.gd` covers it.
- Rows (#72): `Companion.row` / `reach` / `has_reach()`, `Equipment.reach`,
  `EnemyType.row` / `reach_back`; CombatState `can_hit`, `targets_for`,
  `foe_can_reach`, `hero_move`. `tools/rows_check.gd`; `tools/balance_sim.gd`.
- Saving (#45): `scripts/save_game.gd` (one slot; `pack_object`/`unpack_into`
  store resources by path and generated objects by script variables).
  main.gd `_save_now()` / `_restore()` / `_camp_loop()`; heroes are packed
  once in "people" and referenced by index. Runs with `--script` use
  `user://test_save.dat`. New runtime state must be added to both functions.
  `tools/save_check.gd`.
- Coin flip (#77): `scripts/coin_flip.gd` overlay, `await coin.flip(title,
  heads, tails, chance, note)`; EventChoice `coin_flip` (outcomes[0] heads,
  [1] tails); CombatState Intent.KILLING_BLOW, `prepare_killing_blow`,
  `killing_blow_odds`, `coin`; Companion.luck, PartyState.luck().
  `tools/coin_check.gd`.
- Goblin fortress (#44): `scripts/fortress.gd` (hall + gates on floor 4,
  `DungeonMap.marks`), `themes/fortress.tres`, main.gd `_apply_theme`,
  `_gate_fight`/`_break_gates`/`_queen_fight`/`_queen_defeated`,
  `_fight_kind`; CampState `gate_broken`/`queen_defeated`/`bounty_paid`;
  EnemyType tactics ARCHER/GUARD/QUEEN, `summons`, placeholder `tint` and
  `sprite_scale`; CombatState `foe_joined`, guard wall, rage.
  `tools/fortress_check.gd`.
- Settings (#52): `scripts/settings.gd` (static values, `apply()`, audio
  buses Master/Music/Effects; test runs use test_settings.cfg) and
  `scripts/settings_screen.gd`. New sound players should set `bus`.
- Main heroes (#83): `Companion.main_hero`, `is_unconscious()`,
  `is_with_party()`. Secured route (#79): CampState `floor2_reached`,
  `route_open()`, `buy_route()`; CampScreen `cave_chosen(start_depth)`.
  Room props (#46): `RoomEvent.prop`, main.gd `_add_room_props()`.
  `tools/batch_check.gd`.
- Starting heroes (#95): `scripts/hero_select.gd` (HEROES list),
  `data/companions/{mara,corin,alwen}.tres`, Companion `trait_id`,
  `trait_name`, `trait_text`, `backstory`, `pronouns`; SaveGame
  `new_game_hero`; PartyState `has_trait`, `field_bind`.
- Stats, levels, XP (#47): `scripts/progression.gd` (thresholds, floor
  limits, talents, advance/auto_advance); Companion `uses_stats`, stat_str/
  dex/vit/res, aim_base, speed_base, hp_bonus, damage_max_mod, level, xp,
  talents, `refresh_stats()`, `damage_reduction()`, `effective_initiative()`;
  CampState `xp_left`, `best_level`, `advance()`; main.gd `_award_fight_xp`,
  `_grant_xp`. EnemyType `threat`. Armour (#93): Equipment `slot`, `armour`,
  `initiative_penalty`, `force`, `light`; Companion `body`.
  `tools/progression_check.gd`.
- `scripts/chest_screen.gd` – chest window beside the pack: drag (set_drag_
  forwarding), tap, or the take-all icon button; `took` signal.
- `scripts/pack_screen.gd` + `scripts/kit_bag.gd` – live combined Field kit:
  Equipment/Status left, shared physical backpack right, pinned inspection below,
  real stack/capacity pages and explicit actions. Open with the backpack or I/B.
  PartyState methods keep targeting, gear/curses and supply costs authoritative.
  Review/checks and earlier-study supersession: `docs/combined-kit-live.md`.
- `scripts/battle_stage.gd` – authored combat mist surge and low drifting bank
  (#129), viewport-fitted camera quad and static/plain fade when effects are off.
  Preserved source/prompt, exporter and real-renderer review: `docs/combat-fog.md`.
- `audio/placeholder/` – generated placeholder sounds (see its README for
  licence); rebuilt by `tools/make_placeholder_audio.py`.
- `scripts/sounds.gd` + `audio/dark-v1/` – thirty finished CC0-derived effects
  and ambience layers (#96/#99), exact source credits/processing in its catalogue
  and CREDITS.md. Hits/misses/coins use an independent presentation RNG; one-shots
  free themselves. Camp owns its visibility-bound ambience; Main swaps a distant
  drum bed on floor 3 and restarts cave ambience after camp. Separate stems/torch
  loop are available. Review and integration: `docs/elves-and-sound-art.md`.
  Current music/softened footsteps remain; broader #54 stays open.
- `scripts/dungeon_map.gd` – grid data (`is_wall`), cell contents
  (`Content` enum, `content_at`, `enter`), and explored cells. Layout text
  uses ',' for room floor and '.' for corridor floor (rooms are found from
  ','; a fight fills its room via `encounter_zones`), and letters for
  contents: E encounter, C chest, T trap, O strange object,
  R rest spot, > way down, < way up (also the start if there's no S), plus
  D closed passage and B blocked passage (`Door` enum). Contents trigger once, except
  stairs (`REPEATABLE`).
- `scripts/floor_generator.gd` – seeded room-and-corridor floor generator.
  Set `floor_seed` on the Main node to replay a floor (the seed is printed at
  startup); `use_debug_layout` switches to the hand-drawn map.
- `scripts/minimap.gd` – draws the map: explored cells, passages, discovered
  contents, and the party arrow. Corner mode follows the party and emits
  `pressed` when tapped; `full_view` draws the whole explored floor scaled
  to fit (used by the full-screen map in main.gd, opened by tapping the
  minimap or pressing M/Tab, closed by tapping anywhere, M/Tab or Escape).
- `*.uid` files are generated by Godot; commit them alongside their scripts.

## Task tracking

Work is tracked as GitHub Issues: https://github.com/jonathanvarro/Depths/issues
Board (Todo / In Progress / Done): https://github.com/users/jonathanvarro/projects/2

- Milestones set the order: 1 · Explorable dungeon → 2 · Party and combat →
  3 · First playable expedition → 4 · Camp and campaign loop → 5 · Depth and
  polish → 6 · Later. Finish a milestone before starting the next unless the
  owner says otherwise.
- Labels: `exploration`, `party`, `combat`, `ui`, `platform`, `camp`, `art`
  (needs art, usually ChatGPT), `audio`, and `decision needed` (ask the
  owner; don't decide for them).
- When working on an issue, mention it in commit messages (e.g. `Refs #3`, or
  `Closes #3` when every "Done when" box is met).
- Move an issue to In Progress on the board when starting it and Done when
  closed (closing with `Closes #N` moves it automatically).
- New work that comes up goes in a new issue, not into an unrelated one.

## How we work

Multiple AI assistants (Claude and ChatGPT) work on this repo, one at a time,
with the owner handing off between them. They cannot see each other's
conversations, so this repo is the only shared memory.

1. **Read first.** Before changing anything, read this file and `NOTES.md`.
2. **One assistant at a time.** Don't assume the working tree is untouched
   since the last session — check `git status` and `git log` first.
3. **Small, focused changes.** Do the task asked; don't refactor unrelated code.
4. **Automatically commit and push completed tasks.** After completing a
   requested task, run appropriate checks, then automatically commit and push
   your own changes. Leave unrelated changes untouched. Stop and explain if
   checks fail, ownership of changes is unclear, or pushing requires resolving
   conflicts. Never force-push.
5. **Leave a handoff note.** At the end of a task, add an entry to the top of
   `NOTES.md` (see the format there).

## Conventions

<!-- TODO: Add code style, naming rules, things to avoid, etc. -->
- Owner is learning GitHub and programming: explain non-obvious changes in
  plain language.
