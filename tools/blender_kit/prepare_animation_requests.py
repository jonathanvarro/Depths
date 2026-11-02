"""Write local #215 request sheets; explicit owner-requested Drive upload is separate."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';OUT=BASE/'animation-requests-v1'
CLIPS=['Idle.fbx','Walking.fbx','Stand To Sit.fbx','Sitting.fbx']
def main():
    OUT.mkdir(exist_ok=True)
    source=json.loads((BASE/'kit-manifest.json').read_text());expected={e['file']:e['sha256'] for e in source['sources']}
    policy=json.loads(Path(__file__).with_name('display_normalization.json').read_text())
    records={}
    for fit in ['female','male']:
        title=fit.title();model=BASE/'source'/('Base '+title+' - Dying.fbx');digest=hashlib.sha256(model.read_bytes()).hexdigest()
        assert digest==expected['source/'+model.name]
        (OUT/'incoming'/fit).mkdir(parents=True,exist_ok=True)
        text=f'''DEPTHS / BASE {title.upper()} / MIXAMO REQUESTS

1. Download "UPLOAD THIS - Base {title}.fbx" from this folder.
2. Upload that FBX to Mixamo. It is the already-rigged model used by the
   current clothing. Keep this same character loaded for all four requests.
   If Mixamo asks you to place rigging markers or re-rig it, stop and leave
   it unchanged; that would create a different skeleton. A gray/plain skin
   preview is acceptable for this animation-only pass.
3. Download the four clips below with these project settings:
   Format: FBX / FBX Binary (.fbx)
   Skin: Without Skin
   Frames per second: 60
   Keyframe Reduction: None
   Full clip: keep the default timing/trim, speed and arm-space settings.

SAVE THESE FOUR FILES INTO THE "Downloads" SUBFOLDER FOR THIS BODY:
  Idle.fbx           - a relaxed standing idle.
  Walking.fbx        - ordinary walking; enable In Place if offered.
  Stand To Sit.fbx   - standing into an upright CHAIR sit.
  Sitting.fbx        - upright CHAIR hold, knees bent, feet down.

For clips without an In Place option, leave them as supplied. Do not trim,
mirror, rename bones, combine clips, or reuse downloads from the other body.
Use the listed filenames in each body's separate Downloads folder. Note any
settings that differ from the above (a screenshot or SETTINGS.txt is enough).

IMPORTANT SEATED CHOICE
The old "Sitting Idle" is a reclined GROUND pose. It does not match the chair
transition. Request "Sitting" for this first batch. The previous source's
chair hold is approximately seven seconds at 60fps; choose the chair pose
with hands near the thighs. We will verify the returned pairing before
claiming a seamless sit-down/hold sequence.

The original filename contains "Dying" because that is the validated source
package. Its model and skeleton are the ones to use; select the requested
animations in Mixamo after upload. Do not substitute the unweighted
"Base Male Mesh.fbx" or a newly re-rigged character.

WHY THIS UPLOAD HAS NOT BEEN RESHAPED
The two bodies are compatible variants with matching shared bone labels.
One presentation-only scale gives about1.70m/1.80m in the review and aligns
fixed rest-sole references. The upload's mesh, rig, bind transforms and bytes
remain original, so the existing clothes and future downloads stay matched.
Face style and expressions remain separate work.

Source identity: {model.name}
Fit ID: {fit}-v1
Original bones: {65 if fit=='female' else 49}
SHA-256: {digest}

No clips have been validated from this new batch yet. #215 remains open
until your returned files pass bind, motion, contact and export checks.
Adobe's rigged-character upload guide:
https://helpx.adobe.com/creative-cloud/help/mixamo-rigging-animation.html
'''
        (OUT/(fit+'-READ-ME.txt')).write_text(text,encoding='utf-8')
        records[fit]={'source':model.name,'source_sha256':digest,'source_bytes':model.stat().st_size,'upload_filename':'UPLOAD THIS - Base '+title+'.fbx','required':CLIPS,'state':'awaiting_owner_downloads','fit_id':fit+'-v1'}
    root='''DEPTHS / ANIMATION REQUESTS

Open Base Female, then Base Male. Each contains:
  UPLOAD THIS - Base ....fbx  - the exact rigged model for Mixamo.
  READ ME.txt                 - settings and four specific requests.
  Downloads/                  - put that body's returned FBX clips here.

Please obtain Idle, Walking (In Place), Stand To Sit, and Sitting (chair hold)
once with EACH body loaded. Use FBX / Without Skin / 60fps / no key reduction.
Keep default timing, speed, trim and arm-space; record any different settings.
Do not re-rig if Mixamo presents marker placement. Do not use Sitting Idle for
the chair hold: that old clip is a different, reclined ground pose.

The existing source files remain unchanged; display scale/ground normalization
lives on a separate presentation parent. The original6% height difference is
retained. No new facial art or expressions are included in this request.

These owner-requested copies are in your private Drive. No sharing permissions
were added, no animations acquired automatically, and no model files enter Git.
Current validation status: awaiting your eight returned FBX files (#215).
'''
    (OUT/'START-HERE.txt').write_text(root,encoding='utf-8')
    (OUT/'request-manifest.json').write_text(json.dumps({'version':1,'display_normalization':policy,'bodies':records,'primary_seated_hold':'Sitting.fbx','legacy_ground_idle':'Sitting Idle.fbx','final_animation_approval':False},indent=2)+'\n',encoding='utf-8')
    print('ANIMATION_REQUESTS_READY: two source identities verified; eight requested downloads; no source changes')
if __name__=='__main__':main()
