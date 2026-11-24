"""Static, floor-contact poses made from public Depths figure geometry."""
import math
import bmesh
import bpy
from mathutils import Matrix, Vector
from mesh_parts import Mesh
from party import make_hero


def build(prone, palette, geometry, _worked):
    rig, source = make_hero('recruit', palette, lambda *_: None)
    names = list(palette)
    colours = {'skin_warm':'body_skin','skin_high':'body_skin_light','skin_shadow':'body_skin_dark',
               'hair':'body_hair','hair_high':'body_hair_light','brass':'body_buckle','brass_dark':'body_buckle',
               'moss':'body_hood' if prone else 'body_leather',
               'moss_light':'body_hood_light' if prone else 'body_leather_light',
               'deep_olive':'body_hood','linen':'body_linen','linen_dark':'body_cloth',
               'leather':'body_leather','leather_light':'body_leather_light'}
    retained=[]
    for index, obj in enumerate(source[:2]):
        # Retain the sewn torso, belt and head; replace the standing limbs with
        # relaxed, independently authored contact poses. No deformed idle rig.
        bm=bmesh.new();bm.from_mesh(obj.data)
        weights=bm.verts.layers.deform.active;uv=bm.loops.layers.uv.active
        allowed={group.index for group in obj.vertex_groups if group.name in ('spine','root')}
        bags=set()
        if index==0:
            unseen=set(bm.verts)
            while unseen:
                first=unseen.pop();component={first};todo=[first]
                while todo:
                    current=todo.pop()
                    for edge in current.link_edges:
                        other=edge.other_vert(current)
                        if other in unseen:unseen.remove(other);component.add(other);todo.append(other)
                points=[v.co for v in component]
                if min(p.y for p in points)>.01 and max(p.y for p in points)>.20 and min(p.z for p in points)>.91:
                    bags.update(component)
        remove=[]
        for face in bm.faces:
            point=face.loops[0][uv].uv;key=names[int(point.y*8)*8+int(point.x*8)]
            if index==0:
                valid=all(any(group in allowed for group in vertex[weights].keys()) for vertex in face.verts)
                valid=valid and not all(v in bags for v in face.verts)
            else:
                valid=prone or key not in ('deep_olive','moss')
            if not valid:remove.append(face)
        bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(obj.data);bm.free()
        # The source armature is at rest. Work with these public rest vertices.
        obj.modifiers.clear();obj.parent=None;obj.matrix_world=Matrix.Identity(4)
        obj.data.materials.clear();indices={};uv=obj.data.uv_layers.active
        for face in obj.data.polygons:
            point=uv.data[face.loop_start].uv;key=names[int(point.y*8)*8+int(point.x*8)]
            target=colours.get(key,'body_cloth')
            if target not in indices:
                indices[target]=len(obj.data.materials);obj.data.materials.append(geometry.MATERIALS[target])
            face.material_index=indices[target]
        if not prone and index==1:
            # Turn a closed-eyed anonymous face slightly to the side.
            rotation=Matrix.Rotation(.18,4,'Z')
            centre=Vector((0,0,1.60))
            for vertex in obj.data.vertices:vertex.co=centre+rotation.to_3x3()@(vertex.co-centre)
        transform=Matrix.Rotation(-math.pi/2,4,'X')
        if prone:transform=Matrix.Rotation(math.pi,4,'Z')@Matrix.Rotation(math.pi/2,4,'X')
        for vertex in obj.data.vertices:
            p=transform@vertex.co;p.y-=1.0;vertex.co=p
        low=min(v.co.z for v in obj.data.vertices)
        for vertex in obj.data.vertices:vertex.co.z+=.025-low if index==0 else .035-low
        retained.append(obj)
    bpy.data.objects.remove(source[2],do_unlink=True)
    bpy.data.objects.remove(rig,do_unlink=True)

    parts=Mesh()
    def limb(a,b,radii,base,accent):parts.segment(a,b,radii,'static',base,accent,sides=9)
    def volume(centre,size,base,accent):parts.stone(centre,size,'static',base,accent,sides=10)
    coat='body_hood' if prone else 'body_leather'
    accent='body_hood_light' if prone else 'body_leather_light'
    arms=([((.20,.35,.19),(.36,.48,.10),(.23,.69,.070)),
           ((-.20,.35,.19),(-.36,.16,.11),(-.30,-.065,.065))] if prone else
          [((.20,.35,.19),(.36,.10,.12),(.29,-.12,.085)),
           ((-.20,.35,.19),(-.34,.13,.13),(-.19,.22,.31))])
    for shoulder,elbow,hand in arms:
        limb(shoulder,elbow,[(0,.091),(.42,.088),(1,.061)],coat,accent)
        limb(elbow,hand,[(0,.061),(.5,.056),(1,.041)],'body_leather','body_linen')
        volume(hand,(.042,.065,.035),'body_skin','body_skin_light')
    legs=([((.10,-.19,.15),(.13,-.52,.10),(.16,-.85,.073)),
           ((-.10,-.19,.15),(-.22,-.47,.12),(-.31,-.77,.075))] if prone else
          [((.10,-.19,.15),(.15,-.52,.11),(.18,-.86,.075)),
           ((-.10,-.19,.15),(-.20,-.49,.125),(-.27,-.81,.08))])
    for hip,knee,ankle in legs:
        limb(hip,knee,[(0,.093),(.45,.088),(1,.062)],'body_cloth','body_cloth_light')
        limb(knee,ankle,[(0,.063),(.3,.066),(1,.047)],'body_boot','body_leather')
        volume((ankle[0],ankle[1]-.027,ankle[2]),(.064,.109,.061),'body_boot','body_leather')
    if not prone:
        volume((0,.665,.19),(.108,.094,.057),'body_hair','body_hair_light')
    # An irregular cloth repair breaks up the clean tunic panel.
    parts.add([(-.15,.11,.342),(-.065,.12,.342),(-.07,.22,.342),(-.16,.20,.342)],
              [(0,1,2,3)],'body_cloth_light','static')
    obj=geometry.mesh_object('Relaxed limbs',parts.vertices,parts.faces,coat)
    obj.data.materials.clear();indices={}
    for face,key in zip(obj.data.polygons,parts.colours,strict=True):
        if key not in indices:indices[key]=len(obj.data.materials);obj.data.materials.append(geometry.MATERIALS[key])
        face.material_index=indices[key]
    retained.append(obj)
    # Small intrinsic yaw differences; longest floor envelope remains below 2m.
    yaw=Matrix.Rotation(.20 if prone else -.17,4,'Z')
    for obj in retained:
        for vertex in obj.data.vertices:vertex.co=yaw@vertex.co
    points=[obj.data.vertices[i].co for obj in retained for face in obj.data.polygons for i in face.vertices]
    centre=Vector(((min(p.x for p in points)+max(p.x for p in points))/2,
                   (min(p.y for p in points)+max(p.y for p in points))/2,0))
    for obj in retained:
        for vertex in obj.data.vertices:vertex.co-=centre
