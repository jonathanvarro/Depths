"""Original native vector glyphs for small UI; rasterized by Godot at 32px."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/ui/backlog96-v1'
SOURCE=ROOT/'art/source/backlog96-v1/glyphs'
INK='#171c19';PAPER='#e6dac1';RED='#ce5046';GOLD='#dbb477'

def path(d,fill='none',stroke=PAPER,width=2.5):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'

def svg(parts):return '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">'+parts+'</svg>\n'

def main():
    status={
      'bleeding':path('M12 3C10 8 5 12 5 17a7 7 0 0 0 14 0C19 12 14 7 12 3Z',RED,INK,2)+path('M24 17c-1 3-3 4-3 7a3 3 0 0 0 6 0c0-2-2-5-3-7Z',RED,INK,1.5),
      'wounded':path('M16 27 5 16C-2 6 10 1 16 9 22 1 34 6 27 16Z',RED,INK,2)+path('m18 7-5 8 6 2-6 8','none',PAPER,2),
      'healing':path('M12 4h8v8h8v8h-8v8h-8v-8H4v-8h8Z','#8ca875',INK,2)+path('m8 16 6 6 10-12','none',PAPER,2),
      'down':path('M7 13a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z',PAPER,INK,2)+path('m4 25 7-6h9l7 5M11 19l5 8M4 28h24','none',PAPER,3),
      'deep-wound':path('M8 4 24 28M14 4 7 12M21 11l-9 9M27 19l-9 9','none',INK,6)+path('M8 4 24 28M14 4 7 12M21 11l-9 9M27 19l-9 9','none',RED,3),
      'limp':path('M11 4h8l-2 11 7 9-5 4-10-12Z',PAPER,INK,2)+path('M26 8v21M23 8h6','none',GOLD,2.5),
      'unconscious':path('M6 16c0-14 20-14 20 0v5c-4 8-16 8-20 0Z',PAPER,INK,2)+path('m10 16 4 1m4 0 4-1m-9 7h6','none',INK,2),
      'dressed-overlay':path('M2 23 28 20l2 8-26 3Z',PAPER,INK,1.5)+path('m9 23 1 5m11-7 1 6','none','#aa9470',1.5)
    }
    shield='M16 3 27 7v11c0 6-11 11-11 11S5 24 5 18V7Z'
    blade='M22 3 27 8 13 22 8 17Z'
    club='M18 3c-7-2-12 6-8 11l3 3-7 10 4 2 8-11 3 1c8-1 10-13 3-16Z'
    intents={
      'attack':path(blade,PAPER,INK,2)+path('m5 16 11 11m-7-4-5 5','none',GOLD,3),
      'lunge':path('M3 12h15V5l12 11-12 11v-7H3Z',GOLD,INK,2),
      'dart':path('M28 10H13V4L2 15l11 11v-7h15Z',PAPER,INK,2)+path('M22 24h7','none',GOLD,2),
      'web':path('M16 3v26M3 16h26M6 6l20 20M6 26 26 6M10 10h12l3 6-3 6H10l-3-6Z','none',INK,4.5)+path('M16 3v26M3 16h26M6 6l20 20M6 26 26 6M10 10h12l3 6-3 6H10l-3-6Z','none',PAPER,2),
      'bite':path('M4 8h24l-4 12-5-8-3 10-3-10-5 8ZM5 26h22','none',PAPER,3),
      'swing':path(club,PAPER,INK,2)+path('M5 6C0 10 2 17 6 19m-4-1 4 1-1-4','none',GOLD,2.5),
      'heavy':path(club,'#e49a5e',INK,2)+path('M24 19v9m-5-5 5 5 5-5M3 3v6m0 5v3','none',PAPER,2.5),
      'shield':path(shield,GOLD,INK,2)+path('M16 8v16','none',INK,2),
      'killing-blow':path('M5 15C0 0 24-1 23 14l-4 4v8H9v-8Z',RED,INK,2)+path('M8 10h3m5 0h3m-6 10v6m3-6v6M25 19l5 10','none',INK,3),
      'shoot':path('M8 3c17 7 17 19 0 26M8 3v26M3 16h26m-6-5 6 5-6 5','none',INK,5)+path('M8 3c17 7 17 19 0 26M8 3v26M3 16h26m-6-5 6 5-6 5','none',GOLD,2.5),
      'bash':path('M4 5 19 8v11c-3 5-7 7-7 7S4 22 4 18Z',GOLD,INK,2)+path('m23 4-1 7 7-2-5 8 6 3-9 2','none',PAPER,2.5),
      'brace':path(shield,PAPER,INK,2)+path('M8 13h16M8 19h16M16 6v19','none',INK,2.5),
      'call':path('M4 17 25 5v22L4 22Z',GOLD,INK,2)+path('m8 22 4 6h5v-6M28 9l2-3m-2 17 2 3','none',PAPER,2),
      'screech':path('M5 10 13 5v22l-8-5ZM18 10c5 3 5 9 0 12M23 5c9 6 9 16 0 22','none',PAPER,3),
      'cleaver':path('M12 4h16v15H12Z',RED,INK,2)+path('M12 7 4 26l4 3 9-10','none',PAPER,3)+path('M23 8h2','none',PAPER,2)
    }
    chest=path('M4 14 5 27 28 26 28 14ZM4 14 7 6 24 5 28 14M5 14l22-1M15 13v7l4-1v-6','none','#362b20',2.3)
    maps={
      'party':path('M7 4 27 16 7 28l4-12Z',GOLD,'#362b20',2),
      'up':path('M8 28V5m9 23V5M8 10h9m-9 7h9m-9 7h9M25 19V4m-4 5 4-5 4 5','none','#362b20',2),
      'down':path('M8 28V5m9 23V5M8 10h9m-9 7h9m-9 7h9M25 4v24m-4-5 4 5 4-5','none','#362b20',2),
      'rest':path('M3 27V8m0 13h26v6M4 20v-7h9v7m0-7h12l4 7M6 16h4','none','#362b20',2.3),
      'chest':chest,
      'chest-empty':chest+path('M3 4 28 29M28 3 4 29','none','#a33a30',3.2),
      'closed':path('M6 29V4l20-1v26M10 27V8l12-1v20ZM18 17h1','none','#362b20',2.4),
      'blocked':path('M3 28 2 20 8 14l9 2 3 12ZM16 28 17 17l9-3 4 9-2 5ZM8 14 10 5l11-1 6 10M11 7l5 7','none','#362b20',2.3),
      'danger':path('M16 3 30 28H2ZM16 11v9m0 4v1','none','#362b20',2.5),
      'object':path('M9 10c0-10 17-9 16 0 0 5-9 5-9 11m0 5v1','none','#362b20',3.2),
      'frontier':path('M3 12h7m5 0h5m5 0h4M3 21h6m6 0h6m5 0h3','none','#655a46',1.8)
    }
    catalog={'issue':96,'native_canvas':[32,32],'status_display_px':14,'intent_order':list(intents),'groups':{},'authoring':'Original SVG paths; no external icon library.'}
    for group,items in [('status',status),('intent',intents),('map',maps)]:
        folder=SOURCE/group;folder.mkdir(parents=True,exist_ok=True)
        (OUT/group).mkdir(parents=True,exist_ok=True)
        catalog['groups'][group]={}
        for name,parts in items.items():
            (folder/(name+'.svg')).write_text(svg(parts),encoding='utf-8',newline='\n')
            catalog['groups'][group][name]='res://art/ui/backlog96-v1/'+group+'/'+name+'.png'
    (OUT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('34 original SVG glyphs: 8 status, 15 intent and 11 map markers.')

if __name__=='__main__':main()
