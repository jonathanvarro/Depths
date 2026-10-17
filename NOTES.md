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
