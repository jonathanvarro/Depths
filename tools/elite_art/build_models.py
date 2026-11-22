"""Rigid, bone-mounted leader details. Original animated GLBs are never rewritten."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / 'tools/combat_roster'))
from mesh_parts import Mesh, EXTRA, palette_png, set_uv

OUT = ROOT / 'art/enemies/named-leaders-v1'
preview_types={item.identifier for item in bpy.context.preferences.filepaths.bl_rna.properties['file_preview_type'].enum_items}
if 'NONE' in preview_types:bpy.context.preferences.filepaths.file_preview_type='NONE'
BASE = json.loads((ROOT/'art/enemies/field-creatures-3d-v1/catalog.json').read_text())['palette']
PALETTE = BASE | EXTRA
MODELS = {
    'whisker': ('combat-roster-3d-v1/great-rat', .71, []),
    'spinner': ('field-creatures-3d-v1/webspinner', .55, []),
    'skarn': ('goblin-elites-3d-v1/goblin-brute', 1.408, ['wind-up', 'recover']),
    'foreman': ('early-creatures-3d-v1/hollow-miner', 1.42, ['grab']),
    'gristle': ('early-creatures-3d-v1/breach-hound', .90, []),
}
RECOLOURS = {
    'whisker': {'pelt':'696b63','pelt_high':'96988b','pelt_dark':'3d4541','fur_gray':'b0ad98',
                'shell':'73796a','shell_light':'a2a68d','shell_dark':'444c43','eye':'be934a'},
    'spinner': {'web_shell':'c0c5b5','web_light':'e1dfc8','web_dark':'7e8c81','joint':'3f5150','eye':'82756f'},
    'skarn': {'skin':'697257','skin_light':'8b9272','skin_dark':'3e4738','carapace':'5e3830',
              'carapace_light':'8e5140','iron':'424642','iron_edge':'9a9b85','maroon':'884834'},
    'foreman': {'skin':'73786a','skin_light':'999d85','skin_dark':'434b42','cloth':'57564a',
                'cloth_light':'898469','cloth_dark':'353c35','eye':'c6ac60','maroon':'766044'},
    'gristle': {'pelt_dark':'352c2a','pelt':'5c4238','pelt_high':'876753','skin':'85715d',
                'skin_shadow':'684a43','skin_warm':'ab8368','maroon':'70402f','eye':'c16c42'},
}

def pt(v):
    """Godot +Z-front coordinates to Blender Z-up."""
    return (v[0], -v[2], v[1])

def segment(m, a, b, r, bone, colour='ivory', accent=None, tip=None, sides=5):
    m.segment(pt(a),pt(b),[(0,r),(1,r if tip is None else tip)],bone,colour,accent,sides)

def stone(m, pos, size, bone, colour, accent=None, sides=7):
    m.stone(pt(pos),(size[0],size[2],size[1]),bone,colour,accent,sides)

def plate(m, points, depth, bone, colour, edge='iron'):
    # Front faces in X/Y, thickness extending away from the viewer.
    n=len(points);v=[pt((x,y,depth-z)) for z in (0,.016) for x,y in points]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    m.add(v,faces,[colour,edge]+[edge]*n,bone)

def ring(m, centre, rx, ry, bone, colour, sides=12):
    x,y,z=centre
    for i in range(sides):
        a=math.tau*i/sides;b=math.tau*(i+1)/sides
        segment(m,(x+rx*math.cos(a),y+ry*math.sin(a),z),
                (x+rx*math.cos(b),y+ry*math.sin(b),z),.009,bone,colour,sides=4)

def whisker(m):
    # A ragged ash mane, long uneven whiskers and healed muzzle scars.
    for i in range(11):
        z=-.28+i*.064;x=.025*math.sin(i*2.7)
        segment(m,(x,.535,z),(x+.027*math.sin(i*3.1),.61+.026*(i%3),z-.05),.03,
                'spine' if i<7 else 'neck','pelt_high','fur_gray',tip=.003,sides=5)
    for side in (-1,1):
        for i in range(4):
            segment(m,(side*.112,.35+i*.012,.67),(side*(.34+.04*(i%2)),.31+i*.033,.78-i*.057),
                    .0035,'head','ivory',tip=.0015,sides=4)
    for i in range(3):
        segment(m,(-.11+i*.022,.39,.66),(-.092+i*.022,.365,.71),.004,'head','skin_shadow',tip=.002)
    stone(m,(-.113,.565,.417),(.040,.048,.017),'head','fur_gray','pelt_dark',5)

def spinner(m):
    # Raised chalk shell seams and several trailing, forked bundles of old silk.
    for i in range(5):
        z=-.23+i*.058
        stone(m,(-.018,.421+.015*math.sin(i),z),(.113,.018,.035),'abdomen','web_light','web_dark',6)
    for sign in (-1,1):
        for i in range(3):
            x=sign*(.12+.023*i);z=-.19+i*.06
            segment(m,(x,.36,z),(x*1.25,.20,z-.09),.007,'abdomen','web_light',tip=.003,sides=4)
            segment(m,(x*1.25,.20,z-.09),(x*1.16,.075+i*.018,z-.16),.003,'abdomen','web_shell',tip=.0015,sides=4)
    for x,y,z in [(-.13,.345,-.14),(.16,.325,-.08),(.10,.36,-.22)]:
        stone(m,(x,y,z),(.037,.05,.036),'abdomen','web_shell','web_light',6)

def skarn(m):
    # Unequal overlapping plates leave the original cleaver arm and grip clear.
    for i in range(3):
        stone(m,(-.27-i*.028,1.078-i*.049,-.02),(.133,.042,.132),
              'upperarm_R','iron','rust',6)
    for i in range(3):
        segment(m,(-.30+i*.051,1.12,-.03),(-.35+i*.059,1.25+(i%2)*.035,-.07),
                .018,'upperarm_R','bone_dark','ivory',tip=.002,sides=5)
    plate(m,[(-.14,.83),(.115,.91),(.18,.59),(.07,.51),(-.04,.59),(-.12,.54)],.16,
          'spine3','maroon','maroon_dark')
    # Three small scavenged teeth, tied separately rather than mirrored.
    for i in range(3):
        x=-.11+i*.073
        segment(m,(x,.81-i*.024,.19),(x+.014,.70-i*.04,.20),.022,'spine3','bone','ivory',tip=.006)
    ring(m,(.142,.68,.19),.038,.044,'spine2','brass_dark',10)

def foreman(m):
    # Dented helmet brim and a broad tally plate with cut marks.
    stone(m,(0,1.30,.075),(.158,.073,.132),'head','iron','rust',9)
    stone(m,(0,1.259,.102),(.192,.014,.160),'head','leather','iron_edge',9)
    plate(m,[(-.085,.88),(.083,.887),(.086,.74),(-.070,.73)],.149,'torso','brass_dark','iron')
    for i in range(4):
        segment(m,(-.047+i*.028,.83,.170),(-.041+i*.028,.77,.170),.003,'torso','bone_dark',sides=4)
    segment(m,(-.06,.795,.174),(.06,.817,.174),.003,'torso','bone_dark',sides=4)
    # Belt-mounted lamp, rigid to the hip: an existing patrol light owns illumination.
    ring(m,(.245,.632,.07),.035,.055,'root','iron_edge')
    stone(m,(.245,.50,.07),(.067,.014,.063),'root','iron','rust',8)
    stone(m,(.245,.615,.07),(.065,.019,.065),'root','iron','iron_edge',8)
    stone(m,(.245,.557,.07),(.033,.042,.033),'root','brass','bone',6)
    for dx,dz in [(-.049,-.042),(.049,-.042),(-.049,.042),(.049,.042)]:
        segment(m,(.245+dx,.50,.07+dz),(.245+dx,.61,.07+dz),.007,'root','iron_edge')
    for i in range(2):
        ring(m,(-.155+i*.035,.64,.15),.018,.025,'torso','iron_edge',8)
        segment(m,(-.155+i*.035,.62,.15),(-.155+i*.035,.55-i*.02,.15),.006,'torso','iron_edge')

def gristle(m):
    # A low broken restraint and a split, crooked ridge of mineralised hide.
    for i in range(6):
        z=-.34+i*.105;x=(-.026 if i%2 else .031)
        segment(m,(x,.67,z),(x*2.3,.83-(i%3)*.045,z-.055),.041,'root',
                'bone_dark','skin_warm',tip=.004,sides=5)
    for i in range(5):
        angle=math.tau*i/5
        x=.15*math.cos(angle);y=.53+.12*math.sin(angle)
        stone(m,(x,y,.24),(.042,.035,.029),'head','iron','rust',5)
        if i<2:segment(m,(x,y,.24),(x*1.22,y+.06,.25),.017,'head','iron_edge',tip=.002)
    for i in range(3):
        segment(m,(-.145,.59-i*.024,.40),(-.17,.57-i*.024,.48),.006,'head','skin_warm','skin_shadow',tip=.003)
    stone(m,(.14,.65,-.18),(.072,.046,.10),'root','skin_warm','skin_shadow',6)

def export(model_id, masters):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    mesh=Mesh();globals()[model_id](mesh)
    # One rigid mesh per target bone. Its vertices stay in the actor's metric idle space.
    records=[]
    for bone,indices in mesh.groups.items():
        allowed=set(indices);faces=[];colours=[];used=[]
        for face,colour in zip(mesh.faces,mesh.colours):
            if face[0] in allowed:
                faces.append(face);colours.append(colour);used.extend(face)
        used=sorted(set(used));remap={v:i for i,v in enumerate(used)}
        data=bpy.data.meshes.new(bone);data.from_pydata([mesh.vertices[i] for i in used],[],
                                [tuple(remap[i] for i in face) for face in faces]);data.update()
        set_uv(data,BASE if model_id=='spinner' else PALETTE,colours)
        if model_id=='spinner':
            for loop in data.uv_layers.active.data:loop.uv.y*=2
        bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
        obj=bpy.data.objects.new(bone,data);bpy.context.collection.objects.link(obj)
        data.calc_loop_triangles();records.append({'bone':bone,'triangles':len(data.loop_triangles)})
    bpy.ops.wm.save_as_mainfile(filepath=str(masters/(model_id+'.blend')))
    path=OUT/(model_id+'-details.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_materials='NONE',
                              export_animations=False,export_cameras=False,export_lights=False)
    return {'id':model_id,'source_model':MODELS[model_id][0],'attachments':records,
            'added_triangles':sum(x['triangles'] for x in records),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'source_sha256':hashlib.sha256((ROOT/'art/enemies'/(MODELS[model_id][0]+'.glb')).read_bytes()).hexdigest()}

def prepare():
    OUT.mkdir(parents=True,exist_ok=True)
    for id,(base,height,held) in MODELS.items():
        palette=(BASE if id=='spinner' else PALETTE)|RECOLOURS[id]
        # Original spider UVs use 8x4 cells. Map them to the filled half of the
        # writer's 8x8 layout, accounting for glTF's vertical UV flip.
        palette_png(OUT/(id+'-palette.png'),palette)
        text=(ROOT/'art/enemies'/base).parent.joinpath('palette.tres')
        if not text.exists():text=ROOT/'art/enemies/combat-roster-3d-v1/palette.tres'
        material=text.read_text().replace(str(text.parent.relative_to(ROOT)).replace('\\','/')+'/palette.png',
                                          'art/enemies/named-leaders-v1/'+id+'-palette.png')
        if id=='spinner':material+='uv1_scale=Vector3(1,0.5,1)\nuv1_offset=Vector3(0,0.5,0)\n'
        (OUT/(id+'.tres')).write_text(material,newline='\n')
        scene=(ROOT/'art/enemies'/(base+'.tscn')).read_text()
        # Keep the exact source GLB, actor API, held poses and tag clearance.
        scene=scene.replace('load_steps=4','load_steps=5')
        import re
        scene=re.sub(r'path="[^"]+/actor.gd"', 'path="res://art/enemies/named-leaders-v1/actor.gd"',scene)
        scene=re.sub(r'path="[^"]+/palette.tres"','path="res://art/enemies/named-leaders-v1/'+id+'.tres"',scene)
        scene=scene.replace('[node name=',f'[ext_resource type="PackedScene" path="res://art/enemies/named-leaders-v1/{id}-details.glb" id="4"]\n\n[node name=',1)
        scene=re.sub(r'palette_material\s*=\s*ExtResource\("2"\)',
                     'palette_material = ExtResource("2")\ndetails = ExtResource("4")',scene)
        scene=re.sub(r'metadata/visual_height\s*=\s*[\d.]+',f'metadata/visual_height = {height}',scene)
        (OUT/(id+'.tscn')).write_text(scene,newline='\n')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--workspace',type=Path,required=True)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    masters=args.workspace/'build/local-puzzles-elites-v1/masters/leaders'
    masters.mkdir(parents=True,exist_ok=True);prepare()
    assets=[export(id,masters) for id in MODELS]
    (OUT/'catalog.json').write_text(json.dumps({'issue':282,'front':'+Z','units':'metres',
        'animation_policy':'unchanged original GLBs; rigid details bind to the source idle pose',
        'assets':assets},indent=2)+'\n',newline='\n')
