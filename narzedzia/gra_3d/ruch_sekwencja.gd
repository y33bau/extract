extends SceneTree
## Sekwencje ruchu Hadræna z planem czasowym z swiat3d.gd (ciosy 8 klatek co 0,06 s). Uruchom: godot --path godot --rendering-driver vulkan -s ../narzedzia/gra_3d/ruch_sekwencja.gd -- --wyj=/tmp/ruch_sekwencja

var wyj := "/tmp/ruch_sekwencja"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wyj="):
			wyj = a.substr(6)
	DirAccess.make_dir_recursive_absolute(wyj)
	_zrob.call_deferred()


func _scena() -> Node3D:
	var s := Node3D.new()
	root.add_child(s)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.03, 0.025, 0.035)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.38, 0.5)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.glow_enabled = true
	e.ssao_enabled = true
	we.environment = e
	s.add_child(we)
	var podl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	podl.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://zasoby/3d/tekstury/kamien_albedo.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load("res://zasoby/3d/tekstury/kamien_normal.png")
	mat.uv1_scale = Vector3(16, 16, 16)
	podl.material_override = mat
	s.add_child(podl)
	for p in [Vector3(-3, 3, 3), Vector3(4, 3.5, 2)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.72, 0.45)
		l.light_energy = 5.0
		l.omni_range = 14.0
		l.shadow_enabled = true
		l.position = p
		s.add_child(l)
	var k := Camera3D.new()
	k.projection = Camera3D.PROJECTION_ORTHOGONAL
	k.size = 4.2
	s.add_child(k)
	var kier := Vector3(cos(deg_to_rad(30.0)) / sqrt(2.0), sin(deg_to_rad(30.0)), cos(deg_to_rad(30.0)) / sqrt(2.0))
	k.position = Vector3(0, 0.9, 0) + kier * 30.0
	k.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	k.current = true
	return s


func _zrob() -> void:
	root.size = Vector2i(360, 400)
	var S3 = load("res://skrypty/swiat3d.gd")
	var styl := "miecz"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--styl="):
			styl = a.substr(7)
	var bronie := {"miecz": ["bron_miecz", "bron_tarcza"], "dwureczny": ["bron_dwureczny"], "topor": ["bron_topor"], "piesci": []}
	var sc := _scena()
	var n: Node3D = load("res://zasoby/3d/postacie/hadraen.glb").instantiate()
	sc.add_child(n)
	n.rotation.y = deg_to_rad(40)
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	for b in ["bron_dwureczny", "bron_glewia", "bron_topor", "bron_miecz", "bron_tarcza", "bron_pochodnia"]:
		var w: Node3D = n.find_child(b, true, false)
		if w:
			w.visible = b in bronie[styl]
	for c in 3:
		var plan: Array = S3.ATAK_PLAN[styl][c]
		var d := maxf(0.46, 0.34 * 1.35) * (1.22 if c == 2 else 1.0)
		var przed: float = S3.ATAK_PRZED[c]
		var ts := maxf(0.0, (plan[0] - przed * plan[1] / d) / (1.0 - przed / d))
		var tempo: float = (plan[1] - ts) / d
		print("PLAN ", styl, " atak", c + 1, " D=", d, " ts=", ts, " tempo=", tempo)
		ap.play("%s_atak%d" % [styl, c + 1])
		ap.speed_scale = 0.0
		for i in 8:
			var t := d * i / 7.0
			ap.seek(ts + t * tempo, true)
			for k in 6:
				await process_frame
			root.get_viewport().get_texture().get_image().save_png(wyj.path_join("%s_atak%d_%d.png" % [styl, c + 1, i]))
	print("RUCH_KONIEC")
	quit()
