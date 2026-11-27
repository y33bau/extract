extends SceneTree
## Rzeczywista Przystań i rajd: nowe wyposażenie przez istniejące reguły postaci.
var out := ""
var wyniki: Array = []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wyniki="):
			out = a.trim_prefix("--wyniki=")
	call_deferred("_test")

func ok(nazwa: String, warunek: bool) -> void:
	wyniki.append({"nazwa": nazwa, "ok": warunek})
	print("  ", "OK " if warunek else "BŁĄD ", nazwa)

func zrzut(nazwa: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(nazwa + ".png"))

func _test() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var profil = root.get_node("Profil")
	profil.resetuj()
	var gra = load("res://skrypty/gra.gd").new()
	root.add_child(gra)
	current_scene = gra
	for i in 12:
		await process_frame
	ok("nowy bohater w Przystani", gra.przystan.bohater.find_child("sprzet_rusty_sword", true, false) != null)
	await zrzut("01_przystan")
	gra.rozpocznij_rajd("czarnobor", "RYNSZTUNEK")
	for i in 12:
		await process_frame
	var rajd = gra.rajd
	for en in rajd.wrogowie:
		en.uspiony = true
	var p = rajd.gracz
	p.pochodnia_w_rece = false
	var widok = rajd.swiat3d
	if widok == null:
		ok("widok rajdu istnieje", false)
		quit(1)
		return
	var wyglad = widok._wyglad_rynsztunku
	for id in ["rusty_sword", "steel_falchion", "warden_glaive", "ash_greatsword", "executioner_axe"]:
		p.rynsztunek["weapon"] = {"id": id}
		p.rynsztunek["shield"] = {"id": "iron_kite"}
		p.odswiez_zestaw()
		widok._aktualizuj_bohatera(0.01)
		ok("rajd wybiera model " + id, (wyglad.wezly["sprzet_" + id] as Node3D).visible)
		if id == "warden_glaive":
			ok("glewia ma własny styl animacji", widok._ap_bohatera.current_animation.begins_with("glewia_"))
			ok("tarcza na plecach przy 2H", (wyglad.wezly["odlozona_iron_kite"] as Node3D).visible)
	p.rynsztunek["weapon"] = {"id": "steel_falchion"}
	p.rynsztunek["armor"] = {"id": "leather_jerkin", "durability": 100}
	p.odswiez_zestaw()
	widok._aktualizuj_bohatera(0.01)
	await zrzut("02_rajd_kordelas")
	for id in ["leather_jerkin", "chainmail_hauberk", "ash_plate"]:
		p.rynsztunek["armor"] = {"id": id, "durability": 100}
		widok._aktualizuj_bohatera(0.01)
		ok("rajd wybiera pancerz " + id, (wyglad.wezly["pancerz_" + id] as Node3D).visible)
	for id in ["hunter_bow", "yew_longbow", "shadow_bow"]:
		p.rynsztunek["bow"] = {"id": id}
		p.luk_cd = 0.58
		widok._aktualizuj_bohatera(0.01)
		ok("rajd pokazuje łuk " + id, (wyglad.wezly["sprzet_" + id] as Node3D).visible)
		ok("rajd pokazuje naciąganą strzałę " + id, (wyglad.wezly["sprzet_iron_arrow"] as Node3D).visible)
		ok("rajd odtwarza strzał " + id, widok._ap_bohatera.current_animation == "luk_strzal")
		if id == "hunter_bow":
			await zrzut("03_rajd_luk")
	p.luk_cd = 0
	p.rynsztunek["weapon"] = {"id": "warden_glaive"}
	p.rynsztunek["armor"] = {"id": "chainmail_hauberk", "durability": 100}
	p.odswiez_zestaw()
	widok._aktualizuj_bohatera(0.01)
	await zrzut("04_rajd_glewia")
	var bledy: int = wyniki.filter(func(w): return not w["ok"]).size()
	var file := FileAccess.open(out.path_join("wynik.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"kontrole": wyniki, "bledy": bledy}, "\t"))
	print("WYNIK W GRZE: ", "OK" if bledy == 0 else "BŁĄD", " (", wyniki.size() - bledy, "/", wyniki.size(), ")")
	quit(0 if bledy == 0 else 1)
