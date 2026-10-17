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
