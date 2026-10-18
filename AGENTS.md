# Depths

Shared context for AI assistants working on this project (Claude Code reads
this via CLAUDE.md; ChatGPT Codex reads AGENTS.md directly). Keep it current.

## About the project

- **What it is:** A dark, first-person grid dungeon crawler about party strain and dangerous discoveries. Start with a cave + campsite; complete dungeon sites to move toward larger threats such as a castle or demon portal. See `DESIGN.md` for current direction, proposals, and open decisions.
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
- `scripts/companion.gd` + `data/companions/*.tres` – hero definitions
  (Companion resource: identity, health, effects over time). The game
  plays with copies, never the .tres itself.
- `scripts/party_state.gd` – the party: up to 3 heroes, time elapsed
  (1 unit per step), completes timed effects on floor changes. Owned by
  main.gd (`_party_state`); starts with `starting_hero` (Mara).
- `scripts/portrait_set.gd` + `data/portraits/*.tres` – a character's
  layered portrait (aligned 192x192 layers, condition overlays, blink/talk
  frames). Companion.portrait_set points at one.
- `scripts/portrait_view.gd` – draws a PortraitSet; blink(), talk(), hurt(),
  set_condition().
- `scripts/party_card.gd` – HUD card per party slot (portrait, name, health
  bar, condition icons); main.gd builds three bottom-left. With F3 open,
  H hurts and J heals the first hero, to see the cards react.
- `scripts/supplies.gd` – lantern oil (burn scales with level, light
  bands, waste-free refills) and supply counts; owned by PartyState.
- `scripts/supply_item.gd` + `data/items/*.tres` – supply definitions
  (refill lantern / feed party / heal one, amounts, durations, use time).
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
- `scripts/expedition.gd` – one expedition's record (start snapshot plus
  counters) and its gained/lost lines; `Ending` RETURNED / WIPED /
  REACHED_BOTTOM.
- `scripts/results_screen.gd` – end-of-expedition screen. main.gd
  `_end_expedition()` shows it; `_start_new_expedition()` is the placeholder
  camp stop and re-entry from floor 1.
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
  main.gd) and `scripts/camp_screen.gd` (ChatGPT's art/camp/cave-camp-v1
  clearing + layout.json; one activity view per site id). `Injury.recovery_days`.
  `tools/camp_check.gd` drives every place (args: desk|phone, screenshot dir).
- Recruitment (#41): `scripts/recruits.gd` (roles, traits, names; `make(rng)`),
  CampState `candidates` / `hire` / `dismiss` / `leave_behind` / `rejoin`;
  Companion `guard_factor`, `toughness`, `strength`, `weakness`, `founder`.
  Placeholder portraits: `tools/art/build_recruit_silhouettes.py` (Pillow).
  `tools/recruit_check.gd` covers the fire, staying behind, a wipe and torches.
- `scripts/chest_screen.gd` – chest window beside the pack: drag (set_drag_
  forwarding), tap, or the take-all icon button; `took` signal.
- `scripts/pack_screen.gd` – the Pack screen (Pack button under the minimap,
  or I/B). PartyState.use_item(), rest(), cannot_use_reason() do the work.
- `audio/placeholder/` – generated placeholder sounds (see its README for
  licence); rebuilt by `tools/make_placeholder_audio.py`.
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
