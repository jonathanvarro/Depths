"""Registered five event appearances and six reusable metric landmark layouts."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/props/damp-sites-v1';URI='res://art/props/damp-sites-v1/'
D='res://art/dressing/damp-dressing-v1/'
catalog=json.loads((ART/'catalog.json').read_text())
def raw(ident):return URI+ident+'.glb'


class Scene:
    def __init__(self,ident,states=['static'],mode='floor'):
        self.id=ident;self.states=states;self.mode=mode
        self.resources=[f'[ext_resource type="Script" path="{URI}site.gd" id="script"]'];self.ids={};self.nodes=[]
        self.nodes=['[node name="DampSite" type="Node3D"]','script=ExtResource("script")',
          'states=PackedStringArray('+','.join('"'+s+'"' for s in states)+')',f'state="{states[0]}"',f'mount_mode="{mode}"',
          f'metadata/asset_id="{ident}"',f'metadata/requires_floor_cut={str(mode=="floor-cut").lower()}',
          '\n[node name="Mount" type="Node3D" parent="."]']
        self.state_nodes={}
        for state in states:
            if state=='static':continue
            node=state.capitalize();self.state_nodes[state]='Mount/'+node
            self.nodes += [f'\n[node name="{node}" type="Node3D" parent="Mount"]',f'metadata/appearance_state="{state}"']
            if state!=states[0]:self.nodes+=['visible=false']
    def resource(self,path,kind='PackedScene'):
        if path not in self.ids:
            ident='r'+str(len(self.ids));self.ids[path]=ident
            self.resources.append(f'[ext_resource type="{kind}" path="{path}" id="{ident}"]')
        return self.ids[path]
    def item(self,name,path,at=(0,0,0),scale=(1,1,1),yaw=0,state=None,extra=(),parent=None):
        resource=self.resource(path);parent=parent or self.state_nodes.get(state,'Mount')
        self.nodes += [f'\n[node name="{name}" parent="{parent}" instance=ExtResource("{resource}")]',
          f'position=Vector3{tuple(at)}',f'scale=Vector3{tuple(scale)}',f'rotation_degrees=Vector3(0,{yaw},0)']+list(extra)
        if path.startswith(URI) and path.endswith('.glb'):self.nodes+=['metadata/physical_surface=true']
    def marker(self,name,at):
        self.nodes += [f'\n[node name="{name}" type="Marker3D" parent="Mount"]',f'position=Vector3{tuple(at)}']
    def water(self,name,at,size,clear=False):
        # The only alpha surface is this small fish viewing pool; bodies stay opaque.
        tag='water'+str(len(self.resources));mesh=tag+'mesh';mat=tag+'mat'
        ellipse=clear or max(size)<2
        if ellipse:
            self.resources += [f'[sub_resource type="CylinderMesh" id="{mesh}"]',f'top_radius={size[0]/2}',f'bottom_radius={size[0]/2}','height=0.002','radial_segments=32']
        else:
            self.resources += [f'[sub_resource type="PlaneMesh" id="{mesh}"]',f'size=Vector2{tuple(size)}']
        self.resources += [f'[sub_resource type="StandardMaterial3D" id="{mat}"]']
        self.resources += ['transparency=1','albedo_color=Color(0.13,0.23,0.21,0.42)','roughness=0.32','metallic_specular=0.27'] if clear else ['albedo_color=Color(0.12,0.19,0.19,1)','roughness=0.28','metallic_specular=0.32']
        self.nodes += [f'\n[node name="{name}" type="MeshInstance3D" parent="Mount"]',f'position=Vector3{tuple(at)}',
          f'mesh=SubResource("{mesh}")',f'material_override=SubResource("{mat}")','cast_shadow=0']
        if ellipse:self.nodes += [f'scale=Vector3(1,1,{size[1]/size[0]})']
        if clear:self.nodes+=['metadata/clear_water_surface=true']
    def save(self):
        # Ext_resources precede sub_resources even when builders appended later imports.
        ext=[];sub=[];destination=ext
        for line in self.resources:
            if line.startswith('[ext_resource'):destination=ext
            elif line.startswith('[sub_resource'):destination=sub
            destination.append(line)
        text=f'[gd_scene load_steps={sum(x.startswith("[") for x in self.resources)+1} format=3]\n'+'\n'.join(ext+sub)+'\n\n'+'\n'.join(self.nodes)+'\n'
        (ART/(self.id+'.tscn')).write_text(text,encoding='utf-8')
        return {'id':self.id,'scene':URI+self.id+'.tscn','states':self.states,'mount':self.mode}


events=[]
s=Scene('sunken-satchel',['fresh','emptied']);s.item('Pool',raw('blind-fish-pool'))
s.water('OpaquePoolWater',(0,.065,0),(1.12,.75))
for state in s.states:
    s.item('Pack', 'res://art/props/expedition-3d-v1/abandoned-pack.tscn',(0,-.18,0),(.80,.80,.80),-12,state,
      ['state="empty"' if state=='emptied' else 'state="closed"','animate_motion=false'])
s.marker('Interaction',(0,.30,.30));events.append(s.save())
for ident,states,mode in [('cave-pearls',['fresh','gathered'],'floor'),('seep',['fresh','used'],'wall-floor'),
                          ('slick-ledge',['ready','slipped','passed'],'floor-cut')]:
    s=Scene(ident,states,mode)
    for state in states:s.item('Model',raw(ident+'-'+state),state=state)
    s.marker('Interaction',(0,.35,.25 if ident!='seep' else .55));s.marker('SafeApproach',(-.62,0,.6) if ident=='slick-ledge' else (0,0,.80))
    if ident=='seep':s.item('Drip',D+'drip.tscn',(0,1.16,.07),extra=['fall_distance=1.098'])
    events.append(s.save())
s=Scene('blind-fish',['fresh','fished']);s.item('Pool',raw('blind-fish-pool'))
s.water('ClearWater',(0,.09,0),(1.2,.8),True)
for i,(x,z,yaw) in enumerate([(-.26,-.13,25),(.17,-.09,-30),(-.12,.19,115),(.30,.15,165)]):
    s.item('Fish'+str(i),raw('blind-fish-body'),(x,.050,z),(.74,.74,.74),yaw,'fresh',['metadata/swimming_fish=true'])
s.marker('Interaction',(0,.30,.30));events.append(s.save())

landmarks=[]
def part(scene,ident,at,scale=(1,1,1),yaw=0):scene.item('Piece'+str(len(scene.ids))+str(len(scene.nodes)),D+ident+'.tscn',at,scale,yaw)

s=Scene('landmark-sump',mode='landmark');s.item('WaterField',raw('sump-water'))
for x,z in [(-2.50,-2.12),(2.50,-2.11),(-2.50,.90)]:part(s,'slick-boulder',(x,0,z))
for x in [-1.75,.80]:part(s,'soda-straws',(x,2.19,-2.45))
part(s,'mineral-seep',(1.55,1.15,-2.98));s.marker('PoolEvent',(1.6,0,1.45));s.marker('DryApproach',(0,0,2.55))
landmarks.append(s.save()|{'room_cells':[3,3],'bounds_hint':[-3,0,-3,3,2.2,3],'layout':'Still central sump; perimeter banks are visual. Keep actual main-route cells dry; the art does not assign deep water.'})
s=Scene('landmark-weeping-wall',mode='landmark')
s.item('ContinuousCurtain',raw('weeping-curtain'),(0,0,-2.98))
for i,x in enumerate([-1.65,0,1.65]):
    part(s,'puddle-wide',(x,0,-2.26),(.9,1,.85))
for x in [-1.20,1.1]:part(s,'soda-straws',(x,2.19,-2.5))
for i,x in enumerate([-.8,.7]):s.item('Drip'+str(i),D+'drip.tscn',(x,2.19,-2.5),extra=['phase_offset='+str(i*1.1)])
s.marker('SeepEvent',(0,0,-2.0));s.marker('DryApproach',(0,0,.8))
landmarks.append(s.save()|{'room_cells':[3,3],'bounds_hint':[-3,0,-3,3,2.2,3],'layout':'One broad curtain on the real far wall, puddles beneath; centre/front left free. Seep is an optional separate event anchor.'})
s=Scene('landmark-drowned-drift',mode='landmark')
for i,z in enumerate([-2,0,2]):s.item('Rails'+str(i),'res://art/dressing/mine-refined-v2/rails.tscn',(0,0,z))
s.item('SunkenCart',raw('drowned-cart'),(.57,-.035,-.62));s.water('StandingWater',(.51,.095,0),(.96,6))
for i,z in enumerate([-2.2,.8,2.2]):part(s,'mineral-seep',(.985,1.14,z),(.8,.8,.8),-90)
part(s,'hanging-wet-roots',(.44,2.19,-1.5),(.50,1,.8));s.marker('DryApproach',(-.58,0,2));s.marker('WaterEvent',(.55,0,1.7))
landmarks.append(s.save()|{'room_cells':[1,3],'bounds_hint':[-1,0,-3,1,2.2,3],'layout':'Six-metre corridor, rails under the right-hand water lane, cart fitted against that wall. Left strip visually clear; water remains cosmetic unless caller explicitly assigns rules.'})
s=Scene('landmark-rimstone-stair',mode='landmark');s.item('Terraces',raw('rimstone-terraces'),(0,0,-.55))
for x in [-2.6,2.6]:part(s,'wet-stalagmite',(x,0,-1.25),(1.7,1.8,1.7));part(s,'dripping-crack',(x,1.2,-2.98))
s.marker('PearlsEvent',(0,0,-.3));s.marker('DryApproach',(0,0,1.85))
landmarks.append(s.save()|{'room_cells':[3,3],'bounds_hint':[-3,0,-3,3,2.2,3],'layout':'Low stepped calcite pools form a landmark, not a new stair transition. Keep the sides and foreground as the main-route approach.'})
s=Scene('landmark-bone-silt',mode='landmark');s.item('SiltBank',raw('bone-silt-bank'),(0,0,-2.05))
for i,(x,z) in enumerate([(-.95,-2.2),(-.38,-1.84),(.25,-2.12),(.85,-1.79)]):
    s.item('WashedBones'+str(i),'res://art/dressing/bone-decor-v1/scattered-bones.tscn',(x,.075,z),(.75,.75,.75),i*47)
s.item('Ribs','res://art/dressing/bone-decor-v1/small-remains.tscn',(.15,.075,-2.3),(.65,.65,.65),-27)
part(s,'wet-gravel',(-1.5,0,-2.1));part(s,'puddle-small',(1.45,0,-2.0));s.marker('DryApproach',(0,0,.8))
landmarks.append(s.save()|{'room_cells':[3,3],'bounds_hint':[-3,0,-3,3,2.2,3],'layout':'Washed anonymous bones embedded in a low bank at a dead-end wall. Pure scenery; never reuse tutorial bodies or invent a searchable companion.'})
s=Scene('landmark-wet-royal-cache',mode='landmark')
for i,(x,z) in enumerate([(-2.2,-2.4),(-1.34,-2.36),(2.27,-2.3)]):part(s,'collapsed-crates',(x,0,z),yaw=i*33)
part(s,'split-barrel',(2.36,0,-1.6));part(s,'fallen-banner',(-.85,0,-1.56),(1.3,1,1.3),-22)
part(s,'cache-rubble-planks',(-2.05,0,-1.6));part(s,'cache-spilled-grain',(-1.35,0,-1.45));part(s,'puddle-wide',(1.7,0,-2.2))
for x in [-1.6,.0,1.6]:part(s,'hanging-wet-roots',(x,2.19,-2.55))
s.marker('BuriedCache',(1.35,0,-1.45));s.marker('DryApproach',(0,0,.65))
landmarks.append(s.save()|{'room_cells':[3,3],'bounds_hint':[-3,0,-3,3,2.2,3],'layout':'Wet broken royal supplies along the back and sides, central approach and buried-cache anchor free. Preserve the existing buried-cache quest and actual mandatory site placement.'})

catalog['events']=events;catalog['landmarks']=landmarks
catalog['runtime_contract']={'api':['state','set_state(value, animate=false) -> bool','set_motion(enabled)','mount_in_cell(map,cell,cell_size) -> bool'],
 'state_aliases':'closed selects fresh/ready; empty aliases the resolved state only for two-state props. Slick ledge rejects empty: caller must specify slipped or passed from actual outcome.',
 'mounts':'Floor props at y=0; seep Mount goes on a real wall with +Z inward. Landmark scenes require their exact rectangular footprint and wall faces; never place into arbitrary room centres without fitting.',
 'floor_cut':'Slick ledge requires the caller floor omitted under its complete 2m tile, like passage shaft art. Real drop is 0.55m. No collision or trap rules are added.',
 'water':'Shallow standing water is art. Only the small blind-fish viewing surface uses alpha; fish/stones and every other body remain opaque.',
 'motion':'Off by default. Only fresh fish school and optional child drips move; effects off resets exact rest and stops processing. No RNG, light, timers or external clips.'}
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('Prepared',len(events),'event appearances and',len(landmarks),'landmark compositions.')
