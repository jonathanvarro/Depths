"""Create registered native wrappers and code-native matching map glyphs."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/features/damp-passages-v1';URI='res://art/features/damp-passages-v1/'
ICONS=ROOT/'art/ui/area-routes-v1';ICONS.mkdir(parents=True,exist_ok=True)
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))


def scene(name, models, kind='static', state='static', label='', destination='', pair=''):
    resources=[f'[ext_resource type="Script" path="{URI}appearance.gd" id="script"]',
               '[ext_resource type="Material" path="res://art/textures/damp-caves-v1/silt-floor.tres" id="ground"]']
    for model in models:resources.append(f'[ext_resource type="PackedScene" path="{URI}{model}.glb" id="{model}"]')
    nodes=['[node name="DampPassage" type="Node3D"]','script=ExtResource("script")',
           'ground_material=ExtResource("ground")',f'kind="{kind}"',f'state="{state}"',f'sign_label="{label}"',
           f'metadata/asset_id="{name}"','metadata/forward="-Z"']
    if destination:nodes+=[f'metadata/destination_hint="{destination}"',f'metadata/paired_asset="{pair}"']
    for model in models:
        node={'curtain-intact':'Intact','curtain-opened':'Opened','siltfall-blocked':'Blocked','siltfall-cleared':'Cleared'}.get(model,'Model')
        nodes += ['',f'[node name="{node}" parent="." instance=ExtResource("{model}")]']
        if node.lower()!=state and kind!='static':nodes+=['visible=false']
    (ART/(name+'.tscn')).write_text(f'[gd_scene load_steps={len(resources)+1} format=3]\n'+'\n'.join(resources)+'\n\n'+'\n'.join(nodes)+'\n',encoding='utf-8')


for asset in catalog['assets']:
    if asset['sign']:
        name=asset['id'];label={'cavern-onward':'Cavern','hollows-onward':'Hollows'}.get(name,'Damp')
        scene(name,[name],label=label,destination=asset['destination_hint'],pair=asset['paired_asset'])
        asset['scene']='res://art/features/damp-passages-v1/'+name+'.tscn'
        asset['sign_label']=label;asset['text_draws']=0;asset['max_scene_draws']=asset['draws']
        asset['map_glyph']='res://art/ui/area-routes-v1/exit-'+asset['destination_hint']+'.svg'
        asset['interaction_label']={'cavern':'Cavern','fungal-hollows':'Fungal Hollows','damp-caves':'Damp Caves'}[asset['destination_hint']]
    else:asset['max_scene_draws']=asset['draws']
for kind,states in [('curtain',['intact','opened']),('siltfall',['blocked','cleared'])]:
    for state in states:scene(kind+'-'+state,[kind+'-'+s for s in states],kind,state)
    for row in catalog['assets']:
        if row['id'].startswith(kind):
            row['scene']=URI+row['id']+'.tscn';row['states']=states
            row['state_wrapper_draws']=1;row['state_wrapper_materials']=1
# Generic B3/B4 references reuse the registered geometry, with useful explicit names.
scene('water-cut-shaft',['cavern-onward'],label='Cavern',destination='cavern',pair='cavern-return')
scene('wet-rope-ascent',['cavern-return'],label='Damp',destination='damp-caves',pair='cavern-onward')

paths={
    'cavern':'<path d="M5 24V15L9 7L16 4L23 7L27 15V24M12 24V17L16 13L20 17V24"/>',
    'fungal-hollows':'<path d="M4 15Q5 7 16 5Q27 7 28 15ZM13 15V25H19V15M8 26H24"/>',
    'damp-caves':'<path d="M11 4L5 15Q3 23 11 23Q19 23 17 15ZM24 10L19 20Q18 26 24 27Q30 26 29 20Z"/>'}
icons=[]
for name,path in paths.items():
    for exit in [False,True]:
        ident=('exit-' if exit else '')+name
        if exit:body='<g transform="translate(0 -1) scale(.86)">'+path+'</g><path d="M19 27H29M25 23L29 27L25 31"/>'
        else:body=path
        svg='<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><g fill="none" stroke="#e6dac1" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">'+body+'</g></svg>\n'
        (ICONS/(ident+'.svg')).write_text(svg,encoding='utf-8')
        icons.append({'id':ident,'path':'res://art/ui/area-routes-v1/'+ident+'.svg','area':name,'role':'destination exit' if exit else 'area'})
(ICONS/'catalog.json').write_text(json.dumps({'issue':302,'assets':icons,'style':'Matches existing expedition-v1/map: ivory 2.5px strokes on 32px, transparent, caller tint. Original code-native SVGs; no bitmap generation.','hookup':'Destination-aware map/arrival naming remains caller-owned. Exit arrow means transition, not numeric depth or guaranteed descent.'},indent=2)+'\n',encoding='utf-8')
catalog['runtime_contract']={'states':'curtain intact/opened; siltfall blocked/cleared; static exits',
    'api':['set_state(value, animate=false) -> bool','set_motion(enabled)'],
    'metadata':'destination_hint and paired_asset are art hints, not binding world IDs',
    'signs':'Raised chalk glyphs match map silhouettes. sign_label is a metadata hint, not generated font geometry. Use canonical interaction_label in the caller prompt before commitment.',
    'ceiling':'Canopy nodes join ceiling group; caller hides/restores for overhead view.'}
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('Prepared eight registered passage states, two aliases and six map glyphs.')
