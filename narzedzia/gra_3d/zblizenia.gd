extends SceneTree
## Zbliżenia postaci (kontrola deformacji siatki). Galeria kontrolna 3D (Forward+): wszyscy wrogowie (zamach/cios) i Hadræn ze wszystkimi broniami,
## przewrót i parowanie. Uruchom: godot --path godot --rendering-driver vulkan -s ../narzedzia/gra_3d/galeria.gd -- --wyj=/tmp/galeria

var wyj := "/tmp/galeria"
var rozmiar_kamery := 2.3
var bez_lod := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wyj="):
			wyj = a.substr(6)
		if a.begins_with("--kamera="):
			rozmiar_kamery = float(a.substr(9))
		if a == "--bez-lod":
			bez_lod = true
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
	k.size = rozmiar_kamery
	s.add_child(k)
	var kier := Vector3(cos(deg_to_rad(30.0)) / sqrt(2.0), sin(deg_to_rad(30.0)), cos(deg_to_rad(30.0)) / sqrt(2.0))
	k.position = Vector3(0, 0.9, 0) + kier * 30.0
	k.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	k.current = true
	return s


func _postac(sc: String, anim: String, t: float, bronie := []) -> Node3D:
	var n: Node3D = load(sc).instantiate()
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	ap.play(anim)
	ap.speed_scale = 0.0
	ap.seek(t * ap.current_animation_length, true)
	for b in ["bron_dwureczny", "bron_glewia", "bron_topor", "bron_miecz", "bron_tarcza", "bron_pochodnia"]:
		var w: Node3D = n.find_child(b, true, false)
		if w and sc.ends_with("hadraen.glb"):
			w.visible = b in bronie
	n.rotation.y = deg_to_rad(20)
	return n


func _zdjecie(nazwa: String, wezly: Array, swiatlo_kolor := Color(0, 0, 0, 0)) -> void:
	var s := _scena()
	for w in wezly:
		s.add_child(w)
		if swiatlo_kolor.a > 0.0:
			var l := OmniLight3D.new()
			l.light_color = Color(swiatlo_kolor.r, swiatlo_kolor.g, swiatlo_kolor.b)
			l.light_energy = 3.0
			l.omni_range = 3.2
			l.position = Vector3(0, 1.7, 0)
			w.add_child(l)
	for i in 8:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(wyj.path_join(nazwa + ".png"))
	s.queue_free()
	await process_frame
	print("GALERIA ", nazwa)


func _zrob() -> void:
	root.size = Vector2i(420, 520) if rozmiar_kamery < 4.0 else Vector2i(1280, 720)
	if bez_lod:
		root.mesh_lod_threshold = 0.0
	var P := "res://zasoby/3d/postacie/"
	var lista := {"hadraen": ["dwureczny_chod"], "npc_marga": ["chod"], "wrog_scout": ["chod"], "wrog_knight": ["zamach"]} if rozmiar_kamery >= 4.0 else {"hadraen": ["dwureczny_postoj", "dwureczny_chod"], "npc_marga": ["postoj", "chod"], "npc_chojrak": ["rozglad", "chod"],
		"npc_chlop": ["postoj", "chod"], "npc_przewoznik": ["postoj", "chod"], "wrog_scout": ["postoj", "chod", "zamach"],
		"wrog_warden": ["postoj", "chod", "zamach"], "wrog_knight": ["postoj", "chod", "zamach"], "wrog_brute": ["postoj", "chod", "zamach"],
		"wrog_archer": ["postoj", "chod", "zamach"], "wrog_boss": ["postoj", "chod", "zamach"]}
	for g in lista:
		for a in lista[g]:
			for t in ([0.25] if rozmiar_kamery >= 4.0 else [0.25, 0.7]):
				var n := _postac(P + g + ".glb", a, t, ["bron_dwureczny"])
				await _zdjecie("%s_%s_%d" % [g, a, int(t * 100)], [n])
	print("GALERIA_KONIEC")
	quit()
