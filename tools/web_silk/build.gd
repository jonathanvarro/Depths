extends SceneTree
## #274: original fine-silk pixels on registered, gently bowed 3D surfaces.
const OUT := "res://art/features/web-silk-v2/"
const COLUMNS := 24
const ROWS := 28

func _initialize() -> void:
	var source_hash := "1caef1c737d3e83cc472f888ed7035036634617cea932c9117b12e76a1dbdd5b"
	assert(FileAccess.get_sha256(OUT+"silk.png")==source_hash)
	for torn in [false,true]:
		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		var uvs := PackedVector2Array()
		var indices := PackedInt32Array()
		for row in ROWS+1:
			for column in COLUMNS+1:
				var u := float(column)/COLUMNS
				var v := float(row)/ROWS
				# Edge anchors stay at the walls/floor/ceiling; silk bows between them.
				var bow := sin(PI*u)*sin(PI*v)
				vertices.append(Vector3((u-.5)*2.0,.02+(1.0-v)*2.36,bow*(.075+.025*sin(u*9.0+v*11.0))))
				normals.append(Vector3(0,0,-1))
				uvs.append(Vector2(u,v))
		for row in ROWS:
			for column in COLUMNS:
				# A real central aperture; the material feathers the retained fringe.
				# Conservative omission keeps all surviving silk registered to intact.
				var x := (float(column)+.5)/COLUMNS
				var y := (float(row)+.5)/ROWS
				if torn and x>.23 and x<.77 and y>.23:continue
				var a := row*(COLUMNS+1)+column
				indices.append_array(PackedInt32Array([a,a+COLUMNS+1,a+1,a+1,a+COLUMNS+1,a+COLUMNS+2]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_NORMAL]=normals
		arrays[Mesh.ARRAY_TEX_UV]=uvs
		arrays[Mesh.ARRAY_INDEX]=indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var name := "torn" if torn else "intact"
		assert(ResourceSaver.save(mesh,OUT+name+".res")==OK)
		print(name,": ",indices.size()/3," triangles; ",vertices.size()," shared registered vertices")
	var catalog := {
		"issue":274,
		"source":"art/source/expedition-v1/web-intact.png",
		"source_provenance":"art/source/expedition-v1/generation-addendum.json",
		"runtime_texture":"silk.png",
		"source_sha256":source_hash,
		"source_pixels":"Exact unmodified original 1254x1254 RGBA painting; not the reduced 256px export",
		"changes":"Registered bowed meshes, lighting/filtering, and a static shader tear; no new bitmap painting",
		"cell_metres":2.0,"wall_metres":2.4,"forward":"-Z",
		"triangles":{"intact":1344,"torn":816},
		"surfaces_per_state":1,"texture_shared_by_states":true,
		"builder_sha256":FileAccess.get_sha256("res://tools/web_silk/build.gd")
	}
	FileAccess.open(OUT+"catalog.json",FileAccess.WRITE).store_string(JSON.stringify(catalog,"\t")+"\n")
	quit()
