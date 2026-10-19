"""#109 combined equipment/inventory review; reuse approved physical art."""
from pathlib import Path
import hashlib,json,re

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/interface/pack-heroes-v4'
OLD=ROOT/'art/concepts/interface/pack-heroes-v3'

def main():
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'.gdignore').touch()
    previous=(OLD/'pack-heroes.html').read_text(encoding='utf-8')
    root_fragment=previous[previous.index('<div id="depths-pack-heroes"'):]
    styles=re.search(r'<style>(.*?)</style>\s*<div class="stage">',root_fragment,re.S).group(1)
    styles=styles.replace("url('assets/", "url('../pack-heroes-v3/assets/")
    script=re.search(r'<script>(.*?)</script>',previous,re.S).group(1)
    def replace(old,new):
        nonlocal script
        assert old in script,old
        script=script.replace(old,new)
    replace("if(['equipment','status','pack'].includes(p.page))state.page=p.page;", "if(['equipment','status'].includes(p.page))state.page=p.page;")
    replace("p.version!==2", "p.version!==4")
    replace("privateContent:{version:2", "privateContent:{version:4")
    replace("design:'Image-slot Pack and hero Equipment/Status'", "design:'Combined equipment left / shared backpack right'")
    replace("$('.page-title').textContent=state.page==='pack'?'Pack':state.page==='status'?'Status':'Equipment';", "$('.page-title').textContent='Equipment & Pack';")
    replace("$('.destination').textContent=state.page==='pack'?'Heroes':'Pack';", "")
    replace("$('.hero-toolbar').hidden=state.page==='pack';$('.hero-heading').hidden=state.page==='pack';$('.tabs').hidden=state.page==='pack';", "$('.hero-toolbar').hidden=false;$('.hero-heading').hidden=false;$('.tabs').hidden=false;")
    replace("$('.pack-page').hidden=state.page!=='pack';", "$('.pack-page').hidden=false;")
    replace("c.className='equip-cell';", "c.className='equip-cell';c.dataset.role=id;")
    replace("active=null;$('.inspect').hidden=true;suppressHover=true;", "active=null;$('.inspect').hidden=true;$('.inspect-hint').hidden=false;$$('.equip-cell').forEach(c=>c.classList.remove('receives'));suppressHover=true;")
    start=script.index('  function placeDetail(){');end=script.index('  function showDetail(',start)
    script=script[:start]+"  function placeDetail(){} // Details occupy their own reserved bottom row.\n"+script[end:]
    replace("$('.inspect-extra').textContent=i.extra||(active.context==='equipped'?'Equipped by '+heroes[state.hero].name:'For '+heroes[state.hero].name);", "const current=state.loadouts[state.hero][i.slot];\n    $('.inspect-extra').textContent=i.extra||(active.context==='equipped'?'Equipped by '+heroes[state.hero].name:'For '+heroes[state.hero].name+(current?' · Replaces '+items[current].name:' · Empty slot'));\n    $('.inspect-hint').hidden=true;$$('.equip-cell').forEach(c=>c.classList.toggle('receives',active.context==='bag'&&c.dataset.role===i.slot));")
    replace("(destination||$('.destination'))", "(destination||$('.back'))")
    replace("  $('.destination').addEventListener('click',()=>changePage(state.page==='pack'?'equipment':'pack'));", "")
    # Reopening either launcher always shows equipment with the same bag.
    replace("state.page=b.dataset.open;", "state.page='equipment';")
    template=(OUT/'layout.html').read_text(encoding='utf-8')
    css=(OUT/'combined.css').read_text(encoding='utf-8')
    html=template.replace('@@styles@@',styles+'\n'+css).replace('@@script@@',script)
    html='\n'.join(line.rstrip() for line in html.splitlines())+'\n'
    assert '@@' not in html
    (OUT/'combined-kit.html').write_text(html,encoding='utf-8',newline='\n')
    manifest={'issue':109,'kind':'Combined browser design review; live game unchanged',
        'base':(OLD/'pack-heroes.html').relative_to(ROOT).as_posix(),
        'base_sha256':hashlib.sha256((OLD/'pack-heroes.html').read_bytes()).hexdigest(),
        'reused_art':['art/concepts/interface/pack-heroes-v3/assets/bag.png','art/concepts/interface/pack-heroes-v3/assets/roll.png'],
        'new_generated_art':False,'layout':'Equipment/status left, shared bag always right, reserved bottom inspection row',
        'demo_only':'Existing isolated sample state, no gameplay or inventory capacity decision.'}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Built combined kit review with the approved backpack and equipment surfaces.')

if __name__=='__main__':main()
