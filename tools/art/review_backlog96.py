"""Native-size contact sheets from exported art, not replacement artwork."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,hashlib,textwrap
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/concepts/backlog96-v1'
FONT=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),16)
FONT.set_variation_by_axes([400 if a['name']==b'Weight' else a['default'] for a in FONT.get_variation_axes()])
def image(path):return Image.open(ROOT/path.replace('res://','')).convert('RGBA')
def board(name,entries,size=(128,128),columns=4,small=64):
    w,h=size;cw=max(192,w+40);ch=h+74
    for bg,colour,ink in [('dark','#1b2420','#e6dac1'),('light','#d6cbb4','#262b27')]:
        result=Image.new('RGBA',(cw*columns,ch*((len(entries)+columns-1)//columns)),colour);d=ImageDraw.Draw(result)
        for i,(label,path) in enumerate(entries):
            im=image(path);x=(i%columns)*cw;y=(i//columns)*ch
            result.alpha_composite(im,(x+(cw-im.width)//2,y+8))
            thumb=im.copy();thumb.thumbnail((small,small),Image.Resampling.NEAREST)
            result.alpha_composite(thumb,(x+8,y+h+12))
            lines=textwrap.wrap(label.replace('-',' '),width=max(10,(cw-small-24)//8))
            d.multiline_text((x+small+16,y+h+14),'\n'.join(lines),font=FONT,fill=ink,spacing=0)
        result.convert('RGB').save(OUT/(name+'-'+bg+'.png'))
def main():
    board('tutorial-poses',[(n+' '+pose,'art/enemies/tutorial-v1/'+n+'/'+pose+'.png') for n in ['starved-rat','small-spider'] for pose in ['idle','attack','hurt']],columns=3,small=48)
    props=json.loads((ROOT/'art/props/cave-events-v1/catalog.json').read_text(encoding='utf-8'))
    entries=[(name,item['texture']) for name,item in props['props'].items() if 'texture' in item]
    entries += [('searched cairn','art/props/cave-events-v1/goblin-stash-empty.png'),('pack','art/props/cave-room-props-v1/abandoned-pack.png'),('pool','art/props/cave-room-props-v1/still-pool.png'),('cold camp','art/props/cave-room-props-v1/cold-camp.png')]
    board('room-props',entries,small=48)
    armour=json.loads((ROOT/'art/items/armour-v1/catalog.json').read_text(encoding='utf-8'))
    board('armour',list(armour['icons'].items()),size=(64,64),columns=3,small=40)
    for group,small in [('status',14),('intent',18),('map',16)]:
        entries=[(p.stem,'res://'+p.relative_to(ROOT).as_posix()) for p in sorted((ROOT/'art/ui/backlog96-v1'/group).glob('*.png'))]
        # Extra empty room below glyphs avoids truncation in the sheet.
        board(group+'-glyphs',entries,size=(32,32),columns=4,small=small)
    board('camp-registration',[('original cave','art/camp/cave-camp-v1/cave.png'),('contract','art/camp/cave-camp-variants-v1/contract-notice.png'),('empty cot','art/camp/cave-camp-v1/treatment.png'),('occupied cot','art/camp/cave-camp-variants-v1/nurse-occupied.png')],size=(256,192),columns=2,small=64)
    board('foreground',[('lantern','art/props/lantern-v1/body.png'),('daylight exit','art/features/daylight-exit-v1/exit.png')],size=(128,256),columns=2,small=64)
    board('coin',[('heads','art/ui/coin-v1/heads.png'),('tails','art/ui/coin-v1/tails.png'),('edge','art/ui/coin-v1/edge.png')],columns=3,small=64)
    paper=image('art/ui/map-v1/parchment.png');d=ImageDraw.Draw(paper)
    for i,name in enumerate(['party','up','down','rest','chest','chest-empty','closed','blocked','danger','object','frontier']):
        x=56+(i%3)*144;y=70+(i//3)*104
        paper.alpha_composite(image('art/ui/backlog96-v1/map/'+name+'.png'),(x,y));d.text((x-12,y+38),name,font=FONT,fill='#362b20')
    paper.save(OUT/'map-material-and-markers.png')
    print('Native/phone contact sheets written for all visual families.')
if __name__=='__main__':main()
