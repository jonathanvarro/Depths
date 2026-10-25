extends SceneTree
## #129: preserve the generated master; export small stepped-alpha game textures.
const OUT := "res://art/effects/combat-fog-v1/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var source := Image.load_from_file("res://art/source/combat-fog-v1/fog-master.png")
	if source == null or source.is_empty():
		push_error("Missing fog master")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	source.resize(640, 214, Image.INTERPOLATE_LANCZOS)
	# The two overlapping half-width samples in the live shader hide the seam.
	# A restrained shared ramp and sixteen alpha steps match the small world art.
	for y in source.get_height():
		for x in source.get_width():
			var c := source.get_pixel(x, y)
			var light := roundf(c.get_luminance() * 31.0) / 31.0
			source.set_pixel(x, y, Color(light * 0.90, light * 0.92, light, roundf(c.a * 15.0) / 15.0))
	assert(source.save_png(OUT + "fog-bank.png") == OK)
	var atlas := Image.create(1280, 540, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for frame in 10:
		var p := float(frame) / 9.0
		for y in 180:
			for x in 320:
				var v := float(y) / 179.0
				var front := 1.0 - p * 1.45
				var local_y := (v - front) / 0.50
				var alpha := 0.0
				if frame == 9 or local_y >= 1.0:
					alpha = 1.0
				elif frame > 0 and local_y >= 0.0:
					alpha = source.get_pixel(x * 2, clampi(int(local_y * 213), 0, 213)).a
				atlas.set_pixel((frame % 4) * 320 + x, (frame / 4) * 180 + y, Color(1, 1, 1, alpha))
	assert(atlas.save_png(OUT + "surge-matte.png") == OK)
	var catalog := {"issue":129,"bank_size":[640,214],"surge_frame_size":[320,180],"surge_frames":10,"surge_columns":4,"enter_seconds":0.6,"exit_seconds":0.5,"backdrop":"Two overlapping scrolling samples of the authored bank; quantized 8fps; near-black upper stage","blend":"ordinary alpha; never additive","settings":"Screen flashes off: plain fade with static settled bank","runtime_texture_bytes":640*214*4+1280*540*4}
	var file := FileAccess.open(OUT + "catalog.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog, "\t") + "\n")
	print("COMBAT_FOG_EXPORT: bank 640x214, ten 320x180 surge states")
	quit()
