"""#225 same KayKit meshes/UVs, three native regional atlas/detail materials."""
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/materials/regional-props-v1'
OUT.mkdir(parents=True,exist_ok=True)
BASE=ROOT/'art/third-party/kaykit-dungeon-remastered/texture-floor1.png'
source=np.asarray(Image.open(BASE).convert('RGB')).astype(float)/255
regions={
    'fungal':{'wall':'art/textures/descent-walls-v1/fungal-stone.png','floor':'art/textures/descent-surfaces-v1/fungal-stone-floor.png',
              'tint':[.82,.94,.70],'detail_tint':[.76,.88,.60],'roughness':.96,'specular':.10,'read':'Damp olive wood and subdued patchy moss'},
    'scorched':{'wall':'art/textures/fortress-v1/wall.png','floor':'art/textures/fortress-v1/floor.png',
                'tint':[.69,.62,.53],'detail_tint':[.58,.53,.47],'roughness':1.0,'specular':.08,'read':'Smoke-darkened timber and char stains'},
    'waterlogged':{'wall':'art/textures/waterworks-v1/wet-plain.png','floor':'art/textures/descent-surfaces-v1/drowned-masonry-floor.png',
                   'tint':[.68,.83,.86],'detail_tint':[.68,.80,.77],'roughness':.82,'specular':.18,'read':'Cold swollen wood, damp silt and mineral stains'},
}
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
record={'issue':225,'base_atlas':{'file':BASE.relative_to(ROOT).as_posix(),'sha256':sha(BASE)},'regions':[],
        'builder_sha256':sha(Path(__file__)),'models_unchanged':{}}
for filename in ['barrel_large.glb','box_large.glb','bottle_B_green.glb']:
    path=ROOT/'art/third-party/kaykit-dungeon-remastered/models'/filename
    record['models_unchanged'][path.relative_to(ROOT).as_posix()]=sha(path)
for name,settings in regions.items():
    # Match the prior recolour workflow. Geometry, UV layout and source bytes stay intact.
    values=np.clip(source*np.array(settings['tint'])[None,None,:],0,1)
    atlas=Image.fromarray(np.rint(values*255).astype('uint8')).quantize(32,dither=Image.Dither.NONE).convert('RGB')
    atlas.save(OUT/(name+'-atlas.png'))
    wall=np.asarray(Image.open(ROOT/settings['wall']).convert('RGB').resize((64,64),Image.Resampling.BOX)).astype(float)/255
    lum=wall@np.array([.2126,.7152,.0722])
    lo,hi=np.percentile(lum,[12,88])
    normalized=np.clip((lum-lo)/max(.01,hi-lo),0,1)
    # World-space patchiness follows the region's own worn wall marks.
    stain=(1-normalized)**1.7*.55
    grain=(.65+.35*normalized)[:,:,None]*(1-stain[:,:,None]*(1-np.array(settings['detail_tint'])))
    detail=Image.fromarray(np.rint(grain*255).astype('uint8')).quantize(32,dither=Image.Dither.NONE).convert('RGB')
    detail.save(OUT/(name+'-grain.png'))
    text=f'''[gd_resource type="StandardMaterial3D" load_steps=3 format=3]
[ext_resource type="Texture2D" path="res://art/materials/regional-props-v1/{name}-atlas.png" id="atlas"]
[ext_resource type="Texture2D" path="res://art/materials/regional-props-v1/{name}-grain.png" id="grain"]
[resource]
resource_name="Regional props / {name}"
albedo_texture=ExtResource("atlas")
texture_filter=2
roughness={settings['roughness']}
metallic_specular={settings['specular']}
detail_enabled=true
detail_albedo=ExtResource("grain")
detail_blend_mode=3
detail_uv_layer=1
uv2_triplanar=true
uv2_world_triplanar=true
uv2_scale=Vector3(0.5,0.5,0.5)
'''
    (OUT/(name+'.tres')).write_text(text,encoding='utf-8',newline='\n')
    record['regions'].append({'id':name,**settings,'wall_sha256':sha(ROOT/settings['wall']),'floor_sha256':sha(ROOT/settings['floor']),
        'atlas_sha256':sha(OUT/(name+'-atlas.png')),'grain_sha256':sha(OUT/(name+'-grain.png')),'material_sha256':sha(OUT/(name+'.tres'))})
(OUT/'catalog.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8',newline='\n')
print('REGIONAL_MATERIALS',len(record['regions']),'shared atlases/materials; original models and floor-1 atlas unchanged')
