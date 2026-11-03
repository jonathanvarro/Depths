"""Listening hub and precise hookup manifest for the #217/#167 asset delivery."""
from pathlib import Path
import html
import json

ROOT=Path(__file__).resolve().parents[2]


def main():
    review=ROOT/'art/concepts/field-audio-v1'
    field=json.loads((ROOT/'audio/field-v1/catalog.json').read_text(encoding='utf-8'))
    deeper=json.loads((ROOT/'audio/galleries-v1/catalog.json').read_text(encoding='utf-8'))
    entries=field['assets']+[dict(e,category='Music' if e.get('music') else 'Galleries') for e in deeper['assets']]
    categories=list(dict.fromkeys(e['category'] for e in entries))
    options='<option value="">All 57 assets</option>'+''.join(f'<option>{html.escape(c)}</option>' for c in categories)
    cards=''
    for e in entries:
        recipe=e.get('recipe',e.get('processing',''))
        cards+=f'''<article data-category="{html.escape(e['category'])}"><h2>{html.escape(e['label'])}</h2><p>{html.escape(e['category'])} · {e['seconds']:.2f}s · {'loop' if e['loop'] else 'one-shot'}</p><audio controls preload="none" aria-label="{html.escape(e['label'])}" src="../../../{html.escape(e['file'])}" {'loop' if e['loop'] else ''}></audio><details><summary>Source and hookup</summary><p>{html.escape(recipe)}</p><p>{html.escape(e.get('hook','Galleries presentation; see the handoff.'))}</p><p>{e['peak_dbfs']:.1f}dBFS peak · {e['rms_dbfs']:.1f}dBFS RMS · <a href="../../../{html.escape(e['file'])}">Individual WAV</a></p></details></article>'''
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · field sound and music</title>
<style>body{margin:0;background:#151b18;color:#e6dfce;font:17px/1.55 system-ui}main{max-width:1100px;margin:auto;padding:24px}h1,h2{font-family:Georgia,serif}h2{font-size:22px}a{color:#ddbd87;overflow-wrap:anywhere}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(290px,100%),1fr));gap:16px}article{border:1px solid #657062;padding:16px;min-width:0;background:#222b24}audio{width:100%;max-width:100%;min-height:44px}select,summary{min-height:44px;font:inherit}select{max-width:100%;background:#28362b;color:inherit;padding:6px}.note{border-left:3px solid #bca06c;padding:12px;background:#283025}details p{font-size:15px}label{display:flex;align-items:center;gap:10px;margin:22px 0}@media(max-width:700px){main{padding:12px}}</style>
<main><h1>Under stone · field sound and music</h1><p>46 new field effects/ambience assets, plus the retained Galleries effects and original score candidate. Quiet footsteps, restrained prayers and rough creature/material reactions. Approved soundtrack and live game hooks are unchanged.</p>
<p class="note">Recorded-material and original procedural designs. Creature reactions are not real animal recordings or cloned voices. The score is original offline synthesis. Final headphone/phone-speaker character and mix judgement remains open.</p>
<h2>Short field sampler</h2><audio controls preload="metadata" src="sampler.wav" aria-label="Field sound sampler"></audio>
<h2>Below the Sluice · existing 72s score candidate</h2><audio controls preload="metadata" src="../../../audio/galleries-v1/below-the-sluice.wav" aria-label="Below the Sluice complete score" loop></audio><p>The approved title, cave, fortress, combat and camp tracks remain intact. This deeper-cave candidate still awaits listening review.</p>
<p><a href="../../../audio/field-v1/CREDITS.md">Field credits</a> · <a href="../../../audio/galleries-v1/CREDITS.md">Galleries/music credits</a> · <a href="../../../docs/field-sound-and-music.md">Delivery and hookup notes</a> · <a href="source-validation.json">Source/format checks</a></p>
<label>Listen by role <select id="category">@@OPTIONS@@</select></label><section class="cards">@@CARDS@@</section></main>
<script>document.querySelector('#category').onchange=e=>{for(const card of document.querySelectorAll('article'))card.hidden=!!e.target.value&&card.dataset.category!==e.target.value;};for(const sound of document.querySelectorAll('audio'))sound.addEventListener('play',()=>{for(const other of document.querySelectorAll('audio'))if(other!==sound)other.pause();});</script></html>'''.replace('@@OPTIONS@@',options).replace('@@CARDS@@',cards)
    (review/'inspector.html').write_text(page,encoding='utf-8')
    print('FIELD_AUDIO_GALLERY',len(entries),'individual assets and complete score')


if __name__=='__main__':main()
