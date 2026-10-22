"""Finish the #96/#99 effect set from verified CC0 foley and original layers.

Offline rebuild: Python + NumPy + soundfile. A private soundfile wheel may
live in ignored build/audio-deps; source archives/credits remain immutable.
"""
from pathlib import Path
import io,json,hashlib,zipfile,sys,wave,math,re
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'build/audio-deps'))
import numpy as np
import soundfile as sf
from generate_sfx_samples import shaped_noise,envelope,time,add
from generate_sfx_dark import filtered,roughness
RATE=44100;SOURCE=ROOT/'art/source/audio-dark-v1';OUT=ROOT/'audio/dark-v1'
PREVIEW=ROOT/'art/concepts/sound-v1';usage=set();assets=[];cache={};built={}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def db(x):return 20*math.log10(max(1e-12,x))
def norm(a,peak=.50,rms=.14):
 a=np.nan_to_num(a).astype(np.float64);a-=np.mean(a)
 gain=min(peak/max(1e-9,float(np.max(np.abs(a)))),rms/max(1e-9,float(np.sqrt(np.mean(a*a)))))
 return a*gain
def speed(a,factor):
 return np.interp(np.arange(max(1,round(len(a)/factor)))*factor,np.arange(len(a)),a)
def read_source(group,name=None):
 key=group+('/'+name if name else '')
 usage.add(key)
 if key in cache:return cache[key].copy()
 if group in ['impact','rpg']:
  blob=zipfile.ZipFile(SOURCE/'downloads'/('kenney-'+group+'.zip')).read('Audio/'+name+'.ogg');a,rate=sf.read(io.BytesIO(blob),dtype='float64')
 else:
  entries=json.loads((SOURCE/'sources.json').read_text())['sources'];entry=next(e for e in entries if e['id']==group);a,rate=sf.read(ROOT/entry['source'],dtype='float64')
 if a.ndim==2:a=a.mean(axis=1)
 if rate!=RATE:a=np.interp(np.arange(round(len(a)*RATE/rate))*rate/RATE,np.arange(len(a)),a)
 a-=np.mean(a);cache[key]=a;return a.copy()
def trimmed(a,tail=.04):
 loc=np.flatnonzero(np.abs(a)>max(.001,np.max(np.abs(a))*.015))
 return a[max(0,loc[0]-int(.004*RATE)):min(len(a),loc[-1]+int(tail*RATE))] if len(loc) else a
def cloth(name='cloth1',pitch=.85):return filtered(speed(trimmed(read_source('rpg',name)),pitch),80,3000)
def impact(name,pitch=.80):return filtered(speed(trimmed(read_source('impact',name)),pitch),35,4000)
def blank(sec):return np.zeros(round(sec*RATE))
def mix(parts,sec):
 y=blank(sec)
 for a,at,gain in parts:add(y,a,at,gain)
 return y
def edges(a,fade=.008):
 n=min(round(fade*RATE),len(a)//3);a[:n]*=np.linspace(0,1,n)**2;a[-n:]*=np.linspace(1,0,n)**2;a[0]=a[-1]=0;return a
def looped(a,seconds):
 n=round(seconds*RATE);fade=round(.7*RATE)
 if len(a)<n+fade:
  # Overlapping, alternating source positions avoid an exposed short loop.
  y=np.zeros(n+fade);hop=max(1,len(a)-round(.35*RATE));src=edges(a.copy(),.16)
  for start in range(0,len(y),hop):add(y,src,start/RATE,1)
  a=y
 result=a[:n].copy();blend=np.linspace(0,1,fade)
 result[:fade]=a[n:n+fade]*(1-blend)+a[:fade]*blend
 result[0]=result[-1]=(result[0]+result[-1])/2
 return result
def save(ident,label,a,loop=False,peak=.50,rms=.13,notes='',deps=None):
 a=norm(a,peak,rms)
 if loop:a[0]=a[-1]=(a[0]+a[-1])/2
 else:a=edges(a)
 pcm=np.rint(np.clip(a,-.999,.999)*32767).astype('<i2');path=OUT/(ident+'.wav')
 with wave.open(str(path),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm.tobytes())
 built[ident]=pcm.astype(np.float64)/32767
 assets.append({'id':ident,'label':label,'path':'res://audio/dark-v1/'+ident+'.wav','seconds':len(a)/RATE,'rate':RATE,'channels':1,'bits':16,'loop':loop,'peak_dbfs':db(float(np.max(np.abs(pcm)))/32767),'rms_dbfs':db(float(np.sqrt(np.mean((pcm/32767)**2)))),'sha256':sha(path),'inputs':sorted(usage),'derived_inputs':deps or [],'notes':notes})
 usage.clear()
def main():
 OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True);(PREVIEW/'.gdignore').write_text('')
 source_manifest=json.loads((SOURCE/'sources.json').read_text())
 assert len(source_manifest['sources'])==7
 for e in source_manifest['sources']:assert sha(ROOT/e['source'])==e['sha256'],e['id'];assert e['license']=='CC0-1.0'
 # Dense material contact, less ringing and no comic pitch drop.
 for i in range(3):
  y=mix([(impact('impactPunch_heavy_00'+str(i),.82+i*.035),.005,.85),(impact('impactSoft_heavy_00'+str(i),.78),.012,.55),(cloth('cloth'+str(i+1),.95),.01,.16)],.68)
  save('hit-'+str(i+1),'Heavy contact '+str(i+1),y,notes='Damped punch/soft foley plus cloth; no sustained resonant note.')
 save('block-wood','Wooden shield block',mix([(impact('impactWood_heavy_000',.77),0,.85),(impact('impactPlank_medium_001',.85),.018,.55),(impact('impactMetal_light_001',.9),.035,.16)],.9))
 save('block-metal','Armour or metal block',mix([(impact('impactPlate_medium_000',.81),0,.65),(impact('impactSoft_medium_001',.8),.009,.45)],.8))
 for i in range(2):
  save('miss-'+str(i+1),'Missed swing '+str(i+1),mix([(cloth('knifeSlice'+('2' if i else ''),.82+i*.08),0,.65),(cloth('cloth'+str(i+2),1.15),.02,.35)],.48),peak=.32,rms=.08)
 rng=np.random.default_rng(962210)
 # Web/venom are authored hybrid effects: wet suction-like modulation over
 # actual cloth/fibre friction. They are not passed off as field recordings.
 n=shaped_noise(rng,.48,120,2500);t=time(.48);wet=n*envelope(t,.008,.075)*(0.55+0.45*np.sin(2*np.pi*(38*t+9*t*t)))
 save('web-spit','Web spit',mix([(wet,.01,.70),(cloth('cloth3',1.9),0,.30)],.6),notes='Original wet air/suction layer with licensed fibre friction.')
 n=shaped_noise(rng,.65,130,2200);t=time(.65);wet=n*envelope(t,.003,.10)*(0.6+0.4*np.sin(2*np.pi*(46*t-15*t*t)))
 save('venom','Venom sting',mix([(wet,0,.72),(impact('impactSoft_medium_002',.7),.01,.25)],.72),notes='Original subdued wet sting plus damp contact; no bright spell chime.')
 for i in range(2):
  a=filtered(trimmed(read_source('rpg','handleCoins'+('2' if i else ''))),180,4200)
  save('coins-'+str(i+1),'Coins in hand '+str(i+1),edges(a),peak=.38,rms=.10)
 save('purchase','Purchase',mix([(filtered(trimmed(read_source('rpg','handleCoins2')),200,3800),.02,.75),(cloth('handleSmallLeather',.95),0,.4)],1.15),peak=.38,rms=.10)
 # Nine spin pairs total 1.6*(1+0.12*average(0..8))=2.368s.
 # Landing contact is registered to the live animation rather than a jingle.
 landing=1.6*(1+.12*4)
 tick=filtered(trimmed(read_source('rpg','metalClick')),500,4200)
 coin=filtered(trimmed(read_source('rpg','handleCoins')),350,3600)
 y=mix([(tick,0,.42),(coin[:round(.18*RATE)],landing,.55)],landing+.5)
 save('coin-flip','Coin flip and landing',y,peak=.38,rms=.07,notes='Single flick, quiet flight, contact at 2.368s: matches nine live spin pairs; no outcome-specific sound.')
 save('chest-open','Heavy chest opening',mix([(filtered(trimmed(read_source('rpg','metalLatch')),150,3500),.01,.65),(cloth('creak2',.72),.13,.68),(impact('impactWood_medium_001',.85),.62,.3)],1.55))
 fire=read_source('fire');light=mix([(filtered(trimmed(read_source('rpg','metalClick')),400,5000),.01,.5),(filtered(fire,80,4200),.11,.45)],1.25)
 save('torch-light','Torch ignition',light,notes='Metal/flint-like contact into recorded fire texture; no cinematic whoosh.')
 fire=read_source('fire');t=time(.6);hiss=shaped_noise(rng,.6,400,3800)*envelope(t,.005,.09)
 save('torch-burnout','Torch dying',mix([(filtered(fire[:round(.55*RATE)],100,2200),0,.45),(hiss,.12,.34)],.8),peak=.38,rms=.09)
 save('stumble','Stumble on stone',mix([(cloth('clothBelt',.85),0,.65),(impact('impactSoft_heavy_001',.8),.10,.6),(impact('footstep_concrete_002',.88),.15,.6)],.9))
 save('fall','Hollow floor fall',mix([(impact('impactPlank_medium_003',.78),0,.7),(cloth('cloth4',.83),.04,.5),(impact('impactSoft_heavy_003',.72),.28,.75),(impact('impactWood_light_002',.8),.39,.24)],1.35))
 click=filtered(trimmed(read_source('rpg','metalClick')),180,2300)[:round(.075*RATE)]
 save('ui-click','Quiet interface click',click,peak=.13,rms=.045,notes='Short muted mechanical contact, deliberately quieter than world effects.')
 wood=impact('impactPlank_medium_000',.65);metal=impact('impactMetal_heavy_002',.7)
 y=mix([(wood,0,.7),(impact('impactWood_heavy_001',.66),.12,.7),(wood,.28,.5),(metal,.30,.3),(impact('impactPlank_medium_003',.72),.46,.65),(impact('impactWood_medium_004',.75),.66,.35),(metal,.79,.15)],2.1)
 save('gate-break','Fortress gate breaking',y,notes='Timber failure, falling boards and dull iron; no explosion.')
 queen=filtered(speed(trimmed(read_source('queen')),.77),180,4200)
 save('queen-screech','Goblin queen screech',queen,peak=.45,rms=.12,notes='Lowered/filtered licensed balloon-friction creature source; not a cloned actor voice.')
 heart=filtered(trimmed(read_source('heartbeat')),35,500)[:round(.86*RATE)]
 # Main contact peaks are around .17/.47s; discard the long quiet source tail.
 save('heartbeat','Bleeding heartbeat',edges(heart,.045),peak=.42,rms=.11,notes='One licensed lub-dub with a short tail; no generated kick-drum glide.')
 drum=filtered(impact('impactSoft_heavy_000',.40),35,650)
 drum=mix([(drum,0,.8),(filtered(impact('impactWood_heavy_000',.52),45,900),.006,.28)],.8)
 save('drum-hit','Muffled war drum',drum,peak=.45,rms=.12)
 # A sparse irregular call under rock, never a cheerful marching beat.
 y=blank(16.7)
 for at,gain in [(0,.6),(1.4,.38),(3.3,.55),(4.75,.30),(7.1,.58),(8.45,.33),(11.0,.56),(12.7,.30),(15.5,.42)]:add(y,built['drum-hit'],at,gain)
 y=filtered(y,40,850);y+=np.roll(y,int(.19*RATE))*.17
 save('distant-drums-loop','Distant fortress drums',looped(y,16),True,peak=.32,rms=.075,deps=['drum-hit'])
 fire=filtered(read_source('fire'),70,3800);save('camp-fire-loop','Campfire',looped(fire,24),True,peak=.40,rms=.10)
 wind=filtered(read_source('wind')[int(3*RATE):],70,2400);save('camp-wind-loop','Wind around the tents',looped(wind,24),True,peak=.32,rms=.075)
 crowd=read_source('crowd');voice=filtered(speed(crowd,.87),220,850)
 voice=.65*voice+.25*np.roll(voice,int(1.13*RATE))+.20*np.roll(voice,int(2.73*RATE))
 voice=filtered(voice,220,800);save('camp-voices-loop','Distant camp murmur',looped(voice,24),True,peak=.20,rms=.055,notes='Recorded crowd transformed into a remote low-band murmur; deliberately low in the composite, no intelligible dialogue intended.')
 y=built['camp-fire-loop']*.72+built['camp-wind-loop']*.60+built['camp-voices-loop']*.12
 save('camp-ambience-loop','Camp ambience',y,True,peak=.40,rms=.10,deps=['camp-fire-loop','camp-wind-loop','camp-voices-loop'])
 save('torch-burn-loop','Held torch crackle',looped(filtered(read_source('fire'),180,3300),8),True,peak=.24,rms=.06)
 # Keep the established cave bed underneath the outskirts drums.
 usage.add('project/audio/placeholder/ambience_cave.wav')
 cave,rate=sf.read(ROOT/'audio/placeholder/ambience_cave.wav',dtype='float64')
 if cave.ndim==2:cave=cave.mean(axis=1)
 if rate!=RATE:cave=np.interp(np.arange(round(len(cave)*RATE/rate))*rate/RATE,np.arange(len(cave)),cave)
 y=looped(cave,16)*.32+built['distant-drums-loop']*.52
 save('outskirts-ambience-loop','Cave outskirts with distant drums',looped(np.tile(y,2),16),True,peak=.34,rms=.075,deps=['distant-drums-loop'],notes='Original existing cave ambience is retained beneath the CC0-derived drum texture.')
 # Browser-friendly reel is a review artifact, not a runtime resource.
 reel=[];timings=[];cursor=0.0
 for e in assets:
  silence=blank(.30);reel.append(silence);cursor+=.30;a=built[e['id']]
  if e['loop']:a=edges(a[:RATE*4].copy(),.12)
  timings.append({'id':e['id'],'start':round(cursor,5),'seconds':len(a)/RATE});reel.append(a);cursor+=len(a)/RATE
 total=np.concatenate(reel);pcm=np.rint(np.clip(total,-.999,.999)*32767).astype('<i2')
 with wave.open(str(PREVIEW/'audition.wav'),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm.tobytes())
 manifest={'issues':[96,99,54],'date':'2026-10-22','format':'44.1kHz mono PCM16 WAV; no runtime synthesis','seed':962210,'sources':'res://art/source/audio-dark-v1/sources.json','assets':assets,'audition':{'file':'art/concepts/sound-v1/audition.wav','seconds':len(total)/RATE,'timings':timings}}
 (OUT/'catalog.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
 (PREVIEW/'timings.json').write_text(json.dumps(timings,indent=2)+'\n')
 for e in assets:
  p=OUT/(e['id']+'.wav.import')
  if not p.exists():continue  # first import supplies the native sidecar/UID
  text=p.read_text()
  for key,value in [('compress/mode','0'),('edit/normalize','false'),('edit/trim','false'),('edit/loop_mode','2' if e['loop'] else '1')]:
   text=re.sub(r'^'+re.escape(key)+r'=.*$',key+'='+value,text,flags=re.M)
  p.write_text(text,encoding='utf-8',newline='\n')
 print('DARK_SOUND_LIBRARY:',len(assets),'finished assets,',round(cursor,2),'s review reel')
if __name__=='__main__':main()
