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
  Main scene: `scenes/main.tscn`. Mouse clicks emulate touch
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
- `scripts/pack_screen.gd` – the Pack screen (Pack button under the minimap,
  or I/B). PartyState.use_item(), rest(), cannot_use_reason() do the work.
- `audio/placeholder/` – generated placeholder sounds (see its README for
  licence); rebuilt by `tools/make_placeholder_audio.py`.
- `scripts/dungeon_map.gd` – grid data (`is_wall`), cell contents
  (`Content` enum, `content_at`, `enter`), and explored cells. Layout text
  uses letters for contents: E encounter, C chest, T trap, O strange object,
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
  3 · First playable expedition. Finish a milestone before starting the next
  unless the owner says otherwise.
- Labels: `exploration`, `party`, `combat`, `ui`, `platform`, and
  `decision needed` (ask the owner; don't decide for them).
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
