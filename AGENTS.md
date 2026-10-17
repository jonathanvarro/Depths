# Depths

Shared context for AI assistants working on this project (Claude Code reads
this via CLAUDE.md; ChatGPT Codex reads AGENTS.md directly). Keep it current.

## About the project

- **What it is:** A dark, first-person grid dungeon crawler about party strain, dangerous discoveries, and descending through increasingly difficult procedural floors. See `DESIGN.md` for current direction, proposals, and open decisions.
- **Language / engine / framework:** Godot 4.7, GDScript, Mobile renderer
  (chosen for iPhone performance). Don't upgrade the Godot version without
  the owner's OK.
- **Target platforms:** Windows and iPhone (iOS). Design every screen for
  both mouse/keyboard and touch from the start; keep UI readable on a phone.
  iOS builds must be exported and signed on a Mac with Xcode.
- **How to run it:** Open `project.godot` in the Godot editor and press F5.
  No main scene is set yet. Mouse clicks emulate touch
  (`input_devices/pointing/emulate_touch_from_mouse`) so touch input can be
  tested on Windows.
- **How to test it:** _TBD_

## Project structure

- `DESIGN.md` – living design direction and proposed first playable scope.
- `AGENTS.md` / `CLAUDE.md` – shared assistant instructions and entry point.
- `NOTES.md` – handoff history between assistants.
- `project.godot` – Godot project settings. Prefer changing settings in the
  editor; if editing by hand, keep changes minimal.
- `.godot/` – Godot's local cache; ignored by git, never commit it.
- No game code or scenes yet.

## How we work

Multiple AI assistants (Claude and ChatGPT) work on this repo, one at a time,
with the owner handing off between them. They cannot see each other's
conversations, so this repo is the only shared memory.

1. **Read first.** Before changing anything, read this file and `NOTES.md`.
2. **One assistant at a time.** Don't assume the working tree is untouched
   since the last session — check `git status` and `git log` first.
3. **Small, focused changes.** Do the task asked; don't refactor unrelated code.
4. **Don't commit or push unless the owner asks.** The owner commits between
   handoffs so every assistant's work is a separate, reviewable snapshot.
5. **Leave a handoff note.** At the end of a task, add an entry to the top of
   `NOTES.md` (see the format there).

## Conventions

<!-- TODO: Add code style, naming rules, things to avoid, etc. -->
- Owner is learning GitHub and programming: explain non-obvious changes in
  plain language.
