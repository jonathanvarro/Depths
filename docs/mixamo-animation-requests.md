# Per-body Mixamo request pack · #215

2026-11-02. Owner authorized normalization as appropriate, then #215, and asked
for separate Google Drive model/request folders so they can obtain animations.
The private request pack is ready. The owner has now returned27 clips,
including both locomotion packs; current results are in
[received-animation-library.md](received-animation-library.md).
**Final #215/#214 acceptance still needs a quiet female chair hold and sequence/
contact acceptance. No Mixamo animations were acquired automatically.**

## Normalization decision

The two source rigs share49 bone labels with identical parent relationships.
Female has16 extra ring/pinky joints. Male is about5.87% taller; torso/leg/head
shapes differ as body variants. Equal bone counts or destructive proportion
changes are unnecessary for this animation request. Facial style/layout and
expressions remain separate future art; neither base has a facial rig.

The normalized review now uses one common presentation factor,
`0.44341862717489255`, giving female/male body heights about1.7003m/1.8000m.
`tools/blender_kit/display_normalization.json` records that policy. The uniform
parent scale preserves every length/height ratio. Each outfit's fixed rest-sole
reference becomes display y=0; its parent placement is constant across all
poses and wardrobe selections. It is not foot locking, animated root correction
or a physical/gameplay height stat. Existing contact defects remain visible.

The mesh, skeleton bind/rest/object transforms and Actions inside each source
remain unchanged, as do the fitted clothing and raw GLBs. Actual native restored
body bounds verify the intended display heights. Cameras/portrait framing use
the same scale, and the report records metric display gaps plus original-unit
gaps/hips separately. **Use the unchanged source FBXs for Mixamo**, keeping the
existing garment and animation contracts compatible. No new normalized bind rig
or re-rigging is needed.

## Drive organization and authorization

The connected private Drive now contains:

```text
3D Objects / Animations / Animation Requests - Depths /
  START HERE.txt
  Base Female /
    UPLOAD THIS - Base Female.fbx
    READ ME.txt
    Downloads /
  Base Male /
    UPLOAD THIS - Base Male.fbx
    READ ME.txt
    Downloads /
```

Both upload files are exact copies of the previously verified local
`Base Female - Dying.fbx` / `Base Male - Dying.fbx` (982,336 /736,240 bytes).
Their names make the correct upload obvious. The original Drive/source files
are not moved or replaced. The female upload may have a plain/gray preview;
this is an animation/rig pass, not texture authoring. Do not substitute the
unweighted `Base Male Mesh.fbx`.

Completed connector readback verified the model names, sizes, parent folders,
instructions and initially empty return folders. They are now populated with
the owner's uploads. All observed files/folders remain
unshared; no permissions were added. URLs/IDs and verified metadata are retained
locally in `build/local-blender-kit-v1/animation-requests-v1/drive-handoff.json`.
Source identity hashes and the two request sheets are beside it. Link the
observed folder URLs from that handoff when needed; do not guess IDs.

This is the owner's explicit exception to the earlier local-only instruction:
the two upload models and request text are copied into their private Drive.
All other source/derived art, animations, Blender masters and captures remain
local and out of Git; no assets are made public or uploaded to Mixamo by an agent.

## Four requests for each body

Keep the indicated character loaded while obtaining all four, then switch body.
Use **FBX / Without Skin /60fps / no keyframe reduction**, default speed, trim,
duration and arm-space. Save the exact filenames below in that body's
`Downloads` folder. Record different settings with a screenshot/`SETTINGS.txt`.
If Mixamo asks for marker placement/re-rigging, stop and preserve the file.
Adobe documents skeleton mapping for an uploaded already-rigged FBX in its
[rigged-character guide](https://helpx.adobe.com/creative-cloud/help/mixamo-rigging-animation.html).

| File | Request |
|---|---|
| Idle.fbx | Relaxed standing idle |
| Walking.fbx | Ordinary walk; enable In Place if offered |
| Stand To Sit.fbx | Standing into an upright chair sit |
| Sitting.fbx | Matching upright chair hold, hands near thighs, feet down |

The last request intentionally replaces `Sitting Idle.fbx` in the first batch.
Actual source-pose measurement found `Sitting.fbx` starts close to the end of
`Stand To Sit`: hips-to-feet height differs by0.00113 source units; the tested
head/spine/leg-axis deviations stay below2.48°. `Sitting Idle` is the reclined
ground pose: its lower legs differ by about81°/98°. Existing source
`Sitting.fbx` lasts7.0s at60fps. This evidence selects the better candidate;
it does not establish seamless final continuity on the returned per-body clips.
Keep ground idle separately in the catalog; do not relabel it as chair idle.

## #215 intake is prepared, not approved

The initial flat-cache audit reported eight requests awaited, with four passing
regression probes. The current owner batch uses27 original filenames in
individual/pack subfolders; **do not interpret the older flat-cache report as
current cloud absence or ask the owner to rename/re-download all these clips**.
Use the received manifest and new library audit. Both pack idle/walk pairs,
transitions and two seated candidates have been converted and body/native
checked. The remaining specific request is the quiet female matching chair
hold; her uploaded talking clip is retained as a separate conversation pose.

`audit_body_downloads.py` inspects incoming files without saving/importing them
into authoritative masters. It checks exact shared labels/parents, parent-local
rest rotations/translations, bone lengths, object transforms, actual FPS,
Action/slot/range metadata and missing channels. Only absent ring/pinky chains
may use the explicitly recorded rest-relative finger policy. A successful bind
audit is still marked **playback unapproved**. Unreadable files are reported as
access errors, not evidence of missing cloud data or a passing audit.

For subsequent work, use the Drive connector to discover/materialize returned
files into the ignored intake cache, preserving original files/hashes:

```text
build/local-blender-kit-v1/animation-requests-v1/incoming/female/
build/local-blender-kit-v1/animation-requests-v1/incoming/male/
```

Then run with Blender5.2.3:

```powershell
$clipAuditBlender = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$env:BLENDER_USER_RESOURCES = 'E:/GitHub/Depths/build/local-blender-kit-v1/blender-user'
& $clipAuditBlender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/blender_kit/audit_body_downloads.py -- --probe
```

Explicit `--female-dir` / `--male-dir` can select readable synced folders.
Older `Animations/Mixamo_Female` / `Mixamo_Male` locations remain acceptable
inputs if the owner used the earlier plan; inspect rather than rename originals.
Cloud availability must be checked through the connector if DriveFS is
unavailable. The preparer `prepare_animation_requests.py` regenerates only the
local request sheets/manifest and verifies the upload-source hashes; it never
creates folders or uploads bytes by itself.

After arrival, #215 still needs actual target-space/slot playback, all relevant
angles and between-key samples, chair transition/hold continuity, ground/root
and finger checks, save/reopen and independent Blender/Godot4.7.2 Mobile
deformation checks. Corrective retargeting is a fallback when the returned bind
does not match. Preserve #214's existing review until new clips are verified;
do not call final animation acceptance passed because the request pack is ready.
