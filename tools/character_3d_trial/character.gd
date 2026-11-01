extends Node3D
## Original procedural geometry. Rigid bone-attached prototype, not skinned production art.
## +Z is forward. Both identities use this same skeleton and pose library.
const BONES = [
	["hips", -1, Vector3(0, .91, 0)],
	["spine", 0, Vector3(0, .32, 0)],
	["neck", 1, Vector3(0, .22, 0)],
	["head", 2, Vector3(0, .10, 0)],
	["arm_l", 1, Vector3(.255, .14, 0)],
	["forearm_l", 4, Vector3(0, -.29, 0)],
	["hand_l", 5, Vector3(0, -.26, 0)],
	["arm_r", 1, Vector3(-.255, .14, 0)],
	["forearm_r", 7, Vector3(0, -.29, 0)],
	["hand_r", 8, Vector3(0, -.26, 0)],
	["thigh_l", 0, Vector3(.105, -.02, 0)],
	["shin_l", 10, Vector3(0, -.43, 0)],
	["foot_l", 11, Vector3(0, -.40, 0)],
	["thigh_r", 0, Vector3(-.105, -.02, 0)],
	["shin_r", 13, Vector3(0, -.43, 0)],
	["foot_r", 14, Vector3(0, -.40, 0)]
]
const OUTFITS = ["Travel cloth", "Quilted medium", "Heavy plates"]
const BACKS = ["Shield", "Cape", "Frame pack"]
const POSES = ["Standing", "Seated", "Reading"]
var skeleton: Skeleton3D
var sockets: Dictionary = {}
var wardrobes: Array = [[], [], []]
var back_items: Array = [[], [], []]
var lids: Array[Node3D] = []
var eyes: Array[Node3D] = []
var mouth: Node3D
var prop_book: Node3D
var outfit_index := 0
var back_index := 0
var pose_index := 0
var identity := "rook"
var elapsed := 0.0
var animate := false
var materials: Dictionary = {}

func material(key: String, color: Color, metal := 0.0) -> StandardMaterial3D:
	if materials.has(key): return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = .8 if metal == 0.0 else .52
	materials[key] = mat
	return mat

func piece(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3, mat: Material, label: String) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = pos
	node.scale = size
	node.material_override = mat
	parent.add_child(node)
	return node

func ball(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, label := "Facet") -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = 1.0; mesh.height = 2.0
	mesh.radial_segments = 12; mesh.rings = 6
	return piece(parent, mesh, pos, size, mat, label)

func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, label := "Panel") -> MeshInstance3D:
	var mesh = BoxMesh.new(); mesh.size = Vector3.ONE
	return piece(parent, mesh, pos, size, mat, label)

func cone(parent: Node3D, pos: Vector3, height: float, top: float, bottom: float, depth: float, mat: Material, label := "Garment") -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.height = height; mesh.top_radius = top; mesh.bottom_radius = bottom
	mesh.radial_segments = 12; mesh.rings = 1
	return piece(parent, mesh, pos, Vector3(1, 1, depth), mat, label)

func group_at(bone: String, label: String, collection: Array) -> Node3D:
	var node = Node3D.new(); node.name = label
	sockets[bone].add_child(node); collection.append(node)
	return node

func setup(person: String) -> void:
	identity = person
	skeleton = Skeleton3D.new(); skeleton.name = "SharedHumanoid"
	add_child(skeleton)
	for i in BONES.size():
		var b = BONES[i]
		skeleton.add_bone(b[0])
		if b[1] >= 0: skeleton.set_bone_parent(i, b[1])
		skeleton.set_bone_rest(i, Transform3D(Basis.IDENTITY, b[2]))
		var attachment = BoneAttachment3D.new(); attachment.name = b[0] + "_socket"
		skeleton.add_child(attachment); attachment.bone_name = b[0]
		sockets[b[0]] = attachment
	build_body()
	build_head()
	for i in 3: build_outfit(i)
	build_accessories()
	set_outfit(0); set_back(0); set_pose(0)

func build_body() -> void:
	var linen = material("linen", Color("a89e82"))
	var trousers = material("trousers", Color("333432"))
	var leather = material("leather", Color("3e2c25"))
	var skin = material("skin", Color("b88e74") if identity == "rook" else Color("bfa18b"))
	cone(sockets.spine, Vector3(0, -.03, 0), .43, .225, .17, .6, linen, "CompleteUnderlayer")
	cone(sockets.hips, Vector3(0, .01, 0), .21, .17, .19, .65, trousers, "Hips")
	cone(sockets.neck, Vector3(0, .025, 0), .14, .055, .07, 1, skin, "Neck")
	for side in ["l", "r"]:
		ball(sockets["arm_"+side], Vector3(0, -.12, 0), Vector3(.063, .16, .065), linen, "UpperSleeve")
		ball(sockets["forearm_"+side], Vector3(0, -.11, 0), Vector3(.047, .14, .05), linen, "LowerSleeve")
		ball(sockets["hand_"+side], Vector3(0, -.035, .005), Vector3(.043, .07, .025), skin, "Hand")
		var thumb = ball(sockets["hand_"+side], Vector3(-.035 if side == "l" else .035, -.015, .02), Vector3(.018, .032, .018), skin, "Thumb")
		thumb.rotation.z = .4 if side == "l" else -.4
		cone(sockets["thigh_"+side], Vector3(0, -.20, 0), .43, .087, .065, 1, trousers, "TrouserLeg")
		cone(sockets["shin_"+side], Vector3(0, -.19, 0), .38, .064, .043, 1, leather, "BootShaft")
		ball(sockets["foot_"+side], Vector3(0, -.012, .05), Vector3(.066, .054, .135), leather, "BootFoot")

func build_head() -> void:
	var skin = materials.skin
	var hair = material("hair", Color("292222") if identity == "rook" else Color("66665e"))
	var grey = material("grey", Color("b1afa3"))
	var brow = material("brow", Color("3b302a") if identity == "rook" else Color("55544d"))
	var ivory = material("eye", Color("c8c2a6"))
	var iris = material("iris", Color("3c514b"))
	var dark = material("pupil", Color("191d1c"))
	var lips = material("lips", Color("80554e"))
	var head: Node3D = sockets.head
	var wide = 1.0 if identity == "rook" else 1.09
	ball(head, Vector3(0, .075, 0), Vector3(.103*wide, .133, .102), skin, "Skull")
	ball(head, Vector3(0, -.004, .025), Vector3(.076*wide, .062, .075), skin, "Jaw")
	ball(head, Vector3(0, .066, .098), Vector3(.019, .033, .027), skin, "Nose")
	for sign_value in [-1.0, 1.0]:
		ball(head, Vector3(sign_value*.105*wide, .07, 0), Vector3(.018, .038, .022), skin, "Ear")
		ball(head, Vector3(sign_value*.065, .044, .064), Vector3(.028, .022, .023), skin, "Cheek")
		var eye = ball(head, Vector3(sign_value*.047, .101, .085), Vector3(.030, .013, .015), ivory, "Eye")
		eyes.append(eye)
		eyes.append(ball(head, Vector3(sign_value*.047, .101, .099), Vector3(.010, .011, .004), iris, "Iris"))
		eyes.append(ball(head, Vector3(sign_value*.047, .101, .102), Vector3(.004, .007, .002), dark, "Pupil"))
		var lid = ball(head, Vector3(sign_value*.047, .101, .087), Vector3(.032, .014, .017), skin, "ClosedLid")
		lids.append(lid); lid.visible = false
		var eyebrow = box(head, Vector3(sign_value*.049, .126 + (.006 if identity == "rook" and sign_value < 0 else 0), .082), Vector3(.063, .010, .014), brow, "Brow")
		eyebrow.rotation.z = sign_value * (.12 if identity == "rook" else -.10)
		ball(head, Vector3(sign_value*.077, .156, -.009), Vector3(.039, .074, .087), hair, "TempleHair")
	ball(head, Vector3(0, .18, -.012), Vector3(.107*wide, .065, .099), hair, "CrownHair")
	if identity == "rook":
		for i in 6:
			var lock = ball(head, Vector3(-.075+i*.029, .211-absf(i-2)*.004, .022), Vector3(.028, .030, .065), hair if i != 1 else grey, "SweptLock")
			lock.rotation.x = .35
		ball(head, Vector3(0, .031, .098), Vector3(.042, .009, .012), hair, "Moustache")
		ball(head, Vector3(0, -.024, .087), Vector3(.030, .022, .012), hair, "Goatee")
	else:
		for i in 7:
			box(head, Vector3(-.083+i*.027, .181, .060), Vector3(.023, .045, .041), hair if i%3 else grey, "CroppedFringe")
		ball(head, Vector3(-.069, .012, .070), Vector3(.008, .004, .004), lips, "OldScar")
	mouth = box(head, Vector3(0, .012, .097), Vector3(.045, .006, .006), lips, "Mouth")
	mouth.rotation.z = .07 if identity == "rook" else 0

func build_outfit(index: int) -> void:
	var primary = material("outfit_"+str(index), [Color("502c32"), Color("5e6356"), Color("424d53")][index], .6 if index == 2 else 0)
	var trim = material("trim", Color("9c8350"), .55)
	var cloth = material("undercloth", Color("80704f"))
	var leather = materials.leather
	var torso = group_at("spine", OUTFITS[index], wardrobes[index])
	cone(torso, Vector3(0, -.028, 0), .45, .235+index*.009, .182+index*.009, .64, primary, "Torso")
	cone(torso, Vector3(0, -.205, .002), .045, .191+index*.008, .191+index*.008, .70, leather, "Belt")
	box(torso, Vector3(0, -.204, .14), Vector3(.055, .037, .016), trim, "Buckle")
	if index == 0:
		box(torso, Vector3(0, -.025, .151), Vector3(.14, .32, .012), cloth, "Waistcoat")
		for sign_value in [-1.0, 1.0]:
			var lapel = box(torso, Vector3(sign_value*.102, .062, .139), Vector3(.063, .17, .021), primary, "Lapel")
			lapel.rotation.z = sign_value*.25
		for i in 4: ball(torso, Vector3(.025, .08-i*.064, .165), Vector3(.009, .009, .005), trim, "Button")
		for side in ["l", "r"]:
			var tail = group_at("thigh_"+side, "CoatSkirt", wardrobes[index])
			cone(tail, Vector3(0, -.085, -.016), .23, .103, .122, 1, primary, "SplitCoatTail")
	elif index == 1:
		for row in 5:
			for col in 5:
				var stitch = box(torso, Vector3(-.148+col*.074, .13-row*.07, .142), Vector3(.043, .043, .008), cloth, "QuiltPanel")
				stitch.rotation.z = PI/4
		for side in ["l", "r"]:
			var sleeve = group_at("arm_"+side, "PaddedSleeve", wardrobes[index])
			ball(sleeve, Vector3(0, -.115, 0), Vector3(.081, .15, .078), primary, "UpperPadding")
	else:
		ball(torso, Vector3(0, .005, .071), Vector3(.21, .19, .11), primary, "Breastplate")
		box(torso, Vector3(0, .005, .18), Vector3(.018, .28, .013), trim, "CentralRidge")
		for side in ["l", "r"]:
			var shoulder = group_at("arm_"+side, "PlateShoulder", wardrobes[index])
			ball(shoulder, Vector3(0, -.025, 0), Vector3(.105, .085, .105), primary, "Pauldron")
			var bracer = group_at("forearm_"+side, "PlateBracer", wardrobes[index])
			cone(bracer, Vector3(0, -.10, 0), .19, .06, .05, 1, primary, "Vambrace")
			var skirt = group_at("thigh_"+side, "ArticulatedTasset", wardrobes[index])
			box(skirt, Vector3(0, -.08, .09), Vector3(.17, .20, .034), primary, "Tasset")

func build_accessories() -> void:
	var wood = material("wood", Color("69503b"))
	var iron = material("iron", Color("68706c"), .65)
	var linen = materials.linen
	var leather = materials.leather
	var cape_mat = material("cape", Color("343e42"))
	var shield = group_at("forearm_l", "Shield", back_items[0])
	cone(shield, Vector3(.045, -.10, .10), .04, .19, .19, 1, wood, "WoodShield").rotation.x = PI/2
	ball(shield, Vector3(.045, -.10, .135), Vector3(.060, .060, .030), iron, "ShieldBoss")
	for x in [-.08, 0.0, .08]: box(shield, Vector3(.045+x, -.10, .125), Vector3(.006, .31, .008), iron, "ShieldRib")
	var cape = group_at("spine", "Cape", back_items[1])
	# A solid two-sided mantle with a deliberately curved rigid outline.
	var mesh = ArrayMesh.new()
	var verts = PackedVector3Array([
		Vector3(-.27,.15,-.07), Vector3(.27,.15,-.07), Vector3(.32,-.56,-.22),
		Vector3(-.27,.15,-.07), Vector3(.32,-.56,-.22), Vector3(-.32,-.56,-.22)])
	var normals = PackedVector3Array()
	for v in verts: normals.append(Vector3(0,0,-1))
	var arrays = []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=verts; arrays[Mesh.ARRAY_NORMAL]=normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var double_mat = cape_mat.duplicate(); double_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	piece(cape, mesh, Vector3.ZERO, Vector3.ONE, double_mat, "Mantle")
	for sign_value in [-1.0, 1.0]:
		box(cape, Vector3(sign_value*.18,.10,.12), Vector3(.08,.045,.04), cape_mat, "ShoulderDrape")
	ball(cape, Vector3(0,.10,.16), Vector3(.024,.024,.009), iron, "CapeClasp")
	var pack = group_at("spine", "FramePack", back_items[2])
	box(pack, Vector3(0,-.06,-.23), Vector3(.32,.43,.19), linen, "CanvasPack")
	for x in [-.15,.15]:
		box(pack, Vector3(x,-.07,-.34), Vector3(.022,.55,.025), wood, "FrameRail")
		box(pack, Vector3(x*.9,.0,.14), Vector3(.045,.35,.025), leather, "FrontStrap")
	ball(pack, Vector3(0,.19,-.23), Vector3(.21,.075,.08), cape_mat, "Bedroll")
	prop_book = Node3D.new(); prop_book.name="ReadingProp"; sockets.spine.add_child(prop_book)
	box(prop_book, Vector3(0,-.10,.38), Vector3(.29,.04,.19), leather, "BookCover").rotation.x=.15
	box(prop_book, Vector3(0,-.072,.38), Vector3(.27,.014,.17), linen, "Pages").rotation.x=.15

func set_outfit(index: int) -> void:
	outfit_index = clampi(index,0,2)
	for i in wardrobes.size():
		for node in wardrobes[i]: node.visible = i == outfit_index

func set_back(index: int) -> void:
	back_index = clampi(index,0,2)
	for i in back_items.size():
		for node in back_items[i]: node.visible = i == back_index

func rotate_bone(bone: String, axis: Vector3, angle: float) -> void:
	skeleton.set_bone_pose_rotation(skeleton.find_bone(bone), Quaternion(axis,angle))

func set_pose(index: int) -> void:
	pose_index=clampi(index,0,2)
	skeleton.reset_bone_poses()
	rotate_bone("arm_l",Vector3.FORWARD,-.10)
	rotate_bone("arm_r",Vector3.FORWARD,.10)
	rotate_bone("head",Vector3.UP,-.10 if identity=="rook" else .08)
	if pose_index > 0:
		skeleton.set_bone_pose_position(0,BONES[0][2]+Vector3(0,-.43,0))
		for side in ["l","r"]:
			rotate_bone("thigh_"+side,Vector3.RIGHT,-PI/2)
			rotate_bone("shin_"+side,Vector3.RIGHT,PI/2)
			rotate_bone("arm_"+side,Vector3.RIGHT,-.45 if pose_index==1 else -.65)
			rotate_bone("forearm_"+side,Vector3.RIGHT,-.55 if pose_index==1 else -.90)
	prop_book.visible=pose_index==2
	skeleton.force_update_all_bone_transforms()

func set_expression(blink: bool, speaking: bool) -> void:
	for node in eyes: node.visible=not blink
	for node in lids: node.visible=blink
	mouth.scale.y=.018 if speaking else .006

func _process(delta: float) -> void:
	if not animate: return
	elapsed+=delta
	set_expression(fmod(elapsed,4.0)>.0 and fmod(elapsed,4.0)<.13, sin(elapsed*4.0)>.65)
	rotate_bone("head",Vector3.UP,(-.10 if identity=="rook" else .08)+sin(elapsed*.8)*.035)

func mesh_stats() -> Dictionary:
	var result={"meshes":0,"triangles":0}
	_count(self,result)
	return result

func _count(node: Node, result: Dictionary) -> void:
	if node is MeshInstance3D:
		result.meshes+=1
		for i in node.mesh.get_surface_count():
			var arrays=node.mesh.surface_get_arrays(i)
			result.triangles+=(arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size()/3)
	for child in node.get_children(): _count(child,result)
