from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/props/puzzle-fittings-v1'
URI='res://art/props/puzzle-fittings-v1/'

def save(name,kind,models,nodes,extra=None):
    resources=[f'[ext_resource type="Script" path="{URI}prop.gd" id="script"]']
    resources += [f'[ext_resource type="PackedScene" path="{URI}{model}.glb" id="{model}"]' for model in models]
    if extra:resources+=extra
    text=f'[gd_scene load_steps={len(resources)+1} format=3]\n'+'\n'.join(resources)+'\n\n'
    text+='[node name="PuzzleFitting" type="Node3D"]\nscript=ExtResource("script")\nkind="'+kind+'"\nmetadata/asset_id="puzzle-'+kind+'"\n'
    text+='\n'.join(nodes)+'\n'
    (ART/(name+'.tscn')).write_text(text,encoding='utf-8',newline='\n')

for kind in ['barred','locked']:
    model='bar' if kind=='barred' else 'lock-cases'
    name='Bar' if kind=='barred' else 'Locks'
    save(kind+'-door',kind,['door-frame','door-leaf',model],[
      '[node name="Frame" parent="." instance=ExtResource("door-frame")]',
      '[node name="Hinge" type="Node3D" parent="."]','position=Vector3(-0.86,0,0)',
      '[node name="Leaf" parent="Hinge" instance=ExtResource("door-leaf")]',
      f'[node name="{name}" parent="Hinge" instance=ExtResource("{model}")]'])
save('lever','lever',['lever-base','lever-handle'],[
 '[node name="Base" parent="." instance=ExtResource("lever-base")]',
 '[node name="Pivot" type="Node3D" parent="."]','position=Vector3(0,0.55,0)',
 '[node name="Lean" type="Node3D" parent="Pivot"]','rotation=Vector3(-0.610865,0,0)',
 '[node name="Handle" parent="Pivot/Lean" instance=ExtResource("lever-handle")]'])
save('recovered-key','key',['key'],[
 '[node name="Remains" parent="." instance=ExtResource("remains")]',
 '[node name="Key" type="Node3D" parent="."]','position=Vector3(0.18,0.32,0.32)',
 '[node name="Model" parent="Key" instance=ExtResource("key")]',
 '[node name="Glint" type="OmniLight3D" parent="Key"]','light_color=Color(1,0.847,0.541,1)',
 'light_energy=0.6','omni_range=0.9'],
 ['[ext_resource type="PackedScene" path="res://art/dressing/bone-decor-v1/seated-skeleton.tscn" id="remains"]'])
print('Prepared two doors, a wall lever and the recovered-key scene.')
