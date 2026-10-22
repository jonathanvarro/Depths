"""Original native SVG additions to backlog96's intent/status vocabulary."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/monsters-v1/glyphs'
OUT=ROOT/'art/ui/monsters-v1'
INK='#171c19';PAPER='#e6dac1';GOLD='#dbb477';RED='#ce5046';GAS='#a6ac65'
def path(d,fill='none',stroke=PAPER,width=2.5):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'
def outlined(d,colour=PAPER,width=2.5):return path(d,stroke=INK,width=width+2.5)+path(d,stroke=colour,width=width)
LANTERN='M11 8V5c0-5 10-5 10 0v3M8 9h16l2 16H6ZM8 27h16M11 12l1 9h8l1-9'
def main():
    groups={
      'intent':{
        'swoop':path('M3 6 11 9l5-4 5 4 8-3-4 12-6-4-3 3-3-3-6 4Z',PAPER,INK,2)+outlined('M16 18v11m-5-5 5 5 5-5',GOLD),
        'curl':path('M9 11 16 6l8 5 3 10-8 5-10-2-4-7Z',PAPER,INK,2)+outlined('M8 5c11-7 25 3 21 15m-5-4 5 4 2-6',GOLD,2),
        'swell':path('M11 8c-8 4-9 16 1 19 19 6 23-14 11-19Z',GAS,INK,2)+outlined('M16 5V1m-3 2 3-2 3 2M4 14H1m2-3-2 3 2 3M28 14h3m-2-3 2 3-2 3',GOLD,1.8),
        'grab':path('M7 27 5 17c-1-4 3-5 5-1V6c0-4 4-4 4 0v8-11c0-4 4-4 4 0v11-9c0-4 4-4 4 0v10-6c0-4 4-4 4 0v11l-6 8Z',PAPER,INK,1.8),
        'drain-light':outlined(LANTERN,GOLD,2)+outlined('M16 18v-7M24 4l6-3m-2 0 2 0-1 3',PAPER,2.2),
        'set-snare':outlined('M4 23c0-12 24-12 24 0S4 32 4 23ZM25 21l4-14M10 7l5 5-1 10',GOLD,2.5),
        'rally':path('M4 14 25 5v18L4 20Z',GOLD,INK,2)+outlined('M8 21l3 7h5l-3-6M28 8l2-3m-2 14 2 3M27 14h4',PAPER,2),
        'call-brood':path('M11 12c0-12 14-12 14 0 0 6-14 6-14 0Z',PAPER,INK,2)+outlined('M16 18v4M6 27h3m6 0h3m6 0h3M8 23v6m9-6v6m9-6v6',GOLD,2.5)
      },
      'status':{
        'grabbed':path('M8 5h6v12h4V5h6v15c0 13-16 13-16 0Z',PAPER,INK,2)+outlined('M3 18h26M3 22h26',RED,2.8),
        'snared':path('M10 3h9l-2 15 8 7v4H8V17Z',PAPER,INK,2)+outlined('M5 15c-5 8 19 13 23 4 2-8-17-12-23-4ZM27 19l4-7',GOLD,2.2),
        'gassed':path('M7 14c-8-6-3-14 5-10 6-7 16-2 13 5 9 4 3 13-4 10Z',GAS,INK,2)+path('M10 20c-3 13 16 13 13 0Z',PAPER,INK,2)+path('M13 22h1m4 0h1m-4 4h3','none',INK,2)
      },
      'fx':{'light-drained':outlined(LANTERN,GOLD,2.2)+outlined('M12 14 20 22M20 14 12 22',RED,2.8)}
    }
    catalog={'issue':141,'canvas':[32,32],'authoring':'Original native SVG paths in the existing backlog96 palette; no icon font or external library.','groups':{}}
    for group,items in groups.items():
        (SOURCE/group).mkdir(parents=True,exist_ok=True);(OUT/group).mkdir(parents=True,exist_ok=True)
        catalog['groups'][group]={}
        for id,parts in items.items():
            (SOURCE/group/(id+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><title>'+id+'</title>'+parts+'</svg>\n',encoding='utf-8',newline='\n')
            catalog['groups'][group][id]='res://art/ui/monsters-v1/'+group+'/'+id+'.png'
    catalog['groups']['intent']['wind-up']='res://art/ui/backlog96-v1/intent/heavy.png'
    (OUT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('MONSTER_SYMBOLS: 12 original SVGs; existing heavy-blow mark reused for wind-up')
if __name__=='__main__':main()
