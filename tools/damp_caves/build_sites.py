"""#302 E/F: shared landmark terrain and event geometry, using the C/D tools.

Blender background; original pieces and one explicitly retained CC0 minecart.
No game placement, collision, water or quest authority.
"""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import random
import sys
import bpy
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('damp_site_geometry',ROOT/'tools/damp_caves/build_dressing.py')
D=importlib.util.module_from_spec(spec);spec.loader.exec_module(D)
G=D.G;P=D.P
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
D.ART=ROOT/'art/props/damp-sites-v1';D.MASTERS=args.workspace/'build/local-damp-sites-v1/masters'
D.ART.mkdir(parents=True,exist_ok=True);D.MASTERS.mkdir(parents=True,exist_ok=True)
(D.MASTERS/'.gdignore').write_text('')


def ring_pool(rx=.57,ry=.39,water=True):
    # Low bank and shallow opaque water remain on top of the caller's floor.
    for i in range(14):
        a=i*math.tau/14
        D.rock('Scalloped calcite pool bank',(math.cos(a)*rx,math.sin(a)*ry,.045),(.12,.09,.045),i,'calcite')
    if water:D.patch('Shallow still water',rx*.89,ry*.87,'water',.032,seed=41)


def pearl_pool(gathered=False):
    ring_pool()
    positions=[(-.25,-.11,.046),(-.10,.04,.055),(.10,-.14,.042),(.25,.06,.058),(.0,.20,.035),(.29,-.15,.031)]
    for i,(x,y,r) in enumerate(positions):
        if gathered:
            D.patch('Empty pearl depression',r*1.3,r,'wet_dark',.035,(x,y),i)
        else:D.rock('Loose cave pearl',(x,y,.034+r*.55),(r,r,r*.8),i,'pearl')


def seep(used=False):
    # Back face at local Godot Z=0, basin extending +Z into room.
    D.wall_sheet('Seep calcite face',.91,1.22,'wet_rock',.10).location=Vector((0,.0,.75))
    for i in range(4):
        x=-.15+i*.10
        D.tube('Seep mineral channel',[(x,-.035,1.20),(x+.02,-.08,.82),(x-.01,-.05,.36)],[.014,.011,.003],'flowstone',6)
    before=set(bpy.context.scene.objects);ring_pool(.42,.30)
    for obj in set(bpy.context.scene.objects)-before:obj.location.y-=.36
    # A handled cup rests on the lip; used is a moved cup and wet footprint,
    # not a claim that an inexhaustible natural spring has dried up.
    before=set(bpy.context.scene.objects);D.bucket()
    for obj in set(bpy.context.scene.objects)-before:
        obj.scale*=.25;obj.location*=.25;obj.location+=Vector((.34 if not used else -.32,-.41,.055))
    if used:
        D.patch('Damp kneeling mark',.11,.085,'mud',.006,(.18,-.74),7)
        D.patch('Wet cup print',.06,.05,'water',.007,(.34,-.41),8)


def ledge(state):
    # A real recessed cut at the right; this scene needs the caller floor omitted.
    vertices=[(-1,-1,0),(.25,-1,.035),(.25,1,.015),(-1,1,0),
              (.25,-1,.035),(1,-1,0),(1,-.72,0),(.25,-.72,.025),
              (.25,.72,.02),(1,.72,0),(1,1,0),(.25,1,.015)]
    G.mesh_object('Dry left ledge and end landings',vertices,[(0,1,2,3),(4,5,6,7),(8,9,10,11)],'wet_rock')
    # Basin lining and dark bottom do not cap the actual gap at floor height.
    pts=[(.25,-.72,.025),(1,-.72,0),(1,.72,0),(.25,.72,.02)]
    lower=[(x,y,-.55) for x,y,z in pts]
    G.mesh_object('Dark ledge drop',pts+lower,[(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0),(4,7,6,5)],'wet_dark')
    D.tube('Slick calcite lip',[(.23,-.72,.027),(.27,-.2,.052),(.23,.38,.038),(.25,.72,.02)],
           [.017,.027,.021,.014],'flowstone',7)
    for i in range(6):D.rock('Worn ledge edge',(.20+.025*(i%2),-.61+i*.24,.02),(.07,.10,.027),i)
    if state=='slipped':
        for i in range(3):
            D.tube('Fresh sliding scrape',[(-.12+i*.05,-.3,.028),(.06+i*.04,-.08,.040),(.23,.13+i*.04,.045)],[.004,.007,.002],'calcite',4)
        for i in range(4):D.rock('Fallen slip gravel',(.46+i*.11,-.12+i*.09,-.48),(.05,.04,.03),i)
    if state=='passed':
        for y in [-.40,.09,.52]:
            D.patch('Dry safe-path boot scuff',.065,.13,'silt',.012,(-.61,y),int(y*100))


def fish():
    D.rock('Eyeless pale fish body',(0,0,0),(.047,.19,.044),72,'pearl')
    D.rock('Blunt blind fish head',(0,-.15,.0),(.041,.065,.036),73,'calcite')
    G.mesh_object('Forked fish tail',[(0,.16,0),(-.065,.27,.015),(0,.24,.005),(.065,.27,.015)],
                  [(0,1,2),(0,2,3),(2,1,0),(3,2,0)],'cloth')
    for side in [-1,1]:
        G.mesh_object('Pale side fin',[(side*.03,-.04,0),(side*.105,.04,-.01),(side*.04,.065,0)],[(0,1,2),(2,1,0)],'calcite')
    G.mesh_object('Low dorsal fin',[(-.003,-.07,.03),(0,.08,.045),(.004,.14,.027)],[(0,1,2),(2,1,0)],'calcite')


def fish_pool():
    ring_pool(.67,.48,False)
    D.patch('Dark silt pool bottom',.59,.40,'mud',.009,seed=13)
    for i in range(4):D.rock('Smooth submerged pebble',(-.38+i*.21,.23,.025),(.07,.055,.021),i)


def sump():
    # Central water field is surface art, never a new map.water rule.
    D.patch('Sump black standing water',2.12,1.95,'water',.018,seed=61)
    # Low raised banks visually describe the dry ledge around the pool.
    for i in range(27):
        a=i*math.tau/27
        D.rock('Eroded sump perimeter',(math.cos(a)*2.23,math.sin(a)*2.05,.025),(.22,.18,.045),i,'silt')


def weeping_curtain():
    D.wall_sheet('Continuous weeping calcite wall',5.48,1.90,'flowstone',.17).location.z=1.12
    for i in range(23):
        x=-2.51+i*.227;bottom=.24+.20*(.5+.5*math.sin(i*1.7))
        D.tube('Long mineral weep',[(x,-.045,2.13),(x+.025,-.10,1.72),(x-.02,-.15,1.18),
               (x+.017,-.10,.68),(x+.03,-.025,bottom)],
               [.027,.044,.037,.025,.003],'flowstone',7)


def rimstone_stair():
    for row in range(4):
        z=.025+row*.10;ry=.72-row*.09;rx=1.74-row*.14;cy=.68-row*.47
        pts=[(math.cos(a)*rx,cy+math.sin(a)*ry,z) for a in [i*math.pi/24 for i in range(25)]]
        D.tube('Broad rimstone step',pts,[.045]*len(pts),'calcite',8)
        D.patch('Terrace pool',rx*.92,ry*.47,'water',z-.012,(0,cy+.25),row)
    for i in range(6):D.rock('Rimstone bank stub',(-1.5+i*.6,1.22,.10),(.22,.21,.14),i)


def silt_bank():
    D.patch('Washed silt bank',1.36,.69,'silt',.015,seed=66,bulge=.15)
    for i in range(5):
        D.tube('Silt deposition layer',[(-1.14+j*.27,-.42+i*.18+.04*math.sin(j),.04+.08*math.sin(j*math.pi/8)) for j in range(9)],
               [.006]+[.012]*7+[.003],'mud',5)
    for i in range(9):D.rock('Water-rounded bank gravel',(-1.1+i*.25,.38,.05),(.10,.07,.045),i)


def cart():
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'art/third-party/kiokurashi-minecart-v1/Minecart.glb'))
    objects=[o for o in bpy.context.selected_objects if o.type=='MESH'];assert objects
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    low=Vector([min(p[i] for p in points) for i in range(3)]);high=Vector([max(p[i] for p in points) for i in range(3)])
    origin=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
    for obj in objects:
        transform=Matrix.Rotation(math.pi/2,4,'Z')@Matrix.Scale(.76,4)@Matrix.Translation(-origin)@obj.matrix_world
        for v in obj.data.vertices:v.co=transform@v.co
        obj.matrix_world=Matrix.Identity(4);obj.name='CC0 drowned ore cart'
        materials=[]
        for material in obj.data.materials:
            materials.append(G.MATERIALS['wood_grey' if material.name=='Wood' else ('rust' if material.name=='Metal' else 'iron_worn')])
        for i,material in enumerate(materials):obj.data.materials[i]=material
        bpy.context.view_layer.objects.active=obj
        mod=obj.modifiers.new('Mobile fitted drowned cart','DECIMATE');mod.ratio=.34
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # Deposits sit in the open body; no reward contents are implied.
    for i in range(5):D.rock('Cart silt deposit',(-.14+i*.07,.04,.24),(.09,.13,.035),i,'silt')


recipes=[('sump-water',sump,'floor'),('weeping-curtain',weeping_curtain,'wall-floor'),('rimstone-terraces',rimstone_stair,'floor'),('bone-silt-bank',silt_bank,'floor'),
 ('drowned-cart',cart,'floor'),('cave-pearls-fresh',pearl_pool,'floor'),('cave-pearls-gathered',lambda:pearl_pool(True),'floor'),
 ('seep-fresh',seep,'wall-floor'),('seep-used',lambda:seep(True),'wall-floor'),
 ('slick-ledge-ready',lambda:ledge('ready'),'floor-cut'),('slick-ledge-slipped',lambda:ledge('slipped'),'floor-cut'),
 ('slick-ledge-passed',lambda:ledge('passed'),'floor-cut'),('blind-fish-body',fish,'pool-local'),('blind-fish-pool',fish_pool,'floor')]
assets=[D.export(ident,build,mount) for ident,build,mount in recipes]
for row in assets:assert row['triangles']<=6500,row
catalog={'issue':302,'brief':'E six landmark compositions / F five interactive appearance sets','assets':assets,
 'units':'metres; bounds in Godot space','sources':[
 {'type':'Original project geometry','builder':'tools/damp_caves/build_sites.py','helpers':['tools/damp_caves/build_dressing.py','tools/mine_polish/build_models.py','tools/mine_props/build_models.py']},
 {'type':'CC0 1.0','author':'Kio Kurashi','source':'https://kiokurashi.itch.io/3d-static-minecart','record':'art/third-party/kiokurashi-minecart-v1/provenance.json','use':'drowned-cart only; original GLB retained, fitted/decimated/recoloured derivative'},
 {'type':'Retained CC0 library','author':'Kay Lousberg','record':'art/third-party/kaykit-bones-v1/provenance.json','use':'existing bone recipes in bone-silt composition'}],
 'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
 'hookup':'Art appearance only; no event definitions, rewards, map.water, route, collision or saves.'}
(D.ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('DAMP_SITES',[(row['id'],row['triangles']) for row in assets])
