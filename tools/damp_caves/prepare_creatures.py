"""Registered native wrappers, explicit fade sibling and matching vector symbols."""
from pathlib import Path
import hashlib
import json
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/enemies/damp-creatures-v1';URI='res://art/enemies/damp-creatures-v1/'
source=(ART/'biology.gdshader').read_text(encoding='utf-8')
fade=source.replace('render_mode diffuse_burley','render_mode depth_prepass_alpha, diffuse_burley')
fade=fade.replace(' // Normal solid biology never writes alpha. Thin tissue is colour, not glass.',' ALPHA=opacity; // Explicit ambient fade sibling only.')
(ART/'biology-fade.gdshader').write_text(fade,encoding='utf-8')
catalog=json.loads((ART/'catalog.json').read_text())
for row in catalog['assets']:
    ident=row['id'];box=', '.join('"%s": AABB(%s)'%(name,', '.join(f'{n:.5f}' for n in values)) for name,values in row['pose_bounds'].items())
    size={'pale-newt':(.55,1.1),'drowned-mother':(.8,1.35),'blind-crawler':(.85,.85),'leech-swarm':(1.0,.80)}[ident]
    text='[gd_scene load_steps=3 format=3]\n'+f'[ext_resource type="Script" path="{URI}actor.gd" id="script"]\n[ext_resource type="PackedScene" path="{URI}{ident}.glb" id="model"]\n'
    text+='[node name="DampCreature" type="Node3D"]\nscript=ExtResource("script")\n'
    text+=f'pose_bounds={{{box}}}\ncontact_size=Vector2{size}\nmetadata/asset_id="{ident}"\nmetadata/visual_height={row["height"]:.5f}\n'
    if ident=='blind-crawler':text+='held_poses=PackedStringArray("hold")\n'
    text+='[node name="Model" parent="." instance=ExtResource("model")]\n'
    (ART/(ident+'.tscn')).write_text(text,encoding='utf-8');row['scene']=URI+ident+'.tscn'
    row['loops']=['idle','walk','run']+(['hold'] if ident=='blind-crawler' else [])
    row['concept']='res://art/concepts/damp-creatures-v1/'+ident+'.png'
    row['audio']={reaction:'res://audio/damp-caves-v1/'+ident+'-'+reaction+'.wav' for reaction in ['hurt','death']}

icons=ROOT/'art/ui/damp-creatures-v1';icons.mkdir(parents=True,exist_ok=True)
# Original code-native contours matching each accepted family; not edits of concept pixels.
shapes={
 'pale-newt':'<path d="M53 16Q64 6 75 16L81 43L99 37L91 51L108 61L87 59L79 75Q83 102 66 116Q78 96 63 84Q45 78 47 59L20 61L36 50L27 38L46 43Z"/><path d="M47 24L31 17L40 35M81 24L97 17L88 35" fill="none" stroke-width="6"/>',
 'drowned-mother':'<path d="M48 15Q64 5 80 15L87 44L108 39L96 56L117 71L88 65Q95 91 80 105Q62 119 49 105Q78 109 76 87Q42 91 39 66L11 72L31 55L20 39L41 44Z"/><path d="M42 24L22 15L34 39M86 24L106 15L94 39" fill="none" stroke-width="7"/>',
 'blind-crawler':'<path d="M51 36Q64 26 77 36L82 70L75 96L83 109L65 103L47 110L54 96L46 70Z"/><path d="M49 43L29 32L15 43L13 66L27 76L37 65L25 60L24 47L38 50Z"/><path d="M79 43L99 33L111 44L105 60L95 55L101 45L89 48Z"/><path d="M47 55L29 72L17 86M47 69L29 86L22 100M81 58L99 74L111 88M80 72L97 88L105 103M55 35L47 13M73 35L81 13" fill="none" stroke-width="6"/>',
 'leech-swarm':'<path d="M19 93Q5 51 38 50Q20 25 56 31Q78 9 92 38Q123 34 112 70L119 92L106 101L93 76Q100 59 84 52Q74 56 86 83L87 106L74 110L65 81Q71 58 55 54Q39 58 52 80L49 108L35 105L34 83Q43 66 30 64Q18 70 30 94Z"/>'}
for ident,body in shapes.items():
    for role,size in [('map',32),('bestiary',128)]:
        svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 128 128"><g fill="#e6dac1" stroke="#e6dac1" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>\n'
        path=icons/(ident+'-'+role+'.svg');path.write_text(svg,encoding='utf-8')
    row=next(a for a in catalog['assets'] if a['id']==ident)
    row['map_symbol']='res://art/ui/damp-creatures-v1/'+ident+'-map.svg';row['bestiary_thumbnail']='res://art/ui/damp-creatures-v1/'+ident+'-bestiary.svg'
catalog['runtime_contract']={'api':['play(clip)','sample(clip,t)','set_motion(enabled)','set_opacity(a)','framing_bounds()'],
 'floor':'Fixed metric scene floor, +Z front. Every sampled pose is fitted to floor; fall stays inside 2m footprint. Submerge flattens under a caller-owned pool surface instead of moving the actor through the floor.',
 'states':'grab completes into hold loop; release returns idle; submerge and fall hold their last frame; emerge returns idle. Caller still owns combat visibility/targeting.',
 'opacity':'Normal solid shader has no ALPHA. Cached preloaded fade sibling only below full opacity; exact solid shader restored at 1.0.',
 'framing':'Union of all registered clip bounds, retaining both ends of presentation cross-fades.',
 'rules':'No stats, enemy assignment, named-pack patrol, loot, damage, hidden attacks or map glow added.'}
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
concepts=ROOT/'art/concepts/damp-creatures-v1/generation.json';data=json.loads(concepts.read_text(encoding='utf-8'))
data['stage']='I: concepts approved for modelling; models delivered with separate native validation and owner/device review';data['approved']='Owner approved all four for modelling in chat, 2026-11-26'
for row in data['assets']:
    row['approval']='approved for modelling';row['sha256']=hashlib.sha256((ROOT/row['file']).read_bytes()).hexdigest()
concepts.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print('Prepared four creature actors, explicit fade sibling and eight matching vector symbols.')
