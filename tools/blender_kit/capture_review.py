"""Actual Blender renders of the saved masters; no generated/retouched imagery."""
import bpy,math,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1';REVIEW=OUT/'review'
def aim(o,target):o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
def area(name,location,power,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;o=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(o);o.location=location;aim(o,(0,0,1.9))
def main():
    REVIEW.mkdir(exist_ok=True);captures=[]
    for fit in ['female','male']:
        bpy.ops.wm.open_mainfile(filepath=str(OUT/(fit+'_base.blend')),load_ui=False,use_scripts=False)
        scene=bpy.context.scene;rig=bpy.data.objects['rig.'+fit+'.v1']
        scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16;scene.cycles.use_denoising=True
        scene.render.resolution_x=420;scene.render.resolution_y=560;scene.render.resolution_percentage=100
        scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
        world=bpy.data.worlds.new('Review world');scene.world=world;world.use_nodes=True
        world.node_tree.nodes['Background'].inputs[0].default_value=(.10,.12,.14,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45
        area('Review key',(-3,-6,7),750,5);area('Review fill',(4,-2,5),450,5);area('Review rim',(0,4,6),650,4)
        camera=bpy.data.cameras.new('Review camera');o=bpy.data.objects.new('Review camera',camera);scene.collection.objects.link(o);scene.camera=o;camera.type='ORTHO';camera.ortho_scale=4.9
        scene.view_settings.view_transform='AgX'
        for label,position,frame,pose in [('rest-front',(0,-10,1.95),1,'REST'),('rest-side',(10,0,1.95),1,'REST'),('rest-back',(0,10,1.95),1,'REST'),('dying-start',(6,-8,3.5),1,'POSE'),('dying-middle',(6,-8,3.5),131,'POSE'),('dying-end',(6,-8,3.5),261,'POSE')]:
            rig.data.pose_position=pose;scene.frame_set(frame);o.location=position;aim(o,(0,0,1.8))
            if pose=='POSE':
                body=bpy.data.objects['body.'+fit+'.v1'].evaluated_get(bpy.context.evaluated_depsgraph_get())
                verts=[body.matrix_world@v.co for v in body.data.vertices]
                low=Vector(tuple(min(p[i] for p in verts) for i in range(3)));high=Vector(tuple(max(p[i] for p in verts) for i in range(3)))
                center=(low+high)/2;o.location=center+Vector((6,-8,3.5));aim(o,center)
                # Fit the actual posed bounds in projected camera coordinates.
                inverse=o.matrix_world.inverted();bpy.context.view_layer.update();inverse=o.matrix_world.inverted()
                projected=[inverse@p for p in verts];width=max(p.x for p in projected)-min(p.x for p in projected);height=max(p.y for p in projected)-min(p.y for p in projected)
                camera.ortho_scale=max(4.9,height*1.2,width*560/420*1.2)
            else:camera.ortho_scale=4.9
            dest=REVIEW/(fit+'-'+label+'.png');scene.render.filepath=str(dest)
            bpy.ops.render.render(write_still=True)
            captures.append({'fit':fit,'view':label,'frame':frame,'pose':pose,'file':dest.name,'size':[420,560],'camera_follows_source_root_motion':pose=='POSE','ortho_scale':camera.ortho_scale})
            print('KIT_CAPTURE',dest.name,flush=True)
    (REVIEW/'captures.json').write_text(json.dumps({'captures':captures,'source':'Actual Cycles CPU renders from reopened .blend masters; no image generation/retouching.'},indent=2)+'\n',encoding='utf-8')
if __name__=='__main__':main()
