extends Control
## Warownia (hub): Wyprawa, Ekwipunek i Skrytka, Kupiec, Warownia, Umiejętności.
## Pad: krzyżak/drążek nawigacja, A wybór, Y do Relikwiarza, LB/RB zakładki.

signal start_rajdu(kraina: String, ziarno: String)

const Ui = preload("res://skrypty/ui.gd")

var wybrana_kraina := "catacombs"
var ziarno := ""
var kategoria := "all"
var naglowek: Label
var zakladki: TabContainer
var opis: Label
var t_wyprawa: VBoxContainer
var t_ekw: HBoxContainer
var t_kupiec: HBoxContainer
var t_warownia: VBoxContainer
var t_umiej: VBoxContainer
var dialog_reset: ConfirmationDialog
var przycisk_dzwieku: Button
var _fokus_klucz := ""


func _ready() -> void:
	theme = Ui.motyw()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ziarno = _losowe_ziarno()
	var tlo := ColorRect.new()
	tlo.color = Color("0b090d")
	add_child(tlo)
	tlo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var marg := MarginContainer.new()
	add_child(marg)
	marg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		marg.add_theme_constant_override("margin_" + k, 16)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	marg.add_child(v)
	var gora := HBoxContainer.new()
	var tyt := Ui.etykieta("WAROWNIA ", 26, Color("ede4d8"))
	gora.add_child(tyt)
	gora.add_child(Ui.etykieta("POPIOŁÓW", 26, Ui.ZAR))
	var odst := Control.new()
	odst.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gora.add_child(odst)
	naglowek = Ui.etykieta("", 15)
	gora.add_child(naglowek)
	przycisk_dzwieku = Button.new()
	przycisk_dzwieku.text = "🔊"
	przycisk_dzwieku.pressed.connect(func():
		Dzwiek.wyciszony = not Dzwiek.wyciszony
		przycisk_dzwieku.text = "🔇" if Dzwiek.wyciszony else "🔊")
	gora.add_child(przycisk_dzwieku)
	var reset := Button.new()
	reset.text = "Reset"
	reset.pressed.connect(func(): dialog_reset.popup_centered())
	gora.add_child(reset)
	v.add_child(gora)
	zakladki = TabContainer.new()
	zakladki.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(zakladki)
	t_wyprawa = _zakladka("⚔ Wyprawa", VBoxContainer.new())
	t_ekw = _zakladka("🎒 Ekwipunek i Skrytka", HBoxContainer.new())
	t_kupiec = _zakladka("⚖ Kupiec", HBoxContainer.new())
	t_warownia = _zakladka("🏰 Warownia", VBoxContainer.new())
	t_umiej = _zakladka("📜 Umiejętności", VBoxContainer.new())
	zakladki.tab_changed.connect(func(_i): Dzwiek.ui(); _fokus_klucz = ""; odswiez())
	opis = Ui.etykieta("", 13, Ui.POPIOL)
	opis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opis.custom_minimum_size = Vector2(0, 54)
	var po := Ui.panel()
	po.add_child(opis)
	v.add_child(po)
	dialog_reset = ConfirmationDialog.new()
	dialog_reset.title = "Zniszczyć Kronikę Warowni?"
	dialog_reset.dialog_text = "Wszystkie przedmioty, ulepszenia, złoto i umiejętności zostaną usunięte."
	dialog_reset.ok_button_text = "Tak, zresetuj"
	dialog_reset.cancel_button_text = "Anuluj"
	dialog_reset.confirmed.connect(func(): Profil.resetuj(); odswiez())
	add_child(dialog_reset)
	Profil.awans.connect(func(u, lv): opis.text = "📜 Awans: %s (poziom %d)!" % [Dane.umiejetnosci[u]["name"], lv])
	odswiez()


func _zakladka(nazwa: String, zawartosc: Control) -> Control:
	var sc := ScrollContainer.new()
	sc.name = nazwa
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	zawartosc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zawartosc.add_theme_constant_override("separation", 10)
	sc.add_child(zawartosc)
	zakladki.add_child(sc)
	return zawartosc


func _unhandled_input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e.is_action_pressed("zakladka_lewo"):
		zakladki.current_tab = (zakladki.current_tab + zakladki.get_tab_count() - 1) % zakladki.get_tab_count()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("zakladka_prawo"):
		zakladki.current_tab = (zakladki.current_tab + 1) % zakladki.get_tab_count()
		get_viewport().set_input_as_handled()


func _losowe_ziarno() -> String:
	var z := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var s := ""
	for i in 6:
		s += z[randi() % z.length()]
	return s


func _wyczysc(c: Control) -> void:
	for d in c.get_children():
		d.queue_free()


func odswiez() -> void:
	var d := Profil.d
	naglowek.text = "🪙 %d   ⚒ %d   🔥 %d   🏺 %d   |   Wyprawy %d (przeżyte %d)   " % [
		d["gold"], Profil.licz_surowiec("iron"), Profil.licz_surowiec("ash"), Profil.licz_surowiec("relic"), d["stats"]["raids"], d["stats"]["survived"]]
	match zakladki.current_tab:
		0: _wyprawa()
		1: _ekwipunek()
		2: _kupiec()
		3: _warownia()
		4: _umiejetnosci()
	_przywroc_fokus.call_deferred()


func _przywroc_fokus() -> void:
	var kontener := zakladki.get_current_tab_control()
	var pierwszy: Control = null
	for c in kontener.find_children("*", "Button", true, false):
		if c.is_queued_for_deletion() or not c.is_visible_in_tree() or c.disabled:
			continue
		if pierwszy == null:
			pierwszy = c
		if _fokus_klucz != "" and c.get_meta("klucz", "") == _fokus_klucz:
			c.grab_focus()
			return
	if pierwszy:
		pierwszy.grab_focus()


func _przycisk(tekst: String, klucz: String, akcja: Callable, opis_txt := "") -> Button:
	var b := Button.new()
	b.text = tekst
	b.set_meta("klucz", klucz)
	b.pressed.connect(func(): _fokus_klucz = klucz; akcja.call())
	if opis_txt != "":
		b.focus_entered.connect(func(): opis.text = opis_txt)
		b.mouse_entered.connect(func(): opis.text = opis_txt)
	return b


func _slot(inst, klucz: String, akcja: Callable, na_relikwiarz := Callable()) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 56)
	b.clip_text = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta("klucz", klucz)
	if inst == null:
		b.text = "—"
		b.modulate = Color(1, 1, 1, 0.45)
		return b
	var d := Dane.p(inst["id"])
	b.icon = Dane.ikona(inst["id"])
	b.add_theme_constant_override("icon_max_width", 32)
	var dop := " x%d" % int(inst["qty"]) if d.get("type") == "arrow" else ""
	b.text = str(d["name"]) + dop
	var ramka := StyleBoxFlat.new()
	ramka.bg_color = Color("16131a")
	ramka.border_color = Dane.KOLORY_RZADKOSCI.get(d.get("rarity"), Color.GRAY)
	ramka.border_width_left = 4
	ramka.set_corner_radius_all(3)
	ramka.content_margin_left = 8
	b.add_theme_stylebox_override("normal", ramka)
	var t := "%s — %s\n%s\n%s" % [d["name"], Dane.NAZWY_TYPOW.get(d.get("type"), ""), d.get("desc", ""), Dane.opis_statystyk(inst)]
	b.tooltip_text = t
	b.focus_entered.connect(func(): opis.text = t)
	b.mouse_entered.connect(func(): opis.text = t)
	b.pressed.connect(func():
		_fokus_klucz = klucz
		if Input.is_key_pressed(KEY_SHIFT) and na_relikwiarz.is_valid():
			na_relikwiarz.call()
		else:
			akcja.call())
	if na_relikwiarz.is_valid():
		b.gui_input.connect(func(e: InputEvent):
			if e.is_action_pressed("okno_relikwiarz"):
				_fokus_klucz = klucz
				na_relikwiarz.call()
				get_viewport().set_input_as_handled())
	return b


func _zmiana() -> void:
	Dzwiek.ui()
	Profil.zapisz()
	odswiez()


# ------------------------------------------------------------ WYPRAWA
func _wyprawa() -> void:
	_wyczysc(t_wyprawa)
	t_wyprawa.add_child(Ui.etykieta("WYBIERZ KRAINĘ WYPRAWY", 16, Ui.ZLOTO))
	var h := HBoxContainer.new()
	for k in Dane.krainy:
		var id: String = k["id"]
		var b := _przycisk("%s%s\n%s  •  %s" % ["▶ " if id == wybrana_kraina else "", k["name"], k["diff"], k["lootStars"]], "kraina_" + id,
			func(): wybrana_kraina = id; _wyprawa(), "%s\n%s" % [k["subtitle"], k["desc"]])
		b.custom_minimum_size = Vector2(300, 64)
		if id == wybrana_kraina:
			b.add_theme_color_override("font_color", Color("f0b96e"))
		h.add_child(b)
	t_wyprawa.add_child(h)
	var hz := HBoxContainer.new()
	hz.add_child(Ui.etykieta("ZIARNO MAPY: ", 14, Ui.SZARY))
	var pole := LineEdit.new()
	pole.text = ziarno
	pole.max_length = 12
	pole.custom_minimum_size = Vector2(160, 0)
	pole.text_changed.connect(func(t): ziarno = t.to_upper())
	hz.add_child(pole)
	hz.add_child(_przycisk("🎲 Losuj", "losuj", func(): ziarno = _losowe_ziarno(); _wyprawa()))
	t_wyprawa.add_child(hz)
	var l: Dictionary = Profil.d["loadout"]
	var nazwa := func(k): return Dane.p(l[k]["id"])["name"] if l[k] else "BRAK"
	var flaszki := 0
	var strzaly := 0
	for it in l["backpack"] + l["reliquary"]:
		if Dane.p(it["id"]).get("elixKind") == "heal":
			flaszki += 1
		if it["id"] == "iron_arrows":
			strzaly += int(it["qty"])
	var gotowosc := "GOTOWOŚĆ RYCERZA\nBroń: %s   •   Tarcza: %s   •   Łuk: %s (%d strzał)   •   Pancerz: %s\nFlaszki Żaru: %d   •   Sakwa: %d/12   •   Relikwiarz: %d/%d" % [
		nazwa.call("weapon"), nazwa.call("shield"), nazwa.call("bow"), strzaly, nazwa.call("armor"), flaszki, l["backpack"].size(), l["reliquary"].size(), Profil.max_relikwiarz()]
	t_wyprawa.add_child(Ui.etykieta(gotowosc, 14))
	if not l["weapon"]:
		t_wyprawa.add_child(Ui.etykieta("⚠ Brak broni białej! Odbierz Zestaw Wygnańca u Kupca lub załóż broń ze Skrytki.", 13, Color("fca5a5")))
	if flaszki == 0:
		t_wyprawa.add_child(Ui.etykieta("⚠ Nie masz Flaszek Żaru do leczenia w trakcie wyprawy.", 13, Color("fca5a5")))
	var start := Ui.przycisk_akcji("⚔  ROZPOCZNIJ WYPRAWĘ")
	start.set_meta("klucz", "start")
	start.custom_minimum_size = Vector2(0, 56)
	start.add_theme_font_size_override("font_size", 20)
	start.pressed.connect(func(): start_rajdu.emit(wybrana_kraina, ziarno if ziarno != "" else _losowe_ziarno()))
	t_wyprawa.add_child(start)
	var instr := "STEROWANIE  (klawiatura i mysz / pad)\n" + \
		"Ruch: WASD / lewy drążek    •    Celowanie: mysz / prawy drążek\n" + \
		"Combo: LPM / RB lub X    •    Parowanie i blok: PPM / LB    •    Unik: Spacja / B\n" + \
		"Łuk: Q / Y    •    Przeszukaj: E / A    •    Mikstury: 1-2-3 / krzyżak ↑ ← →\n" + \
		"Pochodnia: F / krzyżak ↓    •    Zrzuć sakwę: G / R3    •    Sakwa: Tab / Back\n\n" + \
		"Paruj, gdy broń wroga błyśnie ZŁOTEM, i odpowiedz Ripostą. CZERWONY błysk: tylko unik.\n" + \
		"Pochodnia zajmuje rękę tarczy: rzuć ją przed walką. Złamana postura (żółty pasek) też otwiera Ripostę.\n" + \
		"Śmierć zabiera wszystko poza Relikwiarzem i połowę zdobytego doświadczenia."
	t_wyprawa.add_child(Ui.etykieta(instr, 13, Ui.SZARY))


# ------------------------------------------------------------ EKWIPUNEK
func _ekwipunek() -> void:
	_wyczysc(t_ekw)
	var d := Profil.d
	var l: Dictionary = d["loadout"]
	var lewa := VBoxContainer.new()
	t_ekw.add_child(lewa)
	lewa.add_child(Ui.etykieta("RYNSZTUNEK NA WYPRAWĘ (klik zdejmuje do Skrytki)", 14, Ui.ZLOTO))
	var g := GridContainer.new()
	g.columns = 2
	for k in ["weapon", "shield", "bow", "armor"]:
		var slot: String = k
		g.add_child(_slot(l[k], "eq_" + k, func():
			if l[slot] == null:
				return
			if d["stash"].size() >= Profil.max_skrytka():
				opis.text = "Skrytka jest pełna!"
				return
			d["stash"].append(l[slot])
			l[slot] = null
			_zmiana()))
	lewa.add_child(g)
	lewa.add_child(Ui.etykieta("🔒 RELIKWIARZ %d/%d (chroniony po śmierci)" % [l["reliquary"].size(), Profil.max_relikwiarz()], 14, Ui.ZLOTO))
	var gr := GridContainer.new()
	gr.columns = 3
	for i in Profil.max_relikwiarz():
		var idx := i
		gr.add_child(_slot(l["reliquary"][i] if i < l["reliquary"].size() else null, "rel%d" % i, func():
			if d["stash"].size() >= Profil.max_skrytka():
				return
			d["stash"].append(l["reliquary"].pop_at(idx))
			_zmiana()))
	lewa.add_child(gr)
	lewa.add_child(Ui.etykieta("🎒 SAKWA %d/12 (klik → Skrytka, Shift/Y → Relikwiarz)" % l["backpack"].size(), 14, Ui.SZARY))
	var gb := GridContainer.new()
	gb.columns = 3
	for i in Profil.SAKWA_MAX:
		var idx := i
		gb.add_child(_slot(l["backpack"][i] if i < l["backpack"].size() else null, "bp%d" % i,
			func():
				if d["stash"].size() >= Profil.max_skrytka():
					return
				d["stash"].append(l["backpack"].pop_at(idx))
				_zmiana(),
			func():
				if l["reliquary"].size() >= Profil.max_relikwiarz():
					opis.text = "Relikwiarz jest pełny!"
					return
				l["reliquary"].append(l["backpack"].pop_at(idx))
				_zmiana()))
	lewa.add_child(gb)
	var prawa := VBoxContainer.new()
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_ekw.add_child(prawa)
	var hp := HBoxContainer.new()
	var tt := Ui.etykieta("SKRYTKA WAROWNI %d/%d (klik zakłada lub pakuje do sakwy)" % [d["stash"].size(), Profil.max_skrytka()], 14, Ui.ZLOTO)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp.add_child(tt)
	hp.add_child(_przycisk("Sortuj", "sortuj", func():
		var kol := {"weapon": 1, "shield": 2, "bow": 3, "armor": 4, "arrow": 5, "elixir": 6, "material": 7, "valuable": 8}
		d["stash"].sort_custom(func(a, b): return kol.get(Dane.typ(a["id"]), 9) < kol.get(Dane.typ(b["id"]), 9))
		_zmiana()))
	prawa.add_child(hp)
	var gs := GridContainer.new()
	gs.columns = 4
	for i in Profil.max_skrytka():
		var idx := i
		gs.add_child(_slot(d["stash"][i] if i < d["stash"].size() else null, "st%d" % i,
			func():
				var it: Dictionary = d["stash"][idx]
				var t := Dane.typ(it["id"])
				if t in ["weapon", "shield", "bow", "armor"] and l[t] == null:
					l[t] = d["stash"].pop_at(idx)
				elif l["backpack"].size() < Profil.SAKWA_MAX:
					l["backpack"].append(d["stash"].pop_at(idx))
				else:
					opis.text = "Sakwa jest pełna (12/12)!"
					return
				_zmiana(),
			func():
				if l["reliquary"].size() >= Profil.max_relikwiarz():
					opis.text = "Relikwiarz jest pełny!"
					return
				l["reliquary"].append(d["stash"].pop_at(idx))
				_zmiana()))
	prawa.add_child(gs)


# ------------------------------------------------------------ KUPIEC
func _kupiec() -> void:
	_wyczysc(t_kupiec)
	var d := Profil.d
	var lewa := VBoxContainer.new()
	lewa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lewa.size_flags_stretch_ratio = 1.4
	t_kupiec.add_child(lewa)
	lewa.add_child(Ui.etykieta("WĘDROWNY KUPIEC „KOWAL POPIOŁU”  (lepszy oręż odblokowuje Kuźnia)", 14, Ui.ZLOTO))
	var ma_bron: bool = d["loadout"]["weapon"] != null
	for it in d["stash"] + d["loadout"]["backpack"]:
		if Dane.typ(it["id"]) == "weapon":
			ma_bron = true
	if not ma_bron and d["gold"] < 200:
		var zestaw := Ui.przycisk_akcji("🆘 Zestaw Wygnańca (0 zł)")
		zestaw.set_meta("klucz", "zestaw")
		zestaw.pressed.connect(func():
			d["loadout"]["weapon"] = Profil.nowy_przedmiot("rusty_sword")
			d["loadout"]["shield"] = Profil.nowy_przedmiot("wood_buckler")
			if d["loadout"]["backpack"].size() < Profil.SAKWA_MAX:
				d["loadout"]["backpack"].append(Profil.nowy_przedmiot("ember_flask"))
			_zmiana())
		lewa.add_child(zestaw)
	var kat := HBoxContainer.new()
	for k in [["all", "Wszystko"], ["weapon", "Broń"], ["shield", "Tarcze"], ["bow", "Łuki"], ["armor", "Pancerze"], ["elixir", "Mikstury"]]:
		var id: String = k[0]
		var b := _przycisk(("▶ " if kategoria == id else "") + k[1], "kat_" + id, func(): kategoria = id; _kupiec())
		kat.add_child(b)
	lewa.add_child(kat)
	var g := GridContainer.new()
	g.columns = 2
	var kuznia := Profil.budynek("forge")
	for id in Dane.przedmioty:
		var def: Dictionary = Dane.przedmioty[id]
		var t: String = def["type"]
		if t == "material" or t == "valuable":
			continue
		if kategoria != "all" and not (t == kategoria or (kategoria == "bow" and t == "arrow")):
			continue
		var zablok := int(def.get("forgeReq", 0)) > kuznia
		var cena := int(def["price"])
		var napis := "%s — %d zł" % [def["name"], cena] if not zablok else "%s — wymaga Kuźni %d" % [def["name"], int(def["forgeReq"])]
		var pid: String = id
		var b := _przycisk(napis, "kup_" + id, func(): _kup(pid), "%s\n%s" % [def["desc"], Dane.opis_statystyk(Profil.nowy_przedmiot(pid))])
		b.icon = Dane.ikona(id)
		b.add_theme_constant_override("icon_max_width", 28)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(330, 44)
		b.disabled = zablok or d["gold"] < cena
		g.add_child(b)
	lewa.add_child(g)
	var prawa := VBoxContainer.new()
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_kupiec.add_child(prawa)
	var hs := HBoxContainer.new()
	var ts := Ui.etykieta("SPRZEDAŻ ŁUPU (surowce lepiej zachować!)", 14, Ui.ZAR)
	ts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hs.add_child(ts)
	hs.add_child(_przycisk("Sprzedaj kosztowności", "sprzedaj_kosztownosci", func():
		var zysk := 0
		for lista in [d["stash"], d["loadout"]["backpack"]]:
			for i in range(lista.size() - 1, -1, -1):
				if Dane.typ(lista[i]["id"]) == "valuable":
					zysk += Dane.cena_skupu(lista[i]["id"])
					lista.remove_at(i)
		d["gold"] += zysk
		opis.text = "Sprzedano kosztowności za %d zł." % zysk if zysk > 0 else "Brak kosztowności na sprzedaż."
		_zmiana()))
	prawa.add_child(hs)
	var wpisy: Array = []
	for i in d["stash"].size():
		wpisy.append(["stash", i])
	for i in d["loadout"]["backpack"].size():
		wpisy.append(["backpack", i])
	if wpisy.is_empty():
		prawa.add_child(Ui.etykieta("Brak przedmiotów na sprzedaż.", 13, Ui.SZARY))
	for w in wpisy:
		var lista: Array = d["stash"] if w[0] == "stash" else d["loadout"]["backpack"]
		var it: Dictionary = lista[w[1]]
		var cena := Dane.cena_skupu(it["id"])
		var zrodlo: String = w[0]
		var idx: int = w[1]
		var b := _przycisk("%s (%s)  +%d zł" % [Dane.p(it["id"])["name"], "Skrytka" if zrodlo == "stash" else "Sakwa", cena], "sp_%s%d" % [zrodlo, idx], func():
			var ls: Array = d["stash"] if zrodlo == "stash" else d["loadout"]["backpack"]
			ls.remove_at(idx)
			d["gold"] += cena
			Dzwiek.lup()
			_zmiana())
		b.icon = Dane.ikona(it["id"])
		b.add_theme_constant_override("icon_max_width", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		prawa.add_child(b)


func _kup(id: String) -> void:
	var d := Profil.d
	var def := Dane.p(id)
	var cena := int(def["price"])
	if d["gold"] < cena:
		opis.text = "Za mało złota!"
		return
	if d["stash"].size() >= Profil.max_skrytka() and d["loadout"]["backpack"].size() >= Profil.SAKWA_MAX:
		opis.text = "Brak miejsca w Skrytce i Sakwie!"
		return
	d["gold"] -= cena
	var inst := Profil.nowy_przedmiot(id)
	var t: String = def["type"]
	var l: Dictionary = d["loadout"]
	if t in ["weapon", "shield", "bow", "armor"] and l[t] == null:
		l[t] = inst
	elif d["stash"].size() < Profil.max_skrytka():
		d["stash"].append(inst)
	else:
		l["backpack"].append(inst)
	opis.text = "Kupiono: " + str(def["name"])
	Dzwiek.lup()
	_zmiana()


# ------------------------------------------------------------ WAROWNIA
func _warownia() -> void:
	_wyczysc(t_warownia)
	t_warownia.add_child(Ui.etykieta("ROZBUDOWA WAROWNI — inwestuj złoto, żelazo, esencję popiołu i relikty", 15, Ui.ZLOTO))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	for id in Dane.warownia:
		var up: Dictionary = Dane.warownia[id]
		var lv := Profil.budynek(id)
		var maks := int(up["maxLv"])
		var p := Ui.panel()
		p.custom_minimum_size = Vector2(560, 0)
		var v := VBoxContainer.new()
		v.add_child(Ui.etykieta("%s %s   —   poziom %d / %d" % [up["icon"], up["name"], lv, maks], 16, Ui.ZLOTO))
		var o := Ui.etykieta(up["desc"], 13)
		o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(o)
		if lv >= maks:
			v.add_child(Ui.etykieta("✓ MAKSYMALNY POZIOM", 14, Color("34d399")))
		else:
			var k: Dictionary = up["costs"][lv]
			var stac: bool = Profil.d["gold"] >= int(k["gold"]) and Profil.licz_surowiec("iron") >= int(k["iron"]) \
				and Profil.licz_surowiec("ash") >= int(k["ash"]) and Profil.licz_surowiec("relic") >= int(k["relic"])
			var koszt := "🪙 %d zł" % int(k["gold"])
			if int(k["iron"]) > 0: koszt += "   ⚒ %d żelaza" % int(k["iron"])
			if int(k["ash"]) > 0: koszt += "   🔥 %d popiołu" % int(k["ash"])
			if int(k["relic"]) > 0: koszt += "   🏺 %d reliktów" % int(k["relic"])
			v.add_child(Ui.etykieta(koszt, 13, Ui.POPIOL if stac else Color("f87171")))
			var bid: String = id
			var b := Ui.przycisk_akcji("Rozbuduj do poziomu %d" % (lv + 1))
			b.set_meta("klucz", "up_" + id)
			b.disabled = not stac
			b.pressed.connect(func():
				_fokus_klucz = "up_" + bid
				Profil.d["gold"] -= int(k["gold"])
				Profil.zuzyj_surowiec("iron", int(k["iron"]))
				Profil.zuzyj_surowiec("ash", int(k["ash"]))
				Profil.zuzyj_surowiec("relic", int(k["relic"]))
				Profil.d["stronghold"][bid] = Profil.budynek(bid) + 1
				Dzwiek.ekstrakcja()
				opis.text = "🏰 Ulepszono: %s (poziom %d)!" % [up["name"], Profil.budynek(bid)]
				Profil.zapisz()
				odswiez())
			v.add_child(b)
		p.add_child(v)
		g.add_child(p)
	t_warownia.add_child(g)


# ------------------------------------------------------------ UMIEJĘTNOŚCI
func _umiejetnosci() -> void:
	_wyczysc(t_umiej)
	t_umiej.add_child(Ui.etykieta("BIEGŁOŚCI RYCERZA — rosną w walce, przy parowaniu, unikach, strzelaniu i przeszukiwaniu", 15, Ui.ZLOTO))
	for id in Dane.umiejetnosci:
		var u: Dictionary = Dane.umiejetnosci[id]
		var sk: Dictionary = Profil.d["skills"][id]
		var wym := int(sk["lv"]) * 100
		var p := Ui.panel()
		var v := VBoxContainer.new()
		v.add_child(Ui.etykieta("%s %s   —   poziom %d" % [u["icon"], u["name"], int(sk["lv"])], 15, Ui.ZLOTO))
		v.add_child(Ui.etykieta("%s     (%d / %d PD)" % [u["bonusDesc"], int(sk["xp"]), wym], 13))
		var pas := Ui.pasek(Color("c26a2c"), 8)
		pas.max_value = wym
		pas.value = float(sk["xp"])
		v.add_child(pas)
		p.add_child(v)
		t_umiej.add_child(p)
