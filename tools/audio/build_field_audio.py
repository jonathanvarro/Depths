"""#217: offline CC0-derived field foley and original restrained sound design.

No voice cloning, external generation service or live rule/hook edits. Existing
approved audio is only read. Requires NumPy and soundfile (optionally from the
owner's ignored shared build/audio-deps folder).
"""
from pathlib import Path
import hashlib
import io
import json
import math
import re
import sys
import zipfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
if '--deps' in sys.argv:
    sys.path.insert(0, sys.argv[sys.argv.index('--deps')+1])
import numpy as np
import soundfile as sf
import build_dark_sound_library as old

RATE = 44100
OUT = ROOT/'audio/field-v1'
REVIEW = ROOT/'art/concepts/field-audio-v1'
SEED = 21703
assets = []
built = {}
inputs = set()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source(group, name=None, pitch=1, lo=80, hi=3200):
    inputs.add(group + ('/'+name if name else ''))
    if group == 'water':
        archive = ROOT/'art/source/audio-galleries-v1/water-splash-slime-sfx.zip'
        raw = zipfile.ZipFile(archive).read(name+'.ogg')
        a, rate = sf.read(io.BytesIO(raw), dtype='float64')
        if a.ndim == 2:a=a.mean(axis=1)
        if rate != RATE:a=np.interp(np.arange(round(len(a)*RATE/rate))*rate/RATE,np.arange(len(a)),a)
    else:
        a=old.read_source(group,name)
    return old.filtered(old.speed(old.trimmed(a),pitch),lo,hi)


def mix(parts, seconds):
    return old.mix(parts,seconds)


def noise(rng, seconds, lo, hi, attack=.01, decay=.12):
    t=np.arange(round(seconds*RATE))/RATE
    return old.shaped_noise(rng,seconds,lo,hi)*old.envelope(t,attack,decay)


def resonance(seconds, tones, decay=.7, attack=.025):
    t=np.arange(round(seconds*RATE))/RATE
    a=np.zeros(len(t))
    for hz,gain in tones:
        a+=gain*np.sin(math.tau*hz*t)*old.envelope(t,attack,decay)
    inputs.add('original/modal resonance; seed '+str(SEED))
    return a


def room(a, seconds, wet=.10):
    # Quiet mono reflections, not a stereo effect that disappears on a phone.
    return mix([(a,0,1),(a,.113,wet),(a,.257,wet*.44)],seconds)


def save(ident,label,group,a,recipe,loop=False,peak=.38,rms=.085,hook=''):
    a=old.norm(a,peak,rms)
    if loop:a[0]=a[-1]=(a[0]+a[-1])/2
    else:a=old.edges(a,.012)
    path=OUT/(ident+'.wav')
    sf.write(path,a,RATE,subtype='PCM_16')
    decoded,rate=sf.read(path)
    assert rate==RATE and decoded.ndim==1 and np.isfinite(decoded).all()
    assert abs(decoded.mean())<.002 and np.max(np.abs(decoded))<.50
    assert decoded[0]==decoded[-1] and (loop or decoded[0]==0)
    entry={'id':ident,'label':label,'category':group,'file':path.relative_to(ROOT).as_posix(),
           'seconds':len(decoded)/RATE,'rate':RATE,'channels':1,'bits':16,'loop':loop,
           'peak_dbfs':old.db(float(np.max(np.abs(decoded)))),
           'rms_dbfs':old.db(float(np.sqrt(np.mean(decoded**2)))),
           'sha256':sha(path),'inputs':sorted(inputs),'recipe':recipe,'hook':hook,
           'suggested_bus':'Effects','runtime_gain_db':0}
    assert entry['inputs'],ident+' missing provenance'
    assets.append(entry);built[ident]=decoded;inputs.clear();old.usage.clear()
    sidecar=Path(str(path)+'.import')
    if sidecar.exists():
        text=sidecar.read_text(encoding='utf-8')
        for key,value in [('compress/mode','0'),('edit/normalize','false'),('edit/trim','false'),('edit/loop_mode','2' if loop else '1')]:
            text=re.sub('^'+re.escape(key)+'=.*$',key+'='+value,text,flags=re.M)
        sidecar.write_text(text,encoding='utf-8')


def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').touch()
    rng=np.random.default_rng(SEED)
    sources=json.loads((ROOT/'art/source/audio-dark-v1/sources.json').read_text(encoding='utf-8'))['sources']
    sources+=json.loads((ROOT/'art/source/audio-galleries-v1/sources.json').read_text(encoding='utf-8'))['sources']
    for entry in sources:
        assert entry['license']=='CC0-1.0' and sha(ROOT/entry['source'])==entry['sha256']
    # Material steps retain the requested soft level. No low-end boom or
    # bright grit shower; four independently recorded sole contacts.
    for i in range(4):
        a=mix([(source('impact',f'footstep_concrete_00{i}',.94+i*.02,110,2100),.012,.75),
               (source('rpg','cloth'+str(i+1),1.04,160,1300),.018,.12)],.52)
        save('step-stone-'+str(i+1),'Soft gritty stone step '+str(i+1),'Movement',a,
             'Recorded concrete sole at .94–1.00x, 110–2100Hz, low cloth brushing; quiet fixed level.',
             peak=.14,rms=.026,hook='EnvironmentTheme footsteps (four variants); retain private presentation RNG.')
    wind=source('wind',pitch=.94,lo=80,hi=1200)
    for family in ['cave','fungal','stone','fortress']:
        inputs.add('wind')
        seconds=40
        base=old.looped(np.tile(wind,3),seconds)*.35
        t=np.arange(len(base))/RATE
        base*=.78+.13*np.cos(math.tau*3*t/seconds)+.05*np.sin(math.tau*7*t/seconds)
        if family in ['cave','fungal','stone']:
            drip=source('water','bubble_02',1.1 if family=='fungal' else .9,450,2400)
            for at,gain in [(2.7,.07),(9.4,.045),(16.3,.065),(23.9,.05),(32.2,.08),(37.1,.04)]:
                old.add(base,drip,at,gain*(1.25 if family=='fungal' else .7))
        if family=='fungal':
            water=old.looped(source('water','loop_bubbles_02',.80,180,900),seconds)
            base+=water*.055
        if family=='stone':
            stone=source('impact','impactMining_002',.84,150,1900)
            for at,gain in [(12.3,.035),(29.6,.025)]:old.add(base,stone,at,gain)
        if family=='fortress':
            timber=source('rpg','creak2',.65,120,1300)
            iron=source('rpg','metalLatch',.72,180,1700)
            for at,gain in [(8.6,.05),(27.4,.035)]:old.add(base,timber,at,gain)
            old.add(base,iron,19.3,.035)
        save('ambience-'+family,'Quiet '+family+' ambience','Ambience',old.looped(np.r_[base,base[:RATE]],seconds),
             '40s wind/material bed; sparse water/masonry/timber detail by family. No music or intelligible voices; cyclic join.',
             loop=True,peak=.24,rms=.042,hook='EnvironmentTheme '+family+' ambience; Effects bus, visibility/place-owned player.')
    save('wall-bump','Shoulder against rock','Movement',mix([
        (source('impact','impactSoft_heavy_001',.90,80,1700),.015,.55),
        (source('rpg','cloth2',.88,100,1600),0,.42)],.66),
        'Dull soft material contact and jacket friction, no bell or punch transient.',peak=.26,rms=.065,hook='EnvironmentTheme bump')
    save('passage-web','Web pulled apart','Passages',mix([
        (source('rpg','cloth3',.71,180,3400),0,.58),
        (source('rpg','cloth4',1.32,500,3700),.15,.27)],1.05),
        'Layered fibre friction; lower body and short fraying end. No pitched rubber twang.',hook='Cave web opening')
    save('passage-roots','Roots strained and broken','Passages',mix([
        (source('rpg','creak1',.73,90,2300),0,.4),
        (source('impact','impactWood_light_003',.92,180,3400),.25,.3),
        (source('rpg','cloth4',.9,150,2600),.31,.2)],1.3),
        'Dry woody strain, small dull break and fibres; no dramatic timber collapse.',hook='Cave roots opening')
    save('passage-stone-door','Heavy stone door moving','Passages',room(mix([
        (source('rpg','creak2',.52,90,1900),.04,.7),
        (source('impact','impactMining_001',.66,100,1700),.12,.22),
        (source('impact','impactSoft_heavy_003',.80,60,1000),1.02,.3)],1.7),2.05),
        'Low friction creak, muted granular scrape and settling contact; short rock reflections.',hook='Stone/fortress passage open')
    # Prayers are breath/cloth/modal designs, not spoken or imitated voices.
    for ident,label,tones,seconds in [
        ('prayer-cast','Devotional cast',[(146.83,.45),(220,.13)],1.35),
        ('prayer-mend','Mend',[(174.61,.35),(261.63,.10)],1.7),
        ('prayer-light','Holy light',[(146.83,.32),(293.66,.15),(440,.05)],2.2),
        ('prayer-watch','Watchful eye',[(110,.25),(164.81,.15),(233.08,.035)],1.9),
        ('prayer-miscast','Faltered prayer',[(146.83,.25),(155.56,.17)],1.2)]:
        voice=resonance(seconds,tones,decay=.70 if ident!='prayer-light' else 1.2,attack=.08)
        voice+=noise(rng,seconds,230,1700,.08,.35)*.045
        if ident=='prayer-miscast':
            t=np.arange(len(voice))/RATE;voice*=np.clip((.70-t)/.22,0,1)
        save(ident,label,'Prayers',room(voice,seconds+.3,.09),
             'Original low modal resonance and filtered breath-like noise; no speech, bright reward arpeggio or cloned performer.',
             peak=.29,rms=.065,hook='Prayer-specific cast/miscast presentation; no rule/timing change.')
    save('prayer-bind','Bind','Prayers',room(mix([
        (source('rpg','metalLatch',.72,190,2600),.02,.5),
        (source('rpg','metalClick',.78,250,2500),.22,.25),
        (resonance(1.1,[(130.81,.25),(196,.08)]),.02,.4)],1.25),1.6),
        'Restrained chain/latch tightening with original low resonance; damp ending.',peak=.31,rms=.072,hook='Bind prayer')
    for family,pitch,band,length in [('rat',1.85,(650,4200),.42),('spider',1.25,(350,3300),.55),
                                    ('goblin',.69,(140,2100),.95),('beetle',.84,(220,2600),.66),
                                    ('bat',2.35,(900,4300),.48),('deep',.46,(90,1700),1.5)]:
        for state in ['hurt','death']:
            duration=length*(1.55 if state=='death' else 1)
            cry=source('queen',pitch=pitch,lo=band[0],hi=band[1])[:round(duration*RATE)]
            tt=np.arange(len(cry))/RATE
            cry*=.73+.17*np.sin(math.tau*(13 if family in ['rat','bat'] else 7)*tt)
            parts=[(old.edges(cry,.025),.01,.52)]
            if family in ['spider','beetle']:
                parts.append((source('impact','impactWood_light_002' if family=='spider' else 'impactPlate_light_002',1.05,220,3000),.03,.20))
            if state=='death':parts.append((source('rpg','cloth2',.75,100,1500),duration*.36,.19))
            save(f'{family}-{state}',family.title()+' '+state,'Monsters',room(mix(parts,duration+.25),duration+.5,.07),
                 f'Designed {family} reaction from recorded balloon friction at {pitch}x, {band[0]}–{band[1]}Hz; fixed pitch, irregular texture, subdued material tail. Not a real animal or actor recording.',
                 peak=.36,rms=.085,hook=f'{family} family {state}; trigger once from presentation, not game RNG.')
    save('map-noticed','The party is noticed','Warnings',room(mix([
        (source('rpg','drawKnife2',.8,180,2600),0,.45),
        (resonance(.8,[(98,.26),(146.83,.08)]),.03,.5)],.9),1.15),
        'Brief dry scrape and dark pressure tone; no startling high-frequency jump scare.',peak=.32,rms=.074,hook='Group notices party on map')
    save('map-heavy-blow','Heavy blow marks the tile','Warnings',mix([
        (source('impact','impactSoft_heavy_002',.70,60,1700),.015,.5),
        (source('rpg','metalLatch',.62,180,1800),.18,.32),
        (resonance(.8,[(123.47,.25),(174.61,.11)]),.01,.5)],1.2),
        'Distinct two-part weight/catch cue for the marked heavy attack, not an impact dealt to a hero.',peak=.36,rms=.085,hook='Heavy-blow tile warning; preserve warning timing')
    save('trap-dart','Dart plate and release','Traps',mix([
        (source('rpg','metalClick',1.05,220,3300),0,.36),
        (source('rpg','drawKnife1',1.35,300,3400),.065,.37)],.58),
        'Short trigger click then air/shaft release; no magical zap.',hook='Dart plate trigger')
    save('trap-snare','Snare tightening','Traps',mix([
        (source('rpg','clothBelt2',1.1,120,2400),.01,.45),
        (source('rpg','metalLatch',.90,150,2700),.075,.4)],.8),
        'Leather/fibre pull and dull catch; no cartoon spring.',hook='Snare trigger')
    save('trap-alarm-bell','Alarm bell','Traps',room(source('impact','impactBell_heavy_001',.86,160,3800),2.1,.12),
        'Recorded small heavy bell, restrained bandwidth and short room; clear alarm identity.',peak=.36,rms=.075,hook='Alarm bell trap; no spawned-enemy logic in audio')
    save('trap-tripwire','Tripwire stones falling','Traps',mix([
        (source('rpg','clothBelt',1.15,250,2200),0,.26),
        (source('impact','impactMining_001',1.1,220,3300),.08,.35),
        (source('impact','impactMining_003',1.18,250,3400),.22,.25),
        (source('impact','impactMining_004',.99,160,2600),.39,.18)],.95),
        'Taut fibre release and three irregular stone contacts; dull rather than metallic.',hook='Tripwire stone trigger')
    save('brew-drink','Uncork and drink','Brews',mix([
        (source('rpg','handleSmallLeather',1.12,180,1900),0,.25),
        (source('water','bubble_03',.72,160,1900),.24,.48),
        (source('water','slime_01',1.25,180,1800),.42,.17)],1.05),
        'Small stopper/handling friction, wet gulp-like bubble and swallow texture; designed foley, no actor.',peak=.30,rms=.068,hook='Drink brew; do not imply identified effect')
    save('brew-shatter','Thrown flask shattering','Brews',mix([
        (source('impact','impactGlass_medium_002',.92,200,4200),.015,.60),
        (source('water','splash_05',1.15,220,3400),.035,.23)],1.25),
        'Dry glass fracture with a small wet spill; no explosive boom.',peak=.39,rms=.09,hook='Thrown brew impact')
    save('level-up','Quiet level advancement','Progress',resonance(2.0,[(146.83,.30),(220,.13),(293.66,.08)],1.0,.03),
        'Original single warm resonant sonority, subdued dark-fantasy character; no cheerful fanfare.',peak=.28,rms=.06,hook='Level-up presentation only')
    for direction,pitch in [('down',.84),('up',1.04)]:
        a=mix([(source('impact','footstep_concrete_002',pitch,110,2200),.03,.32),
               (source('impact','footstep_concrete_004',pitch*.98,100,2100),.37,.26),
               (source('rpg','cloth1',.9,120,1500),.1,.20)],1.05)
        save('stairs-'+direction,'Stairs '+direction,'Progress',room(a,1.45,.14),
             'Two paced stone contacts and pack cloth with short enclosed reflections; distinct pitch/weight by direction.',peak=.25,rms=.055,hook='Accepted floor transition, not prompt opening')
    save('pack-eat','Eat a ration','Pack',mix([
        (source('rpg','cloth4',1.18,180,2500),.01,.20),
        (source('impact','footstep_grass_002',1.22,220,2600),.17,.21),
        (source('water','slime_03',1.25,220,1500),.34,.15)],.9),
        'Dry ration/wrapping texture and small damp contact; designed eating foley, not a recorded actor.',peak=.24,rms=.052,hook='Successful ration use')
    save('pack-bandage','Dress a wound','Pack',mix([
        (source('rpg','cloth3',.84,150,2400),0,.44),
        (source('rpg','clothBelt',.85,150,2000),.32,.30),
        (source('rpg','cloth1',1.05,180,2000),.65,.2)],1.25),
        'Cloth unroll, pull and wrap; no medical machinery or bright heal sparkle.',peak=.25,rms=.056,hook='Successful bandage use')
    save('pack-oil','Pour lantern oil','Pack',mix([
        (source('rpg','handleSmallLeather2',.95,150,1800),0,.22),
        (source('water','splash_08',.80,170,2200),.20,.32),
        (source('water','bubble_01',.82,180,1900),.50,.23),
        (source('rpg','metalClick',.85,250,2200),.94,.16)],1.35),
        'Handled flask, controlled pour/glug and muted cap; no ignition or time-cost change.',peak=.27,rms=.06,hook='Successful oil refill')
    save('pack-tome','Read a tome','Pack',mix([
        (source('rpg','bookOpen',.86,150,2500),0,.30),
        (source('rpg','bookFlip2',.92,200,2800),.28,.43),
        (source('rpg','bookPlace1',.84,100,1700),.83,.17)],1.35),
        'Old cover movement, one page and a settling hand; no lore/identification cue.',peak=.25,rms=.055,hook='Successful tome use')
    save('smith-temper','Hammer on the anvil','Smith',room(mix([
        (source('impact','impactMetal_heavy_001',.94,200,4200),.01,.48),
        (source('impact','impactPlate_medium_002',.83,170,3000),.025,.23)],.9),1.35,.07),
        'One weighted iron/anvil strike with a damp tail; trigger once per successful temper.',peak=.38,rms=.085,hook='Smith successful temper; existing rules/prices/timing stay unchanged')
    catalog={'issue':217,'seed':SEED,'assets':assets,'format':'mono PCM16 44.1kHz WAV',
             'runtime_synthesis':False,'voice_cloning':False,'live_hooks_changed':False,
             'owner_listening_review':'pending','physical_iphone_tested':False}
    (OUT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
    # Compact sampler, not runtime concatenation and not a loudness-normalized
    # comparison: the quiet footstep levels remain audible in context.
    chosen=['step-stone-1','step-stone-2','wall-bump','passage-roots','prayer-mend',
            'rat-hurt','goblin-death','map-heavy-blow','trap-alarm-bell','brew-shatter',
            'pack-bandage','pack-oil','smith-temper','ambience-fungal']
    reel=[];markers=[];cursor=0
    for ident in chosen:
        a=built[ident][:RATE*4]
        if ident.startswith('ambience'):a=old.edges(a.copy(),.10)
        markers.append({'id':ident,'start':cursor,'seconds':len(a)/RATE})
        reel.extend([a,np.zeros(round(.45*RATE))]);cursor+=(len(a)/RATE)+.45
    sf.write(REVIEW/'sampler.wav',np.concatenate(reel),RATE,subtype='PCM_16')
    (REVIEW/'sampler-markers.json').write_text(json.dumps(markers,indent=2)+'\n',encoding='utf-8')
    print('FIELD_AUDIO_BUILT',len(assets),'assets;',round(cursor,2),'second sampler',flush=True)


if __name__=='__main__':
    main()
