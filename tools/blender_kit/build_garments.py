"""#211–#213: editable source-fitted cloth/leather, never source-body edits.

Generated models, bindings, captures and exports remain in ignored local output.
"""
import bpy,bmesh,sys,json,hashlib,math,argparse
sys.dont_write_bytecode=True
from pathlib import Path
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
from mathutils.geometry import convex_hull_2d
sys.path.insert(0,str(Path(__file__).parent))
from prepare_masters import digest_rig
from retarget_for_fit import retarget,CLIPS
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';OUT=BASE/'garments-v1'

def clamp(x,a=0,b=1):return max(a,min(b,x))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def mat(name,color,rough=.85):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough
    return m
def skin_digest(body,rig):
    names=set(rig.data.bones.keys());data={'v':[list(v.co) for v in body.data.vertices],'faces':[list(p.vertices) for p in body.data.polygons],'uv':[[list(x.uv) for x in l.data] for l in body.data.uv_layers],'weights':[[(body.vertex_groups[g.group].name,g.weight) for g in v.groups if body.vertex_groups[g.group].name in names] for v in body.data.vertices]}
    return hashlib.sha256(json.dumps(data,sort_keys=True).encode()).hexdigest()

class Builder:
    def __init__(self,fit):
        self.fit=fit;self.rig=bpy.data.objects['rig.'+fit+'.v1'];self.body=bpy.data.objects['body.'+fit+'.v1'];self.rig.data.pose_position='REST';bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
        self.vertices=[self.body.matrix_world@v.co for v in self.body.data.vertices]
        self.weights=[{self.body.vertex_groups[g.group].name:g.weight for g in v.groups if g.weight>1e-8 and self.body.vertex_groups[g.group].name in self.rig.data.bones} for v in self.body.data.vertices]
        self.body.data.calc_loop_triangles();self.triangles=[tuple(t.vertices) for t in self.body.data.loop_triangles]
        self.bvh=BVHTree.FromPolygons(self.vertices,self.triangles,all_triangles=True)
        self.hip=self.bone('Hips');self.neck=self.bone('Neck');self.waist=self.hip.z+.20
        self.items=[];self.cover={};self.params={}
        if fit=='female':
            material=self.body.data.materials[0];node=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
            image=next(n.image for n in material.node_tree.nodes if n.type=='TEX_IMAGE' and n.image)
            assert min(image.pixels[3::4])>.999,'Do not force an actually transparent source texture opaque'
            for link in list(node.inputs['Alpha'].links):material.node_tree.links.remove(link)
            node.inputs['Alpha'].default_value=1
            self.params['source_body_material']={'opaque_alpha_depth_fix':True,'pixels_repainted':False,'reason':'Original source image alpha is255 everywhere. Redundant FBX alpha link caused glTF BLEND self-sorting artifacts.'}
        self.palette={'tunic':mat('cloth.tunic',(.20,.225,.155)),'trousers':mat('cloth.trousers',(.065,.079,.072)),'belt':mat('leather.belt',(.16,.095,.052)),'boots':mat('leather.boots',(.115,.065,.034)),'sole':mat('leather.sole',(.038,.029,.022)),'trim':mat('cloth.worn-edges',(.115,.135,.085)),'iron':mat('iron.buckle',(.15,.16,.145),.65)}
    def bone(self,name):return self.rig.matrix_world@self.rig.data.bones['mixamorig:'+name].head_local
    def allowed(self,index,kind):
        w=self.weights[index]
        if kind=='tunic':return sum(v for n,v in w.items() if any(s in n for s in ['Hips','Spine','Shoulder','Arm','ForeArm','Neck','Hand']))
        if kind=='trousers':return sum(v for n,v in w.items() if any(s in n for s in ['Hips','Spine','UpLeg','Leg']))
        return sum(v for n,v in w.items() if any(s in n for s in ['Leg','Foot','Toe']))
    def weights_at(self,p):
        hit,normal,index,distance=self.bvh.find_nearest(p)
        if hit is None:return {'mixamorig:Hips':1}
        tri=self.triangles[index];a,b,c=[self.vertices[v] for v in tri];v0=b-a;v1=c-a;v2=hit-a
        d00=v0.dot(v0);d01=v0.dot(v1);d11=v1.dot(v1);d20=v2.dot(v0);d21=v2.dot(v1);den=d00*d11-d01*d01
        t=(d11*d20-d01*d21)/den if abs(den)>1e-12 else 0;u=(d00*d21-d01*d20)/den if abs(den)>1e-12 else 0
        bary=[max(0,1-t-u),max(0,t),max(0,u)];total=sum(bary);result={}
        for i,bw in zip(tri,bary):
            for name,w in self.weights[i].items():result[name]=result.get(name,0)+w*bw/total
        result=dict(sorted(result.items(),key=lambda a:a[1],reverse=True)[:8]);s=sum(result.values())
        return {n:v/s for n,v in result.items() if v>1e-8}
    def mesh(self,name,verts,faces,piece,material,thickness=0,weight=None):
        data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
        o=bpy.data.objects.new(name,data);collection=bpy.data.collections['garment.'+('boots' if piece.startswith('boot.') else piece)];collection.objects.link(o)
        o['fit_id']=self.fit+'-v1';o['piece']=piece;o['weight_provenance']='Body-triangle barycentric transfer, top8 normalized; intentional hip/sole overrides documented.'
        o.parent=self.rig;o.matrix_parent_inverse=self.rig.matrix_world.inverted();o.matrix_world=Matrix.Identity(4)
        o.data.materials.append(material)
        for i,v in enumerate(verts):
            weights=weight(Vector(v)) if weight else self.weights_at(Vector(v));total=sum(weights.values())
            for bone,value in weights.items():
                group=o.vertex_groups.get(bone) or o.vertex_groups.new(name=bone);group.add([i],value/total,'REPLACE')
        if thickness:
            solid=o.modifiers.new('Editable finished thickness','SOLIDIFY');solid.thickness=thickness;solid.offset=-1;solid.use_rim=True
            # Acute split-hem corners must not grow unbounded miter spikes.
            solid.use_even_offset=False;solid.thickness_clamp=1.0
        arm=o.modifiers.new('Source rig skin','ARMATURE');arm.object=self.rig;arm.use_deform_preserve_volume=False
        self.items.append(o);return o
    def patch(self,kind,low,high,side=None):
        mesh=bpy.data.meshes.new('temporary.patch');mesh.from_pydata(self.vertices,[],[list(p.vertices) for p in self.body.data.polygons]);mesh.update()
        bm=bmesh.new();bm.from_mesh(mesh);bm.verts.ensure_lookup_table()
        remove=[]
        for face in bm.faces:
            score=sum(self.allowed(v.index,kind) for v in face.verts)/len(face.verts)
            center=face.calc_center_median()
            if score<.62 or (side is not None and center.x*side<0):remove.append(face)
        bmesh.ops.delete(bm,geom=remove,context='FACES')
        for z,normal in [(low,(0,0,1)),(high,(0,0,-1))]:
            if z is not None:bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,z),plane_no=normal,clear_inner=True,clear_outer=False,dist=1e-7)
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001)
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS');bm.normal_update()
        bpy.data.meshes.remove(mesh);return bm
    def extract(self,bm):
        bm.verts.index_update();bm.verts.ensure_lookup_table();return [v.co.copy() for v in bm.verts],[[v.index for v in f.verts] for f in bm.faces]
    def body_coverage(self,kind,low,high,side=None):
        # Keep a small underlap of source body at each open neck/cuff/waist edge.
        chosen=[]
        for i,p in enumerate(self.vertices):
            if self.allowed(i,kind)<.80:continue
            if low is not None and p.z<low+.025:continue
            if high is not None and p.z>high-.025:continue
            if side is not None and p.x*side<0:continue
            if kind=='tunic':
                hand_side='Left' if p.x>0 else 'Right';wrist=self.bone(hand_side+'Hand');forearm=self.bone(hand_side+'ForeArm');axis=(wrist-forearm).normalized()
                if abs(p.x)>abs(forearm.x)*.85 and (p-(wrist-axis*.025)).dot(axis)>-.025:continue
            chosen.append(i)
        # Mask removes a whole face when even one vertex is masked. Keep the
        # boundary's incident faces too, rather than cutting above a waist or
        # cuff merely because a long source triangle crosses the cut plane.
        candidate=set(chosen);boundary=set()
        for face in self.body.data.polygons:
            if not all(i in candidate for i in face.vertices):boundary.update(face.vertices)
        return sorted(candidate-boundary)
    def tunic(self):
        bottom=self.hip.z+.075;top=self.neck.z+.015
        bm=self.patch('tunic',bottom,top)
        # True planar wrist openings instead of weight-threshold jagged ends.
        for prefix,side in [('Left',1),('Right',-1)]:
            wrist=self.bone(prefix+'Hand');forearm=self.bone(prefix+'ForeArm');axis=(wrist-forearm).normalized();cut=wrist-axis*.025
            region_verts=[v for v in bm.verts if v.co.x*side>abs(forearm.x)*.85]
            region_set=set(region_verts);geom=region_verts+[e for e in bm.edges if all(v in region_set for v in e.verts)]+[f for f in bm.faces if all(v in region_set for v in f.verts)]
            bmesh.ops.bisect_plane(bm,geom=geom,plane_co=cut,plane_no=axis,clear_inner=False,clear_outer=True,dist=1e-7)
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS');bm.normal_update()
        bottom_verts=[v for v in bm.verts if abs(v.co.z-bottom)<1e-5]
        # Loosen the torso and sleeves as real geometry. No body recolour.
        for v in bm.verts:
            normal=v.normal.copy();v.co+=normal*(.052 if abs(v.co.x)<.55 else .042)
            if abs(v.co.x)<.48:
                v.co.x*=1.08;v.co.y*=1.10
        bottom_verts.sort(key=lambda v:math.atan2(v.co.y,v.co.x))
        if len(bottom_verts)<6:raise RuntimeError('No usable tunic hip opening')
        # Two split skirt gores, not a skin-tight crotch/romper shell.
        seam_edges=set()
        for i,a in enumerate(bottom_verts):
            b=bottom_verts[(i+1)%len(bottom_verts)]
            if a.co.x*b.co.x<=0:seam_edges.add(i)
        prior=bottom_verts
        for row,drop,flare in [(0,.09,1.03),(1,.25,1.10),(2,.43,1.13)]:
            ring=[]
            for v in bottom_verts:
                p=Vector((v.co.x*flare,v.co.y*flare,bottom-drop))
                radial=Vector((p.x,p.y,0)).normalized()
                hit,_,_,_=self.bvh.ray_cast(Vector((radial.x*2,radial.y*2,p.z)),-radial,2)
                if hit is not None:
                    # Waist-sized rings cannot clear the wider seat. Fit each
                    # gore row outside that body's actual hip/thigh envelope.
                    radius=max(Vector((p.x,p.y,0)).length,Vector((hit.x,hit.y,0)).length+.09)
                    p.x=radial.x*radius;p.y=radial.y*radius
                ring.append(bm.verts.new(p))
            for i in range(len(ring)):
                if row>0 and i in seam_edges:continue
                try:bm.faces.new((prior[i],prior[(i+1)%len(ring)],ring[(i+1)%len(ring)],ring[i]))
                except ValueError:pass
            prior=ring
        bm.normal_update();verts,faces=self.extract(bm);bm.free()
        def tunic_weights(p):
            if p.z<bottom-.03:
                t=clamp((bottom-p.z)/.43)*.38;return {'mixamorig:Hips':1-t,'mixamorig:'+('Left' if p.x>=0 else 'Right')+'UpLeg':t}
            return self.weights_at(p)
        o=self.mesh('garment.tunic.'+self.fit+'.v1',verts,faces,'tunic',self.palette['tunic'],.016,tunic_weights)
        o['design']='Loose long sleeves; modest neck; finished thickness; front/back split gores; separate belt.'
        self.cover['tunic']=self.body_coverage('tunic',bottom-.04,top)
        self.params['tunic']={'hip_opening':bottom,'hem':bottom-.43,'neck':top,'thickness':.016,'split_starts':bottom-.09}
        return o
    def trousers(self):
        low=min(self.bone('LeftFoot').z,self.bone('RightFoot').z)+.015;high=self.waist+.045
        bm=self.patch('trousers',low,high)
        cuff=max(self.bone('LeftFoot').z,self.bone('RightFoot').z)+.48
        # Actual cuff rings are required: interpolating one long knee/ankle
        # triangle leaves loose cloth piercing the boot below its opening.
        for z in [cuff-.16,cuff-.03,cuff+.04]:
            bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,z),plane_no=(0,0,1),dist=1e-7)
        bm.normal_update()
        for v in bm.verts:
            offset=.008+.037*clamp((v.co.z-(cuff-.03))/.12)
            v.co+=v.normal*offset
            if v.co.z<self.hip.z-.25:v.co.x+=(.012 if v.co.x>0 else -.012)*clamp((v.co.z-(cuff+.03))/.12)
        bm.normal_update();verts,faces=self.extract(bm);bm.free()
        def trouser_weights(p):
            source=self.weights_at(p)
            # A continuous soft gusset avoids transferring the source's abrupt
            # left/right inner-thigh ownership across tiny crotch edges.
            cross=math.exp(-((p.x/.18)**2)*2)
            vertical=clamp((p.z-(self.hip.z-.70))/.24)*clamp(((self.hip.z+.02)-p.z)/.12)
            blend=cross*vertical
            left=.5+.5*math.tanh(p.x/.16)
            target={'mixamorig:Hips':.62,'mixamorig:LeftUpLeg':.38*left,'mixamorig:RightUpLeg':.38*(1-left)}
            result={n:w*(1-blend) for n,w in source.items()}
            for n,w in target.items():result[n]=result.get(n,0)+w*blend
            return result
        o=self.mesh('garment.trousers.'+self.fit+'.v1',verts,faces,'trousers',self.palette['trousers'],.014,trouser_weights)
        o['gusset_weights']='Continuous hips/left/right upper-leg blend across the central crotch; source skin unchanged.'
        self.cover['trousers']=self.body_coverage('trousers',low-.04,high)
        self.params['trousers']={'waist':high,'ankle':low,'thickness':.014,'tunic_underlap':.17}
        return o
    def belt(self,tunic):
        tunic.data.calc_loop_triangles();tree=BVHTree.FromPolygons([v.co for v in tunic.data.vertices],[tuple(t.vertices) for t in tunic.data.loop_triangles],all_triangles=True)
        z=self.waist;center=Vector((0,.03,z));ring=[];count=20
        for i in range(count):
            angle=2*math.pi*i/count;direction=Vector((math.cos(angle),math.sin(angle),0));hit=tree.ray_cast(center,direction,2)[0]
            if hit is None:hit=Vector((direction.x*.47,center.y+direction.y*.32,z))
            ring.append(hit+direction*.024)
        verts=[Vector((p.x,p.y,z+dz)) for dz in [-.045,.045] for p in ring];faces=[(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
        o=self.mesh('garment.belt.'+self.fit+'.v1',verts,faces,'belt',self.palette['belt'],.019,lambda p:{'mixamorig:Hips':.65,'mixamorig:Spine':.35})
        # Separate simple iron frame, weighted with the belt, without a new slot.
        front=min(ring,key=lambda p:p.y);center=Vector((.10,front.y-.03,z));bv=[];bf=[]
        for x,zv,sx,sz in [(-.066,0,.012,.062),(.066,0,.012,.062),(0,-.055,.067,.012),(0,.055,.067,.012)]:
            self.box(bv,bf,center+Vector((x,0,zv)),Vector((sx,.012,sz)))
        self.mesh('detail.buckle.'+self.fit+'.v1',bv,bf,'belt',self.palette['iron'],0,lambda p:{'mixamorig:Hips':.65,'mixamorig:Spine':.35})
        self.params['belt']={'height':z,'width':.09,'separate_object':True}
        return o
    def box(self,verts,faces,center,half):
        start=len(verts)
        verts.extend(center+Vector((x*half.x,y*half.y,z*half.z)) for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)])
        faces.extend(tuple(start+i for i in f) for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    def boot(self,side):
        label='left' if side==1 else 'right';prefix='Left' if side==1 else 'Right';ankle=self.bone(prefix+'Foot');toe=self.bone(prefix+'ToeBase');high=ankle.z+.48
        bm=self.patch('boots',None,high,side)
        top=[v for v in bm.verts if abs(v.co.z-high)<1e-5]
        for v in bm.verts:v.co+=v.normal*.043
        cuff_points=[v.co.copy() for v in top]
        bm.normal_update();verts,faces=self.extract(bm);bm.free()
        boot=self.mesh('garment.boot.'+label+'.'+self.fit+'.v1',verts,faces,'boot.'+label,self.palette['boots'],.018)
        # Cuff is a deliberate flared ring. Shaft follows lower leg, not foot.
        points=cuff_points
        if len(points)<4:raise RuntimeError('Boot shaft has no usable cut ring')
        cx=sum(p.x for p in points)/len(points);cy=sum(p.y for p in points)/len(points)
        rx=max(abs(p.x-cx) for p in points)+.008;ry=max(abs(p.y-cy) for p in points)+.008
        cv=[];cf=[];n=12
        for z,scale in [(high-.045,1),(high+.035,1.06)]:
            for i in range(n):cv.append(Vector((cx+rx*scale*math.cos(i*2*math.pi/n),cy+ry*scale*math.sin(i*2*math.pi/n),z)))
        cf=[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        self.mesh('detail.cuff.'+label+'.'+self.fit+'.v1',cv,cf,'boot.'+label,self.palette['boots'],.022,lambda p:{'mixamorig:'+prefix+'Leg':1})
        # Closed low-poly sole, independently weighted through foot and toe.
        footprint=[p for p in verts if p.z<ankle.z*.60]
        hull=convex_hull_2d([Vector((p.x,p.y)) for p in footprint]);outline=[footprint[i] for i in hull]
        center=sum(outline,Vector())/len(outline);outline=[center+(p-center)*1.025 for p in outline];bottom=min(p.z for p in verts)-.028
        # A shaped upper welt overlaps the source-fitted leather arch/heel;
        # a flat slab alone can leave a visible upper/sole gap.
        sv=[Vector((p.x,p.y,bottom)) for p in outline]+[Vector((p.x,p.y,max(bottom+.065,min(p.z+.018,bottom+.11)))) for p in outline];n=len(outline)
        sf=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        def sole_weights(p):
            t=clamp((ankle.y-p.y)/max(.05,ankle.y-toe.y));return {'mixamorig:'+prefix+'Foot':1-t*.80,'mixamorig:'+prefix+'ToeBase':t*.80}
        self.mesh('detail.sole.'+label+'.'+self.fit+'.v1',sv,sf,'boot.'+label,self.palette['sole'],0,sole_weights)
        self.cover['boot.'+label]=self.body_coverage('boots',None,high,side)
        self.params['boot.'+label]={'cuff':high,'sole_bottom':bottom,'sole_thickness_range':[.065,.11],'shaft_binding':prefix+'Leg','ankle_foot_toe':'Source barycentric weights; sole transitions Foot to ToeBase.'}
        return boot
    def finish_coverage(self):
        for piece,indices in self.cover.items():
            name='cover.'+('boots.'+piece.split('.')[1] if piece.startswith('boot.') else piece)
            group=self.body.vertex_groups.get(name) or self.body.vertex_groups.new(name=name)
            if indices:group.add(indices,1,'REPLACE')
        combined=self.body.vertex_groups['cover.boots'];combined.add(sorted(set(self.cover['boot.left']+self.cover['boot.right'])),1,'REPLACE')
        visible=set(range(len(self.body.data.vertices)))-set(i for indices in self.cover.values() for i in indices)
        group=self.body.vertex_groups.new(name='coverage.keep');group.add(sorted(visible),1,'REPLACE')
        mask=self.body.modifiers.new('Reversible visible-garment coverage','MASK');mask.vertex_group=group.name
        bpy.context.view_layer.objects.active=self.body;bpy.ops.object.modifier_move_up(modifier=mask.name)
        self.body['coverage_help']='Use wardrobe_visibility.py to recompute coverage when toggling pieces; source faces are retained.'

def build(fit,with_motion=True):
    source=BASE/(fit+'_base.blend');bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
    b=Builder(fit);rig_hash=digest_rig(b.rig);skin_hash=skin_digest(b.body,b.rig)
    tunic=b.tunic();b.trousers();b.belt(tunic);b.boot(1);b.boot(-1);b.finish_coverage()
    motions=[]
    if with_motion:
        for clip,file in CLIPS.items():
            motions.append(retarget(b.rig,fit,BASE/'source/clips'/file,clip));print('GARMENT_RETARGET',fit,clip,motions[-1]['sampled_max_limb_axis_error_deg'],flush=True)
    assert digest_rig(b.rig)==rig_hash and skin_digest(b.body,b.rig)==skin_hash,'Source rig/body was changed'
    b.rig.data.pose_position='REST';bpy.context.scene.frame_set(1)
    bpy.context.scene['garment_contract']='depths-expedition-garments-v1';bpy.context.scene['source_master_sha256']=sha(source)
    path=OUT/(fit+'_garments.blend');bpy.ops.wm.save_as_mainfile(filepath=str(path),check_existing=False)
    entries=[]
    for o in b.items:
        o.data.calc_loop_triangles();entries.append({'name':o.name,'piece':o['piece'],'base_vertices':len(o.data.vertices),'base_triangles':len(o.data.loop_triangles),'materials':[m.name for m in o.data.materials],'modifiers':[m.type for m in o.modifiers]})
    return {'fit_id':fit+'-v1','master':path.name,'sha256':sha(path),'source_master':source.name,'source_master_sha256':sha(source),'source_rig_digest':rig_hash,'source_skin_digest':skin_hash,'garments':entries,'parameters':b.params,'motions':motions,'coverage':{k:len(v) for k,v in b.cover.items()},'owner_approved':False}
def main():
    p=argparse.ArgumentParser();p.add_argument('--fit',choices=['female','male','both'],default='both');p.add_argument('--no-motion',action='store_true');p.add_argument('--rebuild',action='store_true')
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    OUT.mkdir(exist_ok=True)
    fits=['female','male'] if args.fit=='both' else [args.fit]
    for fit in fits:
        if (OUT/(fit+'_garments.blend')).exists() and not args.rebuild:raise RuntimeError('Garment master exists; explicit --rebuild required, never overwrite downstream edits silently.')
        result=build(fit,not args.no_motion);(OUT/(fit+'-manifest.json')).write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('GARMENT_MASTERS_READY',fits,flush=True)
if __name__=='__main__':main()
