"""Run with Blender --background --factory-startup --disable-autoexec --python.

Read-only source inspection. Reports stay in ignored output, never in Git.
"""
import bpy,sys,json,hashlib,math
sys.dont_write_bytecode=True
from pathlib import Path
from collections import Counter
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/local-blender-kit-v1'
def matrix(m):return [[round(float(x),9) for x in row] for row in m]
def points_bbox(points):
    p=list(points)
    return {'min':[min(v[i] for v in p) for i in range(3)],'max':[max(v[i] for v in p) for i in range(3)],'dimensions':[max(v[i] for v in p)-min(v[i] for v in p) for i in range(3)]} if p else {}
def action_report(a):
    bags=[]
    for layer in a.layers:
        for strip in layer.strips:
            for bag in getattr(strip,'channelbags',[]):
                curves=list(bag.fcurves)
                bags.append({'slot_handle':bag.slot_handle,'curves':len(curves),'keyframes':sum(len(c.keyframe_points) for c in curves),'paths':sorted(set(c.data_path for c in curves))})
    return {'name':a.name,'frame_range':list(a.frame_range),'slots':[{'identifier':s.identifier,'handle':s.handle,'type':s.target_id_type} for s in a.slots],'layers':len(a.layers),'channelbags':bags}
def scene_report():
    result={'blender':bpy.app.version_string,'fps':bpy.context.scene.render.fps,'unit_system':bpy.context.scene.unit_settings.system,'unit_scale':bpy.context.scene.unit_settings.scale_length,'objects':[],'actions':[action_report(a) for a in bpy.data.actions],'images':[{'name':i.name,'path':i.filepath,'packed':bool(i.packed_file),'size':list(i.size)} for i in bpy.data.images]}
    for o in bpy.context.scene.objects:
        e={'name':o.name,'type':o.type,'parent':o.parent.name if o.parent else None,'matrix_world':matrix(o.matrix_world),'scale':list(o.scale),'rotation_mode':o.rotation_mode}
        if o.type=='ARMATURE':
            ad=o.animation_data
            e.update({'pose_position':o.data.pose_position,'action':ad.action.name if ad and ad.action else None,'action_slot':ad.action_slot.identifier if ad and ad.action_slot else None,'bones':[{'name':b.name,'parent':b.parent.name if b.parent else None,'head':list(b.head_local),'tail':list(b.tail_local),'matrix_local':matrix(b.matrix_local),'deform':b.use_deform} for b in o.data.bones]})
        if o.type=='MESH':
            m=o.data;m.calc_loop_triangles();weights=[[(g.group,g.weight) for g in v.groups if g.weight>1e-8] for v in m.vertices]
            e.update({'vertices':len(m.vertices),'faces':len(m.polygons),'triangles':len(m.loop_triangles),'uv_layers':[l.name for l in m.uv_layers],'colour_attributes':[a.name for a in m.color_attributes],'materials':[m.name if m else None for m in m.materials],'groups':[g.name for g in o.vertex_groups],'influences':dict(Counter(str(len(w)) for w in weights)),'weight_sum_min':min((sum(w for _,w in v) for v in weights),default=0),'weight_sum_max':max((sum(w for _,w in v) for v in weights),default=0),'modifiers':[{'name':m.name,'type':m.type,'object':m.object.name if m.type=='ARMATURE' and m.object else None} for m in o.modifiers],'bind_bbox':points_bbox(o.matrix_world@v.co for v in m.vertices)})
        result['objects'].append(e)
    result['materials']=[{'name':m.name,'diffuse':list(m.diffuse_color),'nodes':[{'type':n.type,'name':n.name,'image':n.image.name if n.type=='TEX_IMAGE' and n.image else None} for n in m.node_tree.nodes] if m.node_tree else []} for m in bpy.data.materials]
    return result
def main():
    records=[]
    for p in sorted((OUT/'source').iterdir()):
        if p.suffix.lower() not in ['.fbx','.blend']:continue
        bpy.ops.wm.read_factory_settings(use_empty=True)
        if p.suffix.lower()=='.fbx':bpy.ops.import_scene.fbx(filepath=str(p),use_image_search=False,automatic_bone_orientation=False)
        else:bpy.ops.wm.open_mainfile(filepath=str(p),load_ui=False,use_scripts=False)
        record=scene_report();record.update({'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size});records.append(record)
        print('KIT_AUDIT',p.name,[(o['name'],o.get('vertices',len(o.get('bones',[])))) for o in record['objects']],[(a['name'],a['frame_range']) for a in record['actions']],flush=True)
    (OUT/'source-audit.json').write_text(json.dumps({'sources':records},indent=2)+'\n',encoding='utf-8')
if __name__=='__main__':main()
