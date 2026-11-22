"""#220: local, editable jacket fits on a pinned current assembly snapshot.

Run in Blender with --python-exit-code 1 before --python, then
-- --workspace E:/GitHub/Depths. All derived media stay in ignored build/.
The source rig, body, original garments and Actions are never edited.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/blender_kit'))
from build_garments import Builder, skin_digest
from prepare_masters import digest_rig
from capture_garments import setup, frame_camera


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def activate(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def solid_material(name, colour):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*colour, 1)
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*colour, 1)
    shader.inputs['Roughness'].default_value = .92
    return mat


def cloth_material(fit, hip):
    """Neutral reflectance only; procedural working shader retained in master."""
    mat = bpy.data.materials.new('jacket.canvas.working.' + fit)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    out = nodes.new('ShaderNodeOutputMaterial')
    emission = nodes.new('ShaderNodeEmission')
    links.new(emission.outputs[0], out.inputs['Surface'])
    coord = nodes.new('ShaderNodeTexCoord')
    split = nodes.new('ShaderNodeSeparateXYZ')
    links.new(coord.outputs['Object'], split.inputs[0])

    def calc(op, a, b=None):
        n = nodes.new('ShaderNodeMath'); n.operation = op
        for i, x in enumerate([a, b] if b is not None else [a]):
            if isinstance(x, (int, float)): n.inputs[i].default_value = x
            else: links.new(x, n.inputs[i])
        return n.outputs[0]

    noise = nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = 18
    noise.inputs['Detail'].default_value = 4
    links.new(coord.outputs['Object'], noise.inputs['Vector'])
    grain = nodes.new('ShaderNodeTexNoise'); grain.inputs['Scale'].default_value = 240
    links.new(coord.outputs['Object'], grain.inputs['Vector'])
    # Broad channels and broken running stitches; modest irregularity is authored.
    phase = calc('ADD', calc('MULTIPLY', split.outputs['X'], 34),
                 calc('MULTIPLY', calc('SINE', calc('MULTIPLY', split.outputs['Z'], 9)), .12))
    seam = calc('POWER', calc('ADD', calc('MULTIPLY', calc('COSINE', phase), .5), .5), 28)
    dash = calc('GREATER_THAN', calc('SINE', calc('MULTIPLY', split.outputs['Z'], 225)), .1)
    stitches = calc('MULTIPLY', seam, dash)
    variation = calc('ADD', calc('MULTIPLY', noise.outputs['Fac'], .45), .54)
    variation = calc('MULTIPLY', variation, calc('ADD', calc('MULTIPLY', grain.outputs['Fac'], .15), .85))
    variation = calc('SUBTRACT', variation, calc('MULTIPLY', seam, .20))
    variation = calc('ADD', variation, calc('MULTIPLY', stitches, .10))
    hem_dirt = calc('MAXIMUM', calc('SUBTRACT', hip + .02, split.outputs['Z']), 0)
    variation = calc('SUBTRACT', variation, calc('MULTIPLY', hem_dirt, .26))
    colour = nodes.new('ShaderNodeMixRGB'); colour.blend_type = 'MULTIPLY'; colour.inputs[0].default_value = 1
    colour.inputs[1].default_value = (.16, .148, .084, 1)
    links.new(variation, colour.inputs[2]); links.new(colour.outputs[0], emission.inputs['Color'])
    return mat


def bake_canvas(obj, material, path):
    activate(obj)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=.025)
    bpy.ops.object.mode_set(mode='OBJECT')
    image = bpy.data.images.new('jacket.canvas512.' + obj['body_fit'], width=512, height=512, alpha=False)
    target = material.node_tree.nodes.new('ShaderNodeTexImage'); target.image = image
    material.node_tree.nodes.active = target
    armature = next(m for m in obj.modifiers if m.type == 'ARMATURE')
    armature.show_render = armature.show_viewport = False
    scene = bpy.context.scene; scene.render.engine = 'CYCLES'; scene.cycles.device = 'CPU'; scene.cycles.samples = 1
    scene.render.bake.margin = 8; scene.render.bake.use_clear = True
    bpy.ops.object.bake(type='EMIT')
    armature.show_render = armature.show_viewport = True
    image.filepath_raw = str(path); image.file_format = 'PNG'; image.save(); image.pack()
    portable = solid_material('jacket.canvas.baked.' + obj['body_fit'], (.22, .20, .12))
    tex = portable.node_tree.nodes.new('ShaderNodeTexImage'); tex.image = image; tex.interpolation = 'Linear'
    portable.node_tree.links.new(tex.outputs['Color'], portable.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    obj.data.materials.clear(); obj.data.materials.append(portable)
    # Preserve procedural authoring shader as an unused editable datablock.
    material.use_fake_user = True
    return portable


def build_fit(fit, source, record, out):
    before = sha(source)
    assert before == record['master_sha256'], 'Input assembly changed; review a new snapshot first'
    bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False, use_scripts=False)
    builder = Builder(fit); rig, body = builder.rig, builder.body
    rig_hash, body_hash = digest_rig(rig), skin_digest(body, rig)
    # Action values/slots remain untouched; the original Dying is active at save.
    original = bpy.data.actions[next(m['action'] for m in record['motions'] if m['id'] == 'dying')]
    actions_before = {a.name:len(a.layers) for a in bpy.data.actions}
    hip, neck = builder.hip, builder.neck
    collection = bpy.data.collections.new('PADDED_JACKET_PRODUCTION_' + fit)
    bpy.context.scene.collection.children.link(collection)
    originals = [o for o in bpy.context.scene.objects if o.get('piece')]
    for o in originals:
        o['outfit'] = 'tunic' if o.get('piece') in ['tunic', 'belt'] else 'both'

    source_tunic = bpy.data.objects['garment.tunic.' + fit + '.v1']
    jacket = source_tunic.copy(); jacket.data = source_tunic.data.copy()
    jacket.name = 'garment.padded-jacket.' + fit + '.v2'; collection.objects.link(jacket)
    jacket['piece'] = 'tunic'; jacket['outfit'] = 'jacket'; jacket['body_fit'] = fit
    jacket['fit_id'] = fit + '-v1'  # Existing Blender coverage-helper namespace.
    jacket['base_fit_id'] = record['fit_id']
    # Clean continuous sewn panels replace the draft's fragmented body-patch
    # topology. The source tunic is retained as its own swappable garment.
    verts, faces = [], []
    height=neck.z-hip.z
    trousers=bpy.data.objects['garment.trousers.'+fit+'.v1']
    trousers.data.calc_loop_triangles()
    trouser_tree=BVHTree.FromPolygons([trousers.matrix_world@v.co for v in trousers.data.vertices],
                                    [tuple(t.vertices) for t in trousers.data.loop_triangles],all_triangles=True)
    sections=[(-.35,.54,.37,.33),(-.23,.54,.37,.33),(-.08,.51,.36,.31),
              (.10,.51,.38,.37),(.30,.50,.38,.36),(height*.35,.50,.38,.35),(height*.60,.51,.37,.33)]
    # Upper rings follow each body's chest/neck height, not one shared body scale.
    sections += [(height*.77,.50,.34,.31),(height*.94,.47,.30,.29),
                 (height+.045,.42,.25,.24),(height+.12,.195,.172,.163)]
    sections.sort(key=lambda s:s[0])
    n=32
    for row,(dz,rx,front,back) in enumerate(sections):
        for i in range(n):
            a=math.tau*i/n; z=hip.z+dz
            cy=hip.y+(neck.y-hip.y)*max(0,min(1,(dz+.1)/(neck.z-hip.z+.1)))
            p=Vector((rx*math.cos(a),cy+(front if math.sin(a)<0 else back)*math.sin(a),z))
            direction=Vector((p.x,p.y-cy,0)).normalized()
            origin=Vector((hip.x,cy,z))
            hits=[(builder.bvh.ray_cast(origin,direction,1.2)[0],.075)]
            if dz<.28:hits.append((trouser_tree.ray_cast(origin,direction,1.2)[0],.055))
            for hit,ease in hits:
                if hit and (hit-origin).length+ease>(p-origin).length:
                    p=origin+direction*((hit-origin).length+ease)
            radial=Vector((p.x,p.y-cy,0)).normalized()
            p+=radial*(.006*(.5-.5*math.cos(p.x*34))+.003*math.sin(i*2.1+row*.9))
            if row==0:p.z+=.006*math.sin(i*1.7)
            verts.append(p)
            if row and not (row<=2 and i in [0,16]):
                k=row*n+i;faces.append((k-n,k-n+(1 if i<n-1 else 1-n),k+(1 if i<n-1 else 1-n),k))
    for prefix,side in [('Left',1),('Right',-1)]:
        shoulder=builder.bone(prefix+'Arm');elbow=builder.bone(prefix+'ForeArm');wrist=builder.bone(prefix+'Hand')
        start=len(verts);count=16
        ring_count=13
        for row in range(ring_count):
            t=row/(ring_count-1)
            center=shoulder.lerp(elbow,t*2) if t<=.5 else elbow.lerp(wrist,(t-.5)*2)
            axis=(elbow-shoulder if t<=.5 else wrist-elbow).normalized()
            center-=axis*.055*(1-t)
            if row==ring_count-1:center-=axis*.014
            u=Vector((0,1,0));v=axis.cross(u).normalized()
            radius=.162-.015*t+.055*math.sin(t*math.pi)-.003*math.cos(row*2.1)
            for i in range(count):
                a=math.tau*i/count
                verts.append(center+(u*math.cos(a)+v*math.sin(a))*radius)
                if row:
                    k=start+row*count+i;d=1 if i<count-1 else 1-count
                    faces.append((k-count,k-count+d,k+d,k))
        # Closed shoulder seam overlaps the padded yoke, while cuff stays open.
        faces.append(tuple(start+i for i in reversed(range(count))))
    mesh=bpy.data.meshes.new('jacket.clean-sewn-panels.'+fit);mesh.from_pydata(verts,[],faces);mesh.update()
    bm=bmesh.new();bm.from_mesh(mesh);bm.verts.index_update();bm.normal_update()
    # Open neck/hem/split surfaces do not define a closed volume. Blender's
    # generic "outside" operation can turn the entire torso inward. Orient
    # against the known panel axis instead, including each sleeve cap.
    torso_vertices=len(sections)*n
    for face in bm.faces:
        center=face.calc_center_median()
        if all(v.index<torso_vertices for v in face.verts):
            desired=Vector((center.x,center.y-hip.y,0))
        else:
            side_index=(min(v.index for v in face.verts)-torso_vertices)//(ring_count*count)
            prefix='Left' if side_index==0 else 'Right'
            shoulder=builder.bone(prefix+'Arm');wrist=builder.bone(prefix+'Hand');axis=(wrist-shoulder).normalized()
            if len(face.verts)==count:desired=-axis
            else:desired=center-(shoulder+axis*(center-shoulder).dot(axis))
        if face.normal.dot(desired)<0:face.normal_flip()
        assert face.normal.dot(desired)>=-1e-7
    bm.to_mesh(mesh);bm.free();mesh.update()
    jacket.data=mesh
    jacket.vertex_groups.clear()
    for i,p in enumerate(verts):
        if i<len(sections)*n and hip.z+.08<p.z<hip.z+.32:
            # The waist band and belt share one intentional bind. This avoids
            # the belt sinking into padding when the torso leans or twists.
            weights={'mixamorig:Hips':.65,'mixamorig:Spine':.35}
        elif i<len(sections)*n and p.z<hip.z+.06:
            amount=max(0,min(.32,(hip.z+.06-p.z)*.65))
            weights={'mixamorig:Hips':1-amount,'mixamorig:'+('Left' if p.x>=0 else 'Right')+'UpLeg':amount}
        else:weights=builder.weights_at(p)
        for bone,value in weights.items():
            group=jacket.vertex_groups.get(bone) or jacket.vertex_groups.new(name=bone);group.add([i],value,'REPLACE')
    for m in jacket.modifiers:
        if m.type == 'SOLIDIFY': m.thickness = .027
    for p in jacket.data.polygons: p.use_smooth = True
    jacket.data.update()
    working = cloth_material(fit, hip.z)
    jacket.data.materials.clear(); jacket.data.materials.append(working)
    canvas = bake_canvas(jacket, working, out/'textures'/(fit+'-canvas512.png'))
    leather = solid_material('jacket.worn-tabs.' + fit, (.105, .065, .035))
    wood = solid_material('jacket.toggle-wood.' + fit, (.29, .19, .085))
    patch_mat = solid_material('jacket.repaired-elbow.' + fit, (.112, .089, .049))
    thread = solid_material('jacket.flax-thread.' + fit, (.32, .27, .16))

    def detail(name, verts, faces, material, thickness=0, weight=None, piece='tunic'):
        data = bpy.data.meshes.new(name); data.from_pydata(verts, [], faces); data.update()
        obj = bpy.data.objects.new(name+'.'+fit+'.v2', data); collection.objects.link(obj)
        obj.parent = rig; obj.matrix_parent_inverse = rig.matrix_world.inverted()
        obj['piece'] = piece; obj['outfit'] = 'jacket'; obj['fit_id'] = fit+'-v1'; obj['base_fit_id'] = record['fit_id']
        data.materials.append(material)
        for i, p in enumerate(verts):
            values = weight(Vector(p)) if weight else builder.weights_at(Vector(p))
            for bone, value in values.items():
                group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
                group.add([i], value, 'REPLACE')
        if thickness:
            m = obj.modifiers.new('Finished edge thickness', 'SOLIDIFY'); m.thickness = thickness; m.offset = -1; m.use_even_offset = False; m.thickness_clamp = 1
        arm = obj.modifiers.new('Same source skeleton', 'ARMATURE'); arm.object = rig
        for p in data.polygons: p.use_smooth = True
        return obj

    jacket.data.calc_loop_triangles()
    tree = BVHTree.FromPolygons([jacket.matrix_world@v.co for v in jacket.data.vertices], [tuple(t.vertices) for t in jacket.data.loop_triangles], all_triangles=True)

    def surface(x, z, front=True):
        hit, normal, _, _ = tree.ray_cast(Vector((x,-3 if front else 3,z)), Vector((0,1 if front else -1,0)), 6)
        return hit+normal*.012 if hit is not None else None

    # Front overlap follows the finished shell at each row, with no detached floating card.
    verts, faces = [], []
    for i in range(22):
        z = hip.z-.30+(neck.z-hip.z+.39)*i/21
        left = .015+.015*math.sin(i*.24)
        pair = [surface(x,z) for x in [left-.055,left+.065]]
        if any(p is None for p in pair): break
        base = len(verts); verts.extend(pair)
        if base: faces.append((base-2,base-1,base+1,base))
    detail('detail.jacket-overlap', verts, faces, canvas, .018)
    # Low collar is fitted to the actual neck envelope; open front with an overlap.
    verts, faces = [], []
    for row, dz in enumerate([.055,.115,.18]):
        for i in range(21):
            a = -math.pi*.45 + math.tau*.94*i/20
            direction = Vector((math.cos(a),math.sin(a),0))
            origin = Vector((neck.x,neck.y,neck.z-.035))
            hit = builder.bvh.ray_cast(origin,direction,.6)[0]
            radius = (hit-origin).length+.041 if hit else .22
            verts.append(Vector((neck.x+direction.x*radius,neck.y+direction.y*radius,neck.z+dz+.004*math.sin(i*1.8))))
            if row and i: k=row*21+i; faces.append((k-22,k-21,k,k-1))
    detail('detail.jacket-collar', verts, faces, canvas, .028, lambda p:{'mixamorig:Neck':.25,'mixamorig:Spine2':.75})
    # Three tapered leather straps, round wooden toggles and small flax ties.
    straps, sf, toggles, tf, ties, tif = [], [], [], [], [], []
    for k, z in enumerate([hip.z+(neck.z-hip.z)*f for f in [.30,.54,.78]]):
        for x, zz in [(-.13,z-.027),(.125,z-.021),(.125,z+.023),(-.13,z+.031)]:
            p = surface(x,zz)
            assert p is not None, 'Closure must land on cloth'
            straps.append(p+Vector((0,-.018,0)))
        sf.append(tuple(range(len(straps)-4,len(straps))))
        center = surface(.11,z)+Vector((0,-.049,0))
        for ring, dz in enumerate([-.057,.057]):
            for i in range(8):
                a=math.tau*i/8
                toggles.append(center+Vector((math.cos(a)*.018,math.sin(a)*.018,dz+.003*math.sin(i+k))))
        s=len(toggles)-16
        tf.extend([tuple(s+i for i in reversed(range(8))),tuple(s+8+i for i in range(8))])
        tf.extend((s+i,s+(i+1)%8,s+8+(i+1)%8,s+8+i) for i in range(8))
        builder.box(ties,tif,center+Vector((0,-.020,0)),Vector((.024,.006,.008)))
    detail('detail.jacket-tabs',straps,sf,leather,.014)
    detail('detail.jacket-toggles',toggles,tf,wood)
    detail('detail.jacket-toggle-ties',ties,tif,thread)
    # An asymmetric repaired elbow patch with twelve visible running stitches.
    elbow = builder.bone('LeftForeArm')
    verts, faces = [], []
    for row, dz in enumerate([-.11,0,.11]):
        for j, dx in enumerate([-.12,0,.12]):
            p=surface(elbow.x+dx,elbow.z+dz,False)
            if p is None: p=Vector((elbow.x+dx,elbow.y+.19,elbow.z+dz))
            verts.append(p+Vector((0,.005,0)))
            if row and j: k=row*3+j; faces.append((k-4,k-3,k,k-1))
    repair=detail('detail.jacket-elbow-patch',verts,faces,patch_mat,.009)
    stitch_v, stitch_f = [], []
    for i in range(12):
        a=math.tau*i/12; x=elbow.x+.105*math.cos(a); z=elbow.z+.095*math.sin(a)
        p=surface(x,z,False)
        if p is not None: builder.box(stitch_v,stitch_f,p+Vector((0,.017,0)),Vector((.012,.004,.0035)))
    detail('detail.jacket-repair-stitches',stitch_v,stitch_f,thread)
    # A jacket-specific belt clears the padding while retaining the same logical toggle.
    def shell_weights(point):
        hit,_,index,_=tree.find_nearest(point)
        ids=jacket.data.loop_triangles[index].vertices
        a,b,c=[jacket.matrix_world@jacket.data.vertices[i].co for i in ids]
        u=b-a;v=c-a;w=hit-a;den=u.dot(u)*v.dot(v)-u.dot(v)**2
        wb=(v.dot(v)*w.dot(u)-u.dot(v)*w.dot(v))/den
        wc=(u.dot(u)*w.dot(v)-u.dot(v)*w.dot(u))/den
        bary=[max(0,1-wb-wc),max(0,wb),max(0,wc)];values={}
        for i,factor in zip(ids,bary):
            for g in jacket.data.vertices[i].groups:
                name=jacket.vertex_groups[g.group].name
                if name in rig.data.bones:values[name]=values.get(name,0)+g.weight*factor
        values=dict(sorted(values.items(),key=lambda p:p[1],reverse=True)[:8]);total=sum(values.values())
        return {name:value/total for name,value in values.items() if value>1e-8}
    for obj in originals:
        if obj.get('piece') != 'belt': continue
        twin = obj.copy(); twin.data=obj.data.copy(); twin.name=obj.name.replace('.v1','.jacket-v2'); collection.objects.link(twin)
        twin['outfit']='jacket'
        twin.vertex_groups.clear()
        for v in twin.data.vertices:
            p=twin.matrix_world@v.co; d=Vector((p.x-hip.x,p.y-hip.y,0))
            if d.length:
                direction=d.normalized();origin=Vector((hip.x,hip.y,p.z))
                hit=tree.ray_cast(origin,direction,1.2)[0]
                radius=max(d.length+.035,(hit-origin).length+(.035 if 'buckle' in obj.name else .018) if hit is not None else 0)
                p=origin+direction*radius
            v.co=twin.matrix_world.inverted()@p
            for name,value in shell_weights(p).items():
                group=twin.vertex_groups.get(name) or twin.vertex_groups.new(name=name)
                group.add([v.index],value,'REPLACE')
    # Merge detail materials into one skinned object: one draw surface per material,
    # not one surface for every stitch, closure or patch.
    details=[o for o in collection.objects if o.type=='MESH' and o!=jacket and o.get('piece')=='tunic']
    for obj in details:
        activate(obj)
        for modifier in list(obj.modifiers):
            if modifier.type!='ARMATURE': bpy.ops.object.modifier_apply(modifier=modifier.name)
    activate(details[0])
    for obj in details: obj.select_set(True)
    bpy.ops.object.join(); detail_obj=bpy.context.object; detail_obj.name='detail.jacket-construction.'+fit+'.v2'
    # New collar/placket construction uses a neutral canvas swatch rather than
    # sampling unrelated islands in the shell's purpose-made UV atlas.
    detail_canvas=solid_material('jacket.edge-canvas.'+fit,(.105,.097,.054))
    for i,m in enumerate(detail_obj.data.materials):
        if m==canvas: detail_obj.data.materials[i]=detail_canvas
    for obj in originals:
        if obj.get('outfit')=='tunic': obj.hide_set(True); obj.hide_render=True
    for obj in collection.objects: obj.hide_set(False); obj.hide_render=False
    rig.animation_data.action=original; rig.animation_data.action_slot=original.slots[0]; rig.data.pose_position='REST'
    bpy.context.scene.frame_set(1); bpy.context.view_layer.update()
    assert digest_rig(rig)==rig_hash and skin_digest(body,rig)==body_hash
    assert {a.name:len(a.layers) for a in bpy.data.actions}==actions_before
    weight_checks=0
    for obj in collection.objects:
        for v in obj.data.vertices:
            weights=[g.weight for g in v.groups if obj.vertex_groups[g.group].name in rig.data.bones]
            assert weights and len(weights)<=8 and abs(sum(weights)-1)<.0001,(obj.name,v.index,weights)
            weight_checks+=1
    target=out/'editable'/(fit+'_padded-jacket.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(target),check_existing=False)
    captures=[]; camera=setup()
    for mode,angle,frame in [('rest','front',1),('rest','side',1),('rest','back',1),('idle','quarter',120.5),('idle','back',120.5),('sit_down','quarter',69.5),('seated','side',200.5)]:
        rig.data.pose_position='REST' if mode=='rest' else 'POSE'
        if mode!='rest':
            action=bpy.data.actions[next(m['action'] for m in record['motions'] if m['id']==mode)]
            rig.animation_data.action=action; rig.animation_data.action_slot=action.slots[0]
        bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1); bpy.context.view_layer.update()
        frame_camera(camera,angle); name=fit+'-'+mode+'-'+angle+'.png'
        bpy.context.scene.render.filepath=str(out/'review'/name); bpy.ops.render.render(write_still=True)
        captures.append({'fit':fit,'motion':mode,'angle':angle,'file':name})
    assert sha(source)==before
    return {'master':str(target),'master_sha256':sha(target),'source_master':str(source),'source_master_sha256':before,
            'fit_id':record['fit_id'],'rig_digest':rig_hash,'body_digest':body_hash,'weight_checks':weight_checks,
            'garments':[{'name':o.name,'piece':o['piece'],'outfit':o.get('outfit','both')} for o in originals+list(collection.objects)],
            'motions':record['motions'],'floor_y':record['floor_y'],'captures':captures}


def main():
    p=argparse.ArgumentParser(); p.add_argument('--workspace',type=Path,required=True); p.add_argument('--rebuild',action='store_true')
    p.add_argument('--source-assembly',default='assembly-v6',choices=['assembly-v5','assembly-v6'])
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    source=args.workspace/'build/local-blender-kit-v1'/args.source_assembly; out=args.workspace/'build/local-padded-jacket-v2'
    for name in ['editable','textures','review','assets']: (out/name).mkdir(parents=True,exist_ok=True)
    (out/'editable'/'.gdignore').touch()
    if (out/'construction.json').exists():
        if not args.rebuild:raise RuntimeError('Output exists; use a new version or explicitly --rebuild generated files')
        previous=json.loads((out/'construction.json').read_text())
        for r in previous['fits'].values():
            if sha(Path(r['master']))!=r['master_sha256']:raise RuntimeError('Editable master has manual changes; preserve it and choose a new output version')
    manifest=json.loads((source/'manifest.json').read_text())
    records={fit:build_fit(fit,source/record['master'],record,out) for fit,record in manifest['fits'].items()}
    (out/'construction.json').write_text(json.dumps({'fits':records,'source_assembly':str(source),'source_manifest_sha256':sha(source/'manifest.json'),'failures':[]},indent=2)+'\n')
    print('JACKET_CONSTRUCTION_READY',sum(r['weight_checks'] for r in records.values()),flush=True)


if __name__=='__main__': main()
