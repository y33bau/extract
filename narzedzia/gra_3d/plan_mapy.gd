extends SceneTree
## Plan mapy z góry (bez 3D): mury, komnaty wg rodzaju, kosze, skrzynie, ekstrakcje, start, wrogowie.
## Uruchom: godot --headless --path godot -s ../narzedzia/gra_3d/plan_mapy.gd -- --kraina=catacombs --ziarno=ABC --wyj=/tmp/plan.png
func _initialize() -> void:
	var kraina := "catacombs"
	var ziarno := "ABC"
	var wyj := "/tmp/plan.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kraina="): kraina = a.substr(9)
		if a.begins_with("--ziarno="): ziarno = a.substr(9)
		if a.begins_with("--wyj="): wyj = a.substr(6)
	_zrob.call_deferred(kraina, ziarno, wyj)


func _zrob(kraina: String, ziarno: String, wyj: String) -> void:
	var Dane = root.get_node("/root/Dane")
	var M = load("res://skrypty/mapgen.gd")
	var m = M.new()
	var t0 := Time.get_ticks_msec()
	m.generuj(Dane.kraina(kraina), ziarno, 1)
	var ms := Time.get_ticks_msec() - t0
	var n: int = M.ROZMIAR
	var s := 6
	var img := Image.create(n * s, n * s, false, Image.FORMAT_RGB8)
	var kol_typ := {"komnata": Color("3a3440"), "krypta": Color("2f3a4a"), "sala_filarow": Color("4a3f2f"), "dziedziniec": Color("394a2f"),
		"kaplica": Color("5a4a20"), "legowisko": Color("5a2626"), "skarbiec": Color("6a5a10"), "start": Color("20506a"), "ekstrakcja": Color("1f5a46")}
	var typ_pola := {}
	for k in m.komnaty:
		var rr: Rect2i = k["r"]
		for y in range(rr.position.y, rr.end.y):
			for x in range(rr.position.x, rr.end.x):
				typ_pola[y * n + x] = k["typ"]
	for y in n:
		for x in n:
			var t: int = m.kafel(x, y)
			var c := Color("111014")
			match t:
				0: c = kol_typ.get(typ_pola.get(y * n + x, ""), Color("2a2630"))
				1: c = Color("4d4752")
				3: c = Color("8a8090")
				4: c = Color("ff8a20")
				5: c = Color("6a6050")
				6: c = Color("40ffb0")
			img.fill_rect(Rect2i(x * s, y * s, s, s), c)
	for sk in m.skrzynie:
		img.fill_rect(Rect2i(sk["tx"] * s + 1, sk["ty"] * s + 1, s - 2, s - 2), Color("ffd84a"))
	img.fill_rect(Rect2i(int(m.start.x) * s - 3, int(m.start.y) * s - 3, 12, 12), Color("40a0ff"))
	img.save_png(wyj)
	var ile := {}
	for k in m.komnaty:
		ile[k["typ"]] = ile.get(k["typ"], 0) + 1
	print("PLAN ", kraina, " ", ziarno, " komnat=", m.komnaty.size(), " ", ile, " skrzyn=", m.skrzynie.size(), " koszy=", m.kosze.size(), " ekstrakcji=", m.ekstrakcje.size(), " czas=", ms, "ms")
	quit()
