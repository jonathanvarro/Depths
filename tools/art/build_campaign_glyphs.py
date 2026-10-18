"""Original native vectors extending the existing #96 icon vocabulary for #105."""
from pathlib import Path
import json
from build_backlog_glyphs import path, svg, INK, PAPER, RED, GOLD

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/campaign-v1/glyphs'

def main():
    icons={
        'rush':path('m4 9 6 7-6 7m10-14 7 7-7 7','none',GOLD,3)+path('M25 7v6m0 7v5','none',PAPER,2),
        'recover':path('M11 9a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z',PAPER,INK,1.5)+path('m9 13 6 4-1 10M9 13l-3 9m9-5 7 4m-8 6h8','none',PAPER,3)+path('m23 5 5 3-5 4m0 1 5 3-5 4','none',GOLD,1.8),
        'beat':path('M7 12c0-5 18-5 18 0v13c0 5-18 5-18 0Z','#866344',INK,2)+path('M7 12c0 5 18 5 18 0M11 16l5 10 5-10','none',PAPER,2)+path('m3 3 9 5m17-5-9 5','none',GOLD,3),
        'webbed':path('M4 4 28 28M28 4 4 28M16 2v28M2 16h28','none',PAPER,1.8)+path('m7 7 9-3 9 3 3 9-3 9-9 3-9-3-3-9Zm5 5 4-2 4 2 2 4-2 4-4 2-4-2-2-4Z','none',PAPER,1.5),
        'venom':path('M16 3C12 10 6 14 6 21a10 8 0 0 0 20 0c0-7-6-11-10-18Z','#9da06d',INK,2)+path('m11 17 3 4m7-4-3 4m-5 4h6','none',INK,2),
        'guard':path('M16 3 28 8v9c0 6-5 10-12 13C9 27 4 23 4 17V8Z',PAPER,INK,2)+path('M16 7v19M8 11l8-3 8 3','none',INK,2.2),
        'drummed':path('M8 16c0-4 16-4 16 0v11c0 4-16 4-16 0Z','#866344',INK,2)+path('M8 16c0 4 16 4 16 0M12 20l4 8 4-8','none',PAPER,1.8)+path('M16 11V2m-5 5 5-5 5 5','none',GOLD,2.5)+path('m3 9 3 3m23-3-3 3','none',GOLD,2),
        'armour':path('M8 3 12 6h8l4-3 4 9-5 3v14H9V15l-5-3Z',PAPER,INK,2)+path('M12 6v7l4 3 4-3V6m-4 10v11M9 23h14','none',INK,2),
        'miss':path('M21 8a5 5 0 1 0 0 10 5 5 0 0 0 0-10Z','none',PAPER,2)+path('M3 23h10c8 0 8 7 15 6m-5-4 5 4-5 1','none',GOLD,2.8),
        'heart':path('M16 28 5 17C-2 7 10 1 16 9 22 1 34 7 27 17Z',PAPER,INK,2)+path('M16 12v10m-5-5h10','none','#6c8659',2.5),
        'nerves':path('M8 24v-6C1 5 19-2 24 8l2 7-4 2v6h-7l-1 6','none',PAPER,2.5)+path('m15 5-4 8h6l-5 9','none',GOLD,2.5)+path('m27 3 3-1M3 4 1 1','none',GOLD,1.8),
        'rest':path('M4 12h24v16H4Z','#99876d',INK,2)+path('M4 12c0-8 10-8 10 0v16M5 18h8M18 15h7','none',PAPER,2)+path('M4 29h24','none',PAPER,1.5)
    }
    SOURCE.mkdir(parents=True,exist_ok=True)
    for name,parts in icons.items():(SOURCE/(name+'.svg')).write_text(svg(parts),encoding='utf-8',newline='\n')
    (SOURCE.parent/'glyph-catalog.json').write_text(json.dumps({'issues':[105,96],'canvas':[32,32],
        'source':'Original native SVG drawings; same contour and material palette as backlog96-v1.',
        'runtime':{n:'res://art/ui/visual105-v1/'+n+'.png' for n in icons}},indent=2)+'\n',encoding='utf-8')
    print('Wrote 12 editable glyph sources for existing live filenames.')

if __name__=='__main__':main()
