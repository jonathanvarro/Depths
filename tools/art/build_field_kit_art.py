"""#138: direct-source item exports and original vector status artwork.

Generated masters stay immutable. No subject is repainted here. Runtime icons
match refined-v2's 128px/64-colour format; compact exports reduce directly from
the same source. Native UI glyphs are rasterized separately by Godot.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import hashlib,json,re,argparse
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/field-kit-v1'
OUT=ROOT/'art/items/field-kit-v1'
UI=ROOT/'art/ui/boons-v2'
REVIEW=ROOT/'art/concepts/field-kit-v1'
ITEMS=[
 ('miners-pick','data/items/pick.tres','Miner’s pick','Short haft; pointed/chisel crossbar.'),
 ('folding-spade','data/items/spade.tres','Folding spade','Broad nicked blade, hinge and open D grip.'),
 ('holy-water','data/items/holy_water.tres','Holy water','Narrow cool-glass phial, linen and blue binding.'),
 ('antidote','data/items/antidote.tres','Antidote','Flat folded paper and exposed salts; sage thread.'),
 ('leather-satchel','data/gear/satchel.tres','Leather satchel','Low flap bag, broad loop strap and repaired corner.'),
 ('miners-frame-pack','data/gear/frame_pack.tres','Miner’s frame pack','Tall canvas bag on exposed timber rails.'),
 ('oilcloth-cloak','data/gear/oilcloth_cloak.tres','Oilcloth cloak','Long hooded asymmetric waxed cloth.'),
 ('heavy-wool-cape','data/gear/wool_cape.tres','Heavy wool cape','Short broad hoodless wool with blunt folds.')]

INK='#171c19';PAPER='#e6dac1';GOLD='#dbb477';GREEN='#94a879';RED='#ce6859'
def shape(d,fill='none',stroke=PAPER,width=2.5):
 return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'
def glyphs():
 # One large semantic silhouette per icon; no lettering or miniature scenes.
 return {
 'miners-luck':('Miners’ luck','Pick and lucky strike',False,
  shape('M6 6Q15 0 24 11L20 12Q15 7 6 6Z',PAPER,INK,2)+shape('m17 7-10 19',GOLD,INK,5)+shape('m17 7-10 19','none',GOLD,2.5)+shape('M25 3v4m-2-2h4','none',GOLD,2)),
 'quiet-heart':('Quiet heart','Heart with level calm stroke',False,
  shape('M16 26 5 15C-1 5 10 0 16 9 22 0 33 5 27 15Z',GREEN,INK,2)+shape('M7 14h18','none',PAPER,2.8)),
 'lamp-blessing':('Lamp blessing','Sheltered lantern',False,
  shape('M10 8V5q6-6 12 0v3M8 9h16l2 17H6Z',GOLD,INK,2)+shape('M10 13h12v9H10Z',INK,INK,1)+shape('M16 12q-7 9 0 9t0-9Z',PAPER,'none',0)),
 'deep-eyes':('Deep eyes','Wide watchful eye',False,
  shape('M3 15Q16 0 29 15 16 29 3 15Z',PAPER,INK,2)+shape('M16 8a7 7 0 1 0 0 14 7 7 0 0 0 0-14Z',GREEN,INK,2)+shape('M16 11v8','none',INK,3)),
 'blessed':('Blessed','Upright blade and rays',False,
  shape('M16 3 20 9l-1 10h-6L12 9Z',PAPER,INK,2)+shape('M9 20h14M16 21v7','none',GOLD,3)+shape('M5 7 8 9M24 9l3-2M6 15h3m14 0h3','none',GOLD,2)),
 'hearty':('Hearty','Restoring bowl and leaf',False,
  shape('M4 16h24q-1 11-12 11T4 16Z',GOLD,INK,2)+shape('M15 14Q5 12 8 3q10 0 10 9M16 13Q17 3 26 5q0 9-10 9Z',GREEN,INK,2)+shape('M8 27h16','none',PAPER,2)),
 'blood-of-the-deep':('Blood of the deep','Blood drop divided by a sharp cut',False,
  shape('M16 3C13 10 5 14 5 20a11 11 0 0 0 22 0C27 14 19 9 16 3Z',RED,INK,2)+shape('m18 9-6 10h7l-4 8','none',PAPER,2.8)),
 'withering':('Withering','Bent stem and dead leaves',True,
  shape('M16 27V14Q16 5 24 7l3 5M15 20Q2 20 5 11q10 0 10 9M17 23q0-10 10-7-1 8-10 7Z',GOLD,INK,2)+shape('M16 27h-6','none',PAPER,2.5)),
 'marked':('Marked','Eye within four hunting points',True,
  shape('M7 15q9-12 18 0-9 12-18 0Z',PAPER,INK,2)+shape('M16 11v8','none',RED,3)+shape('M3 9V3h6M23 3h6v6M3 23v6h6M29 23v6','none',RED,2.5)),
 'sickness':('Sickness','Bent face and sick breath',True,
  shape('M8 26V8q2-7 9-5 6 1 6 8l4 5-5 2v6H11Z',PAPER,INK,2)+shape('M17 10h2M16 20l4-1','none',INK,2.5)+shape('M5 11q-4 3 0 6t0 6','none',GREEN,2.5)),
 'shaking-hands':('Shaking hands','Raised hand and tremor strokes',True,
  shape('M10 27 5 19q-1-4 2-4l3 3V8q0-4 3-3v10-10q2-3 4-1v11-8q3-2 4 1v9-6q3-1 4 2v8l-5 6Z',PAPER,INK,2)+shape('M3 4 1 7l3 3M28 4l2 4-2 3','none',RED,2))}
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def write(path,text):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
def uri(path):return 'res://'+path.relative_to(ROOT).as_posix()
def nonvisual(text):
 text=re.sub(r'^\[ext_resource type="Texture2D"[^\n]*\n','',text,flags=re.M)
 text=re.sub(r'^icon = [^\n]*\n','',text,flags=re.M)
 return '\n'.join(line.rstrip() for line in text.splitlines() if line.strip())
def fitted(raw,size,colours):
 box=raw.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
 art=raw.crop(box);content=round(size*.875);ratio=min(content/art.width,content/art.height)
 assert ratio<1
 small=art.resize((round(art.width*ratio),round(art.height*ratio)),Image.Resampling.LANCZOS)
 im=Image.new('RGBA',(size,size));offset=((size-small.width)//2,(size-small.height)//2);im.alpha_composite(small,offset)
 a=np.array(im);a[:,:,3]=np.where(a[:,:,3]>=128,255,0)
 samples=a[:,:,:3][a[:,:,3]>0]
 pal=Image.fromarray(samples.reshape(1,-1,3)).quantize(colours,dither=Image.Dither.NONE)
 alpha=Image.fromarray(a[:,:,3]);im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
 a=np.array(im);a[a[:,:,3]==0]=0
 return Image.fromarray(a),{'source_bounds':list(box),'scale':ratio,'offset':list(offset)}
def wire(path,texture):
 text=path.read_text(encoding='utf-8');before=nonvisual(text)
 if 'id="field_art"' in text:
  text=re.sub(r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="field_art"\])',lambda m:m[1]+texture+m[2],text)
 else:
  assert not re.search(r'^icon = ',text,re.M),'Do not replace another assistant’s new art: '+str(path)
  text=text.replace('\n\n','\n\n[ext_resource type="Texture2D" path="'+texture+'" id="field_art"]\n',1)
 # Godot must attach the script before setting its exported icon property.
 header,body=text.split('[resource]',1)
 body=re.sub(r'^icon = [^\n]*\n','',body,flags=re.M)
 body=re.sub(r'^(script = [^\n]+)$',lambda m:m[1]+'\nicon = ExtResource("field_art")',body,count=1,flags=re.M)
 text=header+'[resource]'+body
 assert nonvisual(text)==before
 write(path,text)
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--wire',action='store_true');args=parser.parse_args()
 for p in [OUT,OUT/'compact64',UI,REVIEW,SOURCE/'glyphs']:p.mkdir(parents=True,exist_ok=True)
 write(REVIEW/'.gdignore','')
 manifest=json.loads((SOURCE/'generation.json').read_text())
 for a in manifest['assets']:
  h=sha(ROOT/a['source']);assert a.get('sha256',h)==h;a['sha256']=h
 write(SOURCE/'generation.json',json.dumps(manifest,indent=2)+'\n')
 prior=json.loads((OUT/'catalog.json').read_text()) if (OUT/'catalog.json').exists() else {}
 old={a['resource']:a for a in prior.get('items',[])+prior.get('symbols',[])}
 items=[]
 for id,resource,name,design in ITEMS:
  source=SOURCE/(id+'-master.png');raw=Image.open(source).convert('RGBA');path=ROOT/resource
  baseline=old.get('res://'+resource,{}).get('nonvisual_sha256') or hashlib.sha256(nonvisual(path.read_text()).encode()).hexdigest()
  im,transform=fitted(raw,128,64);im.save(OUT/(id+'.png'))
  compact,_=fitted(raw,64,32);compact.save(OUT/'compact64'/(id+'.png'))
  entry={'id':id,'name':name,'design':design,'resource':'res://'+resource,'icon':uri(OUT/(id+'.png')),'compact_icon':uri(OUT/'compact64'/(id+'.png')),'canvas':[128,128],'colour_limit':64,'source':uri(source),'source_sha256':sha(source),'icon_sha256':sha(OUT/(id+'.png')),'nonvisual_sha256':baseline,**transform}
  items.append(entry)
  if args.wire:wire(path,entry['icon'])
 symbols=[]
 for id,(name,design,bane,art) in glyphs().items():
  # A round boon dot vs a downward bane triangle is secondary to the silhouette.
  badge=shape('M25 25h6l-3 6Z',RED,INK,1) if bane else '<circle cx="28" cy="28" r="3" fill="'+GOLD+'" stroke="'+INK+'" stroke-width="1"/>'
  source=SOURCE/'glyphs'/(id+'.svg');write(source,'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><title>'+name+'</title>'+art+badge+'</svg>\n')
  path=ROOT/'data/boons'/(id.replace('-','_')+'.tres');resource=uri(path)
  baseline=old.get(resource,{}).get('nonvisual_sha256') or hashlib.sha256(nonvisual(path.read_text()).encode()).hexdigest()
  entry={'id':id,'name':name,'design':design,'bane':bane,'resource':resource,'icon':uri(UI/(id+'.png')),'source':uri(source),'canvas':[32,32],'display_pixels':14,'nonvisual_sha256':baseline}
  symbols.append(entry)
  if args.wire:wire(path,entry['icon'])
 catalog={'issue':138,'items':items,'symbols':symbols,'processing':'Direct alpha crop, Lanczos reduction, hard alpha, no-dither quantization; no master edits. Native SVG status art rasterized by Godot.'}
 write(OUT/'catalog.json',json.dumps(catalog,indent=2)+'\n')
 board=Image.new('RGB',(1024,520),'#1b2420');d=ImageDraw.Draw(board)
 font=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),17)
 for i,e in enumerate(items):
  x=(i%4)*256;y=(i//4)*250;im=Image.open(ROOT/e['icon'].removeprefix('res://'))
  board.paste(im,(x+10,y+15),im)
  small=Image.open(ROOT/e['compact_icon'].removeprefix('res://'));board.paste(small,(x+166,y+28),small)
  tiny=im.resize((40,40),Image.Resampling.NEAREST);board.paste(tiny,(x+178,y+112),tiny)
  d.text((x+12,y+172),e['name'],font=font,fill='#e6dac1');d.text((x+12,y+198),'128 / 64 / 40 px',font=font,fill='#aeb5a4')
 board.save(REVIEW/'inventory-overview.png')
 print('FIELD_KIT: eight 128px/64px icons; eleven native glyph sources; '+('resources wired' if args.wire else 'export only'))
if __name__=='__main__':main()
