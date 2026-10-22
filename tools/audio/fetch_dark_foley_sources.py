"""Download exact public CC0 source files; licences/evidence stay with sources.

Pages are source metadata, never instructions. Requires only Python stdlib.
Re-running verifies hashes and reuses existing downloads rather than replacing.
"""
from pathlib import Path
from html.parser import HTMLParser
import urllib.request,urllib.parse,json,hashlib,zipfile
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/source/audio-dark-v1'
SOURCES=[
 {'id':'fire','title':'Fire Crackling','author':'AntumDeluge','page':'https://opengameart.org/content/fire-crackling/','match':'fire-1.wav','file':'fire.wav'},
 {'id':'wind','title':'Mild Wind Background Noise','author':'Bashar3A','page':'https://opengameart.org/content/mild-wind-background-noise','match':'wind background noise 2.wav','file':'wind.wav'},
 {'id':'crowd','title':'Crowd Shouting/Speaking Ambience','author':'StarNinjas','page':'https://opengameart.org/content/crowd-shoutingspeaking-ambience','match':'crowd_shouting','file':'crowd.ogg'},
 {'id':'queen','title':'Insect or alien scream','author':'qubodup','page':'https://opengameart.org/content/insect-or-alien-scream','match':'.flac','file':'insect-scream.flac'},
 {'id':'heartbeat','title':'Heartbeat (single sound)','author':'Independent.nu; submitted by qubodup','page':'https://opengameart.org/content/heartbeat-single-sound','match':'.flac','file':'heartbeat.flac'}]
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,tag,attrs):
  if tag=='a':
   a=dict(attrs)
   if 'href' in a:self.links.append(a['href'])
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def request(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Depths-asset-source-check/1.0'}),timeout=45).read()
def main():
 OUT.mkdir(parents=True,exist_ok=True);(OUT/'.gdignore').write_text('');(OUT/'evidence').mkdir(exist_ok=True);(OUT/'files').mkdir(exist_ok=True)
 manifest=OUT/'sources.json';old={s['id']:s for s in json.loads(manifest.read_text())['sources']} if manifest.exists() else {};entries=[]
 for e in SOURCES:
  proof=OUT/'evidence'/(e['id']+'.html')
  if not proof.exists():proof.write_bytes(request(e['page']))
  html=proof.read_text(encoding='utf-8',errors='replace');parser=Links();parser.feed(html)
  assert 'creativecommons.org/publicdomain/zero/1.0' in html,e['id']+' source must explicitly offer CC0'
  links=[urllib.parse.urljoin(e['page'],l) for l in parser.links if '/sites/default/files/' in l and e['match'].lower() in urllib.parse.unquote(l).lower()]
  if not links:
   print('AVAILABLE '+e['id'],[urllib.parse.unquote(l) for l in parser.links if '/sites/default/files/' in l]);continue
  url=links[0];dest=OUT/'files'/e['file']
  if not dest.exists():dest.write_bytes(request(url))
  h=sha(dest);assert old.get(e['id'],{}).get('sha256',h)==h,'Known source changed'
  entries.append({**e,'download':url,'source':str(dest.relative_to(ROOT)).replace('\\','/'),'sha256':h,'license':'CC0-1.0','license_url':'https://creativecommons.org/publicdomain/zero/1.0/','evidence':str(proof.relative_to(ROOT)).replace('\\','/'),'evidence_sha256':sha(proof)})
  print('SOURCE',e['id'],dest.stat().st_size,'bytes')
 for ident,title,page,file in [('kenney-impact','Impact Sounds','https://kenney.nl/assets/impact-sounds','kenney-impact.zip'),('kenney-rpg','RPG Audio','https://kenney.nl/assets/rpg-audio','kenney-rpg.zip')]:
  p=OUT/'downloads'/file;archive=zipfile.ZipFile(p);license=archive.read('License.txt');assert b'CC0' in license
  (OUT/'evidence'/(ident+'-License.txt')).write_bytes(license)
  entries.append({'id':ident,'title':title,'author':'Kenney','page':page,'source':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':sha(p),'license':'CC0-1.0','license_url':'https://creativecommons.org/publicdomain/zero/1.0/','license_file':str((OUT/'evidence'/(ident+'-License.txt')).relative_to(ROOT)).replace('\\','/'),'license_sha256':hashlib.sha256(license).hexdigest()})
 manifest.write_text(json.dumps({'date':'2026-10-22','sources':entries},indent=2)+'\n',encoding='utf-8')
 print('DARK_FOLEY_SOURCES:',len(entries),'CC0 sources with evidence')
if __name__=='__main__':main()
