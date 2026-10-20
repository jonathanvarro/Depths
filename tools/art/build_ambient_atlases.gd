extends SceneTree
## Native pixel FX authoring for #129/#128. No gameplay/placement/state hooks.
## Every loop is sampled from a periodic phase, so frames share one drawing.
const DIR := "res://art/effects/ambient-v1/"
const REVIEW := "res://art/concepts/cave-dressing-v1/"
var catalogue: Array[Dictionary] = []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	DirAccess.make_dir_recursive_absolute(REVIEW)
	var ignore := FileAccess.open(REVIEW + ".gdignore", FileAccess.WRITE)
	ignore.close()
	make_chalk()
	make_fog()
	for kind in ["eyes-rat", "eyes-cluster", "eyes-unknown", "darkness", "dust", "drip", "smoke", "embers", "torch-smoke-embers", "shadow", "wall-flame"]:
		make_loop(kind)
	if FileAccess.file_exists("res://art/dressing/cave-v1/wall-fungus.png"):
		make_loop("fungus-pulse")
	var file := FileAccess.open(DIR + "catalog.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"issue":129,"phase":"Periodic native pixel drawings; all values are cosmetic.","effects":catalogue},"\t")+"\n")
	file.close()
	print("AMBIENT_ATLASES exported %d effects" % catalogue.size())
	quit()

func make_chalk() -> void:
	var source_dir := "res://art/source/cave-dressing-v1/"
	DirAccess.make_dir_recursive_absolute(source_dir+"native")
	for name in ["chalk-arrow","chalk-cross","chalk-tally"]:
		var image:=Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string(source_dir+name+".svg"))==OK)
		assert(image.save_png(source_dir+"native/"+name+".png")==OK)

func write_png(image: Image, name: String) -> void:
	var error := image.save_png(DIR + name + ".png")
	assert(error == OK, name)

func make_fog() -> void:
	var strip := Image.create(256,64,false,Image.FORMAT_RGBA8)
	for y in 64:
		for x in 256:
			var u := float(x)/255.0
			var v := float(y)/63.0
			var field := .48 + .24*sin(TAU*u*3.0 + v*5.0) + .16*cos(TAU*u*5.0-v*7.0) + .1*sin(TAU*u+v*11.0)
			var a: float = floorf(clampf(field,0,1)*pow(sin(PI*v),1.5)*7.0)/7.0*.18
			strip.set_pixel(x,y,Color(.40,.44,.44,a))
	# Exact wrap boundary; top/bottom already vanish into transparency.
	for y in 64:
		strip.set_pixel(255,y,strip.get_pixel(0,y))
	write_png(strip,"fog-strip")
	catalogue.append({"id":"fog-strip","texture":DIR+"fog-strip.png","size":[256,64],"blend":"alpha","animation":"UV scroll, suggested 0.01 cycles/s","repeat_x":true,"max_alpha":.18})
	for variant in 3:
		var patch := Image.create(128,64,false,Image.FORMAT_RGBA8)
		for y in 64:
			for x in 128:
				var dx := (float(x)-63.5)/61.0
				var dy := (float(y)-31.5)/(26.0-float(variant)*3.0)
				var radius := dx*dx + dy*dy
				var wave := .78+.22*sin(float(x)*.09+float(y)*.12+float(variant)*2.0)
				var a: float = floorf(clampf(1.0-radius,0,1)*wave*6.0)/6.0*.20
				patch.set_pixel(x,y,Color(.40,.44,.44,a))
		var id := "fog-patch-%d" % (variant+1)
		write_png(patch,id)
		catalogue.append({"id":id,"texture":DIR+id+".png","size":[128,64],"blend":"alpha","animation":"slow translation/fade; static patch","max_alpha":.20})

func make_loop(kind: String) -> void:
	var size := Vector2i(64,64)
	var count := 8
	var fps := 8.0
	if kind.begins_with("eyes"):
		size=Vector2i(32,16);count=12
	elif kind=="darkness":
		size=Vector2i(640,360);fps=6.0
	elif kind in ["drip","smoke","torch-smoke-embers"]:
		size=Vector2i(64,128)
	elif kind=="embers":
		size=Vector2i(32,64)
	elif kind=="wall-flame":
		size=Vector2i(32,64);count=4
	elif kind=="fungus-pulse":
		size=Vector2i(128,128);fps=6.0
	var cols := 4
	var rows := ceili(float(count)/cols)
	var atlas := Image.create(size.x*cols,size.y*rows,false,Image.FORMAT_RGBA8)
	for frame in count:
		var picture := draw_frame(kind,size,float(frame)/count,frame,count)
		if frame==0:
			assert(picture.get_data()==draw_frame(kind,size,1.0,count,count).get_data(),"Loop endpoint: "+kind)
		atlas.blit_rect(picture,Rect2i(Vector2i.ZERO,size),Vector2i(frame%cols*size.x,frame/cols*size.y))
	write_png(atlas,kind)
	write_frames(kind,size,count,cols,fps)
	var blend := "additive" if kind.begins_with("eyes") or kind in ["embers","fungus-pulse"] else "alpha"
	var entry := {"id":kind,"texture":DIR+kind+".png","frames":DIR+kind+".tres","frame_size":[size.x,size.y],"frame_count":count,"columns":cols,"fps":fps,"loop":true,"blend":blend,"filter":"nearest"}
	if kind=="darkness":
		entry["intensities"]={"hint":.2,"medium":.5,"strong":1.0}
		entry["clear_center"]=[192,108,448,252]
		entry["layer"]="Below HUD; cosmetic strength follows carried light/nerves, respecting reduced motion."
	if kind.begins_with("eyes") or kind=="shadow":
		entry["placement"]="Rare, one at a time, beyond carried light, Dim/Out or Shaken; unrelated to real enemies. Play once then remove."
		if kind=="shadow":
			entry["placement"]="Very rare, beyond carried light, Dim/Out only; unrelated to real enemies. Play once then remove."
	if kind in ["fungus-pulse","wall-flame","embers"]:
		entry["light_rules"]="Appearance only; never change Supplies, fear bands or enemy visibility rules."
	catalogue.append(entry)

func write_frames(kind: String,size: Vector2i,count: int,cols: int,fps: float) -> void:
	var text := "[gd_resource type=\"SpriteFrames\" load_steps=%d format=3]\n\n[ext_resource type=\"Texture2D\" path=\"%s%s.png\" id=\"atlas\"]\n\n" % [count+2,DIR,kind]
	for frame in count:
		text+="[sub_resource type=\"AtlasTexture\" id=\"frame%d\"]\natlas = ExtResource(\"atlas\")\nregion = Rect2(%d, %d, %d, %d)\n\n" % [frame,frame%cols*size.x,frame/cols*size.y,size.x,size.y]
	text+="[resource]\nanimations = [{\"frames\": ["
	for frame in count:
		text+=(", " if frame>0 else "")+"{\"duration\": 1.0, \"texture\": SubResource(\"frame%d\")}" % frame
	text+="], \"loop\": true, \"name\": &\"loop\", \"speed\": %s}]\n" % fps
	var file := FileAccess.open(DIR+kind+".tres",FileAccess.WRITE)
	file.store_string(text);file.close()

func dot(image: Image,center: Vector2,radius: Vector2,color: Color) -> void:
	for y in range(maxi(0,floori(center.y-radius.y)),mini(image.get_height(),ceili(center.y+radius.y+1))):
		for x in range(maxi(0,floori(center.x-radius.x)),mini(image.get_width(),ceili(center.x+radius.x+1))):
			var distance := Vector2((x-center.x)/maxf(radius.x,.5),(y-center.y)/maxf(radius.y,.5)).length()
			if distance<=1.0:
				var c := color
				c.a*=ceil((1.0-distance)*4.0)/4.0
				if c.a>image.get_pixel(x,y).a:
					image.set_pixel(x,y,c)

func line(image: Image,a: Vector2,b: Vector2,color: Color) -> void:
	var steps := maxi(1,ceili(a.distance_to(b)))
	for i in steps+1:
		var point := a.lerp(b,float(i)/steps)
		var x:=roundi(point.x);var y:=roundi(point.y)
		if x>=0 and y>=0 and x<image.get_width() and y<image.get_height():
			image.set_pixel(x,y,color)

func draw_frame(kind: String,size: Vector2i,phase: float,frame: int,count: int) -> Image:
	phase=fposmod(phase,1.0)
	frame=posmod(frame,count)
	var image := Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	if kind=="darkness":
		for y in size.y:
			for x in size.x:
				var delta := Vector2((x-319.5)/319.5,(y-179.5)/179.5)
				var edge := maxf(absf(delta.x),absf(delta.y))
				var angle := atan2(delta.y,delta.x)
				var threshold := .76+.09*sin(angle*5.0+phase*TAU)+.025*sin(angle*9.0-phase*TAU)
				var a := smoothstep(threshold,1.05,edge)*.85 if edge>.66 else 0.0
				image.set_pixel(x,y,Color(.018,.019,.024,floor(a*12.0)/12.0))
	elif kind.begins_with("eyes"):
		var fade: float=[0.0,.3,.65,.85,.85,.85,.85,.85,.85,.6,.3,0.0][frame]
		if frame==5:fade=0.0
		elif frame in [4,6]:fade*=.55
		var blink: float=[1.0,1.0,1.0,1.0,.5,.12,.5,1.0,1.0,1.0,1.0,1.0][frame]
		var points: Array[Vector2]=[Vector2(10,8),Vector2(22,8)]
		var tint := Color(.48,.13,.10,fade)
		if kind=="eyes-cluster":
			points=[Vector2(8,7),Vector2(24,7),Vector2(12,5),Vector2(20,5),Vector2(14,10),Vector2(18,10)]
			tint=Color(.42,.22,.16,fade)
		elif kind=="eyes-unknown":
			points=[Vector2(6,8),Vector2(26,8)];tint=Color(.46,.53,.48,fade*.75)
		for point in points:
			dot(image,point,Vector2(2.5 if kind=="eyes-unknown" else 1.6,maxf(.5,1.5*blink)),tint)
	elif kind=="dust":
		for index in 7:
			var t := fposmod(phase+float(index)*.143,1.0)
			var point := Vector2(7+index*8+sin(t*TAU+index)*3,60-t*56)
			dot(image,point,Vector2.ONE,Color(.63,.58,.44,sin(t*PI)*.4))
	elif kind=="drip":
		if frame>0 and frame<5:
			var y := 8.0+pow(float(frame)/4.0,1.6)*100
			dot(image,Vector2(32,y),Vector2(1.5,3),Color(.46,.53,.55,.7))
		if frame>=4 and frame<7:
			var radius := 2.0+(frame-4)*4
			for angle in 48:
				var a:=float(angle)/48*TAU
				var p:=Vector2(32+cos(a)*radius,116+sin(a)*radius*.25)
				line(image,p,p,Color(.4,.48,.48,(1.0-float(frame-4)/3.0)*.5))
	elif kind=="smoke":
		for index in 4:
			var t:=fposmod(phase+float(index)/4,1.0)
			var alpha:=sin(t*PI)*.18
			dot(image,Vector2(32+sin(t*TAU+index)*5,118-t*106),Vector2(3+t*7,5+t*9),Color(.29,.30,.29,alpha))
	elif kind=="embers":
		for index in 3:
			var t:=fposmod(phase+float(index)/3.0,1.0)
			dot(image,Vector2(16+sin(t*TAU+index)*5,60-t*56),Vector2(.7,1.0),Color(.9,.37,.08,sin(t*PI)*.8))
	elif kind=="torch-smoke-embers":
		image=draw_frame("smoke",size,phase,frame,count)
		var sparks:=draw_frame("embers",Vector2i(32,64),phase,frame,count)
		image.blend_rect(sparks,Rect2i(0,0,32,64),Vector2i(16,64))
	elif kind=="shadow":
		var fade:=sin(phase*PI)*.28
		var cx:=-28.0+phase*144.0
		dot(image,Vector2(cx,34),Vector2(9,22),Color(.025,.027,.03,fade))
		dot(image,Vector2(cx-7,46),Vector2(13,10),Color(.025,.027,.03,fade*.6))
	elif kind=="wall-flame":
		for y in 56:
			var v:=float(y)/55.0
			var cx:=16.0+sin(v*6.0+phase*TAU)*3.0*(1.0-v)
			var half:=pow(v,.75)*(8.0+sin(v*9.0-phase*TAU)*2.5)
			for x in 32:
				var edge:=absf(x-cx)/maxf(half,.5)
				if edge<1.0:
					var heat:=(1.0-edge)*(.45+.55*v)
					var color:=Color("a43a12")
					if heat>.25:color=Color("d56a1c")
					if heat>.5:color=Color("edaa38")
					if heat>.72:color=Color("f1d77a")
					image.set_pixel(x,y+6,color)
	elif kind=="fungus-pulse":
		var source:=Image.new()
		assert(source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/dressing/cave-v1/wall-fungus.png"))==OK)
		var pulse:=.32+.28*(.5+.5*sin(phase*TAU))
		for y in size.y:
			for x in size.x:
				var c:=source.get_pixel(x,y)
				var a:=maxf(0.0,c.get_luminance()-.17)*c.a*pulse
				image.set_pixel(x,y,Color(.23,.47,.32,floor(a*16)/16.0))
	return image
