"""Verify finished sound formats, source licences, safe levels and repeatability."""
from pathlib import Path
import hashlib,json,math,re,subprocess,sys,wave
import numpy as np
ROOT=Path(__file__).resolve().parents[2];SOURCE=ROOT/'art/source/audio-dark-v1';OUT=ROOT/'audio/dark-v1';REVIEW=ROOT/'art/concepts/sound-v1';results=[]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,name):
 results.append({'check':name,'ok':bool(ok)})
 if not ok:print('FAIL',name)
cat=json.loads((OUT/'catalog.json').read_text());source=json.loads((SOURCE/'sources.json').read_text())
check(len(cat['assets'])==30,'Thirty finished effects and layers');check(len(source['sources'])==7,'Seven verified CC0 sources')
for e in source['sources']:
 check(sha(ROOT/e['source'])==e['sha256'],'Immutable source '+e['id'])
 check(e['license']=='CC0-1.0','Commercially reusable source '+e['id'])
 if 'evidence' in e:
  check('creativecommons.org/publicdomain/zero/1.0' in (ROOT/e['evidence']).read_text(encoding='utf-8',errors='replace'),'Retained primary licence evidence '+e['id'])
  check(sha(ROOT/e['evidence'])==e['evidence_sha256'],'Exact evidence bytes '+e['id'])
 if 'license_file' in e:
  check('CC0' in (ROOT/e['license_file']).read_text(),'Retained original licence '+e['id'])
  check(sha(ROOT/e['license_file'])==e['license_sha256'],'Exact original licence bytes '+e['id'])
 check(e['page'] in (OUT/'CREDITS.md').read_text(),'Creator/page credit '+e['id'])
preserved=SOURCE/'preserved-earlier-audio.json'
if not preserved.exists():
 files={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for d in ['audio/placeholder','audio/samples-v1','audio/samples-v2-dark'] for p in (ROOT/d).glob('*.wav')}
 preserved.write_text(json.dumps(files,indent=2)+'\n')
for p,h in json.loads(preserved.read_text()).items():check(sha(ROOT/p)==h,'Earlier audio untouched '+p)
memory=0;before={}
for e in cat['assets']:
 p=ROOT/e['path'][6:];before[p]=sha(p)
 with wave.open(str(p),'rb') as w:
  check(w.getframerate()==44100 and w.getnchannels()==1 and w.getsampwidth()==2,'PCM16 mono 44.1k '+e['id'])
  check(abs(w.getnframes()/44100-e['seconds'])<1/44100,'Duration '+e['id']);a=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2')
 memory+=len(a)*2
 check(sha(p)==e['sha256'],'Output hash '+e['id'])
 check(np.max(np.abs(a.astype(np.int32)))<=16400,'At least 6dB headroom '+e['id'])
 check(abs(float(a.mean())/32768)<.002,'No material DC offset '+e['id'])
 check(a[0]==a[-1] if e['loop'] else a[0]==a[-1]==0,'Joined loop/zero shot endpoints '+e['id'])
 settings=p.with_suffix('.wav.import').read_text()
 check('compress/mode=0' in settings and 'edit/normalize=false' in settings and 'edit/trim=false' in settings,'Uncompressed/no altered timing '+e['id'])
 check('edit/loop_mode='+('2' if e['loop'] else '1') in settings,'Explicit import loop flag '+e['id'])
 if not e['inputs']:check(bool(e['derived_inputs']),'Traceable derived sources '+e['id'])
 if e['id']=='ui-click':check(e['peak_dbfs']<-18,'Quiet UI ceiling')
 if e['id']=='heartbeat':check(.5<e['seconds']<1,'One short complete heartbeat')
 if e['id']=='coin-flip':
  code=(ROOT/'scripts/coin_flip.gd').read_text();spins=int(re.search(r'const SPINS := (\d+)',code)[1]);seconds=float(re.search(r'const SPIN_SECONDS := ([\d.]+)',code)[1]);land=seconds*(1+.12*(spins-1)/2)
  check(abs(land-2.368)<1e-6,'Landing matches live tween timing')
  check(np.max(np.abs(a[round(land*44100):round((land+.2)*44100)]))>100,'Audible landing at the registered time')
  check(np.max(np.abs(a[round(.6*44100):round((land-.05)*44100)]))==0,'Quiet coin flight, no outcome cue')
reel=REVIEW/'audition.wav';before[reel]=sha(reel)
if '--rebuild' in sys.argv:
 subprocess.run([sys.executable,str(ROOT/'tools/audio/build_dark_sound_library.py')],cwd=ROOT,check=True)
 for p,h in before.items():check(sha(p)==h,'Deterministic offline rebuild '+p.name)
failed=sum(not r['ok'] for r in results)
(REVIEW/'source-validation.json').write_text(json.dumps({'issues':[96,99],'checks':len(results),'failed':failed,'decoded_pcm_bytes':memory,'deterministic_rebuild':'--rebuild' in sys.argv,'results':results},indent=2)+'\n')
print('DARK_SOUND_SOURCE_VALIDATION:',len(results),'checks,',failed,'failed,',round(memory/1048576,3),'MiB PCM')
sys.exit(1 if failed else 0)
