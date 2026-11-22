"""#281: production puzzle fittings, using the refined mine mesh/material helpers."""
import argparse
import importlib.util
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('worked_props',ROOT/'tools/mine_polish/build_models.py')
P=importlib.util.module_from_spec(spec);spec.loader.exec_module(P)
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ART=ROOT/'art/props/puzzle-fittings-v1';ART.mkdir(parents=True,exist_ok=True)
P.MASTERS=args.workspace/'build/local-puzzles-elites-v1/masters/puzzles';P.MASTERS.mkdir(parents=True,exist_ok=True)
(P.MASTERS/'.gdignore').write_text('')
G=P.G
beam=P.beam;box=P.box;rod=P.rod;nail=P.nail;ring=P.ring

def frame():
    for side in [-1,1]:
        x=side*.93
        beam('Hewn door jamb',(x,0,0),(x+.006*side,0,2.39),.14,.24,'wood_dark',42+side)
        box('Hinge bearing',(x,-.015,.44),(.19,.29,.12),'iron')
        box('Upper hinge bearing',(x,-.015,1.79),(.18,.29,.12),'iron')
        for z in [.42,1.78]:nail((x,-.165,z),'rust',.020)
    beam('Notched lintel',(-1.0,0,2.15),(1.0,.008,2.16),.16,.25,'wood_grey',50)
    for side in [-1,1]:
        for i in range(2):
            x=side*.96
            P.lump('Mortared jamb foot',(x,.03,.07+i*.11),(.105,.17,.065),'stone_dark',i+8)

def leaf():
    for i in range(7):
        x=(i+.5)*1.72/7
        beam('Checked oak plank',(x,0,.025),(x+.004*math.sin(i),0,2.054-.005*(i%3)),1.72/7-.007,.083,'wood' if i%3 else 'wood_grey',i+15)
        if i in [1,3,6]:P.timber_split(x+.025,-.044,.25+i*.14,.66,.006)
    for side in [-1,1]:
        for z in [.31,1.05,1.78]:
            beam('Forged iron cross strap',(.035,side*.052,z),(1.685,side*.052,z+.006),.065,.017,'iron',int(z*35)+int(side))
            for x in [.15,.79,1.56]:nail((x,side*.064,z),'iron_edge',.016)
        ring('Wrought pull ring',(1.43,side*.076,.88),.067,'iron',wire=.008)
        box('Pull escutcheon',(1.43,side*.059,.94),(.095,.022,.13),'iron')
    for z in [.32,1.78]:
        rod('Hinge knuckle',[(.012,0,z-.06),(.012,0,z+.06)],.027,'iron_edge',8)

def bolt():
    beam('Uneven locking bar',(.22,-.102,1.07),(1.66,-.102,1.075),.092,.095,'wood_dark',42)
    for x in [.37,1.53]:
        # Open-sided keepers allow the bar to retract along the leaf.
        box('Bar keeper foot',(x,-.077,1.005),(.10,.082,.018),'iron')
        box('Bar keeper crown',(x,-.077,1.145),(.10,.082,.020),'iron')
        box('Bar keeper face',(x,-.13,1.075),(.1,.018,.16),'iron')
        for z in [1.008,1.142]:nail((x,-.142,z),'iron_edge',.014)
    ring('Bar release loop',(.72,-.162,1.09),.037,'iron_edge',wire=.006)

def locks():
    for side in [-1,1]:
        P.escutcheon('Forged lock case',(1.51,side*.063,1.02),.16,.23,'iron_edge')
        # A real keyhole profile rather than a painted rectangular notch.
        P.lump('Keyhole bowl',(1.51,side*.078,1.04),(.016,.004,.016),'soot',4)
        G.mesh_object('Keyhole stem',[(1.503,side*.081,1.035),(1.517,side*.081,1.035),
          (1.526,side*.081,.993),(1.494,side*.081,.993)],[(0,1,2,3)] if side<0 else [(3,2,1,0)],'soot')
        for x in [1.46,1.56]:nail((x,side*.079,1.095),'rust',.013)

def lever_base():
    G.stone((0,0,.24),(.59,.44,.48),'stone',27)
    box('Repaired mounting plate',(0,.205,.94),(.49,.068,.70),'iron')
    for x in [-.19,.19]:
        for z in [.66,1.22]:nail((x,.163,z),'iron_edge',.025)
    for side in [-1,1]:
        box('Pivot bearing',(side*.13,0,.55),(.075,.17,.14),'iron')
        ring('Bearing collar',(side*.17,0,.55),.048,'iron_edge',(0,math.pi/2,0),.009)
    # Links are actual rings, kept within the old mounting envelope.
    for i in range(11):ring('Interlocked chain link',(.18,.18,1.23+i*.061),.037,'iron',(0,math.pi/2,0) if i%2 else (math.pi/2,0,0),.008)
    box('Chain anchor',(.18,.21,1.91),(.11,.065,.12),'iron')
    nail((.18,.17,1.936),'iron_edge',.018)
    box('Travel scale',(0,.164,1.03),(.14,.015,.21),'silver_dark')
    for z in [.96,1.02,1.08]:box('Scale notch',(.012,.152,z),(.06,.008,.008),'soot')

def lever_handle():
    # Local origin is the old handle pivot; the scene supplies the -35° lean.
    rod('Crooked forged arm',[(0,0,.02),(.008,0,.31),(-.012,0,.59),(0,0,.85)],.030,'iron_edge',8)
    rod('Leather hand grip',[(0,0,.72),(0,0,.91)],.046,'leather',8)
    for z in [.73,.87]:ring('Grip binding',(0,0,z),.046,'iron',(0,0,0),.006)
    P.lump('Grip end',(0,0,.924),(.050,.045,.026),'wood_dark',4)

def key():
    # Broad open bow and uneven ward teeth remain readable in a skeletal hand.
    ring('Open key bow',(0,.005,.092),.055,'gold',(math.pi/2,0,0),.012)
    rod('Key shaft',[(0,0,.060),(.002,0,-.060),(0,0,-.185)],.012,'gold_dark',7)
    for z,length in [(-.131,.045),(-.167,.036)]:
        box('Worn ward tooth',(length*.45,0,z),(length,.024,.018),'gold')
    ring('Key collar',(0,0,-.03),.018,'gold_edge',(0,0,0),.004)

assets=[]
for name,build in [('door-frame',frame),('door-leaf',leaf),('bar',bolt),('lock-cases',locks),
                   ('lever-base',lever_base),('lever-handle',lever_handle),('key',key)]:
    assets.append(P.export(name,build,ART))
(ART/'catalog.json').write_text(json.dumps({'issue':281,'assets':assets,'cell_metres':2,'wall_metres':2.4,
 'front':'+Z','door_width':1.72,'door_height':2.064,'hinge_x':-.86,'lever_pivot':[0,.55,0],
 'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
 'helpers':'tools/mine_polish/build_models.py; tools/mine_props/build_models.py',
 'source_reuse':'Existing verified CC0 seated skeleton and chain gate retained by scenes; new fittings use authored mine helpers'},indent=2)+'\n')
print('PUZZLE_FITTINGS',[(entry['id'],entry['triangles']) for entry in assets])
