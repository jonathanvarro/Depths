"""#302 I: owner-approved wet-cave creatures, original geometry on shared tools.

Blender background, -- --workspace E:/GitHub/Depths. No live assignments.
Concepts approved in chat 2026-11-26. Separate editable masters stay local.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools/combat_roster'))
from mesh_parts import Mesh
from build_roster import activate, fit_floor
sys.path.insert(0,str(ROOT/'tools/creatures_3d'))
from build_early_creatures import armature
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
bpy.context.preferences.filepaths.file_preview_type='NONE'
OUT=ROOT/'art/enemies/damp-creatures-v1';WORK=args.workspace/'build/local-damp-creatures-v1'
OUT.mkdir(parents=True,exist_ok=True);(WORK/'masters').mkdir(parents=True,exist_ok=True);(WORK/'.gdignore').write_text('')
PALETTE={'ivory':'a9a497','belly':'827a71','spine':'655f62','bruise':'77636a','gill':'713d42','gill_tip':'a15b55',
 'mouth':'302b2d','eye':'29272a','tooth':'b9b19b','shell':'96988a','shell_light':'b5b5a1','joint':'65575a',
 'leech':'30282a','leech_light':'504044','leech_band':'3c3033','sucker':'6b4c50','scar':'8e7b76'}
KINDS={'gill':'Gill','gill_tip':'Gill','mouth':'Details','eye':'Details','tooth':'Details','sucker':'Details','scar':'Details',
       'shell':'Shell','shell_light':'Shell'}
MATERIALS={}
for name in ['Skin','Gill','Shell','Details']:
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    node=mat.node_tree.nodes.new('ShaderNodeVertexColor');node.layer_name='Col'
    mat.node_tree.links.new(node.outputs['Color'],mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    MATERIALS[name]=mat


def linear(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def clean():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions):bpy.data.actions.remove(action)


def curve(mesh,points,radii,bone,colour,sides=7,vertical=.9):
    """Smooth closed tube using the existing bat/creature Mesh accumulator."""
    pts=[Vector(p) for p in points];verts=[]
    for i,(p,r) in enumerate(zip(pts,radii)):
        axis=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
        a=axis.cross(Vector((0,0,1)) if abs(axis.z)<.95 else Vector((0,1,0))).normalized();b=axis.cross(a)
        for j in range(sides):
            angle=math.tau*j/sides;verts.append(p+a*r*math.cos(angle)+b*r*vertical*math.sin(angle))
    faces=[tuple(reversed(range(sides)))]
    for i in range(len(pts)-1):
        for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    faces.append(tuple(range((len(pts)-1)*sides,len(pts)*sides)))
    mesh.add(verts,faces,colour,bone)
    return list(range(len(mesh.vertices)-len(verts),len(mesh.vertices)))


def finish(mesh,rig,weights=None,biology=None):
    obj=mesh.finish('Creature',rig,PALETTE)
    obj.data.materials.clear()
    for name in MATERIALS:obj.data.materials.append(MATERIALS[name])
    attr=obj.data.color_attributes.new(name='Col',type='FLOAT_COLOR',domain='CORNER')
    uv=obj.data.uv_layers.active
    for face in obj.data.polygons:
        tag=mesh.colours[face.index];kind=KINDS.get(tag,'Skin');face.material_index=list(MATERIALS).index(kind)
        face.use_smooth=kind in ['Skin','Gill','Shell']
        rgb=[linear(int(PALETTE[tag][i:i+2],16)/255) for i in (0,2,4)]
        for loop in face.loop_indices:
            point=obj.data.vertices[obj.data.loops[loop].vertex_index].co
            # Physical local grain coordinates, broad dorsal tint only; no palette UV sampling.
            uv.data[loop].uv=(point.y,point.z)
            shade=.92+.065*math.sin(point.y*10)+.025*math.sin(point.x*31+point.z*8)
            colour=Vector(rgb)
            if biology and tag in ['ivory','belly','spine','bruise']:
                # Continuous tissue pigment, never hard racing-stripe faces.
                height=point.z/(1.52 if biology=='mother' else 1)
                width=point.x/(1.50 if biology=='mother' else 1)
                dorsal=max(0,min(.68,(height-.275)*6.0))*math.exp(-(width/.115)**2)
                mottling=(math.sin(point.y*27+math.sin(point.x*40))*.5+.5)*.045
                pigment=Vector([linear(int(PALETTE['spine'][i:i+2],16)/255) for i in (0,2,4)])
                colour=colour.lerp(pigment,dorsal+mottling)
            attr.data[loop].color=(*(c*shade for c in colour),1)
    obj.data.color_attributes.active_color=attr
    if weights:
        for index,groups in weights.items():
            for group in obj.vertex_groups:group.remove([index])
            for name,weight in groups.items():
                group=obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
                if weight>0:group.add([index],weight,'REPLACE')
    return obj


def around(pivot,rotation,delta=(0,0,0)):
    return Matrix.Translation(Vector(pivot)+Vector(delta))@rotation.to_matrix().to_4x4()@Matrix.Translation(-Vector(pivot))
def q(axis,degrees):return Quaternion(axis,math.radians(degrees))


def leg_pose(hip,knee,foot,newhip,newfoot):
    """Reach with fixed limb lengths so the independent skin caps stay joined."""
    upper=(knee-hip).length;lower=(foot-knee).length
    axis=(newfoot-newhip).normalized();distance=min((newfoot-newhip).length,upper+lower-.00001)
    newfoot=newhip+axis*distance
    along=(upper*upper-lower*lower+distance*distance)/(2*distance)
    original_axis=(foot-hip).normalized();bend=knee-hip-original_axis*(knee-hip).dot(original_axis)
    bend-=axis*bend.dot(axis);bend.normalize()
    newknee=newhip+axis*along+bend*math.sqrt(max(0,upper*upper-along*along))
    matrices=[]
    for a,b,aa,bb in [(hip,knee,newhip,newknee),(knee,foot,newknee,newfoot)]:
        matrices.append(Matrix.Translation(aa)@(b-a).rotation_difference(bb-aa).to_matrix().to_4x4()@Matrix.Translation(-a))
    return matrices[0],matrices[1],Matrix.Translation(newfoot-foot)


def newt(mother=False):
    mesh=Mesh();weights={}
    def S(p):
        x,y,z=p
        if not mother:return Vector((x,y,z))
        return Vector((x*1.50+(max(0,y-.36)*.40),y*1.22 if y<=.36 else .439+(y-.36)*.70,z*1.52))
    joints=[('root',(0,0,0),None)]
    points={'pelvis':(0,.23,.19),'mid':(0,.02,.215),'chest':(0,-.20,.23),'head':(0,-.38,.24),'jaw':(0,-.38,.17),
      'tail1':(0,.35,.16),'tail2':(0,.49,.12),'tail3':(0,.64,.075),'tail4':(0,.76,.04)}
    legdata={}
    for front in [True,False]:
        for sign,side in [(-1,'r'),(1,'l')]:
            key=('fore' if front else 'hind')+'_'+side;y=-.23 if front else .24
            hip=S((sign*.115,y,.19 if front else .16));knee=S((sign*.225,y+.055,.10));foot=S((sign*.27,y-.025,.025))
            points[key+'_upper']=hip;points[key+'_lower']=knee;points[key+'_foot']=foot
            legdata[key]=(hip,knee,foot,front,sign)
    for sign,side in [(-1,'r'),(1,'l')]:points['gill_'+side]=S((sign*.085,-.31,.265))
    for name,p in list(points.items()):
        if name not in [key+'_'+part for key in legdata for part in ['upper','lower','foot']] and not name.startswith('gill_'):points[name]=S(p)
        joints.append((name,tuple(points[name]),'root'))
    rig=armature(joints)
    # One continuous body, with station weights across the three torso controls.
    rings=[(.34,.070,.09,.15),(.25,.125,.13,.17),(.12,.16,.14,.20),(-.04,.17,.145,.22),(-.21,.14,.12,.23),(-.33,.10,.095,.24)]
    verts=[];sides=12
    for y,w,h,z in rings:
        for j in range(sides):
            a=j*math.tau/sides;verts.append(S((w*math.cos(a),y,z+h*math.sin(a))))
    faces=[tuple(reversed(range(sides)))];tags=['belly']
    for i in range(len(rings)-1):
        for j in range(sides):
            faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
            tags.append('ivory')
    faces.append(tuple(range((len(rings)-1)*sides,len(rings)*sides)));tags.append('ivory')
    start=len(mesh.vertices);mesh.add(verts,faces,tags,'mid')
    for i,(y,w,h,z) in enumerate(rings):
        if y>.10:a,b,t='pelvis','mid',max(0,min(1,(.25-y)/.25))
        else:a,b,t='mid','chest',max(0,min(1,-y/.23))
        for j in range(sides):weights[start+i*sides+j]={a:1-t,b:t}
    # A narrow tapered head and a separately opening lower jaw.
    headrings=[(-.31,.105,.070,.255),(-.41,.112,.065,.25),(-.53,.095,.047,.235),(-.63,.053,.030,.225),(-.66,.018,.024,.22)]
    hv=[]
    for y,w,h,z in headrings:
        for j in range(10):a=j*math.tau/10;hv.append(S((w*math.cos(a),y,z+h*math.sin(a))))
    hf=[tuple(reversed(range(10)))]+[(i*10+j,i*10+(j+1)%10,(i+1)*10+(j+1)%10,(i+1)*10+j) for i in range(4) for j in range(10)]+[tuple(range(40,50))]
    mesh.add(hv,hf,'ivory','head')
    mesh.stone(S((0,-.51,.174)),tuple(S((.089,.14,.020))-S((0,0,0))),'jaw','belly',sides=10)
    mesh.stone(S((0,-.53,.194)),tuple(S((.079,.117,.008))-S((0,0,0))),'head','mouth',sides=8)
    for sign in [-1,1]:
        mesh.stone(S((sign*.091,-.45,.265)),(.010,.015,.006),'head','eye',sides=6)
        for i in range(3):
            a=S((sign*(.045+i*.014),-.55+i*.028,.197));b=a+Vector((0,0,-.014 if not mother else -.020))
            mesh.segment(a,b,[(0,.005),(1,.001)],'head','tooth',sides=4)
    tail=[(.34,.15,.080),(.44,.13,.073),(.54,.105,.061),(.65,.080,.050),(.75,.060,.037),(.83,.040,.025),(.88,.024,.012),(.92,.017,.002)]
    inds=curve(mesh,[S((0,y,z)) for y,z,r in tail],[r*(1.3 if mother else 1) for y,z,r in tail],'tail1','ivory',8,.65)
    for row,(y,z,r) in enumerate(tail):
        station=min(3,max(0,(y-.35)/.17));a=int(station);b=min(3,a+1);t=station-a
        for j in range(8):weights[inds[row*8+j]]={f'tail{a+1}':1-t,f'tail{b+1}':t} if a!=b else {f'tail{a+1}':1}
    for key,(hip,knee,foot,front,sign) in legdata.items():
        mesh.segment(hip,knee,[(0,.043),(0.5,.034),(1,.026)],key+'_upper','ivory','belly',7)
        mesh.segment(knee,foot,[(0,.029),(.6,.022),(1,.017)],key+'_lower','ivory','belly',7)
        mesh.stone(foot,(.037,.043,.016),key+'_foot','belly',sides=7)
        for i in range(3):
            toe=foot+Vector(((i-1)*.022,0,0));tip=toe+Vector(((i-1)*.010,-.060,.0))
            mesh.segment(toe,tip,[(0,.007),(1,.002)],key+'_foot','ivory',sides=4)
    for sign,side in [(-1,'r'),(1,'l')]:
        for i in range(3):
            points_g=[S((sign*.085,-.31,.265)),S((sign*(.14+i*.035),-.28+i*.035,.30+i*.018)),S((sign*(.22+i*.04),-.245+i*.04,.34+i*.035))]
            curve(mesh,points_g,[.013,.009,.002],'gill_'+side,'gill',5)
            for j in range(5):
                p=points_g[0].lerp(points_g[2],.26+j*.135)
                for feather in [-1,1]:
                    length=.045*(1-j*.10)*(1.3 if mother else 1)
                    tip=p+Vector((sign*length*.40,feather*length,length*.28))
                    mesh.segment(p,tip,[(0,.0045),(1,.0008)],'gill_'+side,'gill_tip',sides=3)
    if mother:
        curve(mesh,[S((-.072,-.55,.262)),S((-.025,-.49,.304)),S((.03,-.40,.323))],[.004,.005,.002],'head','scar',5)
        # Flank parasites follow actual elliptical torso stations. One blended
        # torso transform per ring keeps them attached while she rears.
        for i in range(4):
            sign=-1 if i%2 else 1;angle=(.24 if i<2 else .72)
            parasite=[];parasite_weights=[]
            for j in range(6):
                y=-.12+i*.065+j*.022
                hi=next(k for k in range(len(rings)-1) if rings[k][0]>=y>=rings[k+1][0])
                a,b=rings[hi],rings[hi+1];t=(a[0]-y)/(a[0]-b[0])
                w=a[1]*(1-t)+b[1]*t;h=a[2]*(1-t)+b[2]*t;z=a[3]*(1-t)+b[3]*t
                parasite.append(S((sign*(w+.003)*math.cos(angle),y,z+(h+.003)*math.sin(angle))))
                if y>.10:n1,n2,t='pelvis','mid',max(0,min(1,(.25-y)/.25))
                else:n1,n2,t='mid','chest',max(0,min(1,-y/.23))
                parasite_weights.append({n1:1-t,n2:t})
            indices=curve(mesh,parasite,[.005,.012,.014,.013,.009,.003],'mid','leech',6)
            for j in range(6):
                for k in range(6):weights[indices[j*6+k]]=parasite_weights[j]
    obj=finish(mesh,rig,weights,'mother' if mother else 'newt')
    def motion(pose,t):
        trans={name:Matrix.Identity(4) for name in points}
        phase=math.sin(math.tau*t);impact=math.sin(math.pi*t)**2
        collapse=(t*t*(3-2*t)) if pose in ['fall','submerge'] else ((1-t)**2*(1+2*t) if pose=='emerge' else 0)
        flatten=1-(.88 if pose in ['submerge','emerge'] else .60)*collapse
        global_m=Matrix.Diagonal((1,1,flatten,1))
        rear=math.sin(math.pi*t)**2 if pose=='rear' else 0
        lean=around(points['pelvis'],q((1,0,0),-55*rear))
        front=lean@Matrix.Translation((0,-.10*impact if pose=='attack' else 0,.008*phase if pose=='idle' else 0))
        trans['pelvis']=Matrix.Identity(4);trans['mid']=around(points['pelvis'],q((1,0,0),-25*rear));trans['chest']=front
        trans['head']=front@around(points['head'],q((1,0,0),-6*impact if pose=='attack' else -9*rear))
        trans['jaw']=trans['head']@around(points['jaw'],q((1,0,0),28*impact if pose=='attack' else 8*rear))
        if pose=='hurt':
            for key in ['head','chest']:trans[key]=trans[key]@around(points[key],q((0,1,0),-12*impact))
        for i in range(4):trans[f'tail{i+1}']=around(points[f'tail{i+1}'],q((0,0,1),(3+i)*phase if pose in ['idle','walk','run'] else -5*impact))
        for side in ['r','l']:trans['gill_'+side]=trans['head']@around(points['gill_'+side],q((0,1,0),3*phase))
        for key,(hip,knee,foot,is_front,sign) in legdata.items():
            drive=phase*(1 if (is_front==(sign<0)) else -1) if pose in ['walk','run'] else 0
            newhip=(trans['chest'] if is_front else Matrix.Identity(4))@hip
            newfoot=foot+Vector((0,.045*drive,.025*max(0,drive)))
            if is_front and rear>0:newfoot=front@foot
            trans[key+'_upper'],trans[key+'_lower'],trans[key+'_foot']=leg_pose(hip,knee,foot,newhip,newfoot)
        return {name:global_m@matrix for name,matrix in trans.items()}
    return rig,obj,points,motion,['rear','submerge','emerge']


def crawler():
    mesh=Mesh();points={'carapace':Vector((0,0,.24)),'abdomen':Vector((0,.24,.20)),'face':Vector((0,-.20,.27))}
    legs={};claws={}
    for sign,side in [(-1,'r'),(1,'l')]:
        for i in range(3):
            key=f'leg_{side}{i}';hip=Vector((sign*.13,-.10+i*.17,.22));knee=Vector((sign*.31,-.13+i*.19,.12));foot=Vector((sign*.46,-.21+i*.21,.020))
            points[key+'a']=hip;points[key+'b']=knee;legs[key]=(hip,knee,foot,sign,i)
        for name,p in [('upper',(sign*.11,-.18,.25)),('palm',(sign*.31,-.35,.22)),('grip',(sign*.40,-.49,.23))]:points['claw_'+side+'_'+name]=Vector(p)
        claws[side]=sign
        points['feel_'+side]=Vector((sign*.073,-.20,.35))
    rig=armature([('root',(0,0,0),None)]+[(n,tuple(p),'root') for n,p in points.items()])
    mesh.stone((0,-.03,.245),(.20,.27,.135),'carapace','shell','shell_light',sides=12)
    mesh.stone((0,-.03,.14),(.16,.21,.055),'carapace','joint',sides=9)
    for i in range(4):mesh.stone((0,.22+i*.065,.20-i*.026),(.15-i*.022,.080,.072-i*.012),'abdomen','shell','joint',sides=8)
    for i in [-1,0,1]:mesh.stone((i*.071,.49,.10),(.065,.10,.020),'abdomen','shell','shell_light',sides=7)
    mesh.stone((0,-.245,.275),(.115,.08,.068),'face','shell_light',sides=9)
    for sign in [-1,1]:mesh.segment((sign*.047,-.295,.25),(sign*.013,-.33,.22),[(0,.024),(1,.009)],'face','joint',sides=5)
    for key,(hip,knee,foot,sign,i) in legs.items():
        mesh.segment(hip,knee,[(0,.025),(.5,.028),(1,.019)],key+'a','shell','joint',6)
        mesh.segment(knee,foot,[(0,.021),(.65,.016),(1,.005)],key+'b','shell','joint',6)
    for side,sign in claws.items():
        scale=1.0 if side=='r' else .60
        a=points['claw_'+side+'_upper'];p=points['claw_'+side+'_palm'];g=points['claw_'+side+'_grip']
        mesh.segment(a,p,[(0,.050*scale),(.6,.057*scale),(1,.045*scale)],'claw_'+side+'_upper','shell','joint',8)
        mesh.stone(p,(.12*scale,.145*scale,.085*scale),'claw_'+side+'_palm','shell','shell_light',sides=10)
        fixed=[p+Vector((-sign*.05*scale,-.07*scale,0)),p+Vector((-sign*.10*scale,-.22*scale,.01)),p+Vector((-sign*.015*scale,-.29*scale,0))]
        moving=[g,g+Vector((sign*.07*scale,-.15*scale,.01)),g+Vector((-sign*.05*scale,-.22*scale,0))]
        curve(mesh,fixed,[.044*scale,.031*scale,.006],'claw_'+side+'_palm','shell',7)
        curve(mesh,moving,[.038*scale,.027*scale,.005],'claw_'+side+'_grip','shell_light',7)
        base=points['feel_'+side]
        curve(mesh,[base,base+Vector((sign*.12,-.13,.18)),base+Vector((sign*.20,-.40,.10)),base+Vector((sign*.22,-.62,-.10))],[.010,.008,.005,.002],'feel_'+side,'joint',6)
    obj=finish(mesh,rig)
    def motion(pose,t):
        trans={name:Matrix.Identity(4) for name in points};phase=math.sin(math.tau*t);hit=math.sin(math.pi*t)**2
        global_m=Matrix.Diagonal((1,1,1-.58*t*t*(3-2*t) if pose=='fall' else 1,1))
        for side,sign in claws.items():
            opening=.15*hit if pose=='attack' else 0
            if pose=='grab':opening=.8*math.sin(math.pi*t)-.28*t
            if pose=='hold':opening=-.28+.018*phase
            if pose=='release':opening=-.28*(1-t)+.45*math.sin(math.pi*t)
            push=.10*hit if pose in ['attack','grab'] else (.03 if pose=='hold' else 0)
            for name in ['upper','palm','grip']:
                key='claw_'+side+'_'+name
                trans[key]=Matrix.Translation((0,-push,0))
            trans['claw_'+side+'_grip']@=around(points['claw_'+side+'_grip'],q((0,0,1),-sign*math.degrees(opening)))
            key='feel_'+side;trans[key]=around(points[key],q((0,0,1),sign*4*phase))
        for key,(hip,knee,foot,sign,i) in legs.items():
            stride=phase*(1 if (i+(sign>0))%2 else -1) if pose in ['walk','run'] else 0
            tip=foot+Vector((0,.037*stride,.025*max(0,stride)))
            trans[key+'a'],trans[key+'b'],_=leg_pose(hip,knee,foot,hip,tip)
        if pose=='hurt':trans['carapace']=around(points['carapace'],q((0,1,0),9*hit))
        return {name:global_m@matrix for name,matrix in trans.items()}
    return rig,obj,points,motion,['grab','hold','release']


def swarm():
    mesh=Mesh();points={};weights={}
    for i in range(12):
        angle=(i%6-2.5)*.34+(math.pi if i>=6 else 0)
        base=Vector((math.sin(angle)*.15,math.cos(angle)*.10,.07))
        front=Vector((math.sin(angle)*.46,-math.cos(angle)*.42,.047))
        rear=Vector((-math.sin(angle)*.19,.20+(i%3)*.025,.065))
        points[f'leech{i}a']=base;points[f'leech{i}b']=front
        pts=[];radii=[]
        for j in range(10):
            t=j/9;p=rear.lerp(front,t);p.x+=.055*math.sin(t*math.pi+i);p.z+=.075*math.sin(t*math.pi)**2
            pts.append(p);radii.append((.020+.028*math.sin(t*math.pi)**.7)*(1+.07*math.sin(j*2.8)))
        start=len(mesh.vertices);indices=curve(mesh,pts,radii,f'leech{i}a','leech',7,.82)
        # Periodic broad rings give a segmented annelid, not unbroken spaghetti.
        first_face=len(mesh.faces)-(2+(len(pts)-1)*7)
        for j in range(9):
            for k in range(7):mesh.colours[first_face+1+j*7+k]='leech_band' if j%3==0 else ('leech_light' if k in [1,2] else 'leech')
        for j in range(10):
            t=max(0,min(1,(j/9-.25)/.65))
            for k in range(7):weights[start+j*7+k]={f'leech{i}a':1-t,f'leech{i}b':t}
        # Annular mouth lies at the advancing end; dark inset is small, no teeth.
        axis=(pts[-1]-pts[-2]).normalized();a=axis.cross(Vector((0,0,1))).normalized();b=axis.cross(a)
        verts=[]
        for r,offset in [(radii[-1]*1.12,0),(radii[-1]*.52,.003)]:
            for j in range(7):ang=j*math.tau/7;verts.append(pts[-1]+axis*offset+r*(a*math.cos(ang)+b*math.sin(ang)))
        faces=[(j,(j+1)%7,(j+1)%7+7,j+7) for j in range(7)]
        mesh.add(verts,faces,'sucker',f'leech{i}b')
    rig=armature([('root',(0,0,0),None)]+[(n,tuple(p),'root') for n,p in points.items()]);obj=finish(mesh,rig,weights)
    def motion(pose,t):
        trans={};phase=math.sin(math.tau*t);hit=math.sin(math.pi*t)**2
        spread=hit if pose in ['attack','spread'] else ((1-t)*.55 if pose=='regroup' else 0)
        flatten=1-.65*t*t*(3-2*t) if pose=='fall' else 1
        global_m=Matrix.Diagonal((1,1,flatten,1))
        for i in range(12):
            a=points[f'leech{i}a'];b=points[f'leech{i}b'];direction=Vector((b.x,b.y,0)).normalized()
            wiggle=.010*math.sin(math.tau*t+i*1.1)
            trans[f'leech{i}a']=Matrix.Translation((wiggle,0,abs(wiggle)*.3))
            reach=direction*(.19*spread+(.025*phase if pose in ['walk','run'] else 0))
            if pose=='burn':reach=-direction*.14*hit;reach.z=.04*hit
            if pose=='hurt':reach=-direction*.055*hit
            trans[f'leech{i}b']=Matrix.Translation(reach+Vector((wiggle,0,.008*math.sin(math.pi*t+i)**2)))
        return {name:global_m@matrix for name,matrix in trans.items()}
    return rig,obj,points,motion,['spread','regroup','burn']


def export(ident,builder):
    clean();rig,obj,points,motion,extra=builder();bpy.context.scene.render.fps=24
    frames={'idle':48,'attack':18,'hurt':12,'fall':24,'walk':24,'run':16}
    frames.update({pose:(36 if pose=='hold' else 24) for pose in extra})
    for pose,length in frames.items():
        action=bpy.data.actions.new(pose);action.use_fake_user=True;rig.animation_data.action=action
        for frame in range(length+1):
            t=frame/length;matrices=motion(pose,t)
            rig.pose.bones['root'].matrix_basis=Matrix.Identity(4)
            for name,transform in matrices.items():
                bone=rig.pose.bones[name];bone.rotation_mode='QUATERNION'
                bone.matrix=transform@bone.bone.matrix_local
                for prop in ['location','rotation_quaternion','scale']:bone.keyframe_insert(prop,frame=frame,group=name)
        for slot in action.slots:
            for layer in action.layers:
                for strip in layer.strips:
                    bag=strip.channelbag(slot)
                    if bag:
                        for curve_f in bag.fcurves:
                            for key in curve_f.keyframe_points:key.interpolation='LINEAR'
    bounds=fit_floor(rig,[obj]);activate(rig,bpy.data.actions['idle'],0)
    for mesh in [obj]:mesh.data.calc_loop_triangles()
    triangles=len(obj.data.loop_triangles);assert triangles<=3000,(ident,triangles)
    assert len(rig.data.bones)<=25,(ident,len(rig.data.bones))
    for pose,b in bounds.items():
        assert b['high'][0]-b['low'][0]<1.99 and b['high'][1]-b['low'][1]<1.99,(ident,pose,b)
    bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'masters'/(ident+'.blend')))
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);obj.select_set(True);bpy.context.view_layer.objects.active=rig
    path=OUT/(ident+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_materials='EXPORT',
      export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_anim_slide_to_zero=True,
      export_force_sampling=True,export_optimize_animation_size=False,export_rest_position_armature=True,
      export_vertex_color='ACTIVE',export_cameras=False,export_lights=False)
    pose_bounds={}
    for pose,b in bounds.items():
        lo,hi=b['low'],b['high'];pose_bounds[pose]=[lo[0],lo[2],-hi[1],hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]]
    joins=[]
    if ident in ['pale-newt','drowned-mother']:
        for key in [n.removesuffix('_upper') for n in points if n.endswith('_upper')]:
            joins.extend([{'a':key+'_upper','b':key+'_lower'},{'a':key+'_lower','b':key+'_foot'},{'a':'chest' if key.startswith('fore') else 'pelvis','b':key+'_upper'}])
    elif ident=='blind-crawler':
        joins=[{'a':n,'b':n[:-1]+'b'} for n in points if n.startswith('leg_') and n.endswith('a')]
    return {'id':ident,'model':'res://art/enemies/damp-creatures-v1/'+ident+'.glb','triangles':triangles,'skin_joins':joins,
      'bones':len(rig.data.bones),'skinned_draws':len([s for s in MATERIALS if any(KINDS.get(c,'Skin')==s for c in PALETTE if c in PALETTE and any(p.material_index==list(MATERIALS).index(s) for p in obj.data.polygons))]),
      'clips':bounds,'pose_bounds':pose_bounds,'height':pose_bounds['idle'][4]+pose_bounds['idle'][1],
      'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'clip_fps':24,'forward':'+Z','lights':0,'collision':False}


assets=[export('pale-newt',newt),export('blind-crawler',crawler),export('leech-swarm',swarm),export('drowned-mother',lambda:newt(True))]
catalog={'issue':302,'approved':'Owner approved all four concepts for modelling in chat, 2026-11-26','assets':assets,
 'source':'Original concept-faithful geometry, reusing project Mesh, armature and sampled floor-registration/export helpers. No private model or external animation.',
 'concepts':'art/concepts/damp-creatures-v1/generation.json','masters':'build/local-damp-creatures-v1/masters',
 'free_source_audit':'Existing project free/original helpers reused. A candidate CC0 crayfish scan on Sketchfab returned 403 and was not downloaded or used; no third-party creature rights inferred from a search result.',
 'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'live_bindings_changed':False}
(OUT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('DAMP_CREATURES',[(a['id'],a['triangles'],a['bones']) for a in assets])
