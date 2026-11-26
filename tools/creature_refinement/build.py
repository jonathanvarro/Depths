"""#292: refine the retained CC0 rat and author an articulated cave bat.

Run in Blender background, -- --sources <owner workspace>. No source masters
are changed. New editable masters stay in that workspace's ignored build/.
"""
import argparse, hashlib, json, math, sys
from pathlib import Path
import bpy, bmesh
from mathutils import Vector, Quaternion, Euler
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools/combat_roster'))
from mesh_parts import Mesh
from build_roster import PALETTE, activate, bake_constraints, fit_floor, points_for
sys.path.insert(0,str(ROOT/'tools/creatures_3d'))
from build_early_creatures import armature

parser=argparse.ArgumentParser()
parser.add_argument('--sources',type=Path,required=True)
parser.add_argument('--predatory',action='store_true',help='#294 rat silhouette and grounded-bat follow-up; retains v2')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
FAMILY='creatures-predatory-v3' if args.predatory else 'creatures-refined-v2'
OUT=ROOT/'art/enemies'/FAMILY;OUT.mkdir(parents=True,exist_ok=True)
WORK=args.sources/('build/local-creatures-predatory-v3' if args.predatory else 'build/local-creatures-refined-v2');(WORK/'masters').mkdir(parents=True,exist_ok=True)
COLOURS={**PALETTE,'hide':'614c40','hide_light':'806651','hide_dark':'44372f',
         'skin':'80605a','skin_dark':'563d3d','membrane':'65423a','membrane_light':'795347',
         'eye':'11110f','nose':'392b2a','ivory':'bba786','claw':'8a7864'}
KINDS={'hide':'Fur','hide_light':'Fur','hide_dark':'Fur','pelt':'Fur','pelt_high':'Fur','pelt_dark':'Fur',
       'skin':'Skin','skin_dark':'Skin','membrane':'Membrane','membrane_light':'Membrane'}
if args.predatory:COLOURS.update(hide='5d5143',hide_light='88735a',hide_dark='3e3931',eye='b83b23',ivory='d1b689')

def paint(obj,types=None,body=False,great=False):
    attr=obj.data.color_attributes.new(name='Col',type='FLOAT_COLOR',domain='CORNER')
    material_names=['Fur','Skin','Membrane','Details']
    for name in material_names:
        material=bpy.data.materials.get(name) or bpy.data.materials.new(name)
        material.use_nodes=True
        nodes=material.node_tree.nodes
        colour=nodes.get('Vertex Color') or nodes.new('ShaderNodeVertexColor');colour.layer_name='Col'
        material.node_tree.links.new(colour.outputs['Color'],nodes.get('Principled BSDF').inputs['Base Color'])
        obj.data.materials.append(material)
    for face in obj.data.polygons:
        tag=types[face.index] if types else 'hide'
        kind=KINDS.get(tag,'Details');face.material_index=material_names.index(kind)
        srgb=tuple(int(COLOURS[tag][i:i+2],16)/255 for i in (0,2,4))
        rgb=tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in srgb)
        for loop in face.loop_indices:
            p=obj.matrix_world@obj.data.vertices[obj.data.loops[loop].vertex_index].co
            # Broad painted value structure, with no world-space stone grain.
            shade=(.92+.11*math.sin(p.y*8)+.04*math.sin(p.x*29+p.z*7)) if kind=='Fur' else 1
            if body:shade*=.91+.12*max(0,min(1,p.z/.45))
            attr.data[loop].color=(*(max(0,min(1,c*shade)) for c in rgb),1)
        face.use_smooth=kind in ['Fur','Skin']
    obj.data.color_attributes.active_color=attr

def part_object(mesh,rig,name,tags):
    # The established mesh helper handles existing posed bind/rest transforms.
    # Its temporary palette UVs are not used by the new vertex-colour shader.
    colours=mesh.colours.copy();mesh.colours=['pelt']*len(colours)
    obj=mesh.finish(name,rig,PALETTE);paint(obj,colours);return obj

def export(id,rig,meshes,source,bones_expected=None):
    bake_constraints(rig)
    if id=='cave-bat':
        action=bpy.data.actions['fall-ground']
        values=[]
        for frame in range(round(action.frame_range[1])+1):
            activate(rig,action,frame);points=points_for(meshes)
            shift=Vector()
            for axis in [0,1]:
                low=min(p[axis] for p in points);high=max(p[axis] for p in points)
                shift[axis]=max(-.98-low,min(.98-high,0))
            values.append((frame,rig.location.copy()+shift))
        for frame,location in values:rig.location=location;rig.keyframe_insert('location',frame=frame)
    bounds=fit_floor(rig,meshes)
    activate(rig,bpy.data.actions['idle'],0)
    bpy.context.scene.render.fps=24
    for obj in list(bpy.context.scene.objects):
        if obj.type in ['CAMERA','LIGHT']:bpy.data.objects.remove(obj,do_unlink=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'masters'/f'{id}.blend'))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in ([rig.parent] if rig.parent else [])+[rig,*meshes]:obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    path=OUT/f'{id}.glb'
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_materials='EXPORT',export_animations=True,export_animation_mode='ACTIONS',
        export_frame_range=False,export_anim_slide_to_zero=True,export_force_sampling=True,
        export_optimize_animation_size=False,export_rest_position_armature=True,
        export_vertex_color='ACTIVE',export_cameras=False,export_lights=False)
    counts={}
    for mesh in meshes:mesh.data.calc_loop_triangles();counts[mesh.name]=len(mesh.data.loop_triangles)
    if bones_expected:assert len(rig.data.bones)==bones_expected
    assert sum(counts.values())<4500,(id,counts)
    height=bounds['idle']['high'][2]
    # Blender XYZ -> Godot X,Z,-Y. Keep pose bounds in the scene for framing.
    pose_bounds={}
    for pose, b in bounds.items():
        lo,hi=b['low'],b['high']
        pose_bounds[pose]=[lo[0],lo[2],-hi[1],hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]]
    dictionary=', '.join('"%s": AABB(%s)'%(p,', '.join(f'{n:.5f}' for n in values)) for p,values in pose_bounds.items())
    text='[gd_scene load_steps=4 format=3]\n'
    text+=f'[ext_resource type="Script" path="res://art/enemies/{FAMILY}/actor.gd" id="1"]\n'
    text+=f'[ext_resource type="Material" path="res://art/enemies/{FAMILY}/fur.tres" id="2"]\n'
    text+=f'[ext_resource type="PackedScene" path="res://art/enemies/{FAMILY}/{id}.glb" id="3"]\n'
    text+='[node name="Actor" type="Node3D"]\nscript=ExtResource("1")\npalette_material=ExtResource("2")\n'
    text+=f'pose_bounds = {{{dictionary}}}\nmetadata/visual_height={height:.5f}\n'
    if id=='cave-bat':text+='held_poses=PackedStringArray("landed")\nflying=true\n'
    text+='[node name="Model" parent="." instance=ExtResource("3")]\n'
    (OUT/f'{id}.tscn').write_text(text,encoding='utf-8')
    return {'id':id,'source':source,'triangles':sum(counts.values()),'surfaces':counts,'bones':len(rig.data.bones),
            'height':height,'clips':bounds,'pose_bounds':pose_bounds,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def rat(great=False):
    master=args.sources/'build/local-rat-landmarks-v1/masters/rat-adapted.blend'
    bpy.ops.wm.open_mainfile(filepath=str(master),load_ui=False,use_scripts=False)
    rig=bpy.data.objects['Rat_Armature'];body=bpy.data.objects['Rat']
    activate(rig,bpy.data.actions['idle'],0)
    # Replace the source's disconnected flat ear islands with rooted rims.
    bm=bmesh.new();bm.from_mesh(body.data)
    visited=set();ears=[]
    for start in bm.verts:
        if start in visited:continue
        pending=[start];island=[]
        while pending:
            vertex=pending.pop()
            if vertex in visited:continue
            visited.add(vertex);island.append(vertex)
            pending.extend(edge.other_vert(vertex) for edge in vertex.link_edges)
        points=[body.matrix_world@v.co for v in island]
        if len(island)<=12 and min(p.z for p in points)>.35 and max(p.y for p in points)<-.5:ears.extend(island)
    assert len(ears)==18,'Only the two original nine-vertex ear islands are replaced'
    bmesh.ops.delete(bm,geom=ears,context='VERTS');bm.to_mesh(body.data);bm.free()
    # Subdivide the retained source surface once to round the muzzle and limb
    # silhouettes. Skin weights interpolate; source actions/bones stay intact.
    bpy.context.view_layer.objects.active=body;body.select_set(True)
    modifier=body.modifiers.new('Silhouette refinement','SUBSURF');modifier.levels=1
    bpy.ops.object.modifier_move_up(modifier=modifier.name)
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    inverse=body.matrix_world.inverted()
    for vertex in body.data.vertices:
        p=body.matrix_world@vertex.co
        original=p.copy()
        if p.y<-.46:
            amount=min(1,(-p.y-.46)/.37)
            p.y=-.46+(p.y+.46)*(1.03 if args.predatory else .82)
            p.x*=(1.18-.60*amount) if args.predatory else (1+.16*amount)
            if args.predatory:p.z=.23+(p.z-.23)*1.06
        if p.y>.20:
            amount=min(1,(p.y-.20)/.63)
            p.x=p.x*.67+.10*math.sin(amount*math.pi*.9)
            p.z=.285+(p.z-.285)*.66-.21*amount+.018*math.sin(amount*math.pi)
        if p.z<.065 and abs(p.x)>.14:p.x=math.copysign(.21+(abs(p.x)-.21)*.62,p.x)
        if args.predatory:
            leg_weight=sum(g.weight for g in vertex.groups if body.vertex_groups[g.group].name.startswith('base') and body.vertex_groups[g.group].name!='base')
            p.x*=1-.30*min(1,leg_weight)
            if original.y>-.46:p.z=.06+(p.z-.06)*(.74 if great else .83)
            if great and -.38<original.y<.20:
                weight=math.exp(-((original.y+.17)/.25)**2)
                p.x*=1+.18*weight
        elif great and -.35<original.y<.23:
            weight=math.exp(-((original.y+.12)/.24)**2)
            p.x*=1+.17*weight;p.z+=.048*weight*min(1,max(0,(p.z-.12)/.20))
        vertex.co=inverse@p
    body.data.validate(clean_customdata=False)
    body.data.materials.clear()
    tags=[]
    for face in body.data.polygons:
        p=body.matrix_world@face.center
        points=[body.matrix_world@body.data.vertices[i].co for i in face.vertices]
        p=sum(points,Vector())/len(points)
        # Ears, tail and paw undersides get a separate skin response.
        skin=(p.y>.24 or (not args.predatory and p.y<-.43 and p.z>.365) or p.z<.055)
        tags.append('skin_dark' if skin else ('hide_dark' if great else 'hide'))
    paint(body,tags,body=True,great=great)
    head_surface=None
    if args.predatory:
        body.data.update();bpy.context.view_layer.update()
        evaluated=body.evaluated_get(bpy.context.evaluated_depsgraph_get());skin=evaluated.to_mesh()
        head_surface=BVHTree.FromPolygons([evaluated.matrix_world@v.co for v in skin.vertices],[list(p.vertices) for p in skin.polygons])
        evaluated.to_mesh_clear()
    details=Mesh()
    # Short rounded nose and paired whisker pads, replacing the pointed wedge.
    snout=-.842 if args.predatory else -.744
    details.stone((0,snout,.242 if args.predatory else .244),(.019 if args.predatory else .026,.018 if args.predatory else .020,.016 if args.predatory else .020),'head','nose',sides=8 if args.predatory else 10)
    for sign,side in [(-1,'R'),(1,'L')]:
        details.stone((sign*.024,-.785 if args.predatory else -.702,.240),(.024 if args.predatory else .028,.032,.019),'head','hide',sides=8 if args.predatory else 9)
        if args.predatory:
            origin=Vector((sign*.098,-1.8,.85))
            direction=(Vector((sign*.098,-.61,.29))-origin).normalized()
            hit,normal,_,_=head_surface.ray_cast(origin,direction)
            assert hit is not None,'Visible eyes must sit on the actual posed head surface'
            centre=hit-direction*.018
            details.stone(centre,(.024,.017,.014),'head','nose',sides=7)
            iris=centre-direction*.017
            details.stone(iris,(.014,.010,.008),'head','eye',sides=7)
            details.stone(iris-direction*.009+Vector((sign*.003,0,.002)),(.002,.0015,.0015),'head','ivory',sides=5)
            # Round, smaller ears rooted behind the eyes, never upright rabbit paddles.
            details.stone((sign*.124,-.470,.365),(.046,.017,.046),'head','hide_dark',sides=8)
            details.stone((sign*.124,-.486,.365),(.030,.005,.030),'head','skin_dark',sides=7)
        else:
            details.stone((sign*.096,-.584,.313),(.012,.009,.011),'head','eye',sides=10)
            details.stone((sign*.098,-.591,.318),(.002,.0015,.002),'head','ivory',sides=6)
            details.stone((sign*.13,-.525,.365),(.064,.018,.084),'head','hide_dark',sides=11)
            details.stone((sign*.13,-.544,.365),(.042,.006,.057),'head','skin_dark',sides=10)
        # Small incisors remain attached to their real jaw/head bones.
        for x in [sign*(.024 if great and args.predatory else .011)]:
            if args.predatory:
                details.segment((x,-.835,.224),(x,-.852,.174 if great else .198),[(0,.012 if great else .008),(1,.006)],'head','ivory',sides=6)
                details.segment((x,-.846,.183),(x,-.858,.215),[(0,.010 if great else .007),(1,.004)],'mouth','ivory',sides=6)
            else:
                details.segment((x,-.756,.224),(x,-.769,.200),[(0,.008),(1,.006)],'head','ivory',sides=6)
                details.segment((x,-.766,.190),(x,-.774,.207),[(0,.007),(1,.004)],'mouth','ivory',sides=6)
        for y,z,bone in [(-.365,.023,'base.001_'+side+'.001'),(-.025,.031,'base_'+side+'.001')]:
            foot_x=sign*(.148 if args.predatory else .211)
            details.stone((foot_x,y-.026,z),(.037,.054,.016),bone,'skin_dark',sides=8)
            for toe in [-1,0,1]:
                at=(foot_x+toe*.020,y-.061,z-.002)
                tip=(at[0]+toe*.004,at[1]-.035,z-.007)
                details.segment(at,tip,[(0,.011),(1,.007)],bone,'skin',sides=6)
                details.segment(tip,(tip[0],tip[1]-.014,tip[2]-.001),[(0,.006),(1,.001)],bone,'claw',sides=5)
    if args.predatory:
        for i in range(7 if great else 4):
            y=-.32+i*.065;z=.33+.018*math.sin(i*.4)
            for sign in [-1,1]:
                x=sign*(.04 if great else .028)
                details.add([(x-.026,y-.04,z),(x+.026,y-.04,z),
                    (x+sign*.025,y+.065,z+(.065 if great else .04)),(x,y+.04,z-.012)],
                    [(0,1,2),(1,3,2),(3,0,2)],['hide','hide_light','hide_dark'],'spine')
    elif great:
        # Low overlapping tapered bristle fans follow the spine; no stones.
        for i in range(7):
            y=-.27+i*.066;z=.43+.045*math.sin(i*.43)
            for sign in [-1,1]:
                x=sign*(.02+.008*(i%2))
                details.add([(x-.022,y-.04,z),(x+.022,y-.04,z),(x+sign*.014,y+.052,z+.028),
                             (x,y+.035,z-.015)],[(0,1,2),(1,3,2),(3,0,2)],'hide_dark','spine')
    additions=part_object(details,rig,'Features',None)
    # Shared surface slots batch the source hide and fitted features into
    # three skinned draws, instead of duplicating fur/skin draw calls.
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True);additions.select_set(True);bpy.context.view_layer.objects.active=body
    bpy.ops.object.join()
    meshes=[body]
    if great:
        rig.parent.scale.x*=1.30;rig.parent.scale.y*=1.0 if args.predatory else 1.03;rig.parent.scale.z*=1.30
    return export('great-rat' if great else 'rat',rig,meshes,
        {'author':'br-n518','licence':'CC0-1.0','retained_originals':'art/third-party/oga-rat-v1','master_sha256':hashlib.sha256(master.read_bytes()).hexdigest()},21)

def bat():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    joints=[('root',(0,0,0),None),('head',(0,-.09,1.08),'root'),('jaw',(0,-.18,1.04),'head')]
    fur,skin,wings,detail=Mesh(),Mesh(),Mesh(),Mesh()
    fur.stone((0,.045,1.04),(.105,.17,.125),'root','hide_dark',sides=10)
    fur.stone((0,-.10,1.10),(.084,.082,.079),'head','hide',sides=10)
    skin.stone((0,-.176,1.07),(.047,.043,.033),'head','skin_dark',sides=9)
    detail.panel([(-.021,1.075),(0,1.118),(.021,1.075),(0,1.067)],-.207,.012,'head','nose','skin_dark')
    skin.stone((0,-.187,1.043),(.038,.037,.012),'jaw','skin_dark',sides=8)
    for sign,side in [(-1,'R'),(1,'L')]:
        joints.extend([(f'wing_{side}',(sign*.07,.015,1.07),'root'),
                       (f'elbow_{side}',(sign*.26,-.09,1.14),f'wing_{side}'),
                       (f'wrist_{side}',(sign*.45,-.13,1.16),f'elbow_{side}'),
                       (f'finger_{side}',(sign*.56,.01,1.10),f'wrist_{side}'),
                       (f'foot_{side}',(sign*.06,.12,.93),'root')])
        # Thin folded ears with a recessed inner surface, rather than cones.
        outline=[(.025,1.145),(.036,1.245),(.065,1.30),(.091,1.247),(.083,1.15)]
        skin.panel([(sign*x,z) for x,z in outline],-.105,.018,'head','skin','skin_dark')
        detail.stone((sign*.049,-.169,1.112),(.008,.006,.008),'head','eye',sides=8)
        detail.stone((sign*.051,-.175,1.115),(.0015,.001,.0015),'head','ivory',sides=5)
        fur.segment((sign*.025,-.165,1.13),(sign*.068,-.146,1.132),[(0,.012),(1,.006)],'head','hide_dark',sides=7)
        detail.segment((sign*.022,-.205,1.059),(sign*.023,-.212,1.035),[(0,.006),(1,.001)],'head','ivory',sides=5)
        skin.segment((sign*.06,.125,.955),(sign*.066,.15,.884),[(0,.020),(1,.012)],f'foot_{side}','skin_dark',sides=7)
        for toe in [-1,0,1]:
            x=sign*.064+toe*.012
            detail.segment((x,.145,.887),(x,.108,.877),[(0,.006),(1,.004)],f'foot_{side}','claw',sides=5)
        # Bowed membrane with distinct forearm/wrist and finger fans. The
        # leading edge rises and the trailing edge cups below the body line.
        xs=[.07,.26,.45,.62,.80]
        front=[.015,-.09,-.13,-.08,.015];back=[.16,.30,.37,.28,.035]
        top=[1.07,1.14,1.16,1.14,1.09];bottom=[1.00,.955,.94,.97,1.065]
        for i in range(4):
            bone=f'wing_{side}' if i==0 else (f'elbow_{side}' if i==1 else (f'wrist_{side}' if i==2 else f'finger_{side}'))
            vertices=[]
            for station in [i,i+1]:
                for chord in [0,.5,1]:
                    y=front[station]*(1-chord)+back[station]*chord
                    z=top[station]*(1-chord)+bottom[station]*chord-.035*math.sin(chord*math.pi)
                    vertices.append((sign*xs[station],y,z))
            wings.add(vertices,[(0,3,4),(0,4,1),(1,4,5),(1,5,2)],'membrane' if i%2 else 'membrane_light',bone)
            skin.segment(vertices[0],vertices[3],[(0,.013),(1,.008)],bone,'skin_dark',sides=6)
            if i>0:skin.segment(vertices[0],vertices[5],[(0,.007),(1,.003)],bone,'skin_dark',sides=5)
        # Hooked thumb on the wrist provides an extra contour during landing.
        detail.segment((sign*.45,-.13,1.16),(sign*.46,-.18,1.20),[(0,.010),(1,.006)],f'wrist_{side}','claw',sides=6)
        detail.segment((sign*.46,-.18,1.20),(sign*.45,-.20,1.18),[(0,.006),(1,.001)],f'wrist_{side}','claw',sides=5)
    rig=armature(joints)
    meshes=[part_object(part,rig,name,None) for part,name in [(fur,'Fur'),(skin,'Skin'),(wings,'Membrane'),(detail,'Details')]]
    membrane=meshes[2]
    membrane.vertex_groups.clear()
    # Shared station weights keep duplicate colour-boundary vertices together
    # during folding; the membrane is continuous across elbow and wrist seams.
    for vertex in membrane.data.vertices:
        side='L' if vertex.co.x>0 else 'R'
        station=min(range(5),key=lambda i:abs(abs(vertex.co.x)-[.07,.26,.45,.62,.80][i]))
        names=[[f'wing_{side}'],[f'wing_{side}',f'elbow_{side}'],[f'elbow_{side}',f'wrist_{side}'],[f'wrist_{side}',f'finger_{side}'],[f'finger_{side}']][station]
        for name in names:
            group=membrane.vertex_groups.get(name) or membrane.vertex_groups.new(name=name)
            group.add([vertex.index],1/len(names),'REPLACE')
    for pose,length in [('idle',24),('attack',18),('hurt',12),('hurt-ground',12),('fall',24),('fall-ground',24),('landed',24),('swoop',18),('bite',18)]:
        action=bpy.data.actions.new(pose);action.use_fake_user=True;rig.animation_data.action=action
        for frame in range(length+1):
            t=frame/length;beat=math.sin(math.tau*t);impact=math.sin(math.pi*t)**2
            grounded=pose in ['landed','bite','hurt-ground','fall-ground']
            landing=(max(0,(t-.48)/.52)**2*(3-2*max(0,(t-.48)/.52))) if pose=='swoop' else (1 if grounded else 0)
            rig.location=(0,-.15*impact if pose in ['swoop','bite'] else 0,
                          -.90 if grounded else (-.88*t if pose=='fall' else (-.90*(t*t*(3-2*t)) if pose=='swoop' else .02*beat)))
            rig.rotation_mode='QUATERNION';rig.rotation_quaternion=Quaternion((0,1,0),math.radians(58*t if pose in ['fall','fall-ground'] else 0))
            for b in rig.pose.bones:b.rotation_mode='QUATERNION';b.rotation_quaternion=Quaternion();b.location=(0,0,0)
            for sign,side in [(-1,'R'),(1,'L')]:
                def turn(name,x=0,y=0,z=0):
                    basis=rig.data.bones[name].matrix_local.to_3x3()
                    world=Euler(tuple(math.radians(v) for v in (x,y,z)),'XYZ').to_matrix()
                    rig.pose.bones[name].rotation_quaternion=(basis.inverted()@world@basis).to_quaternion()
                fold=26*impact if pose in ['swoop','attack'] else 0
                def mixed(name,air,ground):turn(name,*(a*(1-landing)+b*landing for a,b in zip(air,ground)))
                mixed(f'wing_{side}',(-10,sign*(-7+29*beat),sign*fold),(12,sign*9,sign*(40 if args.predatory else 66)))
                mixed(f'elbow_{side}',(3,sign*(-12*math.sin(math.tau*t-.35)),sign*fold*.5),(-12,sign*8,sign*(22 if args.predatory else 48)))
                mixed(f'wrist_{side}',(-6,sign*(9*math.sin(math.tau*t-.55)),sign*fold*.35),(10,sign*-10,sign*(18 if args.predatory else 43)))
                mixed(f'finger_{side}',(0,sign*6*beat,0),(0,0,sign*(12 if args.predatory else 26)))
            rig.pose.bones['head'].rotation_quaternion=Quaternion((1,0,0),math.radians(9*impact if pose in ['attack','bite','swoop'] else 2*beat))
            rig.pose.bones['jaw'].rotation_quaternion=Quaternion((1,0,0),math.radians(27*impact if pose in ['attack','bite','swoop'] else 1.5))
            if pose in ['hurt','hurt-ground']:rig.pose.bones['root'].rotation_quaternion=Quaternion((0,1,0),math.radians(12*impact))
            for obj in [rig,*rig.pose.bones]:
                for channel in ['location','rotation_quaternion','scale']:obj.keyframe_insert(channel,frame=frame)
    return export('cave-bat',rig,meshes,{'author':'Depths original','licence':'project original','adaptation':'Reuses the original bat role/clip API and metric conventions; newly articulated wings, head, jaw and feet.'},13)

def whisker_details():
    # The old leader's ear patch and high mane no longer fit this silhouette.
    # Keep her identifying uneven whiskers/scars, fitted to the new muzzle;
    # the ash-tinted base already supplies the low bristle mane.
    sys.path.insert(0,str(ROOT/'tools/elite_art'))
    import build_models as leaders
    def fitted(mesh):
        for side in (-1,1):
            for i in range(4):
                leaders.segment(mesh,(side*.045,.315+i*.008,.81 if args.predatory else .735),
                    (side*(.30+.035*(i%2)),.28+i*.034,(.90 if args.predatory else .81)-i*.042),
                    .0025,'head','ivory',tip=.0008,sides=4)
        for i in range(3):
            leaders.segment(mesh,(-.075+i*.018,.345,.78 if args.predatory else .704),
                (-.061+i*.018,.322,.81 if args.predatory else .735),.003,'head','skin_shadow',tip=.0015)
    leaders.whisker=fitted;leaders.OUT=OUT
    record=leaders.export('whisker',WORK/'masters')
    record['source_model']=FAMILY+'/great-rat'
    record['source_sha256']=hashlib.sha256((OUT/'great-rat.glb').read_bytes()).hexdigest()
    record['adaptation']='Retained uneven whiskers and scars fitted to the revised muzzle; base bristles replace the high mane; detached old ear patch removed.'
    return record

catalog=[rat(),rat(True)]
if args.predatory:
    # Approved flying bat geometry/colours stay byte-equivalent; only the
    # grounded fold and landing blend are revised in this sibling library.
    COLOURS.update(hide='614c40',hide_light='806651',hide_dark='44372f',eye='11110f',ivory='bba786')
catalog.append(bat())
(OUT/'catalog.json').write_text(json.dumps({'assets':catalog},indent=2)+'\n')
(OUT/'whisker-catalog.json').write_text(json.dumps(whisker_details(),indent=2)+'\n')
print('REFINED_CREATURES',json.dumps([{k:a[k] for k in ['id','triangles','bones','height']} for a in catalog]),flush=True)
