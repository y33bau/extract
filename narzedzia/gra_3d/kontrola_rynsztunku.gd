extends SceneTree
## Test integracyjny prawdziwego GLB: warianty, odkładanie, skóra, łuk i animacje.
const Wyglad = preload("res://skrypty/wyglad_rynsztunku.gd")
var out := ""
var world: Node3D
var model: Node3D
var ap: AnimationPlayer
var wyglad := Wyglad.new()
var wyniki: Array = []
var etykieta: Label

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--wyniki="):
			out = arg.trim_prefix("--wyniki=")
	call_deferred("_test")

func sprawdz(nazwa: String, ok: bool) -> void:
	wyniki.append({"nazwa": nazwa, "ok": ok})
	print("  ", "OK " if ok else "BŁĄD ", nazwa)

func pokazany(nazwa: String) -> bool:
	return wyglad.wezly.has(nazwa) and (wyglad.wezly[nazwa] as Node3D).visible

func poza(anim: String, sekundy := 0.0) -> void:
	ap.play(anim)
	ap.seek(sekundy, true)
	ap.advance(0)
	ap.speed_scale = 0
	await process_frame
	await process_frame

func zrzut(nazwa: String) -> void:
	etykieta.text = nazwa.replace("_", " ")
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	im.save_png(out.path_join(nazwa + ".png"))

func _test() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1100, 800)
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.10, 0.09, 0.09)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.82, 0.9)
	env.environment.ambient_light_energy = 0.65
	world.add_child(env)
	for pos in [Vector3(2, 4, 3), Vector3(-3, 2, 0), Vector3(0, 3, -3)]:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_energy = 3.0
		light.omni_range = 12.0
		world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.8
	world.add_child(camera)
	camera.position = Vector3(-2.8, 2.2, 5)
	camera.look_at(Vector3(0, 1, 0))
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(6, 6)
	world.add_child(floor_mesh)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.13, 0.12)
	floor_mesh.material_override = mat
	model = (load(Wyglad.SCENA) as PackedScene).instantiate()
	world.add_child(model)
	wyglad.przygotuj(model)
	ap = model.find_child("AnimationPlayer", true, false)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	etykieta = Label.new()
	etykieta.position = Vector2(28, 24)
	etykieta.add_theme_font_size_override("font_size", 28)
	canvas.add_child(etykieta)
	var eq := {"weapon": {"id": "rusty_sword"}, "shield": {"id": "wood_buckler"}, "armor": {"id": "leather_jerkin"}}
	var zestawy := ["miecz_tarcza", "miecz_tarcza", "glewia", "dwureczny", "topor"]
	var unikalne: Dictionary = {}
	for i in Wyglad.BRONIE.size():
		var id: String = Wyglad.BRONIE[i]
		eq["weapon"] = {"id": id}
		wyglad.odswiez(eq, zestawy[i])
		sprawdz("osobny model " + id, pokazany("sprzet_" + id))
		var mesh: MeshInstance3D = wyglad.wezly.get("sprzet_" + id)
		unikalne[mesh.mesh.get_instance_id()] = true
		sprawdz("brak starego modelu " + id, not pokazany("bron_miecz") and not pokazany("bron_glewia") and not pokazany("bron_topor"))
		await poza("glewia_postoj" if i == 2 else ("dwureczny_postoj" if i == 3 else ("topor_postoj" if i == 4 else "miecz_postoj")))
		await zrzut(id)
	sprawdz("pięć różnych siatek broni", unikalne.size() == 5)
	eq["weapon"] = {"id": "rusty_sword"}
	for id in Wyglad.TARCZE:
		eq["shield"] = {"id": id}
		wyglad.odswiez(eq, "miecz_tarcza")
		sprawdz("tarcza w ręce " + id, pokazany("sprzet_" + id) and not pokazany("odlozona_" + id))
		await poza("miecz_postoj")
		await zrzut(id)
		wyglad.odswiez(eq, "glewia")
		sprawdz("tarcza odłożona przy 2H " + id, not pokazany("sprzet_" + id) and pokazany("odlozona_" + id))
	for id in Wyglad.PANCERZE:
		eq["armor"] = {"id": id}
		eq["shield"] = null
		wyglad.odswiez(eq, "miecz")
		var pancerz: MeshInstance3D = wyglad.wezly.get("pancerz_" + id)
		sprawdz("skóra i widoczność " + id, pancerz != null and pancerz.skin != null and pancerz.visible and not pokazany("cialo") and pokazany("cialo_pod_pancerzem"))
		await poza("miecz_postoj")
		await zrzut(id)
	for id in Wyglad.LUKI:
		eq["bow"] = {"id": id}
		wyglad.odswiez(eq, "miecz", true, true, 1.0)
		sprawdz("łuk i strzała " + id, pokazany("sprzet_" + id) and pokazany("sprzet_iron_arrow") and pokazany("sprzet_quiver"))
		sprawdz("broń w pochwie przy łuku " + id, pokazany("odlozona_rusty_sword") and pokazany("pochwa_rusty_sword") and not pokazany("sprzet_rusty_sword"))
		var luk: MeshInstance3D = wyglad.wezly.get("sprzet_" + id)
		sprawdz("naciągana cięciwa " + id, luk.mesh.get_blend_shape_count() > 0)
		await poza("luk_celowanie")
		await zrzut(id)
		wyglad.odswiez(eq, "miecz")
		sprawdz("łuk na plecach " + id, pokazany("odlozona_" + id) and not pokazany("sprzet_" + id))
	var szkielet: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var biodra := szkielet.find_bone("mixamorig_Hips")
	eq["weapon"] = {"id": "warden_glaive"}
	wyglad.odswiez(eq, "glewia")
	for i in 3:
		var n := "glewia_atak%d" % (i + 1)
		sprawdz("własna animacja " + n, ap.has_animation(n))
		var poprawna_wysokosc := biodra >= 0
		for j in 10:
			await poza(n, j * 0.19)
			if biodra >= 0:
				var y := (szkielet.global_transform * szkielet.get_bone_global_pose(biodra).origin).y
				poprawna_wysokosc = poprawna_wysokosc and y > 0.5 and y < 1.3
		sprawdz("biodra nad ziemią " + n, poprawna_wysokosc)
		await poza(n, 0.8)
		await zrzut(n)
	var bledy := wyniki.filter(func(w): return not w["ok"]).size()
	var file := FileAccess.open(out.path_join("wynik.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"kontrole": wyniki, "bledy": bledy}, "\t"))
	print("WYNIK RYNSZTUNKU: ", "OK" if bledy == 0 else "BŁĄD", " (", wyniki.size() - bledy, "/", wyniki.size(), ")")
	quit(0 if bledy == 0 else 1)
