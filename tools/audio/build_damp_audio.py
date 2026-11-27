"""#302 H/I: restrained wet-cave foley and material-based creature reactions.

Offline retained CC0 recordings + original noise design. No generated voice,
runtime synthesis, music replacement or live audio assignments.
Run with the bundled Python 3.12 and --deps E:/GitHub/Depths/build/audio-deps.
"""
from pathlib import Path
import argparse
import hashlib
import io
import json
import math
import re
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
parser=argparse.ArgumentParser();parser.add_argument('--deps',type=Path,required=True)
parser.add_argument('--workspace',type=Path,required=True);args=parser.parse_args()
sys.path.insert(0,str(args.deps))
import numpy as np
import soundfile as sf
import build_dark_sound_library as old

RATE=44100;SEED=30211
OUT=ROOT/'audio/damp-caves-v1';REVIEW=args.workspace/'build/local-damp-audio-v1'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
(REVIEW/'.gdignore').write_text('')
assets=[];built={};inputs=set()
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

# Existing final audio remains byte-for-byte intact, including approved music.
preserved={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in (ROOT/'audio').rglob('*')
           if p.suffix.lower() in ['.wav','.ogg','.mp3'] and OUT not in p.parents}
(REVIEW/'preserved-audio.json').write_text(json.dumps(preserved,indent=2)+'\n')
source_records=[]
for family in ['audio-dark-v1','audio-galleries-v1']:
    source_records+=json.loads((ROOT/'art/source'/family/'sources.json').read_text(encoding='utf-8'))['sources']
source_records={r['id']:r for r in source_records}
source_records['impact']=source_records['kenney-impact'];source_records['rpg']=source_records['kenney-rpg']
for key in ['water','wind','impact','rpg','queen']:
    r=source_records[key];assert r['license']=='CC0-1.0' and sha(ROOT/r['source'])==r['sha256'],key


def source(group,name=None,pitch=1,lo=100,hi=2600):
    inputs.add(group+('/'+name if name else ''))
    if group=='water':
        blob=zipfile.ZipFile(ROOT/source_records['water']['source']).read(name+'.ogg')
        a,rate=sf.read(io.BytesIO(blob),dtype='float64')
        if a.ndim==2:a=a.mean(axis=1)
        if rate!=RATE:a=np.interp(np.arange(round(len(a)*RATE/rate))*rate/RATE,np.arange(len(a)),a)
    else:a=old.read_source(group,name)
    return old.filtered(old.speed(old.trimmed(a),pitch),lo,hi)


def noise(rng,seconds,lo,hi,attack=.015,decay=.12):
    inputs.add('original/band-limited shaped noise; seed '+str(SEED))
    t=np.arange(round(seconds*RATE))/RATE
    return old.shaped_noise(rng,seconds,lo,hi)*old.envelope(t,attack,decay)


def room(parts,seconds,wet=.08):
    a=old.mix(parts,seconds)
    return old.mix([(a,0,1),(a,.139,wet),(a,.283,wet*.38)],seconds)


def save(ident,label,category,a,recipe,hook,peak=.28,rms=.060,loop=False):
    a=old.norm(a,peak,rms)
    if loop:a[0]=a[-1]=(a[0]+a[-1])/2
    else:a=old.edges(a,.016)
    path=OUT/(ident+'.wav');sf.write(path,a,RATE,subtype='PCM_16')
    decoded,rate=sf.read(path,dtype='float64')
    assert rate==RATE and decoded.ndim==1 and np.isfinite(decoded).all()
    assert np.max(np.abs(decoded))<=peak+.0001 and abs(decoded.mean())<.002
    assert decoded[0]==decoded[-1] and (loop or decoded[0]==0)
    entry={'id':ident,'label':label,'category':category,'file':path.relative_to(ROOT).as_posix(),
      'seconds':len(decoded)/RATE,'rate':RATE,'channels':1,'bits':16,'loop':loop,'bus':'Effects',
      'suggested_player_volume_db':-10.0 if loop else None,
      'peak_dbfs':old.db(float(np.max(np.abs(decoded)))),'rms_dbfs':old.db(float(np.sqrt(np.mean(decoded**2)))),
      'sha256':sha(path),'inputs':sorted(inputs),'recipe':recipe,'hook':hook,'peak_ceiling':peak}
    assets.append(entry);built[ident]=decoded;inputs.clear();old.usage.clear()
    sidecar=Path(str(path)+'.import')
    if sidecar.exists():
        text=sidecar.read_text(encoding='utf-8')
        for key,value in [('compress/mode','0'),('edit/normalize','false'),('edit/trim','false'),('edit/loop_mode','2' if loop else '1')]:
            text=re.sub('^'+re.escape(key)+'=.*$',key+'='+value,text,flags=re.M)
        sidecar.write_text(text,encoding='utf-8')


rng=np.random.default_rng(SEED)
# Distinct restrained material contacts, not four pitches of one step.
for i in range(4):
    a=room([(source('impact',f'footstep_concrete_00{i}',.94+i*.025,100,2000),.006,.55),
            (source('water',f'splash_0{i+1}',1.10+i*.035,180,2100),.016,.18),
            (source('rpg','cloth'+str(i+1),1.04,180,1200),.01,.08)],.62,.055)
    save('step-wet-'+str(i+1),'Quiet wet stone step '+str(i+1),'Movement',a,
       'Distinct recorded sole/splash/cloth members, low wet contact, short quiet reflection. No added bass thump.',
       'Future Damp Caves theme footsteps; preserve independent presentation RNG.',peak=.14,rms=.019)
save('step-splash','Shallow puddle step','Movement',room([
    (source('water','splash_06',.91,90,2600),.009,.55),
    (source('impact','footstep_concrete_004',.90,90,1700),.018,.25)],.86,.07),
    'Low sole contact under a contained recorded splash; stronger wet cue without raising footstep loudness.',
    'Explicit puddle/shallow-water sound selection only; does not assign map.water or movement cost.',peak=.16,rms=.023)
save('wall-bump-wet','Wet rock wall contact','Movement',room([
    (source('impact','impactSoft_heavy_001',.88,70,1700),.015,.48),
    (source('rpg','cloth2',.90,100,1400),0,.38),
    (source('water','slime_03',1.21,150,1700),.03,.12)],.76,.075),
    'Damped shoulder and fabric friction with a little wet rock drag; no punch/bell cue.',
    'Future Damp Caves theme bump.',peak=.25,rms=.050)
save('passage-wet-roots','Wet root curtain torn','Passages',room([
    (source('rpg','creak1',.78,100,2100),0,.30),
    (source('rpg','cloth4',.83,180,2700),.14,.37),
    (source('water','slime_08',1.15,120,2200),.19,.24),
    (source('impact','impactWood_light_003',.95,170,2100),.37,.16)],1.55,.10),
    'Wet fibre tension, fraying cloth, restrained suction and a small woody break; no elastic twang.',
    'B1 organic curtain opening; caller owns tool/fire outcome and timing.',peak=.34,rms=.072)
save('passage-siltfall','Silt and limestone cleared','Passages',room([
    (source('impact','impactMining_001',.69,90,2000),.02,.30),
    (source('rpg','creak2',.68,90,1600),.06,.32),
    (source('water','slime_11',.86,80,1500),.22,.25),
    (source('impact','impactMining_002',.86,150,2400),.61,.16),
    (noise(rng,.80,140,1700,.05,.22),.13,.12)],1.85,.09),
    'Granular slide and damp rock friction settling into small contacts, not a detonation or new collapse mechanic.',
    'B2 siltfall visual resolution; tool cost, collision and delay remain caller-owned.',peak=.36,rms=.072)
for i,(name,pitch) in enumerate([('bubble_01',1.24),('bubble_02',.98),('bubble_03',1.42)]):
    a=source('water',name,pitch,430,2500)[:round(.28*RATE)]
    save('drip-'+str(i+1),'Small cave drip '+str(i+1),'Dressing',room([(a,0,.8)],.72,.11),
       'Short isolated recorded water contact with a quiet rock reflection; no UI chime or continuous faucet.',
       'Sparse presentation-only drip. Distance/visibility bound; do not use gameplay RNG or one sound per visual bead.',peak=.10,rms=.013)
# A distant water/air bed, not a musical drone or a repeated near-field splash.
seconds=48
water=old.looped(source('water','loop_water_03',.83,75,1450),seconds)
wind=old.looped(source('wind',pitch=.91,lo=65,hi=580),seconds)
t=np.arange(seconds*RATE)/RATE
bed=water*.37+wind*.24
bed*=.91+.055*np.sin(math.tau*3*t/seconds)+.025*np.cos(math.tau*7*t/seconds)
for i,(at,gain) in enumerate([(2.4,.045),(8.7,.028),(14.1,.036),(22.8,.023),(31.6,.040),(40.5,.027),(45.4,.032)]):
    old.add(bed,built['drip-'+str(i%3+1)],at,gain)
# Credits remain per-asset even though the same designed drips were built earlier.
inputs.update(['water/bubble_01','water/bubble_02','water/bubble_03'])
bed=old.looped(np.r_[bed,bed[:RATE]],seconds)
save('ambience-damp','Damp Caves: distant water and drips','Ambience',bed,
   '48s cyclic recorded distant water and low air; seven sparse subdued drip contacts, no tonal music, voice or bass pulse.',
   'Future EnvironmentTheme ambience on Effects, one place-owned visibility-bound player; do not stack with old regional bed.',peak=.18,rms=.031,loop=True)
# Material-based reactions: designed animal/colony sounds, not actor imitations.
for family in ['pale-newt','blind-crawler','leech-swarm','drowned-mother']:
    for reaction in ['hurt','death']:
        dying=reaction=='death';length=1.32 if dying else .66
        if family in ['pale-newt','drowned-mother']:
            pitch=.62 if family=='drowned-mother' else .91
            rasp=source('queen',pitch=pitch,lo=190,hi=2200)[:round((.82 if dying else .38)*RATE)]
            rasp*=np.linspace(1,.08,len(rasp))**1.3
            a=room([(rasp,.02,.25),(source('water','slime_05' if dying else 'slime_02',pitch,100,2100),.04,.30),
                    (noise(rng,.42,180,1700,.018,.09),.0,.08)],length,.075)
            recipe='Restrained licensed balloon-friction rasp, wet material recoil and original filtered air; mother has lower/heavier tissue. No human voice or cloned performance.'
        elif family=='blind-crawler':
            a=room([(source('impact','impactMining_002',.90 if dying else 1.13,220,2700),.01,.25),
                    (source('water','slime_14',1.09,150,2000),.025,.20),
                    (source('impact','impactSoft_medium_002',.82,100,1500),.17 if dying else .05,.24)],length,.08)
            recipe='Small shell/stone click, restrained joint drag and dull settling contact; no roaring crustacean or cartoon clack.'
        else:
            a=room([(source('water','slime_09' if dying else 'slime_04',.77 if dying else .95,100,1900),.01,.45),
                    (source('water','splash_11',.90,120,1900),.19 if dying else .07,.16)],length,.06)
            recipe='Suction release and wet body recoil; death settles rather than screams. No actor or tonal sting.'
        save(family+'-'+reaction,family.replace('-',' ').title()+' '+reaction,'Creatures',a,recipe,
             'Optional future family reaction assignment after concept/model acceptance; do not alter current enemy bindings.',peak=.32 if dying else .28,rms=.062 if dying else .055)

for path,digest in preserved.items():assert sha(ROOT/path)==digest,'Existing audio changed: '+path
used_ids={entry.split('/')[0] for row in assets for entry in row['inputs'] if not entry.startswith('original/')}
data={'issue':302,'seed':SEED,'assets':assets,'sources':[source_records[k] for k in sorted(used_ids)],
 'input_aliases':{'impact':'kenney-impact','rpg':'kenney-rpg'},
 'preserved_audio_files':len(preserved),'old_audio_unchanged':True,'human_listening_review':'pending; technical checks are not listening approval',
 'live_bindings_changed':False,'creature_models':'Owner approved four concepts for modelling, 2026-11-26. Reactions remain listening candidates, not accepted combat rules.',
 'format':'mono 44.1kHz PCM16 WAV, explicit import loops, no normalize/trim; Effects bus',
 'builder_sha256':sha(Path(__file__))}
(OUT/'catalog.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
# Listening reel is a separate review artifact, with gaps and no gain lift.
reel=[]
for row in assets:
    a=built[row['id']];a=old.edges(a[:8*RATE].copy(),.08) if row['loop'] else a
    reel.extend([a,np.zeros(round(.55*RATE))])
sf.write(REVIEW/'audition.wav',np.concatenate(reel),RATE,subtype='PCM_16')
print('DAMP_AUDIO',len(assets),'assets;',len(preserved),'earlier audio files preserved')
