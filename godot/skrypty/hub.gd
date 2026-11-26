extends Control
## Warownia (hub): Wyprawa, Ekwipunek i Skrytka, Kupiec, Warownia, Umiejętności.
## Pad: krzyżak/drążek nawigacja, A wybór, Y do Relikwiarza, LB/RB zakładki.

signal start_rajdu(kraina: String, ziarno: String)
signal zamknij  # powrót do Przystani (B / Esc / przycisk)

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
var przycisk_grafiki: Button
var _fokus_klucz := ""


func _ready() -> void:
	theme = Ui.motyw()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ziarno = _losowe_ziarno()
	var tlo := ColorRect.new()
	tlo.color = Color(0.043, 0.035, 0.05, 0.9)  # półprzezroczyste: za menu widać Przystań
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
	naglowek = Ui.etykieta("", 15, Color("d9c7a4"))
	przycisk_dzwieku = Button.new()
	przycisk_dzwieku.text = "Dźwięk: wł."
	przycisk_dzwieku.pressed.connect(func():
		Dzwiek.wyciszony = not Dzwiek.wyciszony
		przycisk_dzwieku.text = "Dźwięk: wył." if Dzwiek.wyciszony else "Dźwięk: wł.")
	gora.add_child(przycisk_dzwieku)
	przycisk_grafiki = Button.new()
	przycisk_grafiki.text = "Grafika: " + Profil.JAKOSCI[Profil.jakosc()]
	przycisk_grafiki.tooltip_text = "Jakość grafiki rajdu (cienie, odbicia, mgła). Niższa = płynniej."
	przycisk_grafiki.pressed.connect(func():
		Profil.ustaw_jakosc((Profil.jakosc() + 1) % Profil.JAKOSCI.size())
		Dzwiek.ui()
		przycisk_grafiki.text = "Grafika: " + Profil.JAKOSCI[Profil.jakosc()])
	gora.add_child(przycisk_grafiki)
	var wroc := Button.new()
	wroc.text = "Przystań"
	wroc.tooltip_text = "Wróć do Przystani (B / Esc)"
	wroc.pressed.connect(func(): zamknij.emit())
	gora.add_child(wroc)
	var reset := Button.new()
	reset.text = "Reset"
	reset.pressed.connect(func(): dialog_reset.popup_centered())
	gora.add_child(reset)
	v.add_child(gora)
	v.add_child(naglowek)
	zakladki = TabContainer.new()
	zakladki.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(zakladki)
	t_wyprawa = _zakladka("Wyprawa", VBoxContainer.new())
	t_ekw = _zakladka("Ekwipunek", HBoxContainer.new())
	t_kupiec = _zakladka("Kupiec", HBoxContainer.new())
	t_warownia = _zakladka("Warownia", VBoxContainer.new())
	t_umiej = _zakladka("Umiejętności", VBoxContainer.new())
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
	Profil.awans.connect(func(u, lv): opis.text = "Awans: %s (poziom %d)!" % [Dane.umiejetnosci[u]["name"], lv])
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
	if e.is_action_pressed("ui_cancel") and not dialog_reset.visible:
		zamknij.emit()
		get_viewport().set_input_as_handled()
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
	naglowek.text = "Złoto %d   ·   Żelazo %d   ·   Popiół %d   ·   Relikty %d   ·   Wyprawy %d (przeżyte %d)   " % [
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
	b.custom_minimum_size = Vector2(166, 58)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta("klucz", klucz)
	if inst == null:
		b.text = ""
		b.add_theme_stylebox_override("normal", Ui.styl_slotu(Color.GRAY))
		b.add_theme_stylebox_override("focus", Ui.styl_slotu(Color.GRAY, true))
		b.add_theme_stylebox_override("hover", Ui.styl_slotu(Color.GRAY, true))
		b.modulate = Color(1, 1, 1, 0.55)
		return b
	var d := Dane.p(inst["id"])
	b.icon = Dane.ikona(inst["id"])
	b.add_theme_constant_override("icon_max_width", 32)
	var dop := " x%d" % int(inst["qty"]) if d.get("type") == "arrow" else ""
	b.text = str(d["name"]) + dop
	var rz: Color = Dane.KOLORY_RZADKOSCI.get(d.get("rarity"), Color.GRAY)
	b.add_theme_stylebox_override("normal", Ui.styl_slotu(rz))
	b.add_theme_stylebox_override("hover", Ui.styl_slotu(rz, true))
	b.add_theme_stylebox_override("focus", Ui.styl_slotu(rz, true))
	b.add_theme_stylebox_override("pressed", Ui.styl_slotu(rz, true))
	b.add_theme_color_override("font_color", rz.lightened(0.35))
	b.add_theme_font_size_override("font_size", 14)
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


## Zaznaczona opcja (wybrana kraina, kategoria): bordowa tablica i złoty napis — bez strzałek.
func _wybrany(b: Button) -> void:
	b.add_theme_stylebox_override("normal", b.get_theme_stylebox("focus"))
	b.add_theme_color_override("font_color", Color("ffd58a"))


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
		var b := _przycisk("%s%s\n%s  •  %s" % ["" if id == wybrana_kraina else "", k["name"], k["diff"], k["lootStars"]], "kraina_" + id,
			func(): wybrana_kraina = id; _wyprawa(), "%s\n%s" % [k["subtitle"], k["desc"]])
		b.custom_minimum_size = Vector2(250 if Dane.krainy.size() > 3 else 300, 72)
		if id == wybrana_kraina:
			_wybrany(b)
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
	hz.add_child(_przycisk("Losuj", "losuj", func(): ziarno = _losowe_ziarno(); _wyprawa()))
	t_wyprawa.add_child(hz)
	# kontrakty Chojraka: liczą się tylko po udanej ekstrakcji
	t_wyprawa.add_child(Ui.etykieta("KONTRAKTY CHOJRAKA (liczą się po powrocie z wyprawy)", 15, Ui.ZLOTO))
	for k in Profil.d.get("kontrakty", []):
		t_wyprawa.add_child(Ui.etykieta("   • %s — %d/%d — nagroda %d zł" % [Profil.opis_kontraktu(k), int(k["postep"]), int(k["cel"]), int(k["nagroda"])], 13))
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
		t_wyprawa.add_child(Ui.etykieta("Uwaga: brak broni białej! Odbierz Zestaw Wygnańca u Kupca lub załóż broń ze Skrytki.", 13, Color("fca5a5")))
	if flaszki == 0:
		t_wyprawa.add_child(Ui.etykieta("Uwaga: nie masz Flaszek Żaru do leczenia w trakcie wyprawy.", 13, Color("fca5a5")))
	var start := Ui.przycisk_akcji("Rozpocznij wyprawę")
	start.set_meta("klucz", "start")
	start.custom_minimum_size = Vector2(0, 56)
	start.add_theme_font_size_override("font_size", 20)
	start.pressed.connect(func(): start_rajdu.emit(wybrana_kraina, ziarno if ziarno != "" else _losowe_ziarno()))
	t_wyprawa.add_child(start)
	var instr := "Paruj, gdy broń wroga błyśnie ZŁOTEM, i odpowiedz Ripostą. CZERWONY błysk: tylko unik.\n" + \
		"Pochodnia zajmuje rękę tarczy: rzuć ją przed walką. Złamana postura też otwiera Ripostę.\n" + \
		"Śmierć zabiera wszystko poza Relikwiarzem i połowę zdobytego doświadczenia.\n" + \
		"Pełne sterowanie (klawiatura, mysz i pad): pauza — Esc / P / Start."
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
	lewa.add_child(Ui.etykieta("RELIKWIARZ %d/%d (chroniony po śmierci)" % [l["reliquary"].size(), Profil.max_relikwiarz()], 14, Ui.ZLOTO))
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
	lewa.add_child(Ui.etykieta("SAKWA %d/12 (klik: do Skrytki, Shift / Y: do Relikwiarza)" % l["backpack"].size(), 14, Ui.SZARY))
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


# ------------------------------------------------------------ KUPIEC (kram jak w NightBrand)
## Tryby: Kup / Sprzedaj. Karty przedmiotów (ikona, nazwa w kolorze rzadkości, cena); z prawej szczegóły i porównanie
## z założonym. Zablokowane i za drogie karty da się wybrać (pad) i przeczytać, dlaczego nie można kupić.
var tryb_kupca := "kup"
var _sz_ikona: TextureRect
var _sz_nazwa: Label
var _sz_typ: Label
var _sz_opis: Label
var _sz_staty: Label
var _sz_porown: Label
var _sz_cena: Label


func _kupiec() -> void:
	_wyczysc(t_kupiec)
	var d := Profil.d
	var lewa := VBoxContainer.new()
	lewa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lewa.add_theme_constant_override("separation", 8)
	t_kupiec.add_child(lewa)
	var gora := HBoxContainer.new()
	var tyt := Ui.etykieta("KRAM MARGI", 22, Color("efe2c8"))
	tyt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gora.add_child(tyt)
	gora.add_child(Ui.etykieta("Twoje złoto: %d zł" % int(d["gold"]), 18, Ui.ZLOTO))
	lewa.add_child(gora)
	lewa.add_child(Ui.etykieta("Lepszy oręż odblokowuje Kuźnia Warowni.", 14, Color("9d8f78")))
	var tryby := HBoxContainer.new()
	tryby.add_theme_constant_override("separation", 8)
	for t in [["kup", "Kup"], ["sprzedaj", "Sprzedaj łup"]]:
		var id: String = t[0]
		var b := _przycisk(t[1], "tryb_" + id, func(): tryb_kupca = id; _kupiec())
		b.custom_minimum_size = Vector2(180, 46)
		if tryb_kupca == id:
			_wybrany(b)
		tryby.add_child(b)
	lewa.add_child(tryby)
	var ma_bron: bool = d["loadout"]["weapon"] != null
	for it in d["stash"] + d["loadout"]["backpack"]:
		if Dane.typ(it["id"]) == "weapon":
			ma_bron = true
	if not ma_bron and d["gold"] < 200:
		var zestaw := Ui.przycisk_akcji("Zestaw Wygnańca (0 zł)")
		zestaw.set_meta("klucz", "zestaw")
		zestaw.pressed.connect(func():
			d["loadout"]["weapon"] = Profil.nowy_przedmiot("rusty_sword")
			d["loadout"]["shield"] = Profil.nowy_przedmiot("wood_buckler")
			if d["loadout"]["backpack"].size() < Profil.SAKWA_MAX:
				d["loadout"]["backpack"].append(Profil.nowy_przedmiot("ember_flask"))
			_zmiana())
		lewa.add_child(zestaw)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 8)
	if tryb_kupca == "kup":
		var kat := HBoxContainer.new()
		kat.add_theme_constant_override("separation", 6)
		for k in [["all", "Wszystko"], ["weapon", "Broń"], ["shield", "Tarcze"], ["bow", "Łuki"], ["armor", "Pancerze"], ["elixir", "Mikstury"]]:
			var id: String = k[0]
			var b := _przycisk(k[1], "kat_" + id, func(): kategoria = id; _kupiec())
			b.add_theme_font_size_override("font_size", 15)
			if kategoria == id:
				_wybrany(b)
			kat.add_child(b)
		lewa.add_child(kat)
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
			var pid: String = id
			var dol := "wymaga Kuźni %d" % int(def["forgeReq"]) if zablok else "%d zł" % cena
			var b := _karta(pid, Profil.nowy_przedmiot(pid), dol, "kup_" + pid, func(): _kup(pid), zablok or d["gold"] < cena, cena)
			g.add_child(b)
	else:
		var hs := HBoxContainer.new()
		var ts := Ui.etykieta("Surowce (żelazo, popiół, relikty) lepiej zachować na rozbudowę.", 14, Color("9d8f78"))
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
		lewa.add_child(hs)
		var wpisy: Array = []
		for i in d["stash"].size():
			wpisy.append(["stash", i])
		for i in d["loadout"]["backpack"].size():
			wpisy.append(["backpack", i])
		if wpisy.is_empty():
			lewa.add_child(Ui.etykieta("Nie masz nic na sprzedaż.", 15, Ui.SZARY))
		for w in wpisy:
			var lista: Array = d["stash"] if w[0] == "stash" else d["loadout"]["backpack"]
			var it: Dictionary = lista[w[1]]
			var cena := Dane.cena_skupu(it["id"])
			var zrodlo: String = w[0]
			var idx: int = w[1]
			var b := _karta(it["id"], it, "+%d zł   ·   %s" % [cena, "Skrytka" if zrodlo == "stash" else "Sakwa"], "sp_%s%d" % [zrodlo, idx], func():
				var ls: Array = d["stash"] if zrodlo == "stash" else d["loadout"]["backpack"]
				ls.remove_at(idx)
				d["gold"] += cena
				Dzwiek.lup()
				_zmiana(), false, -cena)
			g.add_child(b)
	lewa.add_child(g)
	t_kupiec.add_child(_panel_szczegolow())


## Karta przedmiotu w kramie. przyciemniona = nie stać cię albo zablokowana (nadal do wybrania i przeczytania).
func _karta(id: String, inst: Dictionary, dol: String, klucz: String, akcja: Callable, przyciemniona: bool, cena: int) -> Button:
	var def := Dane.p(id)
	var rz: Color = Dane.KOLORY_RZADKOSCI.get(def.get("rarity"), Color.GRAY)
	var dop := " x%d" % int(inst.get("qty", 0)) if def.get("type") == "arrow" and cena < 0 else ""
	var b := _przycisk("%s%s\n%s" % [def["name"], dop, dol], klucz, akcja)
	b.icon = Dane.ikona(id)
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 40)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(300, 64)
	b.add_theme_font_size_override("font_size", 15)
	for st in ["normal", "hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(st, Ui.styl_slotu(rz, st != "normal"))
	b.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45) if przyciemniona else rz.lightened(0.45))
	b.add_theme_color_override("font_focus_color", Color("fff1d6"))
	b.add_theme_color_override("font_hover_color", Color("fff1d6"))
	if przyciemniona:
		b.modulate = Color(0.75, 0.72, 0.7)
	var pokaz := func(): _pokaz_szczegoly(id, inst, cena)
	b.focus_entered.connect(pokaz)
	b.mouse_entered.connect(pokaz)
	return b


func _panel_szczegolow() -> Control:
	var p := Ui.panel()
	p.custom_minimum_size = Vector2(400, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	_sz_ikona = TextureRect.new()
	_sz_ikona.custom_minimum_size = Vector2(96, 96)
	_sz_ikona.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sz_ikona.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sz_ikona.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	v.add_child(_sz_ikona)
	_sz_nazwa = Ui.etykieta("Wybierz przedmiot", 22, Color("efe2c8"))
	_sz_nazwa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sz_nazwa.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(_sz_nazwa)
	_sz_typ = Ui.etykieta("", 15, Color("b9a27a"))
	_sz_typ.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_sz_typ)
	for l in ["_sz_opis", "_sz_staty", "_sz_porown"]:
		var e := Ui.etykieta("", 15)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.custom_minimum_size = Vector2(360, 0)
		set(l, e)
		v.add_child(e)
	_sz_opis.add_theme_color_override("font_color", Color("d6cbb6"))
	_sz_staty.add_theme_color_override("font_color", Color("ede2cc"))
	_sz_porown.add_theme_color_override("font_color", Color("9fb7a0"))
	_sz_cena = Ui.etykieta("", 20, Ui.ZLOTO)
	_sz_cena.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_sz_cena)
	return p


func _pokaz_szczegoly(id: String, inst: Dictionary, cena: int) -> void:
	if _sz_nazwa == null or not is_instance_valid(_sz_nazwa):
		return
	var def := Dane.p(id)
	var rz: Color = Dane.KOLORY_RZADKOSCI.get(def.get("rarity"), Color.GRAY)
	_sz_ikona.texture = Dane.ikona(id)
	_sz_nazwa.text = str(def["name"])
	_sz_nazwa.add_theme_color_override("font_color", rz.lightened(0.4))
	_sz_typ.text = str(Dane.NAZWY_TYPOW.get(def.get("type"), ""))
	_sz_opis.text = str(def.get("desc", ""))
	var staty := Dane.opis_statystyk(inst)
	_sz_staty.text = staty.substr(staty.find("\n") + 1) if staty.contains("\n") else ""
	# porównanie z założonym przedmiotem tego samego rodzaju
	var t := str(def.get("type", ""))
	var zal = Profil.d["loadout"].get(t) if t in ["weapon", "shield", "bow", "armor"] else null
	if zal != null:
		var zd := Dane.p(zal["id"])
		var por := "Założone: %s" % zd["name"]
		if t in ["weapon", "bow"]:
			por += "   (obrażenia %+d)" % (int(def["dmg"]) - int(zd["dmg"]))
		elif t == "shield":
			por += "   (blok %+d%%)" % roundi((float(def["blockRed"]) - float(zd["blockRed"])) * 100)
		elif t == "armor":
			por += "   (redukcja %+d%%)" % roundi((float(def["reduction"]) - float(zd["reduction"])) * 100)
		_sz_porown.text = por
	elif t in ["weapon", "shield", "bow", "armor"]:
		_sz_porown.text = "Nie masz założonego przedmiotu tego rodzaju."
	else:
		_sz_porown.text = ""
	var kuznia := Profil.budynek("forge")
	if cena < 0:
		_sz_cena.text = "Sprzedaj za %d zł" % -cena
	elif int(def.get("forgeReq", 0)) > kuznia:
		_sz_cena.text = "Wymaga Kuźni na poziomie %d" % int(def["forgeReq"])
	elif int(Profil.d["gold"]) < cena:
		_sz_cena.text = "%d zł   ·   brakuje %d zł" % [cena, cena - int(Profil.d["gold"])]
	else:
		_sz_cena.text = "Kup za %d zł" % cena


func _kup(id: String) -> void:
	var d := Profil.d
	var def := Dane.p(id)
	var cena := int(def["price"])
	if int(def.get("forgeReq", 0)) > Profil.budynek("forge"):
		opis.text = "Ten oręż wymaga Kuźni na poziomie %d." % int(def["forgeReq"])
		return
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
		v.add_child(Ui.etykieta("%s   —   poziom %d / %d" % [up["name"], lv, maks], 16, Ui.ZLOTO))
		var o := Ui.etykieta(up["desc"], 13)
		o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(o)
		if lv >= maks:
			v.add_child(Ui.etykieta("MAKSYMALNY POZIOM", 14, Color("34d399")))
		else:
			var k: Dictionary = up["costs"][lv]
			var stac: bool = Profil.d["gold"] >= int(k["gold"]) and Profil.licz_surowiec("iron") >= int(k["iron"]) \
				and Profil.licz_surowiec("ash") >= int(k["ash"]) and Profil.licz_surowiec("relic") >= int(k["relic"])
			var koszt := "%d zł" % int(k["gold"])
			if int(k["iron"]) > 0: koszt += "   ·   %d żelaza" % int(k["iron"])
			if int(k["ash"]) > 0: koszt += "   ·   %d popiołu" % int(k["ash"])
			if int(k["relic"]) > 0: koszt += "   ·   %d reliktów" % int(k["relic"])
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
				opis.text = "Ulepszono: %s (poziom %d)!" % [up["name"], Profil.budynek(bid)]
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
		v.add_child(Ui.etykieta("%s   —   poziom %d" % [u["name"], int(sk["lv"])], 15, Ui.ZLOTO))
		v.add_child(Ui.etykieta("%s     (%d / %d PD)" % [u["bonusDesc"], int(sk["xp"]), wym], 13))
		var pas := Ui.pasek(Color("c26a2c"), 8)
		pas.max_value = wym
		pas.value = float(sk["xp"])
		v.add_child(pas)
		p.add_child(v)
		t_umiej.add_child(p)
