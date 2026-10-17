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
