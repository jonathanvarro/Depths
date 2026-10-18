"""Native and phone-size art review boards; generated sources are not repainted."""
from pathlib import Path
from PIL import Image,ImageDraw
import json
from build_treasure_art import font

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/campaign-v1'

def load(path):return Image.open(ROOT/path).convert('RGBA')
def sheet(name,entries,size=(128,128),columns=4,small=48):
    w,h=size;cw=max(w+48,204);ch=h+66
    for theme,bg,ink in [('dark','#1b2420','#e6dac1'),('light','#d6cbb4','#282b25')]:
        board=Image.new('RGBA',(cw*columns,ch*((len(entries)+columns-1)//columns)),bg);d=ImageDraw.Draw(board)
        for i,(label,path) in enumerate(entries):
            im=load(path);x=(i%columns)*cw;y=(i//columns)*ch
            board.alpha_composite(im,(x+(cw-w)//2,y+5))
            thumb=im.copy();thumb.thumbnail((small,small),Image.Resampling.NEAREST);board.alpha_composite(thumb,(x+4,y+h+10))
            d.text((x+small+10,y+h+16),label,font=font(14),fill=ink)
        board.convert('RGB').save(OUT/(name+'-'+theme+'.png'))

def main():
    for name,poses in [('queen',['idle','attack','hurt','enraged-idle','enraged-attack','enraged-hurt']),('archer',['idle','draw','release','hurt']),('guard',['idle','attack','hurt','brace'])]:
        sheet(name,[(n,'art/enemies/campaign-v1/'+name+'/'+n+'.png') for n in poses],columns=3 if name=='queen' else 4)
    sheet('cave-enemies',[(name+' '+pose,'art/enemies/campaign-v1/'+name+'/'+pose+'.png') for name in ['great-rat','webspinner','drummer'] for pose in ['idle','attack','hurt']],columns=3)
    sheet('fortress-features',[(name,'art/features/fortress-v1/'+name+'.png') for name in ['gate-barred','gate-broken','hall-closed','hall-open']],columns=4)
    sheet('fortress-props',[(name,'art/props/fortress-v1/'+name+'.png') for name in ['palisade','watch-post','goblin-mark','trophies','throne']],columns=3)
    sheet('new-icons',[(p.stem,str(p.relative_to(ROOT))) for p in sorted((ROOT/'art/ui/visual105-v1').glob('*.png'))],size=(32,32),columns=4,small=14)
    sheet('equipment',[(name,'art/items/campaign-v1/'+name+'.png') for name in ['broken-short-sword','cracked-staff']]+[(name,path) for name,path in [('padded-coat','art/items/inventory-64-v1/padded-coat.png'),('leather-jerkin','art/items/armour-v1/leather-jerkin.png')]],size=(64,64),small=40)
    sheet('camp-cues',[(p.stem,str(p.relative_to(ROOT))) for p in sorted((ROOT/'art/camp/occupancy-v1').glob('*.png'))],size=(64,64),small=32)
    for name in ['corin','alwen']:
        folder=ROOT/'art/portraits/main-heroes-v1'/name
        base=Image.open(folder/'preview.png').convert('RGBA');entries=[('neutral',base)]
        for cond in ['blood','dirt','bandage','pallor']:
            im=base.copy();im.alpha_composite(Image.open(folder/(cond+'.png')).convert('RGBA'));entries.append((cond,im))
        for theme,bg in [('dark','#1b2420'),('light','#d6cbb4')]:
            board=Image.new('RGBA',(192*4,235*2),bg);d=ImageDraw.Draw(board)
            for i,(label,im) in enumerate(entries):
                at=((i%4)*192,(i//4)*235);board.alpha_composite(im,at);d.text((at[0]+8,at[1]+197),label,font=font(16),fill='#e6dac1' if theme=='dark' else '#282b25')
            board.convert('RGB').save(OUT/(name+'-conditions-'+theme+'.png'))
    tiles=[]
    for name in ['wall','wall-timber','floor','ceiling']:
        tile=load('art/textures/fortress-v1/'+name+'.png');board=Image.new('RGBA',(256,276),'#1b2420')
        for x in [0,128]:
            for y in [0,128]:board.alpha_composite(tile,(x,y))
        ImageDraw.Draw(board).text((6,257),name,font=font(14),fill='#e6dac1');tiles.append(board)
    board=Image.new('RGBA',(512,552),'#1b2420')
    for i,im in enumerate(tiles):board.alpha_composite(im,((i%2)*256,(i//2)*276))
    board.convert('RGB').save(OUT/'fortress-repeat.png')
    print('Wrote native/small dark/light review boards for every campaign art family.')

if __name__=='__main__':main()
