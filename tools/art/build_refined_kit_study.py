"""Build the quiet combined Field kit study from current item/hero resources.

No new raster generation or live gameplay changes. Retains the approved bag.
"""
from pathlib import Path
import hashlib, json, os, re

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/concepts/interface/pack-heroes-v5'


def resource(path):
    text = path.read_text(encoding='utf-8')
    result = {}
    for key, raw in re.findall(r'^(\w+) = (.+)$', text.split('[resource]', 1)[1], re.M):
        if raw.startswith('"'):
            result[key] = json.loads(raw)
        elif raw in ('true', 'false'):
            result[key] = raw == 'true'
        elif re.fullmatch(r'-?\d+(\.\d+)?', raw):
            result[key] = float(raw) if '.' in raw else int(raw)
        elif raw.startswith('ExtResource'):
            identifier = re.search(r'"([^"]+)"', raw).group(1)
            ext = re.search(r'\[ext_resource [^\]]*path="([^"]+)" id="' + identifier + r'"\]', text)
            if ext:
                result[key] = ext.group(1)
    result['resource_path'] = path.relative_to(ROOT).as_posix()
    return result


def web_path(path):
    return Path(os.path.relpath(ROOT / path.removeprefix('res://'), OUT)).as_posix()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / '.gdignore').touch()
    definitions = {}
    sources = []
    for directory, kind in [('data/items', 'supply'), ('data/gear', 'gear')]:
        for path in sorted((ROOT / directory).glob('*.tres')):
            item = resource(path)
            if not item.get('icon'):
                continue
            item.update(kind=kind, art=web_path(item['icon']))
            definitions[path.stem] = item
            sources.append(path)
    heroes = []
    for key in ('mara', 'corin', 'alwen'):
        path = ROOT / f'data/companions/{key}.tres'
        hero = resource(path)
        hero['art'] = web_path(hero['portrait'])
        hero['short_name'] = hero['display_name'].removeprefix('Sister ')
        heroes.append(hero)
        sources.append(path)
    data = {'items': definitions, 'heroes': heroes}
    (OUT / 'item-data.json').write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8', newline='\n')
    previous = (ROOT / 'art/concepts/interface/pack-heroes-v3/pack-heroes.html').read_text(encoding='utf-8')
    base = re.search(r'<style>(.*?)</style>\s*<div class="stage">', previous[previous.index('<div id="depths-pack-heroes"'):], re.S).group(1)
    base = base.replace("url('assets/", "url('../pack-heroes-v3/assets/")
    css = base + '\n' + (OUT / 'base.css').read_text(encoding='utf-8') + '\n' + (OUT / 'refined.css').read_text(encoding='utf-8')
    html = (OUT / 'layout.html').read_text(encoding='utf-8').replace('@@styles@@', css).replace('@@data@@', 'const KIT_DATA=' + json.dumps(data, ensure_ascii=False) + ';').replace('@@script@@', (OUT / 'interaction.js').read_text(encoding='utf-8'))
    assert '@@' not in html
    html = '\n'.join(line.rstrip() for line in html.splitlines()).rstrip() + '\n'
    (OUT / 'combined-kit.html').write_text(html, encoding='utf-8', newline='\n')
    manifest = {'kind': 'Isolated combined interface review; live Pack only receives focused cleanup',
        'new_generated_art': False, 'art_sources': ['art/concepts/interface/pack-heroes-v3/assets/bag.png', 'art/concepts/interface/pack-heroes-v3/assets/roll.png'],
        'resource_count': len(definitions), 'hero_fixture': 'Three starting hero options shown together for comparison only; not an approved starting party.',
        'sources': [{'path': path.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()} for path in sources]}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(f'Built Field kit review from {len(definitions)} current items and {len(heroes)} hero definitions.')


if __name__ == '__main__':
    main()
