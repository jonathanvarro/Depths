"""Independent PCM/provenance/old-file/rebuild validation for #302 H/I."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import sys
import wave
parser=argparse.ArgumentParser();parser.add_argument('--deps',type=Path,required=True);parser.add_argument('--workspace',type=Path,required=True)
parser.add_argument('--configure-imports',action='store_true');args=parser.parse_args()
sys.path.insert(0,str(args.deps));import numpy as np
ROOT=Path(__file__).resolve().parents[2];REVIEW=args.workspace/'build/local-damp-audio-v1'
data=json.loads((ROOT/'audio/damp-caves-v1/catalog.json').read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
if args.configure_imports:
    for row in data['assets']:
        p=ROOT/(row['file']+'.import');text=p.read_text(encoding='utf-8')
        for key,value in [('compress/mode','0'),('edit/normalize','false'),('edit/trim','false'),('edit/loop_mode','2' if row['loop'] else '1')]:
            text=re.sub('^'+re.escape(key)+'=.*$',key+'='+value,text,flags=re.M)
        p.write_text(text,encoding='utf-8')
    print('Configured twenty imports; no automatic gain/trim, explicit loop flags.');sys.exit(0)
checks=[]
def check(ok,label):
    checks.append({'ok':bool(ok),'label':label})
    if not ok:print('FAIL',label)
required={'ambience-damp','step-splash','wall-bump-wet','passage-wet-roots','passage-siltfall'}
required|={f'step-wet-{i}' for i in range(1,5)}|{f'drip-{i}' for i in range(1,4)}
required|={f'{family}-{state}' for family in ['pale-newt','blind-crawler','leech-swarm','drowned-mother'] for state in ['hurt','death']}
check({r['id'] for r in data['assets']}==required,'complete twenty roles')
check(len({r['sha256'] for r in data['assets']})==20,'twenty distinct waveforms')
for row in data['sources']:
    check(row['license']=='CC0-1.0' and sha(ROOT/row['source'])==row['sha256'],'retained CC0 source identity '+row['id'])
    if 'evidence' in row:
        evidence=(ROOT/row['evidence']).read_bytes()
        # Git's text checkout normalizes the retained HTML from CRLF to LF.
        # Require an exact raw or EOL-only equivalent hash; never waive content.
        lf=evidence.replace(b'\r\n',b'\n')
        digests={hashlib.sha256(b).hexdigest() for b in [evidence,lf,lf.replace(b'\n',b'\r\n')]}
        check(row['evidence_sha256'] in digests,'unchanged licence evidence (text EOL normalization allowed) '+row['id'])
    if 'license_file' in row:check('CC0' in (ROOT/row['license_file']).read_text(encoding='utf-8'),'retained archive licence '+row['id'])
before={}
for row in data['assets']:
    path=ROOT/row['file'];before[row['id']]=sha(path)
    with wave.open(str(path),'rb') as w:
        check(w.getframerate()==44100 and w.getnchannels()==1 and w.getsampwidth()==2,'mono PCM16 '+row['id'])
        samples=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(np.float64)/32768
    check(len(samples)>4000 and np.isfinite(samples).all(),'nonempty finite audio '+row['id'])
    check(sha(path)==row['sha256'] and abs(len(samples)/44100-row['seconds'])<1/44100,'hash/duration '+row['id'])
    check(abs(samples.mean())<.002 and np.max(np.abs(samples))<=row['peak_ceiling']+.0001,'DC and fixed headroom '+row['id'])
    check(samples[0]==samples[-1] and (row['loop'] or samples[0]==0),'joined or faded endpoints '+row['id'])
    check(row['inputs'] and row['bus']=='Effects','per-asset provenance and bus '+row['id'])
    if row['loop']:check(max(abs(samples[1]-samples[0]),abs(samples[-1]-samples[-2]))<.015,'quiet loop seam '+row['id'])
    if row['id'].startswith('step-'):check(np.max(np.abs(samples))<=.161 and np.sqrt(np.mean(samples**2))<=.024,'quiet steps '+row['id'])
    for entry in row['inputs']:
        group,_,member=entry.partition('/')
        if group=='original':continue
        source_id=data['input_aliases'].get(group,group);record=next(r for r in data['sources'] if r['id']==source_id)
        check(bool(record) and (group not in ['water','impact','rpg'] or bool(member)),'exact source member '+row['id']+' '+entry)
preserved=json.loads((REVIEW/'preserved-audio.json').read_text())
for path,digest in preserved.items():check(sha(ROOT/path)==digest,'earlier audio preserved '+path)
subprocess.run([sys.executable,str(ROOT/'tools/audio/build_damp_audio.py'),'--deps',str(args.deps),'--workspace',str(args.workspace)],check=True,capture_output=True)
for row in data['assets']:check(sha(ROOT/row['file'])==before[row['id']],'deterministic rebuild '+row['id'])
report={'checks':len(checks),'failures':[r['label'] for r in checks if not r['ok']], 'earlier_files':len(preserved),'results':checks,
        'human_listening_review':False,'live_bindings_changed':False}
(REVIEW/'pcm-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('DAMP_AUDIO_PCM',len(checks),'checks,',len(report['failures']),'failures');sys.exit(bool(report['failures']))
