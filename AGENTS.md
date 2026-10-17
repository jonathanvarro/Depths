# Depths

Shared context for AI assistants working on this project (Claude Code reads
this via CLAUDE.md; ChatGPT Codex reads AGENTS.md directly). Keep it current.

## About the project

<!-- TODO: Describe what Depths is in a few sentences. -->
- **What it is:** _TBD_
- **Language / engine / framework:** _TBD_
- **How to run it:** _TBD_
- **How to test it:** _TBD_

## Project structure

<!-- TODO: Fill in as folders are added, e.g. `src/` – game code. -->
_No files yet._

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
