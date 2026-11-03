# Uploaded per-body animation library · #215

Follow-up: the owner has since added female Sit To Stand and re-uploaded Stand
To Sit. [The transition review](female-chair-transition-review.md) records both
separately; a quiet female chair hold remains missing. The 27-file catalogue
below describes the preserved first batch.

2026-11-02. The owner populated the private request folders with 27 clips:
13 female and 14 male. Both include a ten-animation locomotion pack; the other
seven are individual idle/seated clips. All originals are preserved, with Drive
metadata, sizes and SHA-256 identities in the ignored local source manifest.
No Drive files were moved, renamed or replaced.

Local review:
`build/local-blender-kit-v1/animation-requests-v1/received-v1/candidates-v1/review/inspector.html`.

## Recommended starting set

Use each body's **pack idle and walking pair** as the first consistent baseline.
Keep the alternate Standing Idle/Neutral Idle for later character-specific
review. Run, jump, turns and strafes are useful retained options; they do not
need live gameplay rules or immediate hookup just because they are available.

| Body | Uploaded group | Original filenames |
|---|---|---|
| Female | Locomotion pack | idle, walking, running, jump, left/right turn, left/right strafe, left/right strafe walk |
| Male | Locomotion pack | idle, walking, standard run, jump, left/right turn90, left/right strafe, left/right strafe walking |
| Female | Individual | Standing Idle, Stand To Sit, Sitting Talking |
| Male | Individual | Neutral Idle, Stand To Sit, Sitting Idle, Sit To Stand |

All entries above are `.fbx`. The gallery catalogs every exact filename,
duration, FPS, joint count and source-root travel. Source-only inspection is
distinguished from converted/body-reviewed candidates; the remaining 19 clips
are not falsely marked as having passed garment playback.

The newly uploaded male **Sitting Idle** is an upright chair hold, despite
sharing a name with the older 616-frame ground pose. It lasts 257/60 seconds;
the chair transition's ending posture is close (head/hip/leg axes mostly within
about 2.6°, right forearm about 3.2°, right foot about 5.5°). Original filenames
are retained in separate source namespaces; do not interchange them by name.

The female **Sitting Talking** crosses a leg and gestures. Its starting posture
differs materially from the end of Stand To Sit (right lower leg about 36.7°,
right foot about 53.5°). Retain it as a conversation candidate. **A quiet female
chair hold matching her transition is still needed** for final #215 acceptance.
The likely next request is the upright `Sitting` variant described in
[the request handoff](mixamo-animation-requests.md), downloaded on her uploaded
body; judge its preview/pose rather than its filename alone.

## What the uploads establish

- All27 are 60fps and have the intended complete 65/49-joint sets.
- Labels, hierarchy and body-specific bone lengths match the intended original
  bases. This is stronger evidence than the gendered pack title alone.
- Mixamo changed the **rest bases** on download: maximum parent-local rest-angle
  differences are about 38.77° female /41.31° male. Matching lengths do not make
  direct Action assignment valid. These files are useful; they need coordinate
  conversion rather than another round of proportion retargeting/downloads.
- Pack walks travel: approximately 3.448 female /3.101 male source units over
  0.950s /1.033s. They were not delivered as in-place walks. Preserve their paths;
  any future in-place sibling must be separately named/documented. No such
  derivative, loop approval or gameplay movement rule was added here.

## Eight converted review candidates

New editable `female_received.blend` / `male_received.blend` are in the local
`candidates-v1` folder. Their original bodies, UVs, weights, bind/rest rigs,
garment objects/modifiers and original Dying Actions/slots remain unchanged.
Their four new Actions are `received.<body>.idle`, `.walk`, `.sit_down`, `.seated`.
The female `seated` Action is explicitly a **talking candidate**, not an approved
neutral hold. Earlier masters and the normalized interactive #214 reviewer are
preserved; those older fitting Actions are not silently replaced.

`convert_received_candidates.py` copies the uploaded **world joint matrices**
into each target's original rest space and records explicit Action slots.
Because these downloads match the body's lengths/hierarchy, no limb scaling,
hip-height ratio or toe-height reconciliation is required. It preserves every
frame, duration, finger joint and source root trajectory. Quaternion signs are
continuous; between-key samples are checked. No floor/contact IK, animation
trim, invented motion, source edits or new face art is used.

Actual source-vs-target joint comparisons at five samples of each selected
clip, including half frames, have maximum positional error below 0.00002 source
units; measured limb-axis differences are zero at the diagnostic's precision.
Independent exported skin/cloud comparisons remain below 0.00010 source units.
Self-contained full-kit and garment-part GLBs retain materials and five intended
motions (four received candidates plus original Dying).

Full outfits remain 4,198/2,654 triangles and 11 visible surfaces. Source units
and raw object transforms remain unchanged in these files; the shared
[display normalization](mixamo-animation-requests.md) is a separate presentation
parent, not a new FBX bind scale or canonical character-height stat.

## Checks, contacts and remaining work

- 2,961 Blender checks pass after reopening: source rig/skin preservation,
  normalized weights, reversible coverage, selected deformation frames and
  sole/source-foot envelopes.
- 492 independent disk export/reimport checks pass across the two body fits,
  every body/garment mesh, rest and four samples of all five animations.
- 14,417 actual Godot4.7.2 Mobile checks pass:65/49 joints, complete meshes,
  skin weights, texture/material behavior, CPU/native skin bakes and motions.
  Runtime logs are clean; restricted editor import retains its existing
  preference safe-save warning.
- 138 actual Blender captures, two real-frame gait GIFs, six contact sheets and
  two native import renders are available. 220 integrity checks preserve all 27
  new sources,39 earlier sources, original garment masters, selected pose
  evidence and reviewed exports. 80 browser checks verify captures, links,
  catalogue, pause/resume and phone-sized layout/readability of the gallery.

The male chair hold starts about 0.906 source units from the sit-down clip's
ending hips position. Pose similarity is not a claim that raw clips can be
chained without a placement jump. A future controller must align clip placement
explicitly while preserving source curves; blending/contact behavior is not
approved here. Female talking also differs in posture, not just placement.
Ground/seat/finger polish, exact loops, the missing female quiet hold, complete
transition/hold playback and owner style acceptance keep **#215/#214 open**.
Desktop native checks are not physical-iPhone performance evidence.

## Reproduction and handoff

Use Drive discovery/metadata and authenticated raw-file references to materialize
the originals. Keep signed download URLs transient; only stable Drive identity
metadata and source hashes belong in the ignored manifest. The connector's
temporary URL initially failed DNS in the restricted runtime; the approved local
download materialized complete byte counts. No cloud absence was inferred.

Local inputs and reports:

```text
animation-requests-v1/received-v1/
  source-manifest.json
  female/{individual,locomotion}/<original filename>.fbx
  male/{individual,locomotion}/<original filename>.fbx
  library-audit.json
  candidates-v1/
    female_received.blend / male_received.blend
    female-manifest.json / male-manifest.json
    exports/          # full-kit and garment-part candidates
    godot-smoke/      # isolated actual engine checks
    review/inspector.html
```

Run with Blender5.2.3, placing `--python-exit-code 1` before `--python`:
`audit_received_library.py`, then `convert_received_candidates.py`, then
`review_received_candidates.py -- --mode check`, `--mode export` and
`--mode capture`. The capture wrapper supplies its matrix/motion flags.
Converted masters are protected against overwriting subsequent manual edits.
`prepare_received_smoke.py` creates the isolated Godot import/check project;
import it with Godot4.7.2 and run `--script check.gd`. Finally run
`package_received_review.py` and `check_received_gallery.cjs`.

The original flat request-cache audit is historical preflight, not evidence that
these newly uploaded differently named clips are missing. Use this manifest and
catalogue as the current intake. Only reusable tools and non-asset documentation
go to Git. All source/derived media stay local/private; no live camp, portrait,
movement, combat, save or equipment bindings are changed.
