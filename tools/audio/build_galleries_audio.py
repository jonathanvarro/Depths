"""#167/#54: reproducible dark foley plus an original deeper-cave score.

No external audio service or cloned performance. Existing credited CC0 foley
is processed offline; the new score uses original additive/modal synthesis.
"""
from pathlib import Path
import sys,io,json,hashlib,zipfile,wave,math,re
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'build/audio-deps'))
import numpy as np
import soundfile as sf
import build_dark_sound_library as old
RATE=44100
OUT=ROOT/'audio/galleries-v1'; REVIEW=ROOT/'art/concepts/galleries-audio-v1'
SOURCE=ROOT/'art/source/audio-galleries-v1'
assets=[]; inputs=set()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(group,name=None):
    inputs.add(group+('/'+name if name else ''))
    if group!='water':return old.read_source(group,name)
    a,r=sf.read(io.BytesIO(zipfile.ZipFile(SOURCE/'water-splash-slime-sfx.zip').read(name+'.ogg')),dtype='float64')
    if a.ndim==2:a=a.mean(axis=1)
    a=np.interp(np.arange(round(len(a)*RATE/r))*r/RATE,np.arange(len(a)),a)
    return a-a.mean()
def shape(a,pitch=1,lo=70,hi=2600):return old.filtered(old.speed(a,pitch),lo,hi)
def foley(group,name,pitch=1,lo=70,hi=2600):return shape(old.trimmed(read(group,name)),pitch,lo,hi)
def room(a,seconds,delays=(.137,.271,.419),wet=.13):
    return old.mix([(a,0,1)]+[(a,d,wet/(i+1)) for i,d in enumerate(delays)],seconds)
def save(ident,label,a,notes,loop=False,music=False):
    a=old.norm(a,.42 if music else .48,.085 if music else .11)
    if loop:a[0]=a[-1]=(a[0]+a[-1])/2
    else:a=old.edges(a,.025)
    p=OUT/(ident+'.wav')
    sf.write(p,a,RATE,format='WAV',subtype='PCM_16')
    decoded,r=sf.read(p);peak=float(np.max(np.abs(decoded)));rms=float(np.sqrt(np.mean(decoded**2)))
    assert r==RATE and decoded.ndim==1
    assert len(decoded)==len(a)
    assert np.isfinite(decoded).all() and peak<.52 and abs(float(decoded.mean()))<.002
    assert decoded[0]==decoded[-1] and (loop or decoded[0]==0)
    assets.append({'id':ident,'label':label,'file':p.relative_to(ROOT).as_posix(),'rate':r,'channels':1,'seconds':len(decoded)/r,'loop':loop,'music':music,'peak_dbfs':old.db(peak),'rms_dbfs':old.db(rms),'sha256':sha(p),'inputs':sorted(inputs),'processing':notes})
    inputs.clear();return decoded
def score():
    # D2/A2/Eb3: an uneasy open fifth contaminated by the upper semitone.
    # Three 24-second phrases; the final voice withdraws to the opening D.
    inputs.add('original composition and additive/modal synthesis; seed 16754')
    seconds=72;t=np.arange(seconds*RATE)/RATE;rng=np.random.default_rng(16754);y=np.zeros(len(t))
    for hz,gain,phase in [(73.416,.30,0),(110,.15,.7),(146.832,.11,1.2)]:
        voice=np.zeros(len(t))
        for harmonic in [1,2,3,5,7]:
            voice+=np.sin(2*np.pi*hz*harmonic*t+.003*harmonic*np.sin(2*np.pi*t/9)+phase)/(harmonic**1.55)
        y+=voice*gain*(.6+.4*np.sin(np.pi*t/seconds)**2)
    # Slow bowed upper phrases, breathy rather than a bright synth lead.
    for at,duration,hz,gain in [(1,18,220,.14),(21,18,155.563,.11),(42,19,164.814,.12),(61,10,146.832,.10)]:
        nt=np.arange(round(duration*RATE))/RATE;v=np.zeros(len(nt))
        for h in range(1,7):v+=np.sin(2*np.pi*hz*h*nt+.012*h*np.sin(2*np.pi*4.1*nt))/(h*h)
        v*=np.sin(np.pi*nt/duration)**2
        old.add(y,v,at,gain)
    # Sparse decaying struck strings: D, Eb, A, F; deliberately no drum grid.
    for at,hz in [(6,293.665),(18,311.127),(31,220),(45,349.228),(58,293.665)]:
        nt=np.arange(7*RATE)/RATE;v=np.zeros(len(nt))
        for i,ratio in enumerate([1,2.003,3.011,4.024]):v+=np.sin(2*np.pi*hz*ratio*nt+rng.uniform(0,6.28))*np.exp(-nt*(.7+i*.23))/(1+i)**2
        v*=np.minimum(nt/.018,1);old.add(y,v,at,.075)
    y=old.filtered(y,55,1700)
    # Crossfade the cyclic bed itself; no mandatory silence at the seam.
    pad=np.r_[y,y[:RATE]];y=old.looped(pad,72)
    return save('below-the-sluice','Below the Sluice · original score',y,'Original 72s D-centred three-phrase score, detuned bowed harmonic voices and sparse modal struck strings. No sampled music, beat grid, voices or external composer. PCM16 delivery; cyclic join checked after decode.',True,True)
def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True);(REVIEW/'.gdignore').write_text('')
    preserved=json.loads((SOURCE/'preserved-files.json').read_text(encoding='utf-8'))
    for path,record in preserved.items():
        data=(ROOT/path).read_bytes()
        if record['normalize_text_eol']:data=data.replace(b'\r\n',b'\n')
        assert hashlib.sha256(data).hexdigest()==record['sha256'],'Earlier asset changed: '+path
    for e in json.loads((SOURCE/'sources.json').read_text(encoding='utf-8'))['sources']:
        assert e['license']=='CC0-1.0' and sha(ROOT/e['source'])==e['sha256'],e['id']
    # Quiet reflections suggest distance without relying on stereo/headphones.
    a=foley('rpg','creak3',.83,180,2100)
    save('wander-claws','Claws scraping behind',room(a,2.4), 'Recorded creak3 .83x, 180–2100Hz; sparse .137/.271/.419s reflections at .13/n. Quiet scraping, no close impact.')
    a=old.mix([(foley('rpg','cloth4',.72),.06,.5),(foley('impact','footstep_concrete_001',.78),.15,.35),(foley('impact','footstep_concrete_003',.85),.81,.27)],1.6)
    save('wander-shuffle','Shuffling closer',room(a,2.2),'Cloth4 .72x and concrete steps001 .78x /003 .85x at .15/.81s; damp 70–2600Hz reflections.')
    a=foley('rpg','metalClick',.83,350,2200)
    a=old.mix([(a,.1,.25),(a,.63,.37),(a,1.24,.55)],1.8)
    save('wander-stones','Distant stones clicking',room(a,2.4),'Damped recorded metalClick .83x used as small stone contact; three irregular taps grow nearer, no attack impact.')
    a=foley('queen',None,.68,260,1900)
    a=old.edges(a[:int(.65*RATE)],.07)
    save('wander-chitter','Low chittering behind',room(old.mix([(a,.1,.6),(a,.9,.32)],1.8),2.4),'Recorded balloon friction .68x, 260–1900Hz, two .65s calls with .07s fades and quiet reflections. Not an actor/animal recording.')
    for i,(splash,pitch) in enumerate([('splash_03',.76),('splash_08',.83),('splash_12',.79)],1):
        a=old.mix([(foley('water',splash,pitch,65,3200),.025,.8),(foley('impact','footstep_concrete_00'+str(i),.8,50,1800),.045,.24)],1.4)
        save('wade-'+str(i),'Knee-deep step '+str(i),room(a,1.8,wet=.07),f'{splash} at {pitch}x, 65–3200Hz, concrete foot weight .24 at .045s; low short rock reflections.')
    a=old.mix([(foley('rpg','creak1',.48,80,1800),.05,.8),(foley('rpg','creak2',.51,80,1800),1.0,.65),(foley('rpg','metalLatch',.55,80,2000),.16,.25),(foley('impact','impactMetal_medium_002',.55,50,1300),2.3,.20)],3.5)
    crank=save('sluice-wheel','Sluice wheel turning',room(a,4),'Creak1 .48x, creak2 .51x at1s; dull latch at.16s and settling iron at2.3s; no bright spring/ring.')
    water=shape(read('water','loop_water_02'),.8,60,2600);water=old.looped(water,8.8);t=np.arange(len(water))/RATE
    envelope=np.minimum(t/2.2,1)*np.minimum((8.8-t)/4.6,1)**1.5
    drain=save('water-drain','Water rushing away',water*envelope,'loop_water_02 .8x 60–2600Hz, 2.2s rise, 4.6s receding tail, faded zero endpoints.')
    water=old.looped(shape(read('water','loop_water_03'),.72,80,1600),24)
    wind=old.looped(shape(read('wind'),.8,65,470),24)
    y=water*.33+wind*.22
    drip=foley('water','bubble_02',1.15,500,2600)[:int(.24*RATE)]
    for at,gain in [(1.2,.13),(4.8,.17),(8.1,.10),(13.7,.15),(19.2,.11),(21.6,.16)]:old.add(y,old.edges(drip.copy(),.02),at,gain)
    save('galleries-loop','Drowned Galleries ambience',old.looped(np.r_[y,y[:RATE]],24),'Water03 .72x 80–1600Hz, wind .8x 65–470Hz, six subdued bubble02-derived drips. 24s cyclic crossfade; hollow non-musical air.',True)
    music=score()
    # Review sequence is separate from runtime; quiet gaps keep comparisons clear.
    reel=[]
    for entry in assets:
        a,r=sf.read(ROOT/entry['file']);reel.extend([a[:min(len(a),RATE*(24 if entry['music'] else 8))],np.zeros(RATE)])
    sf.write(REVIEW/'audition.wav',np.concatenate(reel),RATE,subtype='PCM_16')
    sf.write(REVIEW/'sluice-sequence.wav',old.mix([(crank,0,1),(drain,3.3,1)],12.1),RATE,subtype='PCM_16')
    data={'assets':assets,'checks':len(assets)*4,'failures':[],'original_music_preserved':True,'preserved_earlier_files':len(preserved),'physical_iphone_tested':False}
    (OUT/'catalog.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    cards=''.join(f'<article><h2>{e["label"]}</h2><audio controls aria-label="{e["label"]}" preload="metadata" src="../../../{e["file"]}"></audio><p>{e["seconds"]:.1f}s · {e["peak_dbfs"]:.1f} dBFS peak</p><p>{e["processing"]}</p></article>' for e in assets)
    (REVIEW/'inspector.html').write_text('<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Galleries sound and music</title><style>body{background:#111712;color:#e6dac1;font:18px Georgia;max-width:1100px;margin:30px auto;padding:15px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:20px}article{border:1px solid #6c6046;padding:16px}audio{max-width:100%}h2{font-size:21px}p{line-height:1.5}a{color:#d9b374}</style><h1>Under stone, under water</h1><p>Ten gameplay sounds and one new original deeper-cave score. Quiet distant warnings; grounded foley; existing music preserved. Headphone and phone-speaker review remains useful.</p><p><a href="audition.wav">All-sound audition</a> · <a href="sluice-sequence.wav">Wheel → draining sequence</a> · <a href="../../../audio/galleries-v1/CREDITS.md">Credits and source licences</a></p><main>'+cards+'</main>',encoding='utf-8')
    for e in assets:
        sidecar=ROOT/(e['file']+'.import')
        if not sidecar.exists():continue
        s=sidecar.read_text(encoding='utf-8')
        for k,v in [('edit/normalize','false'),('edit/trim','false'),('edit/loop_mode','2' if e['loop'] else '1'),('compress/mode','2' if e['music'] else '0')]:s=re.sub('^'+re.escape(k)+'=.*$',k+'='+v,s,flags=re.M)
        sidecar.write_text(s,encoding='utf-8')
    print('GALLERIES_AUDIO:',len(assets),'assets;',data['checks'],'checks; no failures')
if __name__=='__main__':main()
