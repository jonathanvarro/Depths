"""Build the Floor 1–2 event props from the existing mine geometry and palette."""
import argparse
import json
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0,str(ROOT/"tools/mine_props"))
import build_models as geo

ART = ROOT/"art/props/mining-finds-3d-v1"
beam, box, lump, mesh = geo.beam, geo.box, geo.lump, geo.mesh_object


def rack_base():
    for sign in (-1,1):
        x=sign*.55
        beam("Upright",(x,-.15,0),(x+sign*.012,-.12,1.61),.12,.12,"wood",sign+9)
        beam("Foot",(x,-.04,.058),(x,-.44,.058),.18,.12,"wood_dark",sign+21)
        beam("Brace",(x,-.398,.07),(x,-.155,.46),.058,.062,"wood",sign+54)
    for i,z in enumerate((.50,.81,1.035,1.294)):
        beam("Rough backboard",(-.593,-.105,z),(.592,-.104,z+.014*(i%2)),
             .145,.045,"wood_dark" if i==1 else "wood",19+i)
    for i,x in enumerate((-.39,-.07,.19,.41)):
        beam("Tool peg",(x,-.13,1.157+.028*(i%2)),(x,-.302,1.186+.015*(i%2)),.036,.032,
             "wood_light",i+12)
        box("Peg ring",(x,-.165,1.17),(.055,.026,.055),"iron")
    for i,y in enumerate((-.166,-.265,-.368)):
        beam("Shelf plank",(-.64,y,1.425),(.619,y+.008,1.43),.103,.060,
             "wood_light" if i==2 else "wood",66+i)
    for x in (-.48,.48):
        box("Shelf pin",(x,-.404,1.433),(.044,.015,.036),"iron_edge")


def head(label, outline, front, width, metal):
    vertices=[(x,front+layer*width,z) for layer in (0,1) for x,z in outline]
    n=len(outline)
    faces=[tuple(range(n)),tuple(reversed(range(n,2*n)))]
    faces.extend((i,i+n,(i+1)%n+n,(i+1)%n) for i in range(n))
    return mesh(label,vertices,faces,metal)


def rack_fresh():
    beam("Mattock haft",(-.379,-.245,.49),(-.403,-.255,1.155),.052,.047,"wood_light",3)
    head("Mattock pick and adze",[(-.581,1.093),(-.537,1.194),(-.434,1.226),
         (-.361,1.218),(-.278,1.164),(-.237,1.173),(-.239,1.095),(-.314,1.098),
         (-.367,1.148),(-.453,1.158),(-.52,1.145)],-.31,.096,"iron_edge")
    beam("Sledge haft",(-.040,-.242,.66),(-.076,-.266,1.165),.053,.051,"wood",6)
    box("Sledge head",(-.075,-.282,1.155),(.225,.133,.102),"iron",(0,-.06,0))
    box("Sledge strike face",(.041,-.283,1.159),(.028,.128,.094),"iron_edge")
    beam("Short pick haft",(.271,-.248,.63),(.192,-.26,1.16),.041,.042,"wood_light",8)
    head("Short pick",[(-.002,1.09),(.048,1.193),(.155,1.222),(.235,1.213),
         (.335,1.151),(.367,1.089),(.299,1.14),(.221,1.167),(.15,1.169),(.07,1.143)],
         -.308,.065,"iron")
    for i,(x,y,z) in enumerate(((-.24,-.26,1.49),(-.11,-.31,1.495),(.03,-.246,1.49),(.153,-.31,1.482))):
        lump("Coal on shelf",(x,y,z),(.078,.057,.057),"split" if i!=1 else "iron",i+23)


def rack_spent():
    beam("Rotten haft remnant",(.411,-.249,.987),(.423,-.243,1.15),.034,.041,"wood_dark",41)
    head("Rusted head remnant",[(.33,1.159),(.396,1.208),(.462,1.214),
         (.487,1.18),(.431,1.161),(.364,1.146)],-.289,.042,"rust")


def rock_layer(columns, upper):
    vertices=[]
    for x,low,high,y in columns:
        vertices.extend(((x,y+.04,low),(x+.025,y,(low+high)/2),(x,y+.07,high)))
    count=len(vertices)
    vertices.extend((x,-.035,z) for x,_,z in vertices.copy())
    faces=[]
    for i in range(len(columns)-1):
        for j in range(2):
            a=i*3+j
            if (i+j)%2:
                faces.extend(((a,a+3,a+4),(a,a+4,a+1)))
            else:
                faces.extend(((a,a+3,a+1),(a+1,a+3,a+4)))
        for j in (0,2):
            a=i*3+j
            faces.append((a,a+count,a+3+count,a+3))
    for k in (0,count-3):
        for j in range(2):
            a=k+j
            faces.append((a,a+1,a+1+count,a+count))
    obj=mesh("Upper host rock" if upper else "Lower host rock",vertices,faces,"stone")
    obj.data.materials.append(geo.MATERIALS["stone_dark"])
    obj.data.materials.append(geo.MATERIALS["stone_light"])
    for face in obj.data.polygons:
        face.material_index=2 if upper and face.index%7==1 else 1 if face.index%5==0 else 0


def seam_base():
    # Continuous fractured rock above and below the exposed coal stratum.
    rock_layer([(-.78,.02,.61,-.28),(-.61,0,.68,-.41),(-.38,.006,.65,-.46),
                (-.14,0,.62,-.39),(.10,0,.69,-.43),(.38,.003,.72,-.45),
                (.64,.012,.70,-.39),(.79,.05,.61,-.26)],False)
    rock_layer([(-.78,.56,.99,-.25),(-.60,.74,1.30,-.40),(-.38,.78,1.45,-.43),
                (-.14,.81,1.32,-.37),(.10,.82,1.49,-.45),(.38,.83,1.36,-.42),
                (.65,.80,1.26,-.38),(.79,.62,.99,-.26)],True)
    strips=[
        ((-.68,.59),(-.48,.64),(-.26,.635),(-.22,.75),(-.45,.81),(-.64,.75)),
        ((-.28,.625),(-.11,.62),(.08,.69),(.12,.81),(-.075,.855),(-.24,.75)),
        ((.06,.69),(.25,.711),(.48,.682),(.66,.75),(.54,.86),(.31,.862),(.127,.809)),
    ]
    for i, outline in enumerate(strips):
        head("Coal band",outline,-.458-.012*(i%2),.23,"split")
    for i,(x,y,z) in enumerate(((-.49,-.54,.073),(.46,-.44,.08),(.23,-.63,.049))):
        lump("Loose stone",(x,y,z),(.11,.10,z),"stone_dark",103+i)


def seam_fresh():
    for i,(x,z,sx,sz) in enumerate(((-.46,.735,.17,.087),(-.23,.715,.13,.08),
                       (-.031,.751,.18,.11),(.192,.778,.17,.093),(.393,.794,.16,.09))):
        lump("Proud coal plate",(x,-.487,z),(sx,.088,sz),"iron" if i%3==1 else "split",115+i)
    for i,(x,y,z) in enumerate(((-.28,-.61,.05),(-.10,-.69,.062),(.065,-.57,.048),(.26,-.69,.046))):
        lump("Loose coal",(x,y,z),(.074,.063,z),"split",127+i)


def seam_spent():
    rng=random.Random(139)
    for i in range(14):
        x,y,z=rng.uniform(-.4,.42),rng.uniform(-.64,-.49),rng.uniform(.01,.021)
        lump("Pick dust and chips",(x,y,z),(rng.uniform(.019,.045),.031,z),"split",146+i)
    for i,(x,z) in enumerate(((-.44,.74),(-.13,.78),(.13,.795),(.31,.80))):
        head("Pale pick scar",[(x-.05,z+.012),(x+.06,z-.03),(x+.064,z-.047),
             (x-.032,z-.018)],-.478,.014,"ash")


def scene(identifier):
    script='res://art/props/expedition-3d-v1/prop.gd'
    palette='res://art/dressing/mine-3d-v1/palette.tres'
    path="res://art/props/mining-finds-3d-v1/"
    lines=['[gd_scene load_steps=6 format=3]',
           f'[ext_resource type="Script" path="{script}" id="1"]',
           f'[ext_resource type="Material" path="{palette}" id="2"]']
    for index,state in enumerate(("base","fresh","spent"),3):
        lines.append(f'[ext_resource type="PackedScene" path="{path}{identifier}-{state}.glb" id="{index}"]')
    lines.extend(['','[node name="MiningFind" type="Node3D"]','script=ExtResource("1")',
                  'palette_material=ExtResource("2")'])
    for index,name in enumerate(("Frame","Fresh","Spent"),3):
        lines.extend(['',f'[node name="{name}" parent="." instance=ExtResource("{index}")]'])
    lines.append('visible=false')
    (ART/(identifier+".tscn")).write_text("\n".join(lines)+"\n",encoding="utf-8")


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--workspace",type=Path,required=True)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    geo.ART=ART
    geo.MASTERS=args.workspace/"build/local-mining-finds-v1/masters"
    geo.MASTERS.mkdir(parents=True,exist_ok=True)
    specs=(("tool-rack",(rack_base,rack_fresh,rack_spent)),
           ("coal-seam",(seam_base,seam_fresh,seam_spent)))
    assets=[]
    for identifier,parts in specs:
        for state,part in zip(("base","fresh","spent"),parts,strict=True):
            assets.append(geo.export(identifier+"-"+state,part,{}))
        scene(identifier)
    (ART/"catalog.json").write_text(json.dumps({"assets":assets,"floor_origin":True,
        "front":"+Z","units":"metres"},indent=2)+"\n",encoding="utf-8")
    print("MINING PROPS",[(a["id"],a["triangles"]) for a in assets])


if __name__=="__main__":
    main()
