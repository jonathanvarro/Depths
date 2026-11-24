"""#287: original worn iron sconce and charred wall torch, Blender 5.2.3."""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import sys
import bpy

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('torch_worked_geometry',ROOT/'tools/mine_polish/build_models.py')
P=importlib.util.module_from_spec(spec);spec.loader.exec_module(P)
G=P.G
ART=ROOT/'art/dressing/wall-torch-3d-v1'

def build():
    P.box('Hammered wall plate',(0,-.019,-.02),(.15,.027,.22),'iron',(0,-.025,.018))
    for x,z in [(-.055,.054),(.053,.054),(-.052,-.10),(.055,-.102)]:
        P.nail((x,-.041,z),'iron_edge',.012)
    # Bent cradle really connects to the mounting plate; local +Z faces the room.
    P.rod('Bent cradle',[(0,-.041,-.10),(0,-.08,-.14),(0,-.145,-.086),(0,-.143,.01)],.009,'iron',6)
    P.ring('Socket ring',(0,-.126,.018),.036,'iron',(0,0,0),.008)
    P.beam('Split wooden haft',(0,-.111,-.279),(.008,-.145,.227),.042,.04,'wood_dark',287)
    P.beam('Exposed wood edge',(-.015,-.137,-.257),(-.007,-.168,.171),.009,.011,'wood',288)
    P.lump('Charred rag head',(.008,-.144,.211),(.042,.038,.078),'soot',289)
    for i in range(5):
        angle=i*math.tau/5+.18
        x=math.cos(angle)*.04;y=-.144+math.sin(angle)*.033
        P.beam('Uneven burned wrapping',(x,y,.155+i*.003),(x*.8,y,.26-(i%2)*.018),.015,.012,'wood_dark',i+31)
    for z,r in [(-.178,.024),(.154,.043),(.188,.042)]:
        P.ring('Iron binding',(0,-.119-(z+.279)*.067,z),r,'iron',(0,0,0),.004)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    P.MASTERS=args.workspace/'build/local-tutorial-3d-v1/masters'
    ART.mkdir(parents=True,exist_ok=True);P.MASTERS.mkdir(parents=True,exist_ok=True)
    item=P.export('torch',build,ART)
    (ART/'catalog.json').write_text(json.dumps({'issue':287,'asset':item,'units':'metres',
      'mount':'root at wall face and existing mounting height; +Z into room',
      'source':'Original Depths mine geometry helpers, no download or private assets',
      'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
    print('WALL_TORCH',item)

if __name__=='__main__':main()
