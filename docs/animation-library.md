# Animation library

The shared list of every character animation clip the project has, so Claude,
ChatGPT and the owner can see what exists without opening `.fbx` / `.blend`
files. **Update this file whenever you add, test, rename or drop a clip.** It
holds information about the files only; the clips themselves stay local and
out of git (see `docs/blender-expedition-kit-tasks.md`).

## Where the files live

- **Originals:** `G:/My Drive/3D Objects/Animations/Mixamo_Originals/`, as
  downloaded from Mixamo. Never edit or rename these; work on copies.
- **Working copies:** `build/local-blender-kit-v1/source/clips/` (git-ignored),
  copied during #210. `audit_sources.py` / `audit_clips.py` inspect the copies;
  hashes are in `clip-sources.json` and `kit-manifest.json` beside them.
- **Base bodies:** `G:/My Drive/3D Objects/` — `Base Female Mesh.blend`,
  `Base Male Mesh.blend`, and the rigged `Base Female - Dying.fbx` /
  `Base Male - Dying.fbx`.
- **New per-body uploads:**27 files in
  `build/local-blender-kit-v1/animation-requests-v1/received-v1/`, with separate
  female/male and individual/locomotion namespaces. Current catalogue and
  body/native checks: [received-animation-library.md](received-animation-library.md).

## What every clip shares (measured 2026-11-01)

From #210's audit (`tools/blender_kit/audit_clips.py`, output
`build/local-blender-kit-v1/clip-audit.json`), Blender 5.2.3:

- 60 frames per second, one Action each, no mesh inside (skeleton only).
- The same 49-bone Mixamo skeleton (`mixamorig:Hips`, `mixamorig:Head` …),
  with49 names shared by both bases; the female base also has16 extra
  ring/pinky joints.
- **Male body:** bone lengths match exactly (ratio1.0), but its current
  lowered-arm rest pose differs from the clip rigs. Matching lengths do not
  establish a compatible rest basis or prove which download character was used.
- **Female body:** shared names, different proportions (bone lengths
  0.5–1.43× the male's). Expect clips to need retargeting, not a straight
  copy, before they look right on her.
- Matching names alone don't prove a clip works. The audit marks every
  pairing "measured, not approved". #210 also actually assigned Idle, Walking
  and Sitting Idle: both fits need rest-space retargeting (#215). Source-motion
  verification is not final garment/clip acceptance.

## Status words

| Word | Meaning |
|---|---|
| untested | Downloaded and audited; nobody has watched it on this body yet |
| works | Watched in Blender on this body, front/side/back, no obvious breakage |
| needs fix | Plays but something is wrong; say what in Notes |
| source-verified | Reopen/source/export deformation agrees; full multi-angle garment playback and owner acceptance remain separate |
| approved | Owner has accepted it for the game |
| dropped | Not going to be used; say why in Notes |

When you change a status, put the date and who in Notes, e.g.
`2026-11-02 Claude: feet slide on female`.

## Clips

Seconds = (last frame − first frame) / 60. "Loops?" and "In place?" (whether
Mixamo's *In Place* box was ticked, so the hips don't travel) are left as `?`
until someone checks; please fill them in when you do.

### Moving

| Clip file | Frames | Seconds | Loops? | In place? | Male | Female | Notes |
|---|---|---|---|---|---|---|---|
| Walking.fbx | 1–53 | 0.87 | ? | ? | needs fix | needs fix | 2026-11-01 ChatGPT #210: direct assignment gives wrong limb axes on both fits; retarget in #215 (local transfer-validation.json). |
| Female Walk.fbx | 1–70 | 1.15 | ? | ? | untested | untested | |
| Start Walking.fbx | 1–177 | 2.93 | ? | ? | untested | untested | |
| Injured Walking.fbx | 1–61 | 1.00 | ? | ? | untested | untested | |
| Jogging.fbx | 1–154 | 2.55 | ? | ? | untested | untested | |
| Running.fbx | 1–43 | 0.70 | ? | ? | untested | untested | |
| Standard Run.fbx | 1–44 | 0.72 | ? | ? | untested | untested | |
| Injured Run.fbx | 1–38 | 0.62 | ? | ? | untested | untested | |
| Jump.fbx | 1–131 | 2.17 | ? | ? | untested | untested | |
| Jumping Down.fbx | 1–151 | 2.50 | ? | ? | untested | untested | |
| Jumping Down (1).fbx | 1–231 | 3.83 | ? | ? | untested | untested | A different, longer clip from `Jumping Down.fbx`, not a duplicate |
| Pushing.fbx | 1–161 | 2.67 | ? | ? | untested | untested | |

### Standing, idle and social

| Clip file | Frames | Seconds | Loops? | In place? | Male | Female | Notes |
|---|---|---|---|---|---|---|---|
| Idle.fbx | 1–241 | 4.00 | ? | ? | needs fix | needs fix | 2026-11-01 ChatGPT #210: direct assignment gives wrong limb axes on both fits; retarget in #215 (local transfer-validation.json). |
| Unarmed Idle.fbx | 1–115 | 1.90 | ? | ? | untested | untested | |
| Look Over Shoulder.fbx | 1–227 | 3.77 | ? | ? | untested | untested | |
| Standing Greeting.fbx | 1–306 | 5.08 | ? | ? | untested | untested | |
| Talking.fbx | 1–310 | 5.15 | ? | ? | untested | untested | |

### Sitting and resting

| Clip file | Frames | Seconds | Loops? | In place? | Male | Female | Notes |
|---|---|---|---|---|---|---|---|
| Stand To Sit.fbx | 1–135 | 2.23 | ? | ? | untested | untested | |
| Sitting.fbx | 1–421 | 7.00 | ? | ? | untested | untested | 2026-11-02 ChatGPT: source start pose inspected against Stand To Sit end; hips/feet height differs0.00113 source units, sampled axes <2.48°. Chosen for per-body chair-hold requests; actual body playback remains untested. |
| Sitting Idle.fbx | 1–616 | 10.25 | ? | ? | needs fix | needs fix | 2026-11-01 ChatGPT #210: direct assignment gives wrong limb axes on both fits; retarget in #215 (local transfer-validation.json). |
| Sitting Talking.fbx | 1–2644 | 44.05 | ? | ? | untested | untested | Very long; largest file (5.6 MB) |
| Situp To Idle.fbx | 1–265 | 4.40 | ? | ? | untested | untested | |

### Combat and actions

| Clip file | Frames | Seconds | Loops? | In place? | Male | Female | Notes |
|---|---|---|---|---|---|---|---|
| Punching.fbx | 1–76 | 1.25 | ? | ? | untested | untested | |
| Swinging.fbx | 1–147 | 2.43 | ? | ? | untested | untested | |
| Body Block.fbx | 1–207 | 3.43 | ? | ? | untested | untested | |
| Shooting Arrow.fbx | 1–301 | 5.00 | ? | ? | untested | untested | |
| Throwing.fbx | 1–168 | 2.78 | ? | ? | untested | untested | |
| Throw Object.fbx | 1–293 | 4.87 | ? | ? | untested | untested | A different clip from `Throwing.fbx` |
| Sheath A Great Sword 1.fbx | 1–45 | 0.73 | ? | ? | untested | untested | |

### Hurt and dying

| Clip file | Frames | Seconds | Loops? | In place? | Male | Female | Notes |
|---|---|---|---|---|---|---|---|
| Hit To Body.fbx | 1–70 | 1.15 | ? | ? | untested | untested | |
| Standing Death Right 02.fbx | 1–141 | 2.33 | ? | ? | untested | untested | |
| *Dying* (inside `Base … - Dying.fbx`) | 1–261 | 4.33 | No: standing → fallen | No: source body travels | source-verified | source-verified | 2026-11-01 ChatGPT #210: each own Action/OBSlot survives reopen; source/GLB deformation matches at six frames incl. between keys; Godot import/motion passes. Full garment/multi-angle motion acceptance remains pending. |

### Single poses (2 frames, not motion)

| Clip file | Frames | Male | Female | Notes |
|---|---|---|---|---|
| Male Standing Pose.fbx | 1–2 | untested | untested | |
| Male Laying Pose.fbx | 1–2 | untested | untested | |
| Female Sitting Pose.fbx | 1–2 | untested | untested | |

### Other

- `Base Female Mesh.blend` and `Base Male Mesh.blend` each hold an Action
  named `mixamo.com`, frames 1–998 (16.6 s). What it is hasn't been recorded
  yet; it is not an approved alternate clip. The male reference has no
  armature/modifier, so its orphaned Action is not working male motion.
- #210 preserved true source masters and measured the direct-copy gap; see
  [the base contract](blender-base-contract.md). #215 retargets the existing
  supplied clips; #214 performs complete garment/motion acceptance. The
  owner now prefers per-body re-downloads (see the plan below), which would
  replace most of #215's retargeting.

## Plan: download each clip on its own body (owner decision, 2026-11-02)

Instead of hand-retargeting `Mixamo_Originals` onto each body, the owner will
re-download the clips from Mixamo with each base body loaded. Mixamo fits an
animation to whichever character is loaded, so each clip arrives already
matching that body's skeleton and rest pose. Evidence it works: each base's
own Dying clip was downloaded that way and already passes #210's checks.

- **Upload:** `Base Female - Dying.fbx` / `Base Male - Dying.fbx`, the same
  files #210 built the masters from ([base contract](blender-base-contract.md)).
  If Mixamo offers to re-rig the body, **stop**: a new skeleton would no
  longer match the masters or clothing fitted to them.
- **Download settings:** FBX, Without Skin, 60 fps. Note whether *In Place*
  was ticked.
- **Current folders:** `3D Objects/Animations/Animation Requests - Depths/`
  in private Drive now has `Base Female` / `Base Male`, each with the verified
  upload FBX, instructions and a `Downloads` child. Owner explicitly requested
  these private copies on2026-11-02. Earlier `Mixamo_Female` / `Mixamo_Male`
  paths remain valid intake alternatives. `Mixamo_Originals` stays untouched.
- **Order:** Idle, Walking (In Place), Stand To Sit and **Sitting** (chair hold)
  on both bodies. The supplied Sitting start closely matches the chair
  transition; Sitting Idle is a different ground pose. This refinement follows
  the owner's delegated preparation request; see
  [the request pack and source-pose evidence](mixamo-animation-requests.md).
- **Checking:** an assistant audits the new folders, confirms the skeleton
  and rest pose match the master exactly, watches them play, and adds Male /
  Female statuses here. If a per-body download still doesn't match, fall
  back to #215's retargeting for that clip.

This doesn't scale to many body shapes (each needs every clip again); if the
game later has several builds, Godot's import-time retargeting can share one
set. For two bodies, re-downloading is simpler.

The two ready upload files retain exact source bytes, bind rigs and body fits.
Display normalization is a separate shared parent scale/ground reference;
it does not change the FBXs. The owner has now returned27 files, including two
ten-clip locomotion packs. Eight selected motions have exact world-pose
conversion and sampled Blender/native review; a quiet female matching chair
hold and final sequence/contact acceptance remain open. The older flat-cache
"eight missing" report is historical preflight, not the current library state.

## New per-body batch (2026-11-02)

All27 uploads are 60fps, with 65 female /49 male joints and body-matched bone
lengths/hierarchy. Mixamo rebased their rest orientations, so direct Action
assignment is still unsuitable. Eight selected candidates use source-world
matrix conversion into the unchanged target rest rig; source travel/timing are
preserved. This is not owner approval, loop approval or live integration.

| Pack role | Female file · frames | Male file · frames | Current status |
|---|---|---|---|
| Idle | idle.fbx ·1–501 | idle.fbx ·1–501 | Both converted; sampled body/GLB/native review passes |
| Walk | walking.fbx ·1–58 | walking.fbx ·1–63 | Both converted/reviewed; traveling, not in-place |
| Run | running.fbx ·1–43 | standard run.fbx ·1–44 | Source/bind audited; body playback pending |
| Jump | jump.fbx ·1–101 | jump.fbx ·1–131 | Source/bind audited; body playback pending |
| Strafe left | left strafe.fbx ·1–41 | left strafe.fbx ·1–41 | Source/bind audited; body playback pending |
| Strafe right | right strafe.fbx ·1–41 | right strafe.fbx ·1–41 | Source/bind audited; body playback pending |
| Walk strafe left | left strafe walk.fbx ·1–56 | left strafe walking.fbx ·1–63 | Source/bind audited; body playback pending |
| Walk strafe right | right strafe walk.fbx ·1–56 | right strafe walking.fbx ·1–63 | Source/bind audited; body playback pending |
| Turn left | left turn.fbx ·1–71 | left turn 90.fbx ·1–57 | Source/bind audited; body playback pending |
| Turn right | right turn.fbx ·1–71 | right turn 90.fbx ·1–57 | Source/bind audited; body playback pending |

| Body | Individual file | Frames / seconds | Current status |
|---|---|---|---|
| Female | Standing Idle.fbx |1–361 /6.00s| Source/bind audited; body playback pending |
| Female | Stand To Sit.fbx |1–135 /2.23s| Converted; sampled body/GLB/native review passes |
| Female | Sitting Talking.fbx |1–2699 /44.97s| Converted/reviewed conversation pose; crosses a leg, not the missing quiet chair hold |
| Male | Neutral Idle.fbx |1–526 /8.75s| Source/bind audited; body playback pending |
| Male | Stand To Sit.fbx |1–135 /2.23s| Converted; sampled body/GLB/native review passes |
| Male | Sit To Stand.fbx |1–136 /2.25s| Converted and independently checked on the body in assembly-v2; native stand-up matrix passes |
| Male | Sitting Idle.fbx |1–258 /4.28s| Converted/reviewed chair idle; different asset from the older 616-frame ground pose |

Seconds are(last−first)/60; filenames and hashes are preserved in the local
manifest. All loops and final sit/hold continuity remain unapproved. Male
sit/hold needs explicit clip-placement alignment; female needs the matching
quiet hold. Earlier fitting masters/reviewer stay unchanged.

**Current assembled delivery:** [assembly-v2](current-wardrobe-review.md) uses
the chosen body-specific idle/walk, chair transitions, female seated talking /
male chair idle, and both original Dying Actions. All six per-body Actions have
reopen/fit, independent export and real native motion/angle/coverage checks.
Female conversation is an explicit seated stress test, sufficient to inspect
the kit; a calm hold is still unavailable. #214/#215 remain open, with final
contact/registration/loop/quiet-idle polish tracked in #218 without waiving their
acceptance criteria.

## Female chair follow-up (2026-11-02)

The owner added `Sit To Stand.fbx` (1–136, 2.250s) and re-uploaded
`Stand To Sit.fbx` (1–135, 2.233s), both on her 65-joint body at 60fps.
[Separate intake review](female-chair-transition-review.md): both transitions
are converted and sampled body/independent-export/native checked. The earlier
27-file batch and candidate masters remain unchanged. The new sit-down's three
audited poses match the earlier version, despite different file bytes.

Sit-down end and stand-up start have similar posture but different root
placement (about 1.074 source units); explicit placement alignment and full
sequence/contact checks remain. A quiet matching seated hold is still missing;
Sitting Talking remains a conversation pose. No loops or final continuity are
approved; the assembled candidate is now delivered and remaining polish is #218.
This is one additional motion plus a retained
re-upload version, not two new locomotion packs.

## Female chair hold (2026-11-02, Claude, #218)

The owner uploaded female `Sitting.fbx` and `Sitting Idle.fbx`;
[hold review](female-chair-hold-review.md). Both are 60fps, 65 joints, matched
to her body, uncrossed and loop cleanly; converted into a separate
`female_hold.blend` and rendered. No export/Godot check or assembly-v2
hookup yet; owner picks between them.

| Body | Clip | Frames | Status | Notes |
|---|---|---|---|---|
| Female | Sitting.fbx | 1–421 / 7.00s | untested in engine | Recommended hold: same seat height and legs as the sit-down end; ends 0.002 from stand-up placement. Looks around, arms shift; lower body still. |
| Female | Sitting Idle.fbx | 1–179 / 2.97s | untested in engine | Stiller alternative (~1° motion) but sits ~0.1 higher, knees ~18° and hands 24–39° off the transitions; needs a blend. |

## Garment fitting references (2026-11-02, ChatGPT)

#211–#213 include temporary retargeted **copies** of four legacy clips in
`build/local-blender-kit-v1/garments-v1/{female,male}_garments.blend`. This does
not change the raw-clip statuses above or supersede the per-body download plan.
These are garment stress tests, not approved animation choices; #215 stays open.

| Legacy source | Local Action on each fit | Candidate status / findings |
|---|---|---|
| Idle.fbx | fit.female.idle / fit.male.idle | Source/export-verified; actual front/side/back start/middle/end captures. Rest-space axis error corrected. |
| Walking.fbx | fit.female.walk / fit.male.walk | Source/export-verified; between-key checks and12 real gait samples per fit. Source lateral travel retained; loop/in-place acceptance remains open. |
| Stand To Sit.fbx | fit.female.sit_down / fit.male.sit_down | Source/export-verified; ends at chair height. Seat/hand contact is not finalized. |
| Sitting Idle.fbx | fit.female.seated / fit.male.seated | Source/export-verified; a reclined ground sit, **not** a continuous hold for Stand To Sit. |
| Each body's original Dying | Original Action / OBSlot retained | Rechecked with garments and independent Blender/Godot exports; no source motion edits. |

All candidate copies retain60fps, full original durations and explicit saved
Action slots. Additional female ring/pinky joints retain their rest-relative
pose under the animated parent. Target-only vertical toe-height reconciliation
is recorded; no foot locking, source-root editing or contact IK. Read
[the garment handoff](blender-expedition-garments.md) for exact lineage,
local captures and limits. Other supplied clips remain untested.

#214's [native wardrobe review](blender-wardrobe-review.md) (2026-11-02) checks
these same candidate Actions with reversible clothing, full restored-body
deformation, three sampled times/angles, native96/192 cards and recorded
ground-envelope/hips positions. This adds presentation evidence, not new clips
or approval: #215's per-body downloads and matching sit/hold acceptance remain
open, and the raw-clip statuses above are unchanged.

## Adding a clip

1. Download from Mixamo as **FBX**, **Without Skin**, at 60 fps, once with
   each base body loaded (see the plan above). Write down whether *In Place*
   was ticked.
2. Save each copy to that body's folder (`Mixamo_Female/` or `Mixamo_Male/`)
   with Mixamo's name.
3. Add a row above (frames and seconds can come from re-running
   `tools/blender_kit/audit_clips.py`, or from Blender's timeline).
4. Mention the new clip in your `NOTES.md` handoff entry.

Mixamo's terms allow its clips in games, but not redistributing the raw files
on their own; another reason they stay out of git.
