"""Write solid native wrappers and explicit old-id dispositions, without live hooks."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/dressing/damp-dressing-v1';URI='res://art/dressing/damp-dressing-v1/'
catalog=json.loads((ART/'catalog.json').read_text())
for variant in ['wet','mine']:
    (ART/(variant+'.tres')).write_text('[gd_resource type="ShaderMaterial" load_steps=3 format=3]\n'
      '[ext_resource type="Shader" path="'+URI+'dressing.gdshader" id="shader"]\n'
      '[ext_resource type="Texture2D" path="res://art/textures/damp-caves-v1/limestone-wall.png" id="albedo"]\n'
      '[resource]\nshader=ExtResource("shader")\nshader_parameter/limestone_albedo=ExtResource("albedo")\n'
      f'shader_parameter/mine_mix={1.0 if variant=="mine" else 0.0}\nshader_parameter/glow_strength=0.0\n',encoding='utf-8')


def scene(name,models,mount,variant='damp',glow=False,drip=False):
    states=[state for model,state in models]
    resources=[f'[ext_resource type="Script" path="{URI}appearance.gd" id="script"]']
    for model,state in models:resources.append(f'[ext_resource type="PackedScene" path="{URI}{model}.glb" id="{model}"]')
    if drip:resources.append(f'[ext_resource type="PackedScene" path="{URI}drip.tscn" id="drip"]')
    nodes=['[node name="DampDressing" type="Node3D"]','script=ExtResource("script")',
      'states=PackedStringArray('+','.join('"'+s+'"' for s in states)+')',f'state="{states[0]}"',
      f'variant="{variant}"',f'optional_glow={str(glow).lower()}',f'metadata/asset_id="{name}"',f'metadata/mount="{mount}"']
    for model,state in models:
        nodes+=['',f'[node name="{state.capitalize()}" parent="." instance=ExtResource("{model}")]',f'metadata/appearance_state="{state}"']
        if state!=states[0]:nodes+=['visible=false']
    if drip:nodes+=['','[node name="Drip" parent="." instance=ExtResource("drip")]','position=Vector3(0.012,-0.635,-0.007)','fall_distance=1.53']
    (ART/(name+'.tscn')).write_text(f'[gd_scene load_steps={len(resources)+1} format=3]\n'+'\n'.join(resources)+'\n\n'+'\n'.join(nodes)+'\n',encoding='utf-8')


events={'goblin-stash':['fresh','empty'],'lamp-store':['fresh','used'],'three-knocks':['fresh','used']}
for row in catalog['assets']:
    ident=row['id'];event=next((name for name in events if ident.startswith(name+'-')),None)
    if event:
        row['states']=events[event];row['scene']=URI+event+'.tscn';row['appearance_state']=ident.removeprefix(event+'-')
    else:
        scene(ident,[(ident,'static')],row['mount'])
        row['scene']=URI+ident+'.tscn';row['appearance_state']='static'
for name,states in events.items():scene(name,[(name+'-'+s,s) for s in states],'floor')
# Mine counterparts reuse the same geometry with shared dry/warm material, never reskin old palette-point UVs.
dry=['cracks-rubble','chalk-arrow','chalk-cross','chalk-tally','web-strand','rat-nest','puddle-small','puddle-wide','wet-gravel',
     'tracks-drag','floor-crack','old-scorch','root-curtain-a','root-curtain-b','root-foot-tangle','floor-crossing-root',
     'collapsed-crates','split-barrel','fallen-banner','cache-rubble-planks','cache-spilled-grain']
rows={row['id']:row for row in catalog['assets']}
for ident in dry:scene('mine-'+ident,[(ident,'static')],rows[ident]['mount'],'mine')
scene('moss-curtain-lit',[('moss-curtain','static')],'ceiling',glow=True)
scene('fungus-pulse',[('exit-mushrooms','static')],'edge',glow=True)
scene('drip-stalactite-effect',[('drip-stalactite','static')],'ceiling',drip=True)
(ART/'drip.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="'+URI+'drip.gd" id="script"]\n'
  '[node name="Drip" type="Node3D"]\nscript=ExtResource("script")\nmetadata/asset_id="drip"\nmetadata/mount="ceiling"\n',encoding='utf-8')

mapping={ident:ident for ident in dry}
mapping['floor-gravel']='wet-gravel'
mapping.update({'moss-curtain':'moss-curtain','moss-curtain-lit':'moss-curtain-lit','fungus-pulse':'fungus-pulse','drip':'drip',
 'goblin-stash':'goblin-stash','lamp-eaters-lamp':'lamp-store','three-knocks':'three-knocks'})
catalog['dispositions']=[{'old_id':old,'damp_scene':URI+new+'.tscn',
 'mine_scene':URI+'mine-'+new+'.tscn' if new in dry else None,
 'note':'Presentation replacement only; retain original until caller hookup. No later-floor daubs/litter/trophies.'} for old,new in mapping.items()]
catalog['aliases']=[{'id':'moss-curtain-lit','base':'moss-curtain','optional_glow':True},
 {'id':'fungus-pulse','base':'exit-mushrooms','optional_glow':True},
 {'id':'drip-stalactite-effect','base':'drip-stalactite','effect_draw_budget':2,'effect_triangle_budget':400}]
catalog['reuse']=[{'path':'res://art/effects/exploration-mist-v1/','disposition':'Reuse existing three-sheet mist and preference/visibility rules; no second fog implementation.'},
 {'path':'res://art/dressing/cave-growth-3d-v1/','disposition':'Keep existing formations/wall roots/fungal growth for mine/fungal regions. New damp siblings share original helpers, not duplicate sources.'},
 {'path':'res://art/dressing/mine-refined-v2/','disposition':'Keep supports, workings, rails, lanterns and shrine; C/D does not rebuild them.'},
 {'path':'res://art/dressing/bone-decor-v1/','disposition':'Keep verified CC0 bones for later bone-silt landmark.'}]
catalog['runtime_contract']={'states':'static, goblin-stash fresh/empty, lamp-store and three-knocks fresh/used; closed/empty legacy aliases',
 'api':['state','set_state(value, animate=false) -> bool','set_searched(searched)','set_motion(enabled)'],
 'defaults':'Still; no lights/collision, all solid opaque, glow only in explicitly lit wrappers.',
 'effects':'Drip default off. Ceiling origin, fall_distance determines landing; default 2.16m (ripple at roof-2.19m). Stalactite sibling supplies correctly offset hook. set_motion resets phase exactly.',
 'mounts':'wall centre at rock face +Z out; ceiling origin at roof, 0.45m maximum fringe; edge/floor origin y=0. Patches sit 4–18mm above caller floor; do not raise them like sprites.',
 'exit_room':'Use exit-mushrooms, exit-floor-mold and exit-wall-mold ONLY in Fungal Hollows exit room. Main Damp Caves stays wet bare limestone. Glow is not party light.'}
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('Prepared',len(catalog['assets']),'models,',len(dry),'dry material counterparts and',len(mapping),'old-id dispositions.')
