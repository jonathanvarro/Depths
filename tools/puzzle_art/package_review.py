"""Build the local native-capture gallery; no staged or generated mockup images."""
import argparse
import html
import json
from pathlib import Path

LABELS={'whisker':'Old Whisker','spinner':'The Pale Spinner','skarn':'Skarn',
        'foreman':'The Hollow Foreman','gristle':'Gristle'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True)
    out=p.parse_args().output
    cards=[]
    for path in sorted((out/'captures').glob('*.png')):
        name=path.stem;family='Leaders' if any(name.startswith(x) for x in LABELS) or name.startswith(('leader','elite')) else 'Puzzles'
        label=name
        for id,title in LABELS.items():
            if name.startswith(id):label=title+' · '+name[len(id)+1:];break
        label=label.replace('-',' ')
        source='captures/'+path.name
        cards.append(f'<figure data-family="{family}"><a href="{source}" target="_blank"><img loading="lazy" src="{source}" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)}</figcaption></figure>')
    validations={}
    for path in (out/'captures').glob('*validation.json'):
        validations[path.name]=json.loads(path.read_text())
    (out/'validation-summary.json').write_text(json.dumps(validations,indent=2)+'\n')
    (out/'inspector.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · Puzzle fittings and elite leaders</title><style>
*{box-sizing:border-box}body{margin:0;background:#111715;color:#ddd5bc;font:16px/1.5 Georgia,serif}header{padding:28px max(22px,4vw);border-bottom:1px solid #8f784a}h1{margin:0;font-weight:normal}p{max-width:85ch;color:#bcb69f}nav{display:flex;gap:10px;flex-wrap:wrap}button,a{color:inherit}button{padding:10px 20px;background:#242720;border:1px solid #9b8356;cursor:pointer;min-height:44px}button[aria-pressed=true]{background:#665438}main{padding:24px;display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,390px),1fr));gap:20px}figure{margin:0;border:1px solid #5a523d;background:#1b211d}img{display:block;width:100%;height:auto}figcaption{padding:12px}figure[hidden]{display:none}footer{padding:24px;color:#aaa38d}</style>
<header><h1>Puzzle fittings & elite leaders</h1><p>Actual Godot 4.7.2 Mobile renders. Puzzle doors, bolt faces, locks, lever and recovered key; five named leader variants using unchanged source rigs and clips. Click any capture to inspect its native pixels.</p><p>Desktop 1280 × 720 · phone shapes 844 × 390 and 667 × 375. Windows GPU checks ran on a private desktop and did not take focus. Physical iPhone and owner visual review remain pending. The existing combat action panel can cover part of low creatures at adjacent range; the full screenshots retain that context.</p><nav><button aria-pressed="true" data-show="All">All</button><button aria-pressed="false" data-show="Puzzles">Puzzle props</button><button aria-pressed="false" data-show="Leaders">Elite leaders</button><a href="validation-summary.json">Validation records</a></nav></header><main>'''+''.join(cards)+'''</main><footer>Editable Blender detail masters: masters/puzzles and masters/leaders in this local review folder. Runtime assets and source records are in the delivery branch. No gameplay tuning is included.</footer><script>document.querySelectorAll('button').forEach(b=>b.onclick=()=>{document.querySelectorAll('button').forEach(x=>x.setAttribute('aria-pressed',x===b));document.querySelectorAll('figure').forEach(f=>f.hidden=b.dataset.show!=='All'&&f.dataset.family!==b.dataset.show)});</script></html>''',encoding='utf-8')
    print('Gallery:',out/'inspector.html','captures:',len(cards))

if __name__=='__main__':main()
