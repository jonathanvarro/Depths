extends Node3D
## Original hand-shaped cross sections and planar features. +Z forward, metres.
## Shared #203 rest contract; four-slot weights, flat normals, vertex-colour palette.
const BONES = [
 ["hips",-1,Vector3(0,.91,0)],["spine",0,Vector3(0,.32,0)],
 ["neck",1,Vector3(0,.22,0)],["head",2,Vector3(0,.10,0)],
 ["arm_l",1,Vector3(.255,.14,0)],["forearm_l",4,Vector3(0,-.29,0)],["hand_l",5,Vector3(0,-.26,0)],
 ["arm_r",1,Vector3(-.255,.14,0)],["forearm_r",7,Vector3(0,-.29,0)],["hand_r",8,Vector3(0,-.26,0)],
 ["thigh_l",0,Vector3(.105,-.02,0)],["shin_l",10,Vector3(0,-.43,0)],["foot_l",11,Vector3(0,-.40,0)],
 ["thigh_r",0,Vector3(-.105,-.02,0)],["shin_r",13,Vector3(0,-.43,0)],["foot_r",14,Vector3(0,-.40,0)]
]
const OUTFITS=["Burgundy traveller","Quilted field coat","Salvaged plate"]
const BACKS=["Shield","Cape","Frame pack"]
const POSES=["Standing","Seated","Reading"]
const SKIN=Color("b98d74")
const HAIR=Color("29272a")
const SILVER=Color("b8b4a7")
const COAT=Color("662e39")
const GOLD=Color("a88b52")
const DARK=Color("292c32")
const LEATHER=Color("49352f")
const LINEN=Color("ab9c7c")
var skeleton:Skeleton3D
var garments:Array[MeshInstance3D]=[]
var utilities:Array[MeshInstance3D]=[]
var common:MeshInstance3D
var head_mesh:MeshInstance3D
var open_eyes:MeshInstance3D
var shut_eyes:MeshInstance3D
var book:MeshInstance3D
var outfit_index:=0
var back_index:=1
var pose_index:=0
var animated:=false
var clock:=0.0
var rest:Array[Vector3]=[]
var vertices:=PackedVector3Array()
var normals:=PackedVector3Array()
var colours:=PackedColorArray()
var bone_ids:=PackedInt32Array()
var weights:=PackedFloat32Array()
var skin:Skin
var meshes:Array[MeshInstance3D]=[]

func setup() -> void:
 skeleton=Skeleton3D.new();skeleton.name="SharedHumanoid";add_child(skeleton)
 for i in BONES.size():
  skeleton.add_bone(BONES[i][0])
  if BONES[i][1]>=0:skeleton.set_bone_parent(i,BONES[i][1])
  skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,BONES[i][2]))
  rest.append(BONES[i][2]+(rest[BONES[i][1]] if BONES[i][1]>=0 else Vector3.ZERO))
 skin=skeleton.create_skin_from_rest_transforms()
 common=build_body()
 head_mesh=build_face()
 open_eyes=build_eyes(false);shut_eyes=build_eyes(true)
 for i in 3:garments.append(build_outfit(i))
 for i in 3:utilities.append(build_utility(i))
 book=build_book()
 build_pose_library()
 select(0,1,0)

func begin() -> void:
 vertices=PackedVector3Array();normals=PackedVector3Array();colours=PackedColorArray()
 bone_ids=PackedInt32Array();weights=PackedFloat32Array()

func influence(bone:int,other:int=-1,amount:float=0) -> Array:
 return [bone,bone if other<0 else other,1.0-amount,amount]

func tri(a:Vector3,b:Vector3,c:Vector3,col:Color,wa:Array,wb:Array=[],wc:Array=[]) -> void:
 # Godot uses clockwise faces. Use double-sided material to preserve open hems.
 var n=(b-a).cross(c-a).normalized()
 if n.length_squared()<.1:return
 var all_weights=[wa,wa if wc.is_empty() else wc,wa if wb.is_empty() else wb]
 for i in 3:
  vertices.append([a,c,b][i]);normals.append(n);colours.append(col)
  var w=all_weights[i]
  bone_ids.append_array(PackedInt32Array([w[0],w[1],0,0]))
  weights.append_array(PackedFloat32Array([w[2],w[3],0,0]))

func quad(a:Vector3,b:Vector3,c:Vector3,d:Vector3,col:Color,w:Array) -> void:
 tri(a,b,c,col,w);tri(a,c,d,col,w)

func finish(label:String) -> MeshInstance3D:
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
 arrays[Mesh.ARRAY_COLOR]=colours;arrays[Mesh.ARRAY_BONES]=bone_ids;arrays[Mesh.ARRAY_WEIGHTS]=weights
 var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.roughness=.86
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mesh.surface_set_material(0,mat)
 var instance=MeshInstance3D.new();instance.name=label;instance.mesh=mesh;add_child(instance)
 instance.skeleton=NodePath("../SharedHumanoid");instance.skin=skin
 instance.custom_aabb=AABB(Vector3(-1,-.1,-1),Vector3(2,2.2,2))
 meshes.append(instance)
 return instance

func block(center:Vector3,size:Vector3,col:Color,bone:int,basis:Basis=Basis.IDENTITY) -> void:
 var p=[]
 for v in [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,1,-1),Vector3(-1,1,-1),Vector3(-1,-1,1),Vector3(1,-1,1),Vector3(1,1,1),Vector3(-1,1,1)]:p.append(center+basis*(v*size*.5))
 for f in [[0,1,2,3],[5,4,7,6],[4,0,3,7],[1,5,6,2],[3,2,6,7],[4,5,1,0]]:quad(p[f[3]],p[f[2]],p[f[1]],p[f[0]],col,influence(bone))

func tube(sections:Array,segments:int,col:Color,weight_func:Callable,phase:=0.0) -> void:
 # section = [centre,width,depth]. Each section is individually shaped, not a primitive.
 for row in range(sections.size()-1):
  for j in segments:
   var points=[];var ws=[]
   for entry in [[row,j],[row,j+1],[row+1,j+1],[row+1,j]]:
    var s=sections[entry[0]];var theta=TAU*entry[1]/segments+phase
    var p=s[0]+Vector3(sin(theta)*s[1],0,cos(theta)*s[2]);points.append(p);ws.append(weight_func.call(p))
   var shade=col.darkened(.035 if j%3==0 else 0.0)
   tri(points[0],points[1],points[2],shade,ws[0],ws[1],ws[2]);tri(points[0],points[2],points[3],shade,ws[0],ws[2],ws[3])
 for end in [0,sections.size()-1]:
  var s=sections[end];var w=weight_func.call(s[0])
  for j in segments:
   var a=s[0]+Vector3(sin(TAU*j/segments+phase)*s[1],0,cos(TAU*j/segments+phase)*s[2])
   var b=s[0]+Vector3(sin(TAU*(j+1)/segments+phase)*s[1],0,cos(TAU*(j+1)/segments+phase)*s[2])
   if end==0:tri(s[0],b,a,col,w)
   else:tri(s[0],a,b,col,w)

func torso_weight(p:Vector3) -> Array:
 return influence(0,1,clampf((p.y-1.00)/.20,0,1))

func arm_weight(p:Vector3,left:bool) -> Array:
 var upper=4 if left else 7;var lower=upper+1;var hand=upper+2
 if p.y>1.30:return influence(1,upper,clampf((1.40-p.y)/.10,.05,1))
 if p.y>1.01:return influence(upper,lower,clampf((1.16-p.y)/.16,0,1))
 return influence(lower,hand,clampf((.89-p.y)/.09,0,1))

func leg_weight(p:Vector3,left:bool) -> Array:
 var thigh=10 if left else 13
 if p.y>.79:return influence(0,thigh,clampf((.94-p.y)/.15,0,1))
 return influence(thigh,thigh+1,clampf((.53-p.y)/.15,0,1))

func build_body() -> MeshInstance3D:
 begin()
 tube([[Vector3(0,.83,0),.165,.10],[Vector3(0,.92,0),.17,.105],[Vector3(0,1.02,0),.145,.09]],12,DARK,torso_weight)
 tube([[Vector3(0,1.02,0),.145,.09],[Vector3(0,1.18,0),.19,.115],[Vector3(0,1.36,0),.232,.105],[Vector3(0,1.40,0),.13,.08]],12,LINEN,torso_weight)
 tube([[Vector3(0,1.39,0),.065,.063],[Vector3(0,1.50,0),.058,.058],[Vector3(0,1.57,0),.061,.056]],10,SKIN,func(_p):return influence(2,3,.25))
 for left in [true,false]:
  var sign_x=1.0 if left else -1.0;var x=.105*sign_x;var thigh=10 if left else 13
  tube([[Vector3(x,.90,0),.094,.094],[Vector3(x,.78,0),.09,.088],[Vector3(x,.59,-.006),.069,.068],[Vector3(x,.49,-.008),.066,.065],[Vector3(x,.44,-.006),.061,.059],[Vector3(x,.35,0),.054,.057],[Vector3(x,.22,0),.045,.045]],10,DARK,func(p):return leg_weight(p,left))
  # Tall angular boots, distinct turn-down and broad grounded sole.
  tube([[Vector3(x,.07,.035),.059,.115],[Vector3(x,.12,.018),.057,.093],[Vector3(x,.20,0),.048,.056],[Vector3(x,.36,0),.062,.067]],10,LEATHER,func(p):return influence(thigh+1,thigh+2,clampf((.18-p.y)/.10,0,1)))
  tube([[Vector3(x,.335,0),.063,.068],[Vector3(x,.375,0),.064,.069]],10,LEATHER.lightened(.10),func(_p):return influence(thigh+1))
  block(Vector3(x,.04,.045),Vector3(.132,.035,.246),DARK,thigh+2)
  for y in [.18,.29]:
   block(Vector3(x,y,.067),Vector3(.115,.026,.012),LEATHER.darkened(.12),thigh+1)
   block(Vector3(x+sign_x*.04,y,.077),Vector3(.026,.027,.011),GOLD,thigh+1)
  var ax=.255*sign_x
  tube([[Vector3(ax,1.38,0),.071,.073],[Vector3(ax+sign_x*.011,1.27,0),.071,.066],[Vector3(ax,1.13,0),.052,.055],[Vector3(ax,1.08,0),.054,.057],[Vector3(ax,1.01,0),.048,.052],[Vector3(ax,.88,0),.036,.039],[Vector3(ax,.82,0),.034,.037]],10,LINEN,func(p):return arm_weight(p,left))
  # Fitted gloved palm and four visible finger lengths; no mitten spheres.
  var hand=6 if left else 9
  tube([[Vector3(ax,.84,.004),.035,.028],[Vector3(ax,.78,.009),.039,.026],[Vector3(ax,.737,.015),.035,.024]],8,LEATHER,func(_p):return influence(hand))
  for digit in 4:
   var dx=(digit-1.5)*.017
   block(Vector3(ax+dx,.714+absf(digit-1.5)*.008,.015),Vector3(.015,.053-absf(digit-1.5)*.009,.029),LEATHER,hand)
  block(Vector3(ax-sign_x*.042,.777,.027),Vector3(.023,.055,.028),LEATHER,hand,Basis(Vector3.FORWARD,-sign_x*.48))
 return finish("Body_Weighted")

func face_point(x:float,y:float,z:float) -> Vector3:return rest[3]+Vector3(x,y,z)

func face_quad(points:Array,col:Color) -> void:
 quad(face_point(points[0].x,points[0].y,points[0].z),face_point(points[1].x,points[1].y,points[1].z),face_point(points[2].x,points[2].y,points[2].z),face_point(points[3].x,points[3].y,points[3].z),col,influence(3))

func build_face() -> MeshInstance3D:
 begin()
 # Chin, jaw angle, cheekbones, temples, brow and crown: planar topology.
 var sections=[]
 for s in [[-.022,.046,.054,.030],[.005,.069,.066,.024],[.038,.084,.076,.012],[.078,.102,.087,0],[.115,.099,.086,0],[.153,.095,.081,-.003],[.190,.080,.072,-.010],[.219,.046,.048,-.013],[.228,.007,.008,-.013]]:sections.append([face_point(0,s[0],s[3]),s[1],s[2]])
 tube(sections,12,SKIN,func(_p):return influence(3))
 # Small wedge nose with a bridge, defined tip and wings.
 var n=[face_point(-.015,.117,.083),face_point(.015,.117,.083),face_point(.020,.061,.101),face_point(0,.055,.143),face_point(-.020,.061,.101),face_point(0,.116,.107)]
 for f in [[0,1,5],[1,2,5],[2,3,5],[3,4,5],[4,0,5],[4,3,2]]:tri(n[f[0]],n[f[1]],n[f[2]],SKIN.lightened(.025),influence(3))
 for side in [-1.0,1.0]:
  # Cheek plane and swept angular ear.
  face_quad([Vector3(side*.025,.077,.088),Vector3(side*.070,.086,.078),Vector3(side*.083,.055,.063),Vector3(side*.043,.040,.079)],SKIN.lightened(.025))
  face_quad([Vector3(side*.094,.120,-.010),Vector3(side*.119,.119,-.013),Vector3(side*.115,.060,.003),Vector3(side*.091,.058,.025)],SKIN.darkened(.09))
  face_quad([Vector3(side*.099,.109,.0),Vector3(side*.111,.106,.0),Vector3(side*.108,.075,.012),Vector3(side*.098,.073,.014)],SKIN.darkened(.20))
  # Brow ridge, slender asymmetrical eyebrows.
  face_quad([Vector3(side*.019,.119,.085),Vector3(side*.072,.130+(.006 if side<0 else 0),.070),Vector3(side*.082,.117,.071),Vector3(side*.026,.109,.092)],SKIN.darkened(.08))
  face_quad([Vector3(side*.020,.120,.093),Vector3(side*.073,.130+(.006 if side<0 else 0),.080),Vector3(side*.078,.121,.082),Vector3(side*.025,.112,.097)],HAIR)
 # Sculpted moustache wings and a deliberately off-centre mouth.
 for side in [-1.0,1.0]:
  face_quad([Vector3(0,.046,.108),Vector3(side*.031,.040,.098),Vector3(side*.039,.027,.094),Vector3(side*.007,.033,.108)],HAIR)
 face_quad([Vector3(-.028,.025,.098),Vector3(.031,.029,.097),Vector3(.026,.023,.100),Vector3(-.025,.020,.101)],Color("633f3c"))
 face_quad([Vector3(-.024,.006,.099),Vector3(.023,.006,.099),Vector3(.014,-.025,.089),Vector3(-.014,-.025,.089)],HAIR)
 # Sideburns and temple-to-nape cap.
 for side in [-1.0,1.0]:
  face_quad([Vector3(side*.096,.174,-.020),Vector3(side*.104,.130,-.020),Vector3(side*.088,.052,.027),Vector3(side*.078,.140,.065)],HAIR)
 var hair_sections=[]
 for s in [[.115,.095,.079,-.018],[.170,.104,.090,-.015],[.215,.095,.082,-.010],[.247,.056,.053,-.012],[.255,.005,.008,-.015]]:hair_sections.append([face_point(0,s[0],s[3]),s[1],s[2]])
 # Leave the front lower hairline open: back and side panels only.
 for row in range(hair_sections.size()-1):
  for j in range(2,11):
   var a=hair_sections[row];var b=hair_sections[row+1]
   var t=TAU*j/12;var u=TAU*(j+1)/12
   quad(a[0]+Vector3(sin(t)*a[1],0,cos(t)*a[2]),a[0]+Vector3(sin(u)*a[1],0,cos(u)*a[2]),b[0]+Vector3(sin(u)*b[1],0,cos(u)*b[2]),b[0]+Vector3(sin(t)*b[1],0,cos(t)*b[2]),HAIR,influence(3))
 # Hand-shaped swept wedges, not repeated balls. Silver streak is part of the mesh.
 for i in 6:
  var x=-.083+i*.029
  var crest=.235+sin((i+.5)/6.0*PI)*.018
  var a=face_point(x,.197+sin(i*.6)*.008,.063);var b=face_point(x+.028,.198,.064)
  var c=face_point(minf(x+.038,.097),crest,.012);var d=face_point(x+.009,crest-.008,-.029)
  var tip=face_point(x-.012,.160+float(i)*.006,.086)
  var color=SILVER if i==1 else HAIR.lightened(.018*i)
  tri(a,b,c,color,influence(3));tri(a,c,d,color.lightened(.045),influence(3));tri(a,tip,b,color.darkened(.06),influence(3))
 # Fine pale cheek scar, geometric rather than a floating stripe across the face.
 face_quad([Vector3(-.062,.069,.079),Vector3(-.059,.070,.081),Vector3(-.042,.045,.085),Vector3(-.045,.044,.084)],SKIN.lightened(.18))
 return finish("Head_SculptedPlanes")

func build_eyes(closed:bool) -> MeshInstance3D:
 begin()
 for side in [-1.0,1.0]:
  var cx=side*.046
  if closed:
   face_quad([Vector3(cx-.025,.100,.088),Vector3(cx+.024,.102,.088),Vector3(cx+.023,.098,.090),Vector3(cx-.023,.096,.091)],Color("654d46"))
  else:
   # Inset almond, warm iris, dark upper lid. Small eyes keep the face grounded.
   var outline=[Vector3(cx-.027,.101,.087),Vector3(cx,.109,.094),Vector3(cx+.027,.102,.087),Vector3(cx,.093,.096)]
   face_quad(outline,Color("3b3030"))
   face_quad([Vector3(cx-.021,.100,.091),Vector3(cx,.105,.097),Vector3(cx+.020,.102,.091),Vector3(cx,.096,.098)],Color("c8bda5"))
   face_quad([Vector3(cx-.006,.105,.099),Vector3(cx+.006,.105,.099),Vector3(cx+.006,.096,.102),Vector3(cx-.006,.096,.102)],Color("807346"))
   face_quad([Vector3(cx-.0025,.105,.102),Vector3(cx+.003,.105,.102),Vector3(cx+.003,.096,.104),Vector3(cx-.0025,.096,.104)],Color("202727"))
 return finish("Eyes_Closed" if closed else "Eyes_Open")

func build_outfit(index:int) -> MeshInstance3D:
 begin()
 var primary=[COAT,Color("545e55"),Color("515d65")][index]
 var top=.236 if index<2 else .246
 tube([[Vector3(0,1.025,0),.161,.103],[Vector3(0,1.10,0),.173,.112],[Vector3(0,1.24,0),.212,.129],[Vector3(0,1.35,0),top,.117],[Vector3(0,1.39,0),.14,.084]],12,primary,torso_weight)
 # Waist belt, with intentionally off-centre clasp and two small practical pouches.
 tube([[Vector3(0,1.00,0),.168,.111],[Vector3(0,1.045,0),.166,.111]],12,LEATHER,torso_weight)
 block(Vector3(-.025,1.025,.119),Vector3(.052,.036,.016),GOLD,0)
 block(Vector3(-.025,1.025,.129),Vector3(.030,.018,.007),LEATHER,0)
 for side in [-1.0,1.0]:
  block(Vector3(side*.137,.967,.079),Vector3(.081,.105,.072),LEATHER,0,Basis(Vector3.UP,side*.3))
  block(Vector3(side*.137,1.005,.120),Vector3(.072,.026,.009),LEATHER.lightened(.09),0,Basis(Vector3.UP,side*.3))
 # Open skirt panels weighted down each thigh; no solid cylinder across the lap.
 for left in [true,false]:
  var sign_x=1.0 if left else -1.0;var thigh=10 if left else 13
  var hem=.73 if index==0 else .80
  for front in [true,false]:
   var z=1.0 if front else -1.0
   var a=Vector3(sign_x*.015,1.00,z*.109);var b=Vector3(sign_x*.171,1.00,z*.062)
   var c=Vector3(sign_x*.195,hem,z*.098);var d=Vector3(sign_x*.034,hem+.018,z*.142)
   tri(a,b,c,primary,torso_weight(a),torso_weight(b),influence(thigh));tri(a,c,d,primary,torso_weight(a),influence(thigh),influence(thigh))
   var trim=primary.lightened(.15) if index<2 else GOLD.darkened(.2)
   quad(c,d,d+Vector3(0,.014,0),c+Vector3(0,.014,0),trim,influence(thigh))
  # Continuous cloth sleeve shares elbow/shoulder weights with the underlayer.
  var ax=.255*sign_x
  tube([[Vector3(ax,1.405,0),.036,.045],[Vector3(ax,1.365,0),.077,.079],[Vector3(ax+sign_x*.01,1.29,0),.077,.072],[Vector3(ax,1.16,0),.060,.062],[Vector3(ax,1.10,0),.059,.061],[Vector3(ax,1.04,0),.057,.058],[Vector3(ax,.925,0),.044,.047]],10,primary,func(p):return arm_weight(p,left))
  tube([[Vector3(ax,.90,0),.044,.047],[Vector3(ax,.94,0),.047,.050]],10,LEATHER,func(p):return arm_weight(p,left))
  if index==2:
   # Plates remain rigid on upper arm/forearm; cloth at elbow supplies the bend.
   tube([[Vector3(ax,1.29,0),.092,.090],[Vector3(ax,1.38,0),.097,.088],[Vector3(ax,1.42,0),.061,.064]],8,primary.lightened(.10),func(_p):return influence(4 if left else 7))
   tube([[Vector3(ax,.93,0),.047,.052],[Vector3(ax,1.04,0),.062,.064]],8,primary.lightened(.10),func(_p):return influence(5 if left else 8))
 if index==0:
  # Fitted waistcoat, narrow angular lapels, visible buttons and one pocket chain.
  quad(Vector3(-.076,1.064,.113),Vector3(.076,1.064,.113),Vector3(.087,1.30,.131),Vector3(-.087,1.30,.131),GOLD.darkened(.13),influence(1))
  for side in [-1.0,1.0]:
   quad(Vector3(side*.04,1.23,.141),Vector3(side*.125,1.36,.102),Vector3(side*.09,1.39,.103),Vector3(side*.014,1.32,.139),COAT.lightened(.15),influence(1))
  for y in [1.10,1.16,1.22,1.28]:block(Vector3(.016,y,.145),Vector3(.012,.012,.008),GOLD,1)
  for i in 7:block(Vector3(.066+i*.012,1.095-.023*sin(i*PI/6),.131-i*.004),Vector3(.010,.006,.007),GOLD,1)
 elif index==1:
  # Subtle sewn chevrons conform to torso, no floating chessboard patches.
  for y in [1.13,1.20,1.27]:
   for side in [-1.0,1.0]:
    quad(Vector3(side*.017,y,.140),Vector3(side*.15,y+.035,.104),Vector3(side*.15,y+.041,.104),Vector3(side*.017,y+.006,.140),primary.lightened(.14),influence(1))
  block(Vector3(.04,1.23,.146),Vector3(.034,.125,.012),LEATHER,1)
 else:
  # Faceted breastplate and three overlapping lower lames.
  for side in [-1.0,1.0]:
   quad(Vector3(0,1.12,.158),Vector3(side*.175,1.14,.091),Vector3(side*.205,1.31,.089),Vector3(0,1.37,.130),primary.lightened(.08),influence(1))
   for y in [1.07,1.10]:quad(Vector3(0,y,.143),Vector3(side*.167,y,.090),Vector3(side*.177,y+.032,.098),Vector3(0,y+.032,.153),primary,influence(1))
  block(Vector3(0,1.24,.154),Vector3(.009,.22,.010),primary.lightened(.30),1)
 # Slate neckerchief across every variant; identity persists with equipment swaps.
 tube([[Vector3(0,1.39,0),.086,.077],[Vector3(0,1.45,0),.078,.071],[Vector3(0,1.47,0),.068,.065]],10,Color("3d4c51"),func(_p):return influence(2))
 quad(Vector3(-.045,1.44,.078),Vector3(.045,1.44,.078),Vector3(.075,1.30,.132),Vector3(-.018,1.34,.139),Color("3d4c51"),influence(1))
 return finish("Outfit_"+str(index))

func build_utility(index:int) -> MeshInstance3D:
 begin()
 if index==0:
  # Angular heater shield in forearm-local rest coordinates.
  var c=rest[5]+Vector3(.10,-.13,.095)
  var outline=[Vector3(-.16,.19,0),Vector3(.15,.19,0),Vector3(.18,.04,0),Vector3(.10,-.17,0),Vector3(0,-.26,0),Vector3(-.13,-.13,0),Vector3(-.18,.04,0)]
  for i in outline.size():
   var a=c+outline[i];var b=c+outline[(i+1)%outline.size()]
   tri(c+Vector3(0,0,.025),a,b,Color("5e4939") if i%2 else Color("705744"),influence(5))
   quad(a,b,b+Vector3(0,0,.025),a+Vector3(0,0,.025),Color("787d79"),influence(5))
  block(c+Vector3(0,0,.029),Vector3(.024,.35,.018),Color("757e7e"),5)
 elif index==1:
  # Folded segmented cape. Upper rows follow spine, lower rows blend to hips.
  var rows=[[1.40,.23,-.10],[1.26,.265,-.16],[1.05,.285,-.185],[.84,.30,-.20],[.67,.29,-.22]]
  for r in range(rows.size()-1):
   for col in 8:
    var ps=[]
    for e in [[r,col],[r,col+1],[r+1,col+1],[r+1,col]]:
     var row=rows[e[0]];var u=e[1]/8.0
     ps.append(Vector3((u*2-1)*row[1],row[0]+(.018*sin(u*PI*4) if e[0]==4 else 0),row[2]-.025*cos(u*PI*8)))
    tri(ps[0],ps[1],ps[2],Color("37474d").lightened(.025*(col%2)),torso_weight(ps[0]),torso_weight(ps[1]),torso_weight(ps[2]))
    tri(ps[0],ps[2],ps[3],Color("37474d").lightened(.025*(col%2)),torso_weight(ps[0]),torso_weight(ps[2]),torso_weight(ps[3]))
  for side in [-1.0,1.0]:block(Vector3(side*.17,1.36,.079),Vector3(.065,.032,.024),Color("37474d"),1)
  block(Vector3(0,1.38,.096),Vector3(.034,.028,.018),GOLD,1)
 else:
  block(Vector3(0,1.18,-.236),Vector3(.29,.34,.17),Color("7a735d"),1)
  block(Vector3(0,1.36,-.24),Vector3(.30,.065,.18),LEATHER,1)
  for side in [-1.0,1.0]:
   block(Vector3(side*.135,1.17,-.335),Vector3(.022,.47,.026),Color("756047"),1)
   block(Vector3(side*.13,1.26,.125),Vector3(.035,.26,.019),LEATHER,1,Basis(Vector3.FORWARD,-side*.10))
   block(Vector3(side*.075,1.17,-.332),Vector3(.024,.33,.014),LEATHER,1)
  tube([[Vector3(0,1.39,-.24),.17,.075],[Vector3(0,1.48,-.24),.17,.075]],10,Color("3c4b50"),func(_p):return influence(1))
 return finish("Utility_"+str(index))

func build_book() -> MeshInstance3D:
 begin()
 # Two shallow wedges make a readable open ledger; this prop follows spine.
 for side in [-1.0,1.0]:
  var b=Basis(Vector3.FORWARD,side*.12)
  block(Vector3(side*.071,1.13,.384),Vector3(.145,.018,.19),LEATHER,1,b)
  block(Vector3(side*.071,1.144,.384),Vector3(.133,.015,.178),LINEN,1,b)
  for z in [.34,.37,.40,.43]:block(Vector3(side*.074,1.154,z),Vector3(.094,.002,.002),Color("857b65"),1,b)
 return finish("ReadingLedger")

func bone_turn(index:int,angles:Vector3) -> void:
 skeleton.set_bone_pose_rotation(index,Quaternion.from_euler(angles))

func select(outfit:int,utility:int,pose:int) -> void:
 outfit_index=clampi(outfit,0,2);back_index=clampi(utility,0,2);pose_index=clampi(pose,0,2)
 for i in 3:garments[i].visible=i==outfit_index;utilities[i].visible=i==back_index
 skeleton.reset_bone_poses()
 bone_turn(4,Vector3(0,0,-.09));bone_turn(7,Vector3(0,0,.09));bone_turn(3,Vector3(0,-.09,.025))
 if pose_index>0:
  skeleton.set_bone_pose_position(0,BONES[0][2]+Vector3(0,-.43,0))
  for thigh in [10,13]:bone_turn(thigh,Vector3(-1.47,0,0));bone_turn(thigh+1,Vector3(1.43,0,0))
  for upper in [4,7]:
   var inward=.04 if pose_index==1 else .16
   bone_turn(upper,Vector3(-.47 if pose_index==1 else -.60,0,-inward if upper==4 else inward))
   bone_turn(upper+1,Vector3(-.65 if pose_index==1 else -.97,0,0))
  bone_turn(3,Vector3(.04 if pose_index==1 else .22,-.05,.02))
 book.visible=pose_index==2
 blink(false);skeleton.force_update_all_bone_transforms()

func blink(closed:bool) -> void:open_eyes.visible=not closed;shut_eyes.visible=closed

func build_pose_library() -> void:
 var player=AnimationPlayer.new();player.name="PoseLibrary";add_child(player)
 var library=AnimationLibrary.new()
 for index in 3:
  select(0,1,index)
  var clip=Animation.new();clip.length=.6
  for bone in 16:
   var path="SharedHumanoid:"+str(BONES[bone][0])
   var position_track=clip.add_track(Animation.TYPE_POSITION_3D);clip.track_set_path(position_track,NodePath(path))
   var rotation_track=clip.add_track(Animation.TYPE_ROTATION_3D);clip.track_set_path(rotation_track,NodePath(path))
   for time in [0.0,.6]:
    clip.position_track_insert_key(position_track,time,skeleton.get_bone_pose_position(bone))
    clip.rotation_track_insert_key(rotation_track,time,skeleton.get_bone_pose_rotation(bone))
  library.add_animation(["standing","seated","reading"][index],clip)
 player.add_animation_library("",library)

func _process(delta:float) -> void:
 if not animated:return
 clock+=delta;blink(fmod(clock,4.1)<.12)
 bone_turn(3,Vector3(.22 if pose_index==2 else 0,-.09+sin(clock*.7)*.035,.025))

func stats() -> Dictionary:
 var result={"meshes_total":meshes.size(),"meshes_visible":0,"triangles_total":0,"triangles_visible":0,"weighted_vertices":0}
 for node in meshes:
  var arrays=node.mesh.surface_get_arrays(0);var count=arrays[Mesh.ARRAY_VERTEX].size()/3
  result.triangles_total+=count
  if node.visible:result.meshes_visible+=1;result.triangles_visible+=count
  for i in arrays[Mesh.ARRAY_VERTEX].size():
   if arrays[Mesh.ARRAY_WEIGHTS][i*4+1]>.001:result.weighted_vertices+=1
 return result
