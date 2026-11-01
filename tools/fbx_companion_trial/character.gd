extends Node3D
## Local-only source assets are prepared in ignored build/local-fbx-trial.
## Garment shell preserves the source's true bind weights; authored additions use full rig rest binds.
const DATA="res://../../build/local-fbx-trial/"
var model:Node3D
var rig:Skeleton3D
var player:AnimationPlayer
var body:MeshInstance3D
var hair:MeshInstance3D
var outfit:MeshInstance3D
var additions:MeshInstance3D
var hat:MeshInstance3D
var full_skin:Skin
var look:=0
var vertices:=PackedVector3Array()
var normals:=PackedVector3Array()
var colours:=PackedColorArray()
var ids:=PackedInt32Array()
var weights:=PackedFloat32Array()
var material_body:StandardMaterial3D
var mesh_nodes:Array[MeshInstance3D]=[]
var standing_pose:Array=[]
var seated_pose:Array=[]

func setup(appearance:int) -> void:
 look=appearance
 model=load(DATA+"imported.tscn").instantiate();model.scene_file_path="";model.name="SourceRig";add_child(model)
 rig=model.get_node("Skeleton3D");player=model.get_node("AnimationPlayer")
 rig.reset_bone_poses();rig.force_update_all_bone_transforms()
 full_skin=rig.create_skin_from_rest_transforms()
 for node in model.find_children("*","MeshInstance3D",true,false):
  var source_arrays=node.mesh.surface_get_arrays(0)
  var baked=load(DATA+str(node.name)+"-rest.res")
  var arrays=baked.surface_get_arrays(0)
  var converted_normals=arrays[Mesh.ARRAY_NORMAL]
  for i in converted_normals.size():converted_normals[i]=converted_normals[i].normalized()
  arrays[Mesh.ARRAY_NORMAL]=converted_normals
  var mapped=source_arrays[Mesh.ARRAY_BONES].duplicate()
  for i in mapped.size():mapped[i]=node.skin.get_bind_bone(mapped[i])
  arrays[Mesh.ARRAY_BONES]=mapped;arrays[Mesh.ARRAY_WEIGHTS]=source_arrays[Mesh.ARRAY_WEIGHTS]
  # Skin arrays now reference skeleton bone indices, not the source's private bind table.
  var converted=ArrayMesh.new();converted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  node.mesh=converted;node.skin=full_skin;node.custom_aabb=AABB(Vector3(-2,-.2,-1),Vector3(4,4.4,4))
  mesh_nodes.append(node)
  if node.name=="FemaleMesh":body=node
  else:hair=node
 var image=Image.load_from_file(ProjectSettings.globalize_path(DATA+"body-texture.png"))
 material_body=StandardMaterial3D.new();material_body.albedo_texture=ImageTexture.create_from_image(image);material_body.roughness=.95
 material_body.albedo_color=Color("fff0e5") if look==0 else Color("d6e2e8")
 body.material_override=material_body
 var hair_material=StandardMaterial3D.new();hair_material.albedo_color=Color("793f29") if look==0 else Color("9caaa8");hair_material.roughness=.92;hair.material_override=hair_material
 if look==1:
  var arrays=hair.mesh.surface_get_arrays(0)
  var positions=arrays[Mesh.ARRAY_VERTEX]
  for i in positions.size():
   if positions[i].y<3.30:positions[i].y=3.30+(positions[i].y-3.30)*.42
  arrays[Mesh.ARRAY_VERTEX]=positions
  var short_mesh=ArrayMesh.new();short_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);hair.mesh=short_mesh
 outfit=build_outfit_shell();additions=build_kit();hat=build_head_wrap();hat.visible=look==1
 build_animations()
 scale=Vector3.ONE*.46
 play("standing")

func bone(key:String) -> int:return rig.find_bone("mixamorig_"+key)
func begin() -> void:
 vertices=PackedVector3Array();normals=PackedVector3Array();colours=PackedColorArray();ids=PackedInt32Array();weights=PackedFloat32Array()
func influence(index:int,other:int=-1,blend:=0.0) -> Array:return [index,index if other<0 else other,1.0-blend,blend]
func triangle(a:Vector3,b:Vector3,c:Vector3,col:Color,wa:Array,wb:Array=[],wc:Array=[]) -> void:
 var n=(b-a).cross(c-a).normalized()
 if n.length_squared()<.1:return
 var all=[wa,wa if wc.is_empty() else wc,wa if wb.is_empty() else wb]
 for i in 3:
  vertices.append([a,c,b][i]);normals.append(n);colours.append(col)
  ids.append_array(PackedInt32Array([all[i][0],all[i][1],0,0]));weights.append_array(PackedFloat32Array([all[i][2],all[i][3],0,0]))
func quad(a:Vector3,b:Vector3,c:Vector3,d:Vector3,col:Color,w:Array) -> void:triangle(a,b,c,col,w);triangle(a,c,d,col,w)
func finish(label:String) -> MeshInstance3D:
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colours;arrays[Mesh.ARRAY_BONES]=ids;arrays[Mesh.ARRAY_WEIGHTS]=weights
 var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.roughness=.9;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.surface_set_material(0,mat)
 var node=MeshInstance3D.new();node.name=label;node.mesh=mesh;rig.add_child(node);node.skeleton=NodePath("..");node.skin=full_skin;node.custom_aabb=AABB(Vector3(-2,-.2,-1),Vector3(4,4.4,4));mesh_nodes.append(node);return node

func build_outfit_shell() -> MeshInstance3D:
 # Use the source body's own topology/weights for sleeve, tunic, trouser and boot fitting.
 var source=body.mesh.surface_get_arrays(0);var v=source[Mesh.ARRAY_VERTEX];var n=source[Mesh.ARRAY_NORMAL];var ix=source[Mesh.ARRAY_INDEX]
 var slots=source[Mesh.ARRAY_WEIGHTS].size()/v.size()
 var averaged={}
 for i in v.size():
  var key=v[i].snapped(Vector3.ONE*.00001)
  averaged[key]=averaged.get(key,Vector3.ZERO)+n[i]
 var out=[];out.resize(Mesh.ARRAY_MAX)
 var vs=PackedVector3Array();var ns=PackedVector3Array();var cs=PackedColorArray();var bs=PackedInt32Array();var ws=PackedFloat32Array()
 var head=bone("Head");var neck=bone("Neck")
 var exposed=PackedInt32Array()
 for start in range(0,ix.size(),3):
  var included=true;var centroid=Vector3.ZERO
  for j in 3:
   var index=ix[start+j];centroid+=v[index]/3.0
   var dominant=0.0;var dominant_bone=0
   for k in slots:
    if source[Mesh.ARRAY_WEIGHTS][index*slots+k]>dominant:dominant=source[Mesh.ARRAY_WEIGHTS][index*slots+k];dominant_bone=source[Mesh.ARRAY_BONES][index*slots+k]
   var name=rig.get_bone_name(dominant_bone)
   if dominant_bone==head or "Hand" in name:included=false
  if not included or centroid.y>3.04:
   for j in 3:exposed.append(ix[start+j])
   continue
  var cloth=Color("5d6860") if centroid.y>1.90 else Color("353b3c")
  if centroid.y<.72:cloth=Color("49362e")
  var thickness=.036 if centroid.y>1.92 else .023
  for j in 3:
   var index=ix[start+j]
   var outward=averaged[v[index].snapped(Vector3.ONE*.00001)].normalized()
   vs.append(v[index]+outward*thickness);ns.append(n[index]);cs.append(cloth)
   for k in slots:bs.append(source[Mesh.ARRAY_BONES][index*slots+k]);ws.append(source[Mesh.ARRAY_WEIGHTS][index*slots+k])
 out[Mesh.ARRAY_VERTEX]=vs;out[Mesh.ARRAY_NORMAL]=ns;out[Mesh.ARRAY_COLOR]=cs;out[Mesh.ARRAY_BONES]=bs;out[Mesh.ARRAY_WEIGHTS]=ws
 var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,out)
 var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.roughness=.95;mesh.surface_set_material(0,mat)
 var node=MeshInstance3D.new();node.name="FittedExpeditionClothes";node.mesh=mesh;node.skin=full_skin;rig.add_child(node);node.skeleton=NodePath("..");node.custom_aabb=AABB(Vector3(-2,-.2,-1),Vector3(4,4.4,4));mesh_nodes.append(node)
 var exposed_arrays=source.duplicate();exposed_arrays[Mesh.ARRAY_INDEX]=exposed
 var exposed_mesh=ArrayMesh.new();exposed_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,exposed_arrays);body.mesh=exposed_mesh
 return node

func block(center:Vector3,size:Vector3,col:Color,index:int,basis:Basis=Basis.IDENTITY) -> void:
 var ps=[]
 for p in [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,1,-1),Vector3(-1,1,-1),Vector3(-1,-1,1),Vector3(1,-1,1),Vector3(1,1,1),Vector3(-1,1,1)]:ps.append(center+basis*(p*size*.5))
 for f in [[0,1,2,3],[5,4,7,6],[4,0,3,7],[1,5,6,2],[3,2,6,7],[4,5,1,0]]:quad(ps[f[3]],ps[f[2]],ps[f[1]],ps[f[0]],col,influence(index))

func ring(sections:Array,col:Color,weight_func:Callable,segments:=12) -> void:
 for row in range(sections.size()-1):
  for j in segments:
   var ps=[];var w=[]
   for e in [[row,j],[row,j+1],[row+1,j+1],[row+1,j]]:
    var s=sections[e[0]];var theta=TAU*e[1]/segments
    var p=Vector3(sin(theta)*s[1],s[0],s[3]+cos(theta)*s[2]);ps.append(p);w.append(weight_func.call(p))
   triangle(ps[0],ps[1],ps[2],col,w[0],w[1],w[2]);triangle(ps[0],ps[2],ps[3],col,w[0],w[2],w[3])

func build_kit() -> MeshInstance3D:
 begin();var hips=bone("Hips");var spine=bone("Spine1");var chest=bone("Spine2");var neck=bone("Neck")
 # Leather belt, brass clasp, two distinct field pouches.
 ring([[2.05,.45,.31,-.025],[2.13,.44,.30,-.027]],Color("45342b"),func(_p):return influence(hips))
 block(Vector3(0,2.09,.298),Vector3(.10,.067,.025),Color("b4995f"),hips)
 block(Vector3(0,2.09,.315),Vector3(.060,.035,.013),Color("45342b"),hips)
 for side in [-1.0,1.0]:
  block(Vector3(side*.43,1.98,.065),Vector3(.16,.22,.13),Color("5a4433"),hips,Basis(Vector3.UP,side*.35))
  block(Vector3(side*.43,2.07,.131),Vector3(.15,.055,.025),Color("6b523c"),hips,Basis(Vector3.UP,side*.35))
 # Two split tunic tails move with separate thighs, leaving a seated lap opening.
 for side in [-1.0,1.0]:
  var thigh=bone("LeftUpLeg" if side>0 else "RightUpLeg")
  for front in [true,false]:
   var z=1.0 if front else -1.0
   var a=Vector3(side*.025,2.05,z*.235-.025);var b=Vector3(side*.35,2.05,z*.13-.025)
   var c=Vector3(side*.39,1.63,z*.19-.025);var d=Vector3(side*.045,1.65,z*.27-.025)
   triangle(a,b,c,Color("5d6860"),influence(hips),influence(hips),influence(thigh));triangle(a,c,d,Color("5d6860"),influence(hips),influence(thigh),influence(thigh))
   quad(c,d,d+Vector3(0,.025,0),c+Vector3(0,.025,0),Color("a39570"),influence(thigh))
 # Cowl/scarf and compact frame pack, intentionally without simulation.
 ring([[2.99,.18,.14,-.09],[3.10,.15,.13,-.09]],Color("8d7248"),func(_p):return influence(neck))
 quad(Vector3(-.11,3.05,.06),Vector3(.13,3.05,.06),Vector3(.14,2.70,.23),Vector3(-.07,2.78,.24),Color("8d7248"),influence(chest))
 block(Vector3(0,2.64,-.37),Vector3(.51,.59,.25),Color("83795f"),chest)
 block(Vector3(0,2.95,-.38),Vector3(.53,.10,.27),Color("493a2e"),chest)
 for side in [-1.0,1.0]:
  block(Vector3(side*.245,2.64,-.51),Vector3(.034,.76,.040),Color("705a3c"),chest)
  block(Vector3(side*.24,2.73,.21),Vector3(.065,.45,.025),Color("493a2e"),chest,Basis(Vector3.FORWARD,-side*.12))
  block(Vector3(side*.13,2.62,-.508),Vector3(.04,.52,.02),Color("493a2e"),chest)
 # Simple identifiable facial features on this otherwise unpainted base head.
 var head=bone("Head")
 for side in [-1.0,1.0]:
  block(Vector3(side*.105,3.49,.230),Vector3(.115,.021,.018),Color("34312e"),head,Basis(Vector3.FORWARD,side*.09))
  block(Vector3(side*.103,3.488,.243),Vector3(.080,.011,.010),Color("b8ba9d"),head)
  block(Vector3(side*.102,3.488,.250),Vector3(.023,.012,.006),Color("3f514b"),head)
  block(Vector3(side*.107,3.55,.221),Vector3(.12,.020,.022),Color("4c3028") if look==0 else Color("5e696a"),head,Basis(Vector3.FORWARD,side*.12))
 block(Vector3(0,3.335,.294),Vector3(.105,.013,.011),Color("855c51"),head)
 return finish("ExpeditionKit")

func build_head_wrap() -> MeshInstance3D:
 begin()
 ring([[3.60,.306,.30,-.042],[3.67,.302,.30,-.042]],Color("314e5d"),func(_p):return influence(bone("Head")))
 return finish("SlateHeadWrap")

func aim(index:int,direction:Vector3) -> void:
 var rest_global=rig.get_bone_global_rest(index)
 var desired=Basis(Quaternion(rest_global.basis.y.normalized(),direction.normalized()))*rest_global.basis
 var parent=rig.get_bone_parent(index)
 var parent_basis=rig.get_bone_global_pose(parent).basis if parent>=0 else Basis.IDENTITY
 rig.set_bone_pose_rotation(index,(parent_basis.inverse()*desired).orthonormalized().get_rotation_quaternion())
 rig.force_update_all_bone_transforms()

func pose(seated:bool) -> void:
 rig.reset_bone_poses();rig.force_update_all_bone_transforms()
 var hip=bone("Hips");var position=rig.get_bone_pose_position(hip)
 if seated:position.y-=1.04;position.z-=.90
 rig.set_bone_pose_position(hip,position);rig.force_update_all_bone_transforms()
 for side in ["Left","Right"]:
  var sign_x=1.0 if side=="Left" else -1.0
  aim(bone(side+"UpLeg"),Vector3(sign_x*.025,-.08,1) if seated else Vector3(sign_x*.015,-1,-.01))
  aim(bone(side+"Leg"),Vector3(0,-1,-.03))
  aim(bone(side+"Foot"),Vector3(0,-.61,.79))
  aim(bone(side+"Arm"),Vector3(sign_x*.08,-.91,.40) if seated else Vector3(sign_x*.12,-1,0))
  aim(bone(side+"ForeArm"),Vector3(-sign_x*.05,-.40,.92) if seated else Vector3(0,-1,.12))
 rig.force_update_all_bone_transforms()

func snapshot() -> Array:
 var result=[]
 for i in rig.get_bone_count():result.append([rig.get_bone_pose_position(i),rig.get_bone_pose_rotation(i)])
 return result

func foot_floor() -> float:
 rig.force_update_all_bone_transforms()
 var transforms=[]
 for i in rig.get_bone_count():transforms.append(rig.get_bone_global_pose(i)*full_skin.get_bind_pose(i))
 var a=outfit.mesh.surface_get_arrays(0);var v=a[Mesh.ARRAY_VERTEX];var slots=a[Mesh.ARRAY_WEIGHTS].size()/v.size();var lowest=INF
 for i in v.size():
  if v[i].y>.35:continue
  var p=Vector3.ZERO
  for k in slots:p+=transforms[a[Mesh.ARRAY_BONES][i*slots+k]]*v[i]*a[Mesh.ARRAY_WEIGHTS][i*slots+k]
  lowest=minf(lowest,p.y)
 return lowest

func build_animations() -> void:
 pose(false);standing_pose=snapshot();pose(true);seated_pose=snapshot()
 var library=AnimationLibrary.new()
 for key in ["standing","sit_down","seated_idle","stand_up"]:
  var clip=Animation.new();clip.length=2.0 if key=="seated_idle" else 1.6
  if key=="seated_idle":clip.loop_mode=Animation.LOOP_LINEAR
  var times=[0.0,.4,.8,1.2,1.6,2.0] if key=="seated_idle" else [0.0,.4,.8,1.2,1.6]
  var frames=[]
  for time in times:
   var blend=1.0 if key=="seated_idle" else 0.0 if key=="standing" else smoothstep(0,1,time/1.6)
   if key=="stand_up":blend=1.0-blend
   for i in rig.get_bone_count():
    var pos=standing_pose[i][0].lerp(seated_pose[i][0],blend)
    if key=="seated_idle" and i==bone("Hips"):pos.y+=.009*sin(time*PI)
    rig.set_bone_pose_position(i,pos);rig.set_bone_pose_rotation(i,standing_pose[i][1].slerp(seated_pose[i][1],blend))
   # Small root lift keeps the sampled boot soles clear of the floor. No foot IK claimed.
   var hip=bone("Hips");var hip_position=rig.get_bone_pose_position(hip)
   hip_position.y+=maxf(0,-.04-foot_floor());rig.set_bone_pose_position(hip,hip_position)
   frames.append(snapshot())
  for i in rig.get_bone_count():
   var path="Skeleton3D:"+str(rig.get_bone_name(i))
   var ptrack=clip.add_track(Animation.TYPE_POSITION_3D);clip.track_set_path(ptrack,NodePath(path))
   var rtrack=clip.add_track(Animation.TYPE_ROTATION_3D);clip.track_set_path(rtrack,NodePath(path))
   for frame in times.size():
    clip.position_track_insert_key(ptrack,times[frame],frames[frame][i][0]);clip.rotation_track_insert_key(rtrack,times[frame],frames[frame][i][1])
  library.add_animation(key,clip)
 player.add_animation_library("expedition",library)

func play(key:String,time:float=-1) -> void:
 var name="mixamo_com" if key=="source_idle" else "expedition/"+key
 player.play(name)
 if time>=0:player.seek(time,true);player.pause()

func stats() -> Dictionary:
 var result={"triangles":0,"surfaces":0,"bones":rig.get_bone_count()}
 for node in mesh_nodes:
  if not node.visible:continue
  result.surfaces+=node.mesh.get_surface_count()
  for surface in node.mesh.get_surface_count():
   var a=node.mesh.surface_get_arrays(surface)
   result.triangles+=(a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size())/3
 return result
