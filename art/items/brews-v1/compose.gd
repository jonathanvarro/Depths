extends RefCounted
## Presentation only. The expedition system supplies the identity mapping.
const SHAPES := ["squat","tall","flask","vial","gourd","jar"]
const MARKS := ["eye","tooth","spiral","hand","moon","cross"]
const COLOURS := [Color("a54b43"),Color("b58b3d"),Color("75895b"),Color("557f94"),Color("8773a5"),Color("b4a887")]

static func _image(path:String) -> Image:
	return (load(path) as Texture2D).get_image()

static func compose(shape:String,colour:int,mark:String,identified_kind:="") -> Image:
	assert(shape in SHAPES and mark in MARKS and colour>=0 and colour<COLOURS.size())
	var image:=_image("res://art/items/brews-v1/brew-"+shape+".png")
	image.convert(Image.FORMAT_RGBA8)
	var mask:=_image("res://art/items/brews-v1/brew-"+shape+"-liquid-mask.png")
	var tint:Color=COLOURS[colour]
	for y in 64:
		for x in 64:
			if mask.get_pixel(x,y).a<0.5:continue
			var base:=image.get_pixel(x,y)
			if base.a<0.5:base=Color(0.65,0.65,0.65,1)
			image.set_pixel(x,y,Color(base.r*(0.2+0.8*tint.r),base.g*(0.2+0.8*tint.g),base.b*(0.2+0.8*tint.b),1))
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/items/brews-v1/catalog.json"))
	var centre:=Vector2i(32,9)
	for entry in catalog.shapes:
		if entry.id=="brew-"+shape:centre=Vector2i(entry.stamp_center[0],entry.stamp_center[1])
	# An irregular wax stamp remains separate from the glass and fluid identity.
	for y in range(-6,7):
		for x in range(-6,7):
			if x*x+y*y<=35 and Rect2i(0,0,64,64).has_point(centre+Vector2i(x,y)):
				image.set_pixelv(centre+Vector2i(x,y),Color("604332"))
	var stamp:=_image("res://art/ui/expedition-v1/marks/"+mark+".png")
	stamp.resize(10,10,Image.INTERPOLATE_NEAREST)
	for y in 10:
		for x in 10:
			if stamp.get_pixel(x,y).a>=0.5:image.set_pixelv(centre+Vector2i(x-5,y-5),Color("e6dac1"))
	if identified_kind!="":
		assert(identified_kind in ["restorative","caustic","slumber","frenzy","revealing"])
		var label:=_image("res://art/ui/expedition-v1/labels/"+identified_kind+".png")
		var side:=clampi(image.get_used_rect().size.x-2,8,16)
		label.resize(side,side,Image.INTERPOLATE_NEAREST)
		image.blend_rect(label,Rect2i(0,0,side,side),Vector2i(32-side/2,42-side/2))
	return image
