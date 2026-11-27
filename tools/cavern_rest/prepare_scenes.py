"""Assemble #308 metric scenes using new physical-UV and retained CC0 props."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'art/props/cavern-rest-v1';URI='res://art/props/cavern-rest-v1/'
data=json.loads((ART/'catalog.json').read_text());models={row['id']:row for row in data['assets']}
FW='res://art/props/fortress-waterworks-3d-v1/'
FIRE='res://art/features/campfire-3d-v1/'
BONES='res://art/dressing/bone-decor-v1/'
scenes=[]


class Scene:
    def __init__(self,ident,states=('static',),footprint=(2,2),kind='floor'):
        self.id=ident;self.states=states;self.footprint=footprint;self.kind=kind
        self.ext=[f'[ext_resource type="Script" path="{URI}presentation.gd" id="script"]'];self.sub=[];self.ids={};self.nodes=[]
        self.nodes=[f'[node name="CavernRest" type="Node3D"]','script=ExtResource("script")',
          'states=PackedStringArray('+','.join('"'+s+'"' for s in states)+')',f'state="{states[0]}"',
          f'metadata/asset_id="{ident}"',f'metadata/mount="{kind}"',f'metadata/footprint_metres=Vector2{footprint}',
          'metadata/elevation_prototype=false']
        for state in states:
            if state!='static':self.nodes += [f'[node name="{state}" type="Node3D" parent="."]',f'metadata/appearance_state="{state}"',f'visible={str(state==states[0]).lower()}']
    def resource(self,path,kind='PackedScene'):
        if path not in self.ids:
            i='r'+str(len(self.ids));self.ids[path]=i;self.ext.append(f'[ext_resource type="{kind}" path="{path}" id="{i}"]')
        return self.ids[path]
    def item(self,name,path,at=(0,0,0),scale=(1,1,1),yaw=0,state=None,extra=()):
        if not path.startswith('res://'):path=URI+path+'.glb'
        parent=state if state else '.'
        self.nodes += [f'[node name="{name}" parent="{parent}" instance=ExtResource("{self.resource(path)}")]',
          f'position=Vector3{tuple(at)}',f'scale=Vector3{tuple(scale)}',f'rotation_degrees=Vector3(0,{yaw},0)']+list(extra)
        if path.startswith(URI) and path.endswith('.glb') or path==FIRE+'hearth.glb':self.nodes+=['metadata/worked_surface=true']
        if path.startswith(URI) and any(tag in path for tag in ['column-tall','roof-pendant','wall-rib','cliff-face','talus-edge','ledge-tile','cavern-throat','rest-threshold','iron-seam']):self.nodes+=['metadata/cavern_rock=true']
    def marker(self,name,at,label=''):
        self.nodes += [f'[node name="{name}" type="Marker3D" parent="."]',f'position=Vector3{tuple(at)}']
        if label:self.nodes += [f'metadata/interaction_label="{label}"']
    def box(self,name,at,size,colour,material=None):
        ident='box'+str(len(self.sub));mat=ident+'mat';mesh=ident+'mesh'
        self.sub += [f'[sub_resource type="BoxMesh" id="{mesh}"]',f'size=Vector3{tuple(size)}']
        if material:matref='ExtResource("'+self.resource(material,'Material')+'")'
        else:
            self.sub += [f'[sub_resource type="StandardMaterial3D" id="{mat}"]',f'albedo_color=Color{tuple(colour)}','roughness=0.95'];matref=f'SubResource("{mat}")'
        self.nodes += [f'[node name="{name}" type="MeshInstance3D" parent="."]',f'position=Vector3{tuple(at)}',f'mesh=SubResource("{mesh}")',f'material_override={matref}','cast_shadow=0']
        if material:self.nodes+=['metadata/metre_uv=true']
    def save(self,note):
        text=f'[gd_scene load_steps={len(self.ext)+sum(s.startswith("[sub_resource") for s in self.sub)+1} format=3]\n'+'\n'.join(self.ext+self.sub+self.nodes)+'\n'
        (ART/(self.id+'.tscn')).write_text(text,encoding='utf-8')
        scenes.append({'id':self.id,'scene':URI+self.id+'.tscn','states':list(self.states),'footprint_metres':self.footprint,'kind':self.kind,'note':note})


for ident in ['column-tall','roof-pendant','wall-rib','cliff-face','talus-edge','ledge-tile','goblin-daub','goblin-litter','goblin-totem','drying-rack','hanging-trophies','bedroll','scout-tent','map-table','supply-crate','bench']:
    kind='ceiling' if ident=='roof-pendant' else ('wall' if ident in ['wall-rib','cliff-face','goblin-daub'] else 'floor')
    footprint=(2.4,2.8) if ident=='scout-tent' else ((3,.8) if ident=='cliff-face' else (2,2))
    s=Scene(ident,footprint=footprint,kind=kind);s.item('Model',ident)
    if kind=='ceiling':s.nodes+=['metadata/canopy=true']
    s.save('True metric origin; original geometry, physical grain UVs/vertex colours. Column needs a tall room. Ledge tile is level scenery and requires caller terrain integration, not a live slope.' if ident in ['column-tall','ledge-tile'] else 'Metric '+kind+' prop. New physical material; no collision, RNG or rules.')

s=Scene('iron-seam',('fresh','worked'),kind='wall-floor')
for state in s.states:s.item('Ore',f'iron-seam-{state}',state=state)
s.marker('Interaction',(0,.9,.20),'Iron seam');s.save('Mount on a real wall; fresh/worked appearance never awards ore or advances the smith quest.')
s=Scene('hide-curtain',('closed','opened'),kind='passage')
for state in s.states:s.item('Screen','hide-curtain-'+('open' if state=='opened' else 'closed'),state=state)
s.save('Floor-centre/-Z passage. Opened hides the central hide; caller retains floor. Material/wording do not assign web fire rules.')
s=Scene('goblin-barricade',('blocked','cleared'),kind='passage')
for state in s.states:s.item('Palisade',FW+'palisade.tscn',state=state,extra=['state="'+('closed' if state=='blocked' else 'empty')+'"'])
s.save('Retained #246 intact/broken palisade; caller still owns passage clearance. Cleared state art is broken at the edges, not a collision mesh.')
for ident,model,label in [('back-to-damp','cavern-throat','Damp Caves'),('on-to-rest','rest-threshold','Rest Area'),('rest-return','rest-threshold','Cavern'),('rest-to-fortress','cavern-throat','Goblin Fortress')]:
    s=Scene(ident,kind='passage');s.item('Threshold',model);s.marker('Interaction',(0,.8,.25),label)
    down=ident in ['on-to-rest','rest-to-fortress']
    if down:s.box('DownwardExitLanding',(0,-.04,0),(2,.08,2),(0,0,0,1),'res://art/props/cavern-rest-v1/cavern-floor.tres')
    s.save('Open level passage throat. '+('Supplies a full 2m landing because LevelBuilder omits the descent tile.' if down else 'Return retains the caller floor; no duplicate apron.')+' No travel trigger. Canonical label must be shown; graph pairing/arrival remains Areas authority.')

# Compact one-cell event marker can replace the old sprite without a room reservation.
s=Scene('refuge-marker',('fresh','used'))
s.item('Fire',FIRE+'scene.tscn',(-.32,0,-.28),(.52,.52,.52),state='fresh')
s.item('BankedHearth',FIRE+'hearth.glb',(-.32,0,-.28),(.52,.52,.52),state='used')
for state in s.states:
    s.item('Bedroll','bedroll',(.46,0,-.05),(.48,.48,.48),90,state)
s.marker('Interaction',(0,.40,.6),"Scouts' refuge")
s.save('Compact registered fresh/banked event marker; can replace refuge_scouts.prop through existing RoomEvent API. Caller retains solid cell and rest-once rule. One existing small fire light while fresh; still by default.')

# Four actual compositions; scenery not speculative quest/loot behavior.
s=Scene('landmark-totem-field',footprint=(6,6))
for i,(x,z) in enumerate([(-2.3,-1.8),(-1.6,-2.25),(1.4,-2.2),(2.25,-1.5)]):s.item('Totem'+str(i),'goblin-totem',(x,0,z),yaw=(-1)**i*16)
s.item('Rack','drying-rack',(-2.3,0,.5),yaw=90);s.item('Daub','goblin-daub',(0,1.3,-2.98));s.marker('Approach',(0,0,2.7))
s.save('3x3-cell room. Totems/rack at edges; central approach and exit corridor remain clear. No added cult/lore facts.')
s=Scene('landmark-goblin-lookout',footprint=(6,6))
s.item('Post',FW+'watch-post.tscn',(-2.25,0,-2.1));s.item('Palisade',FW+'palisade.tscn',(1.8,0,-2.45))
s.item('Trophy','hanging-trophies',(2.4,0,.1),yaw=-90);s.item('Litter','goblin-litter',(-1.8,0,.5))
s.marker('Approach',(0,0,2.7));s.save('3x3-cell edge lookout; retained CC0/project structure recipes, no guard/spawn or usable elevated platform assigned.')
s=Scene('landmark-collapsed-bridge',footprint=(6,6))
s.item('FallenWalkway',FW+'overhead-walkway.tscn',(-1.6,.33,-2.1),yaw=-18)
s.item('Talus','talus-edge',(-1.8,0,-1.2));s.item('Rim','talus-edge',(1.6,0,-2.3))
s.marker('Approach',(0,0,2.7));s.save('Broken bridge scenery beside a retained dry route, not an impassable gap/repair gate or new traversal rule. Reserve an alcove for the fallen deck.')
s=Scene('landmark-bone-midden',footprint=(6,6))
for i,(x,z) in enumerate([(-2,-2.1),(-1.5,-1.7),(-2.3,-1.2)]):s.item('Bones'+str(i),BONES+'scattered-bones.tscn',(x,0,z),yaw=i*47)
s.item('Trophy','hanging-trophies',(-2.3,0,.2),yaw=90);s.item('Talus','talus-edge',(1.8,0,-2.4));s.marker('Approach',(0,0,2.7))
s.save('3x3-cell dead-end composition; retained verified CC0 anonymous bones. No searchable identity, rewards or guaranteed ambush.')

# The tall rift is presentation geometry only; no player/controller is instantiated.
s=Scene('cavern-rift-identity',footprint=(10,16),kind='room-context')
floor='res://art/props/cavern-rest-v1/cavern-floor.tres';wall='res://art/props/cavern-rest-v1/cavern-wall.tres'
# The eight ledge tiles supply this whole level floor. No second coplanar slab.
s.box('NearRockWall',(-3.85,1,0),(.65,16,16),(0,0,0,1),wall)
s.box('FarRockWall',(4.2,1,0),(.8,16,16),(0,0,0,1),wall)
s.box('ChasmBottom',(1.2,-6.9,0),(6,.25,16),(.035,.055,.063,1))
for i in range(5):
    s.item('HighColumn'+str(i),'column-tall',(3.1,-3,-6+i*3),(.8,1.8,.8),i*17)
    s.item('Pendant'+str(i),'roof-pendant',(-.1+i*.56,8.5,-6+i*3),(1.1,2,1.1))
    s.item('NearCliff'+str(i),'cliff-face',(-3.5,0,-6+i*3),yaw=90)
    s.item('FarCliff'+str(i),'cliff-face',(3.8,0,-6+i*3),yaw=-90)
for i in range(8):s.item('LevelLedge'+str(i),'ledge-tile',(-2.5,0,-7+i*2))
for i in range(3):s.item('DistantLedge'+str(i),'ledge-tile',(3.0,-2+i*2,-4+i*4),(.8,1,1.2),180)
s.item('BoundaryPalisade',FW+'palisade.tscn',(-1.6,0,-4),yaw=90)
s.item('HangingLantern','res://art/dressing/mine-refined-v2/lantern-hanging.tscn',(-3.35,2.25,4.2))
s.marker('EyeHeightView',(-2.5,1.2,6.3));s.marker('LookToward',(0,1,-4));s.save('Tall narrow rift identity vignette, NOT a playable elevation prototype. Only the foreground walkway is level y=0. Needs bespoke void/roof reservation before live placement; distant ledges are scenery, not reachable routes. No collision/controller/map.')

s=Scene('rest-area-approach',('fresh','used'),footprint=(8,8),kind='room-context')
for state in s.states:
    s.item('Tent','scout-tent',(-2.6,0,-.55),yaw=-10,state=state)
    s.item('Planning','map-table',(-1.7,0,-2.7),state=state)
    s.item('Supplies','supply-crate',(-2.8,0,1.8),state=state)
    s.item('Bench','bench',(1.55,0,.9),state=state)
    s.item('Bedroll','bedroll',(2.9,0,-1.5),yaw=15,state=state)
s.item('Fire',FIRE+'scene.tscn',(1.5,0,-.65),(.65,.65,.65),state='fresh')
s.item('BankedHearth',FIRE+'hearth.glb',(1.5,0,-.65),(.65,.65,.65),state='used')
s.item('LookoutColumn','column-tall',(3.6,0,-3.2),(.65,.85,.65))
for i in range(3):s.item('ShelterBack'+str(i),'cliff-face',(-2.65+i*2.65,2.1,-3.85),(.92,.35,1))
for i in range(2):s.item('ShelterSide'+str(i),'cliff-face',(-3.9,2.1,-1.5+i*3),(1,.35,1),90)
s.box('ShelterBackRock',(0,2.5,-4.03),(8,5,.3),(0,0,0,1),wall)
s.box('ShelterLeftRock',(-4.03,2.5,0),(.3,5,8),(0,0,0,1),wall)
s.box('ShelterRoof',(0,5.1,-.4),(8,.3,7.2),(0,0,0,1),'res://art/props/cavern-rest-v1/cavern-ceiling.tres')
s.nodes+=['metadata/canopy=true']
for i in range(3):s.item('LookoutRim'+str(i),'ledge-tile',(3.2,0,-2+i*2),(.8,1,1))
s.item('SafeThreshold','rest-threshold',(0,0,3.1),yaw=180)
s.marker('Interaction',(0,.6,.65),"Scouts' refuge");s.marker('Stash',(-2.8,.5,1.8),'Supplies')
s.marker('Planning',(-1.7,.75,-2.7),'Scouts map');s.marker('Quartermaster',(-2.7,0,2.7),'Route supplies')
s.marker('Lookout',(2.7,1.2,-2.6));s.marker('Arrival',(0,0,3.1))
s.save('4x4-cell first-person refuge composition: grounded tent/pegs/bedrolls, map table and supplies, warm fire at edge, clear central arrival. One small existing light fresh, none banked. Needs reserved room/ceiling height; leave approved Overlook screen, present-party mapping and route/rest/service authority intact. Markers are future caller targets only, not new services/NPCs.')

# Original retained texture families, material-only colour/response adaptations.
for name,tex,colour in [('cavern-wall','cavern-v1/rift-wall.png',(.85,.90,.92,1)),
 ('cavern-floor','cavern-v1/rift-floor.png',(.90,.90,.86,1)),
 ('cavern-ceiling','cavern-v1/rift-ceiling.png',(.80,.86,.90,1))]:
    (ART/(name+'.tres')).write_text('[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n'
      '[ext_resource type="Texture2D" path="res://art/textures/'+tex+'" id="texture"]\n'
      '[resource]\nalbedo_texture=ExtResource("texture")\nalbedo_color=Color'+str(colour)+'\nroughness=0.94\nmetallic_specular=0.16\ntexture_filter=3\ntexture_repeat=true\n',encoding='utf-8')
for material,shader in [('rock','rock'),('cavern-wall-variant','wall-variant')]:
    (ART/(material+'.tres')).write_text('[gd_resource type="ShaderMaterial" load_steps=3 format=3]\n'
      f'[ext_resource type="Shader" path="{URI}{shader}.gdshader" id="shader"]\n'
      '[ext_resource type="Texture2D" path="res://art/textures/cavern-v1/rift-wall.png" id="texture"]\n'
      '[resource]\nshader=ExtResource("shader")\nshader_parameter/albedo_texture=ExtResource("texture")\n',encoding='utf-8')

data['scenes']=scenes
data['retained_inputs']=[{'path':p,'sha256':hashlib.sha256((ROOT/p.removeprefix('res://')).read_bytes()).hexdigest()} for p in
 [FW+'palisade-intact.glb',FW+'palisade-broken.glb',FW+'watch-post.glb',FW+'overhead-walkway.glb',
 FIRE+'hearth.glb',FIRE+'flames.glb','res://art/textures/descent-walls-v1/worked-cave.png',
 'res://art/textures/descent-walls-v1/goblin-hold.png','res://art/textures/descent-surfaces-v1/worked-cave-floor.png','res://art/textures/descent-surfaces-v1/worked-cave-ceiling.png']]
data['hookup']='Compact refuge_scouts.prop URI uses the existing RoomEvent API; no rest/loot/cost/Overlook rule changes. Cavern theme/Areas/Main selection and full approach/rift reserved room/roof geometry remain caller hookup. Elevation prototype deferred.'
data['live_bindings_changed']=True
data['live_binding']={'file':'data/events/refuge_scouts.tres','change':'prop URI only, to compact one-cell 3D marker; original rest/loot/cost/service/Overlook rules preserved'}
(ART/'theme.tres').write_text((ROOT/'themes/cave.tres').read_text(encoding='utf-8').replace(
 'res://art/textures/cave-v1/wall.tres',URI+'cavern-wall.tres',1).replace(
 'res://art/textures/cave-v1/wall.tres',URI+'cavern-wall-variant.tres',1).replace(
 'res://art/textures/cave-v1/floor.tres',URI+'cavern-floor.tres').replace(
 'res://art/textures/cave-v1/ceiling.tres',URI+'cavern-ceiling.tres').replace(
 'res://art/features/web-silk-v2/intact.tscn',URI+'hide-curtain.tscn').replace(
 'res://art/features/web-silk-v2/torn.tscn',URI+'hide-curtain-opened.tscn').replace(
 'res://art/features/transitions-3d-v1/root-barrier.tscn',URI+'goblin-barricade.tscn').replace(
 'res://art/features/transitions-3d-v1/cave-ledge-down.tscn',URI+'on-to-rest.tscn').replace(
 'res://art/features/transitions-3d-v1/root-climb-up.tscn',URI+'back-to-damp.tscn').replace(
 'display_name = "Mine"','display_name = "Cavern"\nwall_face_uv=true').replace(
 'closed_name = "Spider web"','closed_name = "Hide curtain"').replace(
 'closed_open_message = "You tear through the web."','closed_open_message = "You pull the hide curtain aside."').replace(
 'blocked_name = "Tangled roots"','blocked_name = "Goblin barricade"').replace(
 'blocked_message = "Thick roots block the way."','blocked_message = "A goblin barricade blocks the passage."'),encoding='utf-8')
theme_path=ART/'theme.tres';text=theme_path.read_text(encoding='utf-8')
text=text.replace('descent_name = "Pit"','descent_name = "Path to the Rest Area"').replace('descent_prompt = "Climb down into the pit?"','descent_prompt = "Continue to the Rest Area?"').replace('ascent_name = "Hanging roots"','ascent_name = "Way back to the Damp Caves"').replace('ascent_prompt = "Climb the roots back up?"','ascent_prompt = "Return to the Damp Caves?"').replace('exit_message = "Daylight. The way back to camp."','exit_message = "The path back through the Damp Caves."')
theme_path.write_text(text,encoding='utf-8')
# A separate opened default is required by the current LevelBuilder dispatcher.
opened=(ART/'hide-curtain.tscn').read_text(encoding='utf-8').replace('state="closed"','state="opened"',1)
(ART/'hide-curtain-opened.tscn').write_text(opened,encoding='utf-8')
(ART/'catalog.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print('Prepared',len(scenes),'registered scenes, four surface materials and retained-input hashes.')
