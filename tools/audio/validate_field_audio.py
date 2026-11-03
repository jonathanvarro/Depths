"""#217/#167 formats, licensing provenance, old-audio preservation and rebuild."""
from pathlib import Path
import hashlib
import json
import math
import re
import subprocess
import sys
import wave
import zipfile

if '--deps' in sys.argv:sys.path.insert(0,sys.argv[sys.argv.index('--deps')+1])
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
REVIEW=ROOT/'art/concepts/field-audio-v1'
checks=[]


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def check(ok,label):
    checks.append({'ok':bool(ok),'label':label})
    if not ok:print('FAIL',label)


def main():
    field=json.loads((ROOT/'audio/field-v1/catalog.json').read_text(encoding='utf-8'))
    galleries=json.loads((ROOT/'audio/galleries-v1/catalog.json').read_text(encoding='utf-8'))
    check(len(field['assets'])==46,'Complete field asset count')
    needed=['step-stone-'+str(i) for i in range(1,5)]+['ambience-'+f for f in ['cave','fungal','stone','fortress']]
    needed+=['wall-bump','passage-web','passage-roots','passage-stone-door']
    needed+=['prayer-'+s for s in ['cast','mend','light','watch','miscast','bind']]
    needed+=[f+'-'+s for f in ['rat','spider','goblin','beetle','bat','deep'] for s in ['hurt','death']]
    needed+=['map-noticed','map-heavy-blow','trap-dart','trap-snare','trap-alarm-bell','trap-tripwire',
             'brew-drink','brew-shatter','level-up','stairs-down','stairs-up','pack-eat','pack-bandage','pack-oil','pack-tome','smith-temper']
    check(set(needed)=={e['id'] for e in field['assets']},'Every requested role has a named asset')
    entries=field['assets']+galleries['assets']
    check(len({e['sha256'] for e in field['assets']})==46,'All field assets distinct')
    source=[]
    for name in ['audio-dark-v1','audio-galleries-v1']:
        source+=json.loads((ROOT/'art/source'/name/'sources.json').read_text(encoding='utf-8'))['sources']
    for e in source:
        check(e['license']=='CC0-1.0' and sha(ROOT/e['source'])==e['sha256'],'Source licence/identity '+e['id'])
        if 'evidence' in e:
            proof=ROOT/e['evidence']
            check('creativecommons.org/publicdomain/zero/1.0' in proof.read_text(encoding='utf-8',errors='replace'),'Retained primary CC0 page '+e['id'])
            if 'evidence_sha256' in e:check(sha(proof)==e['evidence_sha256'],'Unchanged licence evidence '+e['id'])
        if 'license_file' in e:
            check('CC0' in (ROOT/e['license_file']).read_text(encoding='utf-8'),'Original archive licence '+e['id'])
    preserved=json.loads((ROOT/'art/source/audio-galleries-v1/preserved-files.json').read_text(encoding='utf-8'))
    for name,record in preserved.items():
        data=(ROOT/name).read_bytes()
        if record['normalize_text_eol']:data=data.replace(b'\r\n',b'\n')
        check(hashlib.sha256(data).hexdigest()==record['sha256'],'Earlier asset unchanged '+name)
    memory=0;before={}
    archives={'rpg':zipfile.ZipFile(ROOT/'art/source/audio-dark-v1/downloads/kenney-rpg.zip'),
              'impact':zipfile.ZipFile(ROOT/'art/source/audio-dark-v1/downloads/kenney-impact.zip'),
              'water':zipfile.ZipFile(ROOT/'art/source/audio-galleries-v1/water-splash-slime-sfx.zip')}
    for e in entries:
        path=ROOT/e['file'];before[path]=sha(path)
        with wave.open(str(path),'rb') as w:
            check(w.getframerate()==44100 and w.getnchannels()==1 and w.getsampwidth()==2,'Mono44.1k PCM16 '+e['id'])
            a=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(np.float64)/32768
        memory+=len(a)*2
        check(abs(len(a)/44100-e['seconds'])<1/44100 and sha(path)==e['sha256'],'Duration/hash '+e['id'])
        check(np.max(np.abs(a))<.501 and abs(a.mean())<.002,'Headroom/DC '+e['id'])
        check(a[0]==a[-1] and (e['loop'] or a[0]==0),'Joined/faded endpoints '+e['id'])
        if e['loop']:
            boundary=max(abs(a[1]-a[0]),abs(a[-1]-a[-2]))
            check(boundary<.03,'No large boundary sample jump '+e['id'])
        if e['id'].startswith('step-stone'):
            check(np.max(np.abs(a))<=.141 and math.sqrt(float(np.mean(a*a)))<.028,'Deliberately quiet step '+e['id'])
        check(len(e['inputs'])>0,'Recorded member or original synthesis provenance '+e['id'])
        if e in field['assets']:
            for key in e['inputs']:
                group,_,member=key.partition('/')
                if group in archives:check(('Audio/' if group!='water' else '')+member+'.ogg' in archives[group].namelist(),'Exact source member '+key)
        sidecar=Path(str(path)+'.import').read_text(encoding='utf-8')
        check('edit/normalize=false' in sidecar and 'edit/trim=false' in sidecar,'No import gain/timing edits '+e['id'])
        check('edit/loop_mode='+('2' if e['loop'] else '1') in sidecar,'Explicit loop setting '+e['id'])
        check('compress/mode='+('2' if e.get('music',False) else '0') in sidecar,'Intended compression '+e['id'])
    if '--rebuild' in sys.argv:
        deps=['--deps',sys.argv[sys.argv.index('--deps')+1]] if '--deps' in sys.argv else []
        # Field builder owns only field outputs. Galleries delivered bytes are
        # independently pinned, with their original source recipe retained.
        subprocess.run([sys.executable,str(ROOT/'tools/audio/build_field_audio.py')]+deps,check=True,cwd=ROOT)
        for path,digest in before.items():check(sha(path)==digest,'Deterministic field rebuild / retained Galleries '+path.name)
    failed=[e['label'] for e in checks if not e['ok']]
    result={'checks':len(checks),'failures':failed,'runtime_assets':len(entries),'field_assets':46,
            'decoded_pcm_mib':memory/1048576,'preserved_earlier_files':len(preserved),
            'deterministic_field_rebuild':'--rebuild' in sys.argv,'results':checks,
            'owner_listening_pending':True,'live_hooks_changed':False}
    (REVIEW/'source-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('FIELD_AUDIO_VALIDATION',len(checks),'checks;',len(failed),'failures;',round(memory/1048576,2),'MiB PCM')
    if failed:raise SystemExit(1)


if __name__=='__main__':main()
