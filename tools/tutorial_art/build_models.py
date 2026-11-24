"""#285: original static fallen travellers and a floor-registered dying fire.

Blender --background --factory-startup --disable-autoexec --python-exit-code 1
--python tools/tutorial_art/build_models.py -- --workspace E:/GitHub/Depths
Public project geometry only; no private body or Mixamo files are read.
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
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT/'tools/combat_roster'))
sys.path.insert(0, str(ROOT/'tools/tutorial_art'))
from mesh_parts import EXTRA
from fallen import build as fallen

spec = importlib.util.spec_from_file_location('tutorial_worked_geometry', ROOT/'tools/mine_polish/build_models.py')
P = importlib.util.module_from_spec(spec)
spec.loader.exec_module(P)
G = P.G
PALETTE = json.loads((ROOT/'art/enemies/field-creatures-3d-v1/catalog.json').read_text())['palette'] | EXTRA
BODIES = ROOT/'art/props/opening-bodies-3d-v1'
FIRE = ROOT/'art/features/campfire-3d-v1'
COLOURS = {
    'body_cloth': '514c43', 'body_cloth_light': '6c6455', 'body_leather': '544032',
    'body_leather_light': '725440', 'body_boot': '302b25', 'body_linen': '8d8067',
    'body_skin': 'a77e65', 'body_skin_light': 'b99277', 'body_skin_dark': '745749',
    'body_hair': '46362d', 'body_hair_light': '655040', 'body_buckle': '8c7753',
    'body_hood': '3c4548', 'body_hood_light': '566066', 'body_seam': '9b8668',
    'ember': 'be4d20', 'ember_dark': '79331d', 'flame': 'd87928', 'flame_core': 'e9b054',
}
for key, value in COLOURS.items():
    G.COLOURS[key] = value
    material = bpy.data.materials.new(key)
    material.diffuse_color = (*(int(value[i:i+2],16)/255 for i in (0,2,4)),1)
    G.MATERIALS[key] = material
G.COLOURS['ash']='423e35'
G.MATERIALS['ash'].diffuse_color=(.26,.24,.21,1)
original_group = P.group_for
P.group_for = lambda key: ('Flame' if key.startswith('flame') else 'Ember' if key.startswith('ember')
                          else 'Skin' if key.startswith('body_skin') else 'Cloth' if key.startswith('body_')
                          else original_group(key))


def hearth():
    rng=random.Random(285)
    P.lump('Fine charcoal and ash',(0,0,.022),(.37,.32,.025),'ash',8)
    for i in range(11):
        angle=i*math.tau/11+rng.uniform(-.06,.06)
        r=rng.uniform(.38,.42)
        P.lump('Uneven heat cracked stone', (math.cos(angle)*r,math.sin(angle)*r,.073),
               (rng.uniform(.10,.13),rng.uniform(.08,.11),rng.uniform(.06,.085)),
               'stone_dark' if i%3 else 'stone',seed=i+17)
    for i,(a,b) in enumerate([((-.29,-.13,.075),(.28,.10,.093)),
                             ((-.24,.16,.115),(.25,-.14,.131)),
                             ((-.21,-.07,.175),(.23,.13,.19))]):
        P.beam('Charred split log',a,b,.095,.082,'soot',i+8)
        # Narrow surviving strips of grain and split end caps, not perfect cylinders.
        P.beam('Burnt bark edge',Vector(a)+Vector((0,.043,.01)),Vector(b)+Vector((0,.043,.01)),.018,.013,'wood_dark',i+22)
        for end in [a,b]:P.lump('Split charred end',end,(.048,.039,.041),'wood_dark',i+5)
    for i in range(13):
        angle=rng.uniform(0,math.tau);r=rng.uniform(.03,.23)
        P.lump('Coal', (math.cos(angle)*r,math.sin(angle)*r,.055),(.025,.023,.018),
               'ember_dark' if i%3 else 'ember',i+4)


def flames():
    # Solid low-poly tapered tongues, visible from every angle; no billboards.
    for i,(x,y,h) in enumerate([(-.13,.045,.21),(.035,-.065,.32),(.12,.04,.24),(-.03,.10,.19)]):
        vertices=[]
        for row,(z,r,offset) in enumerate([(0,.058,0),(.32,.046,-.015),(.67,.026,.013),(1,.001,-.018)]):
            for j in range(6):
                a=j*math.tau/6+i*.55
                vertices.append((x+math.cos(a)*r+offset,y+math.sin(a)*r,.15+z*h))
        faces=[tuple(reversed(range(6)))]
        for row in range(3):
            for j in range(6):faces.append((row*6+j,row*6+(j+1)%6,(row+1)*6+(j+1)%6,(row+1)*6+j))
        faces.append(tuple(range(18,24)))
        obj=G.mesh_object('Low flame tongue',vertices,faces,'flame_core' if i%2 else 'flame')


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    P.MASTERS=args.workspace/'build/local-tutorial-3d-v1/masters'
    for folder in [BODIES,FIRE,P.MASTERS]:folder.mkdir(parents=True,exist_ok=True)
    (P.MASTERS/'.gdignore').write_text('')
    assets=[]
    for name,build,folder in [('fallen-a',lambda:fallen(False, PALETTE, G, P),BODIES),('fallen-b',lambda:fallen(True, PALETTE, G, P),BODIES),
                              ('hearth',hearth,FIRE),('flames',flames,FIRE)]:
        assets.append(P.export(name,build,folder))
    record={'issue':285,'units':'metres','floor_origin':'cell centre, sole/contact floor y=0',
            'source':'Original public Depths recruit mesh factory and mine geometry helpers; no external downloads or private models.',
            'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'dependencies':{name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in
                            ['tools/tutorial_art/fallen.py','tools/combat_roster/party.py',
                             'tools/combat_roster/mesh_parts.py','tools/mine_polish/build_models.py',
                             'tools/mine_props/build_models.py']},'assets':assets}
    for folder in [BODIES,FIRE]:
        (folder/'catalog.json').write_text(json.dumps(record,indent=2)+'\n')
    print('TUTORIAL_3D',[(a['id'],a['triangles'],a['min'],a['max']) for a in assets])

if __name__=='__main__':main()
