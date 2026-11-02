"""Real garment fit renders from editable local masters, including source clips."""
import bpy,sys,math,json,hashlib
from pathlib import Path
from mathutils import Vector
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).parent))
from capture_review import aim,area
from wardrobe_visibility import set_pieces,PIECES
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1/garments-v1';REVIEW=OUT/'review'
def setup():
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=12;scene.cycles.use_denoising=True
    scene.render.resolution_x=420;scene.render.resolution_y=560;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
    world=bpy.data.worlds.new('Garment review');scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.10,.12,.14,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45
    area('Review key',(-3,-6,7),800,5);area('Review fill',(4,-2,5),550,5);area('Review rim',(0,4,6),700,4)
    camera=bpy.data.cameras.new('Garment camera');o=bpy.data.objects.new('Garment camera',camera);scene.collection.objects.link(o);scene.camera=o;camera.type='ORTHO';scene.view_settings.view_transform='AgX'
    return o
def frame_camera(camera,angle,boots_only=False):
    deps=bpy.context.evaluated_depsgraph_get();points=[]
    for obj in bpy.context.scene.objects:
        if obj.type!='MESH' or obj.hide_render or obj.get('review_helper'):continue
        if boots_only and not obj.get('piece','').startswith('boot.'):continue
        ev=obj.evaluated_get(deps);mesh=ev.to_mesh();points.extend(ev.matrix_world@v.co for v in mesh.vertices);ev.to_mesh_clear()
    low=Vector(tuple(min(p[i] for p in points) for i in range(3)));high=Vector(tuple(max(p[i] for p in points) for i in range(3)));center=(low+high)/2
    direction={'front':Vector((0,-10,0)),'side':Vector((10,0,0)),'back':Vector((0,10,0)),'quarter':Vector((6,-8,2.5))}[angle]
    if boots_only:direction.z=1.5
    camera.location=center+direction;aim(camera,center);bpy.context.view_layer.update();inv=camera.matrix_world.inverted();projected=[inv@p for p in points]
    width=max(p.x for p in projected)-min(p.x for p in projected);height=max(p.y for p in projected)-min(p.y for p in projected);camera.data.ortho_scale=max(1.1 if boots_only else 4.8,height*1.15,width*560/420*1.15)
def main():
    REVIEW.mkdir(exist_ok=True);captures=[];masters={}
    quick='--quick' in sys.argv
    matrix='--matrix' in sys.argv
    for fit in ['female','male']:
        manifest=json.loads((OUT/(fit+'-manifest.json')).read_text());masters[fit]=hashlib.sha256((OUT/manifest['master']).read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(OUT/manifest['master']),load_ui=False,use_scripts=False)
        rig=bpy.data.objects['rig.'+fit+'.v1'];original=rig.animation_data.action;camera=setup()
        modes=[('rest',None,1),('idle','idle',120.5),('walk','walk',20.5),('sit_down','sit_down',68.5),('seated','seated',300.5),('dying',None,131.5)]
        expanded=[]
        for mode,clip,frame in modes:
            if matrix and mode!='rest':
                info=next(m for m in manifest['motions'] if m['id']==clip) if clip else {'frames':[1,261]}
                first,last=info['frames']
                for sample,time in [('start',first),('middle',(first+last)/2+.5),('end',last)]:expanded.append((mode,clip,time,sample))
            else:expanded.append((mode,clip,frame,'selected'))
        for mode,clip,frame,sample in expanded:
            if mode=='rest':rig.data.pose_position='REST'
            else:
                action=bpy.data.actions[next(m['action'] for m in manifest['motions'] if m['id']==clip)] if clip else original
                rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0];rig.data.pose_position='POSE'
            bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update()
            angles=['front','side','back'] if not quick or mode=='rest' else ['quarter']
            for angle in angles:
                frame_camera(camera,angle);file=fit+'-'+mode+('-'+sample if matrix and mode!='rest' else '')+'-'+angle+'.png';bpy.context.scene.render.filepath=str(REVIEW/file);bpy.ops.render.render(write_still=True)
                captures.append({'fit':fit,'mode':mode,'sample':sample,'angle':angle,'frame':frame,'file':file});print('GARMENT_CAPTURE',file,flush=True)
        if '--motion' in sys.argv:
            info=next(m for m in manifest['motions'] if m['id']=='walk');action=bpy.data.actions[info['action']];rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0];rig.data.pose_position='POSE'
            for i in range(12):
                frame=info['frames'][0]+(info['frames'][1]-info['frames'][0])*i/12;bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update();frame_camera(camera,'quarter');file=fit+'-walk-motion-'+str(i).zfill(2)+'.png';bpy.context.scene.render.filepath=str(REVIEW/file);bpy.ops.render.render(write_still=True);captures.append({'fit':fit,'mode':'walk-motion','sample':i,'angle':'quarter','frame':frame,'file':file})
        # Real removal/overlap examples. Coverage is recomputed, not painted out.
        rig.data.pose_position='REST';bpy.context.scene.frame_set(1)
        for name,pieces in [('tunic-only',{'tunic','belt'}),('trousers-only',{'trousers'}),('boots-only',{'boot.left','boot.right'}),('all-off',set()),('one-boot',{'trousers','boot.left'})]:
            set_pieces(fit,pieces);frame_camera(camera,'front');file=fit+'-'+name+'.png';bpy.context.scene.render.filepath=str(REVIEW/file);bpy.ops.render.render(write_still=True);captures.append({'fit':fit,'mode':name,'sample':'visibility','angle':'front','frame':1,'file':file})
        set_pieces(fit,PIECES)
        # Common raw-rest sole plane, no source pose/root edits to force contact.
        deps=bpy.context.evaluated_depsgraph_get();soles=[o for o in bpy.context.scene.objects if 'detail.sole' in o.name]
        floor_z=min((o.evaluated_get(deps).matrix_world@v.co).z for o in soles for v in o.evaluated_get(deps).data.vertices)-.002
        bpy.ops.mesh.primitive_plane_add(size=8,location=(0,0,floor_z));floor=bpy.context.object;floor['review_helper']=True
        material=bpy.data.materials.new('Review floor only');material.diffuse_color=(.10,.12,.12,1);floor.data.materials.append(material)
        for mode,clip,frame in [('boots-rest',None,1),('boots-walk','walk',20.5)]:
            if clip:
                action=bpy.data.actions[next(m['action'] for m in manifest['motions'] if m['id']==clip)];rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0];rig.data.pose_position='POSE'
            bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update()
            for angle in ['front','side']:
                frame_camera(camera,angle,True);file=fit+'-'+mode+'-'+angle+'.png';bpy.context.scene.render.filepath=str(REVIEW/file);bpy.ops.render.render(write_still=True);captures.append({'fit':fit,'mode':mode,'sample':'sole/cuff','angle':angle,'frame':frame,'reference_floor_z':floor_z,'file':file})
    (REVIEW/'captures.json').write_text(json.dumps({'captures':captures,'masters_sha256':masters,'actual_blender_renders':True,'body_or_face_repainted':False},indent=2)+'\n',encoding='utf-8')
if __name__=='__main__':main()
