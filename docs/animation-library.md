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
  copied by #210's `tools/blender_kit/audit_sources.py`, which records each
  file's SHA-256 in `build/local-blender-kit-v1/clip-sources.json`.
- **Base bodies:** `G:/My Drive/3D Objects/` — `Base Female Mesh.blend`,
  `Base Male Mesh.blend`, and the rigged `Base Female - Dying.fbx` /
  `Base Male - Dying.fbx`.

## What every clip shares (measured 2026-11-01)

From #210's audit (`tools/blender_kit/audit_clips.py`, output
`build/local-blender-kit-v1/clip-audit.json`), Blender 5.2.3:

- 60 frames per second, one Action each, no mesh inside (skeleton only).
- The same 49-bone Mixamo skeleton (`mixamorig:Hips`, `mixamorig:Head` …),
  with the same bone names as both base bodies.
- **Male body:** bone lengths match exactly (ratio 1.0), so the clips were
  downloaded on the male skeleton.
- **Female body:** same bone names, different proportions (bone lengths
  0.5–1.43× the male's). Expect clips to need retargeting, not a straight
  copy, before they look right on her.
- Matching names alone don't prove a clip works. The audit marks every
  pairing "measured, not approved" until someone has watched it play.

## Status words

| Word | Meaning |
|---|---|
| untested | Downloaded and audited; nobody has watched it on this body yet |
| works | Watched in Blender on this body, front/side/back, no obvious breakage |
| needs fix | Plays but something is wrong; say what in Notes |
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
| Walking.fbx | 1–53 | 0.87 | ? | ? | untested | untested | |
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
| Idle.fbx | 1–241 | 4.00 | ? | ? | untested | untested | |
| Unarmed Idle.fbx | 1–115 | 1.90 | ? | ? | untested | untested | |
| Look Over Shoulder.fbx | 1–227 | 3.77 | ? | ? | untested | untested | |
| Standing Greeting.fbx | 1–306 | 5.08 | ? | ? | untested | untested | |
| Talking.fbx | 1–310 | 5.15 | ? | ? | untested | untested | |

### Sitting and resting

| Clip file | Frames | Seconds | Loops? | In place? | Male | Female | Notes |
|---|---|---|---|---|---|---|---|
| Stand To Sit.fbx | 1–135 | 2.23 | ? | ? | untested | untested | |
| Sitting.fbx | 1–421 | 7.00 | ? | ? | untested | untested | |
| Sitting Idle.fbx | 1–616 | 10.25 | ? | ? | untested | untested | |
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
| *Dying* (inside `Base … - Dying.fbx`) | 1–261 | 4.33 | ? | ? | untested | untested | Comes attached to each rigged base, not a separate file |

### Single poses (2 frames, not motion)

| Clip file | Frames | Male | Female | Notes |
|---|---|---|---|---|
| Male Standing Pose.fbx | 1–2 | untested | untested | |
| Male Laying Pose.fbx | 1–2 | untested | untested | |
| Female Sitting Pose.fbx | 1–2 | untested | untested | |

### Other

- `Base Female Mesh.blend` and `Base Male Mesh.blend` each hold an Action
  named `mixamo.com`, frames 1–998 (16.6 s). What it is hasn't been recorded
  yet; whoever opens it, please name it here.

## Adding a clip

1. Download from Mixamo as **FBX**, **Without Skin**, at 60 fps, using the same
   character as the existing clips so the skeleton matches. Write down whether
   *In Place* was ticked.
2. Save it to `Mixamo_Originals/` with Mixamo's name.
3. Add a row above (frames and seconds can come from re-running
   `tools/blender_kit/audit_clips.py`, or from Blender's timeline).
4. Mention the new clip in your `NOTES.md` handoff entry.

Mixamo's terms allow its clips in games, but not redistributing the raw files
on their own; another reason they stay out of git.
