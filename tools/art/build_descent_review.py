"""Review shell for the authored assets. No player, story or gameplay state."""
from pathlib import Path
import json, os
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/descent-completion-v1'
def rel(path):return os.path.relpath(ROOT/path,OUT).replace('\\','/')
def main():
    cat=json.loads((OUT/'catalog.json').read_text())
    ui=json.loads((ROOT/'art/ui/expedition-v1/catalog.json').read_text())
    thumbs=json.loads((ROOT/'art/ui/expedition-v1/thumbnails/catalog.json').read_text())
    brew=json.loads((ROOT/'art/items/brews-v1/catalog.json').read_text())
    pictures=[{'id':e['id'],'group':e['group'],'src':rel(e['export'].removeprefix('res://'))} for e in cat['assets'] if e['group']!='brews']
    thumbs=[{'name':e['enemy'].removesuffix('.tres').replace('_',' ').title(),'src':rel(e['thumbnail'].removeprefix('res://'))} for e in thumbs['items']]
    data={'pictures':pictures,'glyphs':ui['glyphs'],'thumbnails':thumbs,'brew':brew}
    template=Path(__file__).with_name('descent_review.html').read_text(encoding='utf-8')
    (OUT/'inspector.html').write_text(template.replace('/* DATA */{}',json.dumps(data)),encoding='utf-8')
    print('DESCENT_REVIEW: four batches, all master and native-asset previews')
if __name__=='__main__':main()
