extends Control
## Warownia (hub): Wyprawa, Ekwipunek i Skrytka, Kupiec, Warownia, Umiejętności.
## Pad: krzyżak/drążek nawigacja, A wybór, Y do Relikwiarza, LB/RB zakładki.

signal start_rajdu(kraina: String, ziarno: String)
signal zamknij  # powrót do Przystani (B / Esc / przycisk)

const Ui = preload("res://skrypty/ui.gd")
const EkranMenu = preload("res://skrypty/ekran_menu.gd")

var wybrana_kraina := "catacombs"
var ziarno := ""
var kategoria := "all"
var naglowek: Label
var zakladki: TabContainer
var opis: Label
var t_wyprawa: VBoxContainer
var t_ekw: HBoxContainer
var t_kupiec: Control  # lista Kramu Margi (szablon menu)
var uklad: MarginContainer  # stary układ zakładek (Wyprawa, Ekwipunek, Warownia, Umiejętności)
var t_warownia: VBoxContainer
var t_umiej: VBoxContainer
var panel_opisu: PanelContainer
var _komunikat_kupca := ""  # w Kupcu komunikaty (kupiono, brak złota) idą do prawego panelu
var _znaczki: Control  # LB / RB przy zakładkach (pad)
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
	uklad = marg
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
	# Dźwięk i Grafika: w pauzie → Opcje (instrukcja przebudowy menu, etap 1)
	var wroc := Button.new()
	wroc.text = "Przystań"
	wroc.tooltip_text = "Wróć do Przystani (B / Esc)"
	wroc.pressed.connect(func(): zamknij.emit())
	gora.add_child(wroc)
	# Reset (usunięcie zapisu) przeniesiony do pauzy: Opcje → Dane zapisu (ocena NightBrand 26.11)
	v.add_child(gora)
	v.add_child(naglowek)
	zakladki = TabContainer.new()
	zakladki.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(zakladki)
	t_wyprawa = _zakladka("Wyprawa", VBoxContainer.new())
	t_ekw = _zakladka("Ekwipunek", HBoxContainer.new())
	_zakladka("Kupiec", HBoxContainer.new())  # pusta: Kram Margi rysuje się na szablonie (kram)
	t_warownia = _zakladka("Warownia", VBoxContainer.new())
	t_umiej = _zakladka("Umiejętności", VBoxContainer.new())
	# miejsce na znaczek LB przed pierwszą zakładką
	zakladki.add_theme_constant_override("side_margin", 44)
	# zmiana zakładki czyści opis (wcześniej w Kupcu wisiał tekst krainy z Wyprawy)
	zakladki.tab_changed.connect(func(_i): Dzwiek.ui(); _fokus_klucz = ""; opis.text = ""; _komunikat_kupca = ""; odswiez())
	opis = Ui.etykieta("", 13, Ui.POPIOL)
	opis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opis.custom_minimum_size = Vector2(0, 54)
	panel_opisu = Ui.panel()
	panel_opisu.add_child(opis)
	v.add_child(panel_opisu)
	_znaczki = Control.new()
	_znaczki.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_znaczki)
	_znaczki.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_znaczki.draw.connect(func(): Ui.rysuj_znaczki_zakladek(_znaczki, zakladki))
	_zbuduj_kram()
	t_kupiec = kram.lista
	Profil.awans.connect(func(u, lv): _info("Awans: %s (poziom %d)!" % [Dane.umiejetnosci[u]["name"], lv]))
	odswiez()


func _process(_dt: float) -> void:
	if is_visible_in_tree():
		_znaczki.queue_redraw()


## Komunikat dla gracza: w Kupcu w prawym panelu (jeden panel opisu), gdzie indziej w dolnym.
func _info(t: String) -> void:
	if zakladki.current_tab == 2:
		_komunikat_kupca = t
		if _sz_kom != null and is_instance_valid(_sz_kom):
			_sz_kom.text = t
	else:
		opis.text = t


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
	if e.is_action_pressed("ui_cancel"):
		zamknij.emit()
		get_viewport().set_input_as_handled()
		return
	if kram.visible and (e.is_action_pressed("zakladka_lewo") or e.is_action_pressed("zakladka_prawo")):
		# w Kramie LB/RB (Q/E) przełączają Kup / Sprzedaj; za skrajną zakładką — sąsiedni ekran Warowni
		var lewo := e.is_action_pressed("zakladka_lewo")
		if lewo and tryb_kupca == "sprzedaj":
			_kram_tryb("kup")
		elif not lewo and tryb_kupca == "kup":
			_kram_tryb("sprzedaj")
		else:
			zakladki.current_tab = 1 if lewo else 3
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
	panel_opisu.visible = zakladki.current_tab != 2  # Kupiec ma własny panel szczegółów po prawej
	# Kram Margi na nowym szablonie zasłania cały ekran (stary i nowy styl nie stoją obok siebie)
	kram.visible = zakladki.current_tab == 2
	uklad.visible = not kram.visible
	match zakladki.current_tab:
		0: _wyprawa()
		1: _ekwipunek()
		2: _kupiec()
		3: _warownia()
		4: _umiejetnosci()
	_przywroc_fokus.call_deferred()


func _przywroc_fokus() -> void:
	var kontener: Control = kram.lista if kram.visible else zakladki.get_current_tab_control()
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
	b.add_theme_font_size_override("font_size", 12)  # „Tonik Wytrzymałości” mieści się w slocie
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	# wcześniej: styl „focus” pobierany przed wejściem do drzewa = domyślna biała ramka Godota
	b.add_theme_stylebox_override("normal", Ui.styl_wybrany())
	b.add_theme_stylebox_override("hover", Ui.styl_wybrany())
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
	hz.visible = Ui.tryb_autora()  # narzędzie autora — gracz zawsze dostaje losową mapę
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
	start.pressed.connect(func():
		var z := ziarno if (ziarno != "" and Ui.tryb_autora()) else _losowe_ziarno()
		ziarno = _losowe_ziarno()  # następna wyprawa: nowa mapa
		start_rajdu.emit(wybrana_kraina, z))
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
				_info("Skrytka jest pełna!")
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
					_info("Relikwiarz jest pełny!")
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
					_info("Sakwa jest pełna (12/12)!")
					return
				_zmiana(),
			func():
				if l["reliquary"].size() >= Profil.max_relikwiarz():
					_info("Relikwiarz jest pełny!")
					return
				l["reliquary"].append(d["stash"].pop_at(idx))
				_zmiana()))
	prawa.add_child(gs)


# ------------------------------------------------------------ KUPIEC: KRAM MARGI (szablon menu NightBrand, etap 2)
## Ekran na szablonie `ekran_menu.gd`: zakładki Kup / Sprzedaj łup, lista z belkami sekcji po lewej,
## szczegóły z ilustracją, tabelą par i przyciskiem akcji po prawej. Ceny i reguły kupna bez zmian.
## Zablokowane i za drogie towary da się wybrać i przeczytać, dlaczego nie można kupić.
var tryb_kupca := "kup"
var kram: EkranMenu
var _sz_nazwa: Label
var _sz_typ: Label
var _sz_porown: Label
var _sz_kom: Label
var _sz_akcja: Button
var _kram_akcja := Callable()
var _kram_ostatni: Button

const SEKCJE_KRAMU := [["weapon", "Broń biała"], ["shield", "Tarcze"], ["bow", "Łuki i strzały"], ["armor", "Pancerze"], ["elixir", "Mikstury"]]


func _zbuduj_kram() -> void:
	kram = EkranMenu.new()
	add_child(kram)
	kram.visible = false
	kram.wroc_wcisniety.connect(func(): zamknij.emit())
	kram.zakladka_wybrana.connect(func(i: int): _kram_tryb("kup" if i == 0 else "sprzedaj"))


func _kram_tryb(t: String) -> void:
	if tryb_kupca == t:
		return
	tryb_kupca = t
	_komunikat_kupca = ""
	_fokus_klucz = ""
	Dzwiek.ui()
	odswiez()


func _kupiec() -> void:
	var d := Profil.d
	kram.wyczysc()
	kram.tytul.text = "KRAM MARGI"
	kram.podtytul.text = "PRZYSTAŃ  ·  WAROWNIA POPIOŁÓW"
	kram.licznik.text = "%d zł" % int(d["gold"])
	kram.ustaw_zakladki(["Kup", "Sprzedaj łup"], 0 if tryb_kupca == "kup" else 1)
	kram.ustaw_stopke([["lb/rb", "Q / E", "Zakładki"], ["a", "Enter", "Kup" if tryb_kupca == "kup" else "Sprzedaj"], ["b", "Esc", "Wróć"]])
	var kuznia := Profil.budynek("forge")
	kram.stopka_listy.text = "Kuźnia Warowni: poziom %d  ·  lepszy oręż odblokowuje Kuźnia" % kuznia
	_kram_ostatni = null
	if tryb_kupca == "kup":
		var ma_bron: bool = d["loadout"]["weapon"] != null
		for it in d["stash"] + d["loadout"]["backpack"]:
			if Dane.typ(it["id"]) == "weapon":
				ma_bron = true
		if not ma_bron and d["gold"] < 200:
			kram.lista.add_child(Ui.belka_sekcji("Dar Margi"))
			var z := Ui.wiersz_listy(Dane.ikona("rusty_sword"), "Zestaw Wygnańca", "Miecz, puklerz i Flaszka Żaru", "0 zł")
			z.set_meta("klucz", "zestaw")
			z.pressed.connect(func():
				_fokus_klucz = "zestaw"
				d["loadout"]["weapon"] = Profil.nowy_przedmiot("rusty_sword")
				d["loadout"]["shield"] = Profil.nowy_przedmiot("wood_buckler")
				if d["loadout"]["backpack"].size() < Profil.SAKWA_MAX:
					d["loadout"]["backpack"].append(Profil.nowy_przedmiot("ember_flask"))
				_zmiana())
			_kram_wiersz(z, func(): _kram_pokaz_tekst("Zestaw Wygnańca", "DAR MARGI", "Dla tych, którzy wracają z niczym: zardzewiały miecz, drewniany puklerz i jedna Flaszka Żaru. Za darmo, raz na biedę.", "Weź zestaw", func(): z.pressed.emit()))
		for sek in SEKCJE_KRAMU:
			var typy: Array = ["bow", "arrow"] if sek[0] == "bow" else [sek[0]]
			var ids: Array = []
			for id in Dane.przedmioty:
				var def: Dictionary = Dane.przedmioty[id]
				if str(def["type"]) in typy:
					ids.append(id)
			if ids.is_empty():
				continue
			kram.lista.add_child(Ui.belka_sekcji(sek[1]))
			for id in ids:
				var pid: String = id
				var def: Dictionary = Dane.przedmioty[pid]
				var cena := int(def["price"])
				var zablok := int(def.get("forgeReq", 0)) > kuznia
				var podpis := "Wymaga Kuźni %d" % int(def["forgeReq"]) if zablok else _krotkie_staty(Profil.nowy_przedmiot(pid))
				var w := Ui.wiersz_listy(Dane.ikona(pid), str(def["name"]), podpis, "%d zł" % cena, zablok, Ui.M_ZLOTO if d["gold"] >= cena else Ui.M_OSTRZ)
				w.set_meta("klucz", "kup_" + pid)
				w.pressed.connect(func(): _fokus_klucz = "kup_" + pid; _kup(pid))
				var inst := Profil.nowy_przedmiot(pid)
				_kram_wiersz(w, func(): _pokaz_szczegoly(pid, inst, cena))
	else:
		var wpisy: Array = []
		for i in d["stash"].size():
			wpisy.append(["stash", i])
		for i in d["loadout"]["backpack"].size():
			wpisy.append(["backpack", i])
		var suma := 0
		for w0 in wpisy:
			var ls0: Array = d["stash"] if w0[0] == "stash" else d["loadout"]["backpack"]
			if Dane.typ(ls0[w0[1]]["id"]) == "valuable":
				suma += Dane.cena_skupu(ls0[w0[1]]["id"])
		kram.lista.add_child(Ui.belka_sekcji("Kosztowności"))
		var wk := Ui.wiersz_listy(_ikona_lub(Dane.ikona("gold_ring"), "hud:sakwa"), "Sprzedaj wszystkie kosztowności", "Surowce zostają na rozbudowę Warowni", "+%d zł" % suma, suma == 0)
		wk.set_meta("klucz", "sprzedaj_kosztownosci")
		wk.pressed.connect(func():
			_fokus_klucz = "sprzedaj_kosztownosci"
			var zysk := 0
			for lista in [d["stash"], d["loadout"]["backpack"]]:
				for i in range(lista.size() - 1, -1, -1):
					if Dane.typ(lista[i]["id"]) == "valuable":
						zysk += Dane.cena_skupu(lista[i]["id"])
						lista.remove_at(i)
			d["gold"] += zysk
			_info("Sprzedano kosztowności za %d zł." % zysk if zysk > 0 else "Brak kosztowności na sprzedaż.")
			_zmiana())
		_kram_wiersz(wk, func(): _kram_pokaz_tekst("Kosztowności", "SKUP", "Pierścienie, kielichy i inne błyskotki z wypraw. Marga płaci od ręki; żelazo, popiół i relikty lepiej zachować na rozbudowę.", "Sprzedaj za %d zł" % suma, func(): wk.pressed.emit()))
		for zrodlo_nazwa in [["stash", "Skrytka"], ["backpack", "Sakwa"]]:
			var lista_z: Array = d["stash"] if zrodlo_nazwa[0] == "stash" else d["loadout"]["backpack"]
			if lista_z.is_empty():
				continue
			kram.lista.add_child(Ui.belka_sekcji("%s  %d" % [zrodlo_nazwa[1], lista_z.size()]))
			for idx in lista_z.size():
				var it: Dictionary = lista_z[idx]
				var cena := Dane.cena_skupu(it["id"])
				var zrodlo: String = zrodlo_nazwa[0]
				var nr: int = idx
				var def := Dane.p(it["id"])
				var dop := " ×%d" % int(it.get("qty", 0)) if def.get("type") == "arrow" else ""
				var w := Ui.wiersz_listy(Dane.ikona(it["id"]), str(def["name"]) + dop, str(Dane.NAZWY_TYPOW.get(def.get("type"), "")), "+%d zł" % cena)
				w.set_meta("klucz", "sp_%s%d" % [zrodlo, nr])
				w.pressed.connect(func():
					_fokus_klucz = "sp_%s%d" % [zrodlo, nr]
					var ls: Array = d["stash"] if zrodlo == "stash" else d["loadout"]["backpack"]
					ls.remove_at(nr)
					d["gold"] += cena
					Dzwiek.lup()
					_zmiana())
				var itk := it
				_kram_wiersz(w, func(): _pokaz_szczegoly(itk["id"], itk, -cena))
		if wpisy.is_empty():
			kram.lista.add_child(Ui.tekst_menu("Nie masz nic na sprzedaż.", 15, Ui.M_DRUGI))
	_kram_pokaz_tekst("Kram Margi", "PRZYSTAŃ", "Marga sprzedaje oręż, tarcze, łuki i mikstury, a skupuje łup z wypraw. Lepszy oręż odblokowuje Kuźnia Warowni. Wybierz towar z listy.", "", Callable())


func _ikona_lub(t: Texture2D, zapas: String) -> Texture2D:
	return t if t != null else _ikona_hud_menu(zapas.substr(4))


func _ikona_hud_menu(n: String) -> Texture2D:
	var sc := "res://zasoby/ui/hud/%s.webp" % n
	return load(sc) if ResourceLoader.exists(sc) else null


## Wiersz do listy + linia; fokus i najechanie pokazują szczegóły; prawo z listy = przycisk akcji.
func _kram_wiersz(w: Button, pokaz: Callable) -> void:
	kram.lista.add_child(w)
	kram.lista.add_child(Ui.linia())
	w.focus_entered.connect(func(): _kram_ostatni = w; pokaz.call())
	w.mouse_entered.connect(func(): _kram_ostatni = w; pokaz.call())


## Krótki podpis pod nazwą w liście (szeryf 12).
func _krotkie_staty(inst: Dictionary) -> String:
	var d := Dane.p(inst["id"])
	match str(d.get("type", "")):
		"weapon":
			return "Obrażenia %d  ·  Stamina %d" % [d["dmg"], d["stamina"]]
		"shield":
			return "Blok %d%%  ·  Parowanie +%d ms" % [roundi(d["blockRed"] * 100), roundi(d["parryBonus"] * 1000)]
		"bow":
			return "Obrażenia %d  ·  Zasięg %d m" % [d["dmg"], roundi(float(d["range"]))]
		"armor":
			return "Redukcja %d%%  ·  Klasa %d" % [roundi(d["reduction"] * 100), int(d["tier"])]
		"arrow":
			return "%d szt." % int(inst.get("qty", 0))
	return str(Dane.NAZWY_TYPOW.get(d.get("type"), ""))


## Szczegóły bez towaru (opis ekranu albo pozycji specjalnej): ilustracja + tekst + opcjonalny przycisk.
func _kram_pokaz_tekst(nazwa: String, etykieta: String, opis_t: String, akcja_t: String, akcja: Callable) -> void:
	for c in kram.szczegoly.get_children():
		kram.szczegoly.remove_child(c)
		c.queue_free()
	kram.ilustracja.texture = load("res://zasoby/ui/menu/tlo_menu_1.webp")
	kram.duza_ikona.texture = null
	kram.szczegoly.add_child(Ui.naglowek_menu(etykieta, 11, Ui.M_ZAR, 3))
	_sz_nazwa = Ui.naglowek_menu(nazwa, 26, Ui.M_JASNY)
	_sz_nazwa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kram.szczegoly.add_child(_sz_nazwa)
	var o := Ui.tekst_menu(opis_t, 14, Ui.M_TEKST)
	o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kram.szczegoly.add_child(o)
	_sz_typ = null
	_sz_porown = Ui.tekst_menu("", 14, Ui.M_DRUGI)
	_kram_dol(akcja_t, akcja, true)


## Szczegóły towaru: etykieta rodzaju, nazwa, opis, tabela par, porównanie z założonym, przycisk akcji, komunikat.
func _pokaz_szczegoly(id: String, inst: Dictionary, cena: int) -> void:
	if kram == null:
		return
	for c in kram.szczegoly.get_children():
		kram.szczegoly.remove_child(c)
		c.queue_free()
	var d := Profil.d
	var def := Dane.p(id)
	var rz: Color = Dane.KOLORY_RZADKOSCI.get(def.get("rarity"), Color.GRAY)
	kram.ilustracja.texture = load("res://zasoby/ui/menu/tlo_menu_1.webp")
	kram.duza_ikona.texture = Dane.ikona(id)
	var t := str(def.get("type", ""))
	_sz_typ = Ui.naglowek_menu(str(Dane.NAZWY_TYPOW.get(def.get("type"), "")).to_upper(), 11, Ui.M_ZAR, 3)
	kram.szczegoly.add_child(_sz_typ)
	_sz_nazwa = Ui.naglowek_menu(str(def["name"]), 26, rz.lightened(0.45))
	_sz_nazwa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kram.szczegoly.add_child(_sz_nazwa)
	var o := Ui.tekst_menu(str(def.get("desc", "")), 14, Ui.M_TEKST)
	o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kram.szczegoly.add_child(o)
	# tabela par (te same liczby co dotąd, tylko czytelniej)
	match t:
		"weapon":
			kram.szczegoly.add_child(Ui.para("Obrażenia", "%d" % int(def["dmg"])))
			kram.szczegoly.add_child(Ui.para("Stamina za cios", "%d" % int(def["stamina"])))
		"shield":
			kram.szczegoly.add_child(Ui.para("Blok", "%d%%" % roundi(def["blockRed"] * 100)))
			kram.szczegoly.add_child(Ui.para("Parowanie", "+%d ms" % roundi(def["parryBonus"] * 1000)))
		"bow":
			kram.szczegoly.add_child(Ui.para("Obrażenia", "%d" % int(def["dmg"])))
		"armor":
			kram.szczegoly.add_child(Ui.para("Redukcja", "%d%%  (Kl. %d)" % [roundi(def["reduction"] * 100), int(def["tier"])]))
			kram.szczegoly.add_child(Ui.para("Wytrzymałość", "%d" % int(def["maxDurability"])))
		"arrow":
			kram.szczegoly.add_child(Ui.para("Ilość", "%d szt." % int(inst.get("qty", 0))))
	# porównanie z założonym tego samego rodzaju: zielone ▲ lepsze, czerwone ▼ gorsze
	var zal = d["loadout"].get(t) if t in ["weapon", "shield", "bow", "armor"] else null
	_sz_porown = Ui.tekst_menu("", 14, Ui.M_DRUGI)
	if zal != null:
		var zd := Dane.p(zal["id"])
		var roznica := 0
		var co := ""
		if t in ["weapon", "bow"]:
			roznica = int(def["dmg"]) - int(zd["dmg"])
			co = "obrażenia %+d" % roznica
		elif t == "shield":
			roznica = roundi((float(def["blockRed"]) - float(zd["blockRed"])) * 100)
			co = "blok %+d%%" % roznica
		elif t == "armor":
			roznica = roundi((float(def["reduction"]) - float(zd["reduction"])) * 100)
			co = "redukcja %+d%%" % roznica
		_sz_porown.text = "Założone: %s   %s %s" % [zd["name"], "▲" if roznica > 0 else ("▼" if roznica < 0 else "="), co]
		_sz_porown.add_theme_color_override("font_color", Ui.M_ZIELONY if roznica > 0 else (Ui.M_OSTRZ if roznica < 0 else Ui.M_DRUGI))
	elif t in ["weapon", "shield", "bow", "armor"]:
		_sz_porown.text = "Nie masz założonego przedmiotu tego rodzaju."
	kram.szczegoly.add_child(_sz_porown)
	var kuznia := Profil.budynek("forge")
	if cena < 0:
		_kram_dol("Sprzedaj za %d zł" % -cena, func(): if _kram_ostatni: _kram_ostatni.pressed.emit(), false)
	elif int(def.get("forgeReq", 0)) > kuznia:
		_kram_dol("Kup za %d zł" % cena, Callable(), false, "Wymaga Kuźni na poziomie %d." % int(def["forgeReq"]))
	elif int(d["gold"]) < cena:
		_kram_dol("Kup za %d zł" % cena, Callable(), false, "Brakuje %d zł." % (cena - int(d["gold"])))
	else:
		_kram_dol("Kup za %d zł" % cena, func(): _kup(id), false)


## Dół szczegółów: przycisk akcji (przycisk główny NightBrand) i komunikat pod nim.
func _kram_dol(tekst: String, akcja: Callable, tylko_gdy_akcja: bool, ostrzezenie := "") -> void:
	_kram_akcja = akcja
	var odst := Control.new()
	odst.custom_minimum_size = Vector2(0, 4)
	kram.szczegoly.add_child(odst)
	_sz_akcja = null
	if tekst != "" and not (tylko_gdy_akcja and not akcja.is_valid()):
		_sz_akcja = Ui.przycisk_menu(tekst, true)
		_sz_akcja.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_sz_akcja.disabled = not akcja.is_valid()
		_sz_akcja.set_meta("klucz", "akcja_kramu")
		_sz_akcja.pressed.connect(func(): if _kram_akcja.is_valid(): _kram_akcja.call())
		kram.szczegoly.add_child(_sz_akcja)
		# pad: prawo z listy = przycisk akcji, lewo = z powrotem na wiersz
		if _kram_ostatni != null and is_instance_valid(_kram_ostatni):
			_kram_ostatni.focus_neighbor_right = _kram_ostatni.get_path_to(_sz_akcja)
			_sz_akcja.focus_neighbor_left = _sz_akcja.get_path_to(_kram_ostatni)
	_sz_kom = Ui.tekst_menu(ostrzezenie if ostrzezenie != "" else _komunikat_kupca, 14, Ui.M_OSTRZ if ostrzezenie != "" else Ui.M_ZLOTO2)
	_sz_kom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kram.szczegoly.add_child(_sz_kom)


func _kup(id: String) -> void:
	var d := Profil.d
	var def := Dane.p(id)
	var cena := int(def["price"])
	if int(def.get("forgeReq", 0)) > Profil.budynek("forge"):
		_info("Ten oręż wymaga Kuźni na poziomie %d." % int(def["forgeReq"]))
		return
	if d["gold"] < cena:
		_info("Za mało złota!")
		return
	if d["stash"].size() >= Profil.max_skrytka() and d["loadout"]["backpack"].size() >= Profil.SAKWA_MAX:
		_info("Brak miejsca w Skrytce i Sakwie!")
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
	_info("Kupiono: " + str(def["name"]))
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
				_info("Ulepszono: %s (poziom %d)!" % [up["name"], Profil.budynek(bid)])
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
