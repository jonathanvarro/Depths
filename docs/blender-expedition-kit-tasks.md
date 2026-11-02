# Blender expedition clothing kit: agent handoff

Owner requested these work tasks on 2026-11-01. This handoff creates the backlog; it does not start modelling or replace the current artwork.

Parent: [#209 — Blender expedition kit](https://github.com/jonathanvarro/Depths/issues/209).

| Order | Task | Deliverable |
|---|---|---|
| 1 | [#210 — Base masters and rig contract](https://github.com/jonathanvarro/Depths/issues/210) | Audited female/male editable Blender masters, consistent fit/export conventions and a working animation/Action-slot reference |
| 2 | [#211 — Tunic and separate belt](https://github.com/jonathanvarro/Depths/issues/211) | One practical low-poly tunic design fitted and weighted to both bodies |
| 2 | [#212 — Trousers](https://github.com/jonathanvarro/Depths/issues/212) | Both fits, checked at the waist, seat, crotch, knees and boot cuffs |
| 2 | [#213 — Mid-calf leather boots](https://github.com/jonathanvarro/Depths/issues/213) | Male/female left/right fits with clear soles/cuffs and working ankle/toe deformation |
| 3 | [#214 — Assembly, animation and Godot review](https://github.com/jonathanvarro/Depths/issues/214) | Complete kits, real motion/fit checks, independent exports and one local review entry point |

Start with **#210**, then implement the garments against that contract. The garment interfaces must agree before final assembly. The same agent can work sequentially through the set; separate agents must coordinate ownership before modifying shared Blender masters or handoff files. No agent is launched by this task-creation pass.

## Scope to preserve

- Use the owner's supplied male and female humanoid bases and existing Mixamo animations. Preserve bone names/hierarchy/rest poses and Actions; test actual compatibility rather than assuming matching names are enough.
- Build a simple tunic, separate belt, trousers and boots first. A padded jacket is a later variation after the tunic fitting workflow works. New shield/cape/pack models and a full cast are outside the first kit.
- The owner explicitly deferred face painting. Preserve source faces; do not add facial painting/features, named likenesses or new character art. Hair/face authoring is separate.
- Deliver **editable `.blend` masters**, separate named garment objects, both body fits, materials, weights/modifier provenance and local rigged exports. A procedural Godot shell or an image alone is not the Blender deliverable.
- Clothing can start from body-derived geometry, but visible hems/seams, silhouette and deformation need deliberate shaping. Covered-body masking must be reversible and correct when pieces are removed or swapped.
- Test idle, sit-down/seated hold, walking and dying on both bodies, including between-key frames and front/side/back. Use existing clips; list missing/access-limited clips as dependencies instead of fabricating coverage or creating an unnecessary custom animation library.
- Keep Godot4.7.2/Mobile and an isolated review project. Check readable96/192px portraits and landscape phone-shaped views with mouse/touch controls. Desktop captures do not establish physical-iPhone performance.
- No item wear/repair, equipment-stat changes, new gameplay slots, source-body redesign, live camp/HUD/portrait/save integration or replacement of approved2D art.

## Local assets and preparation

The owner supplied these entry points:

- `G:/My Drive/3D Objects/Base Female - Dying.fbx`
- `G:/My Drive/3D Objects/Base Male - Dying.fbx`

These were **not audited in this task-creation pass**: the filesystem metadata read was denied. That is not evidence that the files are absent. The next agent should resolve actual access and inspect the source pair before promising a rig/fitting contract. Do not silently substitute the earlier female-only sample or invent a missing male base.

Keep supplied sources, `.blend` masters, derived meshes/textures, exports, animation files and captures **local in a git-ignored folder**, suggested `build/local-blender-kit-v1`. Record source hashes and retain originals. Only reusable tools, templates, non-asset documentation and test summaries should be committed unless the owner later changes the local-only preference. Do not upload source art to an external service or obtain paid assets as an inferred part of these tasks.

## Existing work to use carefully

- [docs/fbx-companion-trial.md](fbx-companion-trial.md) and `tools/fbx_companion_trial/README.md` describe #206's local working example. Local gallery: `build/local-fbx-trial/review/inspector.html`.
- #206 fitted an earlier female body twice with different hair/colour, not the current male/female pair. Its clothing was a Godot-authored fit shell, not an editable Blender production wardrobe.
- That source used eight influences per body vertex and four for hair, with nontrivial bind-space/scale conversion. Inspect the new pair independently; do not copy those assumptions blindly.
- Blender5.2.3 was observed during owner learning. Assigning an Action can require selecting its existing **Action Slot** as well; the slot's name need not match the target armature. Preserve animations on save/reopen and document one known-working assignment.
- #194/#195 concern inventory icons, not these garment meshes. #181/#197–#201 concern named portrait/cast work and are not closed by this kit.

## Completion and review

Each task defines its own deliverables and checks. #214 should provide one local gallery/project with male/female selectors, garment visibility, animations, pause/scrub, useful angles and actual captures. Record polygon/surface/material/texture counts, source clip settings, fitting limitations and export/reimport results.

Tasks deliver reviewable production candidates. The owner's final style/asset acceptance and any later live integration remain separate; no new approval flow is required merely to carry out the already requested modelling and reversible fixes.
