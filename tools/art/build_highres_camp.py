"""#112: recover source detail at 2.5x texture density, retaining 640px geometry."""
from pathlib import Path
from PIL import Image
import hashlib,json,re

ROOT=Path(__file__).resolve().parents[2]
OLD=ROOT/'art/camp/organic-v3'
SOURCE=ROOT/'art/source/camp-layered-v3'
OUT=ROOT/'art/camp/highres-v4'
REVIEW=ROOT/'art/concepts/camp-highres-v4'
FACTOR=2.5

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def write(path,text):path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
def clean(im):
    im=im.convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=224 else 0));return im

def export_registered(master,registration,old_canvas,dest):
    # Recover the exact old crop/physical footprint from the retained registration.
    crop=clean(master).crop(registration['source_bounds'])
    size=(round((old_canvas[0]-4)*FACTOR),round((old_canvas[1]-4)*FACTOR))
    assert crop.width>=size[0] and crop.height>=size[1],dest.name+' would upscale source'
    crop=crop.resize(size,Image.Resampling.LANCZOS)
    pad=round(2*FACTOR)
    im=Image.new('RGBA',(size[0]+pad*2,size[1]+pad*2));im.paste(crop,(pad,pad));im.save(dest)
    return im

def scale_sprite_nodes(scene):
    blocks=re.split(r'(?=\[node )',scene)
    for i,block in enumerate(blocks):
        if re.match(r'\[node .* type="Sprite2D"',block):
            blocks[i]=block.replace('centered = false','scale = Vector2(0.4, 0.4)\ncentered = false')
    return ''.join(blocks)

def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    write(REVIEW/'.gdignore','')
    layout=json.loads((OLD/'layout.json').read_text())
    sources={};exports={}
    terrain=Image.open(SOURCE/'terrain.png').convert('RGB')
    assert terrain.width>=1600 and terrain.height>=900
    terrain=terrain.resize((1600,900),Image.Resampling.LANCZOS);terrain.save(OUT/'terrain.png')
    sources['terrain']=sha(SOURCE/'terrain.png')
    for site in layout['sites']:
        name=site['id'];source=SOURCE/(site.get('source',name)+'.png')
        reg=layout['registration'][name]
        export_registered(Image.open(source),reg,reg['canvas'],OUT/(name+'.png'))
        sources[name]=sha(source)
        scene=(OLD/(name+'.tscn')).read_text()
        # Shared scripts and animated flame frames retain their original geometry.
        scene=re.sub(r'(res://art/camp/)organic-v3/([^"\n]+\.png)',r'\1highres-v4/\2',scene)
        scene=scale_sprite_nodes(scene).replace('texture_filter = 1','texture_filter = 2')
        write(OUT/(name+'.tscn'),scene)
    reg=layout['registration']['occupied-cot'];source=SOURCE/'occupied-cot.png'
    export_registered(Image.open(source),reg,reg['canvas'],OUT/'occupied-cot.png');sources['occupied-cot']=sha(source)
    # Recreate the original authored notice alignment at high density before cropping.
    source=ROOT/'art/source/backlog96-v1/contract-notice.png'
    im=Image.open(source).convert('RGBA');bounds=im.getchannel('A').point(lambda a:255 if a>=96 else 0).getbbox()
    reference=Image.open(ROOT/'art/camp/cave-camp-v1/cave.png').convert('RGBA');target=reference.getchannel('A').getbbox()
    aligned=Image.new('RGBA',(round(reference.width*FACTOR),round(reference.height*FACTOR)))
    crop=clean(im).crop(bounds).resize((round((target[2]-target[0])*FACTOR),round((target[3]-target[1])*FACTOR)),Image.Resampling.LANCZOS)
    aligned.paste(crop,(round(target[0]*FACTOR),round(target[1]*FACTOR)))
    notice=aligned.crop(tuple(round(v*FACTOR) for v in [68,99,82,123])).resize((20,35),Image.Resampling.LANCZOS)
    notice.save(OUT/'notice.png');sources['notice']=sha(source)
    # The unloading state gets exactly the same registration and independent visibility.
    reg=json.loads((ROOT/'art/concepts/camp-arrivals-v1/export-validation.json').read_text())['registration']
    source=ROOT/'art/source/camp-arrivals-v1/caravan-unloading.png'
    export_registered(Image.open(source),reg,reg['canvas'],OUT/'caravan-unloading.png');sources['unloading']=sha(source)
    scene=(ROOT/'art/camp/arrivals-v1/caravan-unloading.tscn').read_text().replace('art/camp/arrivals-v1/','art/camp/highres-v4/')
    write(OUT/'caravan-unloading.tscn',scale_sprite_nodes(scene).replace('texture_filter = 1','texture_filter = 2'))
    # Anonymous figures/meal are re-sliced from their original sheet, not enlarged 64px exports.
    source=ROOT/'art/source/campaign-v1/camp-occupancy.png';sheet=Image.open(source).convert('RGBA')
    for i,name in enumerate(['seated-a','seated-b','meal','drying-cloth']):
        x=i%2;y=i//2
        cell=sheet.crop((round(x*sheet.width/2),round(y*sheet.height/2),round((x+1)*sheet.width/2),round((y+1)*sheet.height/2)))
        bounds=cell.getchannel('A').point(lambda a:255 if a>=96 else 0).getbbox();crop=clean(cell).crop(bounds)
        crop.thumbnail((105,120) if name.startswith('seated') else (120,100),Image.Resampling.LANCZOS)
        im=Image.new('RGBA',(160,160));im.paste(crop,((160-crop.width)//2,round(57*FACTOR)-crop.height));im.save(OUT/(name+'.png'))
    sources['occupancy']=sha(source)
    for name in ['merchant','apprentice','nurse']:
        source=ROOT/'art/source/campsite-v1'/(name+'.png');im=Image.open(source).convert('RGBA')
        bounds=im.getchannel('A').point(lambda a:255 if a>=96 else 0).getbbox();crop=clean(im).crop(bounds)
        assert crop.width>=491 and crop.height>=491
        crop.thumbnail((491,491),Image.Resampling.LANCZOS)
        frame=Image.new('RGBA',(512,512));frame.paste(crop,(256-crop.width//2,504-crop.height));frame.save(OUT/(name+'.png'))
        sources[name+'-portrait']=sha(source)
    layout['texture_canvas']=[1600,900];layout['texture_density']=FACTOR
    layout['story']='Existing #80 arrival sequence; texture density changes no gameplay or hit areas.'
    write(OUT/'layout.json',json.dumps(layout,indent=2)+'\n')
    pixels=0
    for path in OUT.glob('*.png'):
        im=Image.open(path);pixels+=im.width*im.height;exports[path.name]={'canvas':list(im.size),'sha256':sha(path)}
    report={'issue':112,'source':'Original retained generated masters; no new generation or low-resolution upscaling',
        'logical_canvas':[640,360],'texture_canvas':[1600,900],'texture_density':FACTOR,'filter':'Linear',
        'palette':'Source colours retained; low64-colour quantization removed','rgba_mib':round(pixels*4/1024**2,2),
        'source_sha256':sources,'exports':exports}
    assert report['rgba_mib']<16,report['rgba_mib']
    write(REVIEW/'export-validation.json',json.dumps(report,indent=2)+'\n')
    print('High-resolution camp:',report['rgba_mib'],'MiB RGBA; 1600x900 terrain, registered sites and arrival/occupancy layers.')

if __name__=='__main__':main()
