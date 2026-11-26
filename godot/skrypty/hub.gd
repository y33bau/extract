extends Control
## Warownia (hub) na szablonie menu NightBrand (`ekran_menu.gd`, instrukcja przebudowy menu 26.11, etap 3):
## jeden ekran, zakładki = sekcje (Wyprawa, Ekwipunek, Kupiec, Warownia, Umiejętności), lista po lewej,
## szczegóły z ilustracją i przyciskiem akcji po prawej, stopka ze znaczkami.
## Pad: LB/RB sekcje, LT/RT podzakładki (Kram: Kup / Sprzedaj), krzyżak/drążek lista, A wybór, Y do Relikwiarza,
## B / Esc wraca do Przystani, prawa gałka przewija szczegóły. Klawiatura: Q/E sekcje, Z/C podzakładki.

signal start_rajdu(kraina: String, ziarno: String)
signal zamknij  # powrót do Przystani (B / Esc / przycisk)

const Ui = preload("res://skrypty/ui.gd")
const EkranMenu = preload("res://skrypty/ekran_menu.gd")
const SEKCJE := ["Wyprawa", "Ekwipunek", "Kupiec", "Warownia", "Umiejętności"]
const TYTULY := ["STÓŁ CHOJRAKA", "RYNSZTUNEK", "KRAM MARGI", "ROZBUDOWA WAROWNI", "BIEGŁOŚCI"]
## Ilustracje krain (z NightBrand; docelowo własne — prompty w docs/PROMPTY_MENU.md)
const ILUSTRACJE_KRAIN := {"catacombs": "rozdzial_5", "czarnobor": "rozdzial_4", "spalona_osada": "rozdzial_1", "outskirts": "rozdzial_1", "crypt": "rozdzial_2"}

var wybrana_kraina := "catacombs"
var ziarno := ""
var kategoria := "all"  # zgodność wsteczna (kategorie w Kramie są teraz belkami sekcji)
var zakladki: TabContainer  # stan sekcji (niewidoczny; wygląd rysuje szablon)
var ekran: EkranMenu
var kram: EkranMenu  # ten sam ekran (nazwa z etapu 2)
var t_wyprawa: Control
var t_ekw: Control
var t_kupiec: Control
var t_warownia: Control
var t_umiej: Control
var dialog_startu: ConfirmationDialog
var _komunikat_kupca := ""  # komunikat dla gracza (kupiono, brak złota…) — w panelu szczegółów
var _fokus_klucz := ""


func _ready() -> void:
	theme = Ui.motyw()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ziarno = _losowe_ziarno()
	zakladki = TabContainer.new()
	zakladki.visible = false
	add_child(zakladki)
	for n in SEKCJE:
		var c := Control.new()
		c.name = n
		zakladki.add_child(c)
	ekran = EkranMenu.new()
	kram = ekran
	add_child(ekran)
	ekran.wroc_wcisniety.connect(func(): zamknij.emit())
	ekran.zakladka_wybrana.connect(func(i: int): zakladki.current_tab = i)
	t_wyprawa = ekran.lista
	t_ekw = ekran.lista
	t_kupiec = ekran.lista
	t_warownia = ekran.lista
	t_umiej = ekran.lista
	# zmiana sekcji czyści komunikat (wcześniej w Kupcu wisiał tekst krainy z Wyprawy)
	zakladki.tab_changed.connect(func(_i): Dzwiek.ui(); _fokus_klucz = ""; _komunikat_kupca = ""; odswiez())
	dialog_startu = ConfirmationDialog.new()
	dialog_startu.title = "Wyruszyć?"
	dialog_startu.ok_button_text = "Wyrusz"
	dialog_startu.cancel_button_text = "Jeszcze nie"
	dialog_startu.confirmed.connect(_wyrusz)
	add_child(dialog_startu)
	Profil.awans.connect(func(u, lv): _info("Awans: %s (poziom %d)!" % [Dane.umiejetnosci[u]["name"], lv]))
	visibility_changed.connect(func(): if is_visible_in_tree(): Ui.blokada_po_otwarciu(self))
	odswiez()


## Komunikat dla gracza: w panelu szczegółów (jeden panel opisu na ekran).
func _info(t: String) -> void:
	_komunikat_kupca = t
	if _sz_kom != null and is_instance_valid(_sz_kom):
		_sz_kom.text = t
		_sz_kom.add_theme_color_override("font_color", Ui.M_ZLOTO2)


func _unhandled_input(e: InputEvent) -> void:
	if not is_visible_in_tree() or dialog_startu.visible:
		return
	if e.is_action_pressed("ui_cancel"):
		zamknij.emit()
		get_viewport().set_input_as_handled()
		return
	if zakladki.current_tab == 2 and (e.is_action_pressed("podzakladka_lewo") or e.is_action_pressed("podzakladka_prawo")):
		_kram_tryb("kup" if e.is_action_pressed("podzakladka_lewo") else "sprzedaj")
		get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("zakladka_lewo"):
		zakladki.current_tab = (zakladki.current_tab + zakladki.get_tab_count() - 1) % zakladki.get_tab_count()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("zakladka_prawo"):
		zakladki.current_tab = (zakladki.current_tab + 1) % zakladki.get_tab_count()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("pauza") and zakladki.current_tab == 0:
		# Start na ekranie Wyprawy = „Wyrusz” z potwierdzeniem (jak w NightBrand)
		_pytaj_o_start()
		get_viewport().set_input_as_handled()


func _losowe_ziarno() -> String:
	var z := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var s := ""
	for i in 6:
		s += z[randi() % z.length()]
	return s


func odswiez() -> void:
	var nr := zakladki.current_tab
	ekran.wyczysc()
	ekran.tytul.text = TYTULY[nr]
	ekran.podtytul.text = "PRZYSTAŃ  ·  WAROWNIA POPIOŁÓW"
	ekran.licznik.text = "%d zł" % int(Profil.d["gold"])
	ekran.ustaw_zakladki(SEKCJE, nr)
	ekran.ilustracja.texture = load("res://zasoby/ui/menu/tlo_menu_1.webp")
	ekran.ilustracja.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ekran.stopka_listy.text = ""
	_sz_kom = null
	_kram_ostatni = null
	match nr:
		0: _wyprawa()
		1: _ekwipunek()
		2: _kupiec()
		3: _warownia()
		4: _umiejetnosci()
	_przywroc_fokus.call_deferred()


func _przywroc_fokus() -> void:
	var pierwszy: Control = null
	for c in ekran.lista.find_children("*", "Button", true, false):
		if c.is_queued_for_deletion() or not c.is_visible_in_tree() or c.disabled:
			continue
		if pierwszy == null:
			pierwszy = c
		if _fokus_klucz != "" and c.get_meta("klucz", "") == _fokus_klucz:
			c.grab_focus()
			return
	if pierwszy:
		pierwszy.grab_focus()


func _zmiana() -> void:
	Dzwiek.ui()
	Profil.zapisz()
	odswiez()


## Stopka ekranu wg sekcji: [ikona pada, klawisz, podpis].
func _stopka(akcja_a: String, dodatki: Array = []) -> void:
	var w: Array = [["lb/rb", "Q / E", "Sekcje"]]
	w.append_array(dodatki)
	w.append(["a", "Enter", akcja_a])
	w.append(["b", "Esc", "Przystań"])
	ekran.ustaw_stopke(w)


# ------------------------------------------------------------ WYPRAWA (stół Chojraka; wzór: Przygotowanie NightBrand)
## Lista: krainy (A = wybierz), kontrakty Chojraka, gotowość rycerza. Szczegóły: ilustracja krainy, opis, tabela,
## duży przycisk „Wyrusz” z podpisem. Start na padzie = Wyrusz z potwierdzeniem.
func _wyprawa() -> void:
	var d := Profil.d
	_stopka("Wybierz krainę", [["menu", "Enter na Wyrusz", "Wyrusz"]])
	ekran.stopka_listy.text = "Wyprawy %d  ·  przeżyte %d" % [d["stats"]["raids"], d["stats"]["survived"]]
	ekran.lista.add_child(Ui.belka_sekcji("Krainy"))
	var wybrana: Dictionary = Dane.krainy[0]
	for k in Dane.krainy:
		var id: String = k["id"]
		if id == wybrana_kraina:
			wybrana = k
		var gw := _trudnosc(k)
		var w := Ui.wiersz_listy(_ilustracja_krainy(id), str(k["name"]), "%s  ·  łup %s" % [str(k["diff"]).capitalize(), k["lootStars"]], gw, false, Ui.M_ZAR2, id == wybrana_kraina)
		w.set_meta("klucz", "kraina_" + id)
		var kid := id
		var kd: Dictionary = k
		w.pressed.connect(func(): _fokus_klucz = "kraina_" + kid; wybrana_kraina = kid; Dzwiek.ui(); odswiez())
		_kram_wiersz(w, func(): _pokaz_kraine(kd))
	ekran.lista.add_child(Ui.belka_sekcji("Kontrakty Chojraka"))
	var kontrakty: Array = d.get("kontrakty", [])
	for k in kontrakty:
		var kw := Ui.wiersz_listy(load("res://zasoby/ui/menu/ikona_kronika.webp"), Profil.opis_kontraktu(k), "postęp %d / %d  ·  liczy się po powrocie" % [int(k["postep"]), int(k["cel"])], "+%d zł" % int(k["nagroda"]))
		kw.set_meta("klucz", "kontrakt")
		kw.focus_mode = Control.FOCUS_ALL
		_kram_wiersz(kw, func(): _pokaz_kraine(wybrana))
	if kontrakty.is_empty():
		ekran.lista.add_child(Ui.tekst_menu("  Chojrak nie ma dziś zleceń.", 14, Ui.M_DRUGI))
	# gotowość rycerza (zamiast linii tekstu)
	var l: Dictionary = d["loadout"]
	ekran.lista.add_child(Ui.belka_sekcji("Gotowość rycerza"))
	var flaszki := 0
	var strzaly := 0
	for it in l["backpack"] + l["reliquary"]:
		if Dane.p(it["id"]).get("elixKind") == "heal":
			flaszki += 1
		if it["id"] == "iron_arrows":
			strzaly += int(it["qty"])
	for s in [["weapon", "Broń"], ["shield", "Tarcza"], ["bow", "Łuk"], ["armor", "Pancerz"]]:
		var it = l[s[0]]
		var nazwa: String = Dane.p(it["id"])["name"] if it else "brak"
		var dop := "  ·  %d strzał" % strzaly if s[0] == "bow" and it else ""
		ekran.lista.add_child(_wiersz_info(Dane.ikona(it["id"]) if it else null, "%s: %s%s" % [s[1], nazwa, dop], Ui.M_TEKST if it else Ui.M_OSTRZ))
	ekran.lista.add_child(_wiersz_info(Dane.ikona("ember_flask"), "Flaszki Żaru: %d   ·   Sakwa %d/12   ·   Relikwiarz %d/%d" % [flaszki, l["backpack"].size(), l["reliquary"].size(), Profil.max_relikwiarz()], Ui.M_TEKST if flaszki > 0 else Ui.M_OSTRZ))
	_pokaz_kraine(wybrana)


## Trudność jako jedna skala znaków (◆◆◇◇) z gwiazdek łupu krainy.
func _trudnosc(k: Dictionary) -> String:
	var n := 0
	for ch in str(k["lootStars"]):
		if ch == "★":
			n += 1
	return "◆".repeat(n) + "◇".repeat(maxi(0, 4 - n))


func _ilustracja_krainy(id: String) -> Texture2D:
	return load("res://zasoby/ui/menu/%s.webp" % ILUSTRACJE_KRAIN.get(id, "rozdzial_1"))


## Wiersz informacyjny (bez akcji) — mniejszy, bez fokusu.
func _wiersz_info(ikona: Texture2D, tekst: String, kolor: Color) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 34)
	h.add_theme_constant_override("separation", 12)
	var odst := Control.new()
	odst.custom_minimum_size = Vector2(6, 0)
	h.add_child(odst)
	var ik := TextureRect.new()
	ik.texture = ikona
	ik.custom_minimum_size = Vector2(24, 24)
	ik.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ik.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ik.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ik.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ik)
	var t := Ui.tekst_menu(tekst, 14, kolor)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.clip_text = true
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	return h


func _pokaz_kraine(k: Dictionary) -> void:
	_czysc_szczegoly()
	ekran.ilustracja.texture = _ilustracja_krainy(str(k["id"]))
	var wybrana: bool = k["id"] == wybrana_kraina
	ekran.szczegoly.add_child(Ui.naglowek_menu(("WYBRANA KRAINA" if wybrana else "KRAINA") + "  ·  " + str(k["diff"]), 11, Ui.M_ZAR, 3))
	_sz_nazwa = Ui.naglowek_menu(str(k["name"]), 26, Ui.M_JASNY)
	ekran.szczegoly.add_child(_sz_nazwa)
	var o := Ui.tekst_menu("%s. %s" % [k["subtitle"], k["desc"]], 14, Ui.M_TEKST)
	o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ekran.szczegoly.add_child(o)
	ekran.szczegoly.add_child(Ui.para("Trudność", _trudnosc(k), Ui.M_ZAR2))
	ekran.szczegoly.add_child(Ui.para("Łup", str(k["lootStars"])))
	ekran.szczegoly.add_child(Ui.para("Wrogowie", "ok. %d%s" % [int(k["enemyCount"]), "  ·  boss" if k.get("hasBoss", false) else ""]))
	# ziarno mapy: narzędzie autora (parametr --autor)
	var hz := HBoxContainer.new()
	hz.visible = Ui.tryb_autora()
	hz.add_child(Ui.tekst_menu("Ziarno mapy: ", 14, Ui.M_DRUGI))
	var pole := LineEdit.new()
	pole.text = ziarno
	pole.max_length = 12
	pole.custom_minimum_size = Vector2(160, 0)
	pole.text_changed.connect(func(t): ziarno = t.to_upper())
	hz.add_child(pole)
	var los := Ui.przycisk_menu("Losuj")
	los.pressed.connect(func(): ziarno = _losowe_ziarno(); pole.text = ziarno)
	hz.add_child(los)
	ekran.szczegoly.add_child(hz)
	if wybrana:
		_kram_dol("Wyrusz", _wyrusz, false, "" if Profil.d["loadout"]["weapon"] else "Uwaga: brak broni białej! Weź Zestaw Wygnańca u Margi.")
		_sz_akcja.custom_minimum_size = Vector2(340, 84)
		_sz_akcja.add_theme_font_size_override("font_size", 30)
		_sz_akcja.set_meta("klucz", "start")
		var pod := Ui.naglowek_menu("HADRÆN  ·  %s" % str(k["name"]).to_upper(), 11, Ui.M_DRUGI, 3)
		ekran.szczegoly.add_child(pod)
		ekran.szczegoly.move_child(pod, _sz_akcja.get_index() + 1)
	else:
		_kram_dol("Wybierz tę krainę", func(): wybrana_kraina = str(k["id"]); _fokus_klucz = "kraina_" + str(k["id"]); Dzwiek.ui(); odswiez(), false)
	var instr := Ui.tekst_menu("Paruj, gdy wróg świeci ZŁOTEM, i odpowiedz Ripostą. CZERWONY: tylko unik. Pochodnia zajmuje rękę tarczy. Śmierć zabiera wszystko poza Relikwiarzem.", 12, Ui.M_DRUGI)
	instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ekran.szczegoly.add_child(instr)


func _pytaj_o_start() -> void:
	var k: Dictionary = Dane.krainy[0]
	for kk in Dane.krainy:
		if kk["id"] == wybrana_kraina:
			k = kk
	dialog_startu.dialog_text = "Wyruszyć do: %s?" % k["name"]
	dialog_startu.popup_centered()


func _wyrusz() -> void:
	var z := ziarno if (ziarno != "" and Ui.tryb_autora()) else _losowe_ziarno()
	ziarno = _losowe_ziarno()  # następna wyprawa: nowa mapa
	start_rajdu.emit(wybrana_kraina, z)


# ------------------------------------------------------------ EKWIPUNEK
## Lewy panel: belki Rynsztunek, Relikwiarz, Sakwa, Skrytka; puste miejsca jako jedna blada linia.
## Prawy: portret Hadræna, opis zaznaczonego przedmiotu i co zrobi A / Y. Reguły przenoszenia bez zmian.
func _ekwipunek() -> void:
	var d := Profil.d
	var l: Dictionary = d["loadout"]
	_stopka("Przenieś", [["y", "Shift + klik", "Do Relikwiarza"]])
	ekran.stopka_listy.text = "Skrytka %d/%d  ·  Sakwa %d/12  ·  Relikwiarz %d/%d" % [d["stash"].size(), Profil.max_skrytka(), l["backpack"].size(), l["reliquary"].size(), Profil.max_relikwiarz()]
	ekran.lista.add_child(Ui.belka_sekcji("Rynsztunek na wyprawę"))
	for s in [["weapon", "Broń"], ["shield", "Tarcza"], ["bow", "Łuk"], ["armor", "Pancerz"]]:
		var slot: String = s[0]
		if l[slot] == null:
			ekran.lista.add_child(_wiersz_info(null, "%s: puste miejsce" % s[1], Ui.M_WYL))
			ekran.lista.add_child(Ui.linia())
			continue
		_wiersz_przedmiotu(l[slot], "eq_" + slot, "A: zdejmij do Skrytki", func():
			if d["stash"].size() >= Profil.max_skrytka():
				_info("Skrytka jest pełna!")
				return
			d["stash"].append(l[slot])
			l[slot] = null
			_zmiana())
	ekran.lista.add_child(Ui.belka_sekcji("Relikwiarz  %d / %d  (przeżywa śmierć)" % [l["reliquary"].size(), Profil.max_relikwiarz()]))
	for i in l["reliquary"].size():
		var idx: int = i
		_wiersz_przedmiotu(l["reliquary"][i], "rel%d" % i, "A: do Skrytki", func():
			if d["stash"].size() >= Profil.max_skrytka():
				_info("Skrytka jest pełna!")
				return
			d["stash"].append(l["reliquary"].pop_at(idx))
			_zmiana())
	_wolne(Profil.max_relikwiarz() - l["reliquary"].size())
	ekran.lista.add_child(Ui.belka_sekcji("Sakwa  %d / 12" % l["backpack"].size()))
	for i in l["backpack"].size():
		var idx: int = i
		_wiersz_przedmiotu(l["backpack"][i], "bp%d" % i, "A: do Skrytki   ·   Y: do Relikwiarza",
			func():
				if d["stash"].size() >= Profil.max_skrytka():
					_info("Skrytka jest pełna!")
					return
				d["stash"].append(l["backpack"].pop_at(idx))
				_zmiana(),
			func():
				if l["reliquary"].size() >= Profil.max_relikwiarz():
					_info("Relikwiarz jest pełny!")
					return
				l["reliquary"].append(l["backpack"].pop_at(idx))
				_zmiana())
	_wolne(Profil.SAKWA_MAX - l["backpack"].size())
	ekran.lista.add_child(Ui.belka_sekcji("Skrytka Warowni  %d / %d" % [d["stash"].size(), Profil.max_skrytka()]))
	var sort := Ui.wiersz_listy(load("res://zasoby/ui/menu/ikona_kronika.webp"), "Sortuj Skrytkę", "broń, tarcze, łuki, pancerze, strzały, mikstury…", "")
	sort.set_meta("klucz", "sortuj")
	sort.pressed.connect(func():
		_fokus_klucz = "sortuj"
		var kol := {"weapon": 1, "shield": 2, "bow": 3, "armor": 4, "arrow": 5, "elixir": 6, "material": 7, "valuable": 8}
		d["stash"].sort_custom(func(a, b): return kol.get(Dane.typ(a["id"]), 9) < kol.get(Dane.typ(b["id"]), 9))
		_zmiana())
	_kram_wiersz(sort, func(): _pokaz_bohatera())
	for i in d["stash"].size():
		var idx: int = i
		_wiersz_przedmiotu(d["stash"][i], "st%d" % i, "A: załóż albo spakuj do Sakwy   ·   Y: do Relikwiarza",
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
				_zmiana())
	_wolne(Profil.max_skrytka() - d["stash"].size())
	_pokaz_bohatera()


func _wolne(ile: int) -> void:
	if ile > 0:
		ekran.lista.add_child(_wiersz_info(null, "wolne miejsca: %d" % ile, Ui.M_WYL))


## Wiersz przedmiotu: A = akcja, Y (pad) / Shift+klik = do Relikwiarza.
func _wiersz_przedmiotu(inst: Dictionary, klucz: String, podpowiedz: String, akcja: Callable, na_relikwiarz := Callable()) -> void:
	var d := Dane.p(inst["id"])
	var dop := " ×%d" % int(inst["qty"]) if d.get("type") == "arrow" else ""
	var rz: Color = Dane.KOLORY_RZADKOSCI.get(d.get("rarity"), Color.GRAY)
	var w := Ui.wiersz_listy(Dane.ikona(inst["id"]), str(d["name"]) + dop, _krotkie_staty(inst), str(Dane.NAZWY_TYPOW.get(d.get("type"), "")), false, rz.lightened(0.3))
	w.set_meta("klucz", klucz)
	w.pressed.connect(func():
		_fokus_klucz = klucz
		if Input.is_key_pressed(KEY_SHIFT) and na_relikwiarz.is_valid():
			na_relikwiarz.call()
		else:
			akcja.call())
	if na_relikwiarz.is_valid():
		w.gui_input.connect(func(e: InputEvent):
			if e.is_action_pressed("okno_relikwiarz"):
				_fokus_klucz = klucz
				na_relikwiarz.call()
				get_viewport().set_input_as_handled())
	_kram_wiersz(w, func(): _pokaz_przedmiot(inst, podpowiedz, akcja))


## Portret Hadræna z rynsztunkiem (bez zaznaczonego przedmiotu).
func _pokaz_bohatera() -> void:
	_czysc_szczegoly()
	_portret()
	var l: Dictionary = Profil.d["loadout"]
	ekran.szczegoly.add_child(Ui.naglowek_menu("BOHATER", 11, Ui.M_ZAR, 3))
	_sz_nazwa = Ui.naglowek_menu("Hadræn", 26, Ui.M_JASNY)
	ekran.szczegoly.add_child(_sz_nazwa)
	for s in [["weapon", "Broń"], ["shield", "Tarcza"], ["bow", "Łuk"], ["armor", "Pancerz"]]:
		var it = l[s[0]]
		ekran.szczegoly.add_child(Ui.para(s[1], Dane.p(it["id"])["name"] if it else "brak", Ui.M_ZLOTO2 if it else Ui.M_OSTRZ))
	_kram_dol("", Callable(), true)


func _portret() -> void:
	ekran.ilustracja.texture = load("res://zasoby/ui/menu/hadraen.webp")
	ekran.ilustracja.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _pokaz_przedmiot(inst: Dictionary, podpowiedz: String, akcja: Callable) -> void:
	_czysc_szczegoly()
	_portret()
	var def := Dane.p(inst["id"])
	var rz: Color = Dane.KOLORY_RZADKOSCI.get(def.get("rarity"), Color.GRAY)
	ekran.duza_ikona.texture = Dane.ikona(inst["id"])
	ekran.szczegoly.add_child(Ui.naglowek_menu(str(Dane.NAZWY_TYPOW.get(def.get("type"), "")).to_upper(), 11, Ui.M_ZAR, 3))
	_sz_nazwa = Ui.naglowek_menu(str(def["name"]), 26, rz.lightened(0.45))
	_sz_nazwa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ekran.szczegoly.add_child(_sz_nazwa)
	var o := Ui.tekst_menu(str(def.get("desc", "")), 14, Ui.M_TEKST)
	o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ekran.szczegoly.add_child(o)
	var staty := Dane.opis_statystyk(inst)
	for linia in staty.split("\n"):
		for kawalek in linia.split("   ", false):
			var cz := kawalek.split(":", false, 1)
			if cz.size() == 2:
				ekran.szczegoly.add_child(Ui.para(cz[0].strip_edges(), cz[1].strip_edges()))
	var pod := Ui.tekst_menu(podpowiedz, 13, Ui.M_DRUGI)
	ekran.szczegoly.add_child(pod)
	_kram_dol("", Callable(), true)


func _czysc_szczegoly() -> void:
	for c in ekran.szczegoly.get_children():
		ekran.szczegoly.remove_child(c)
		c.queue_free()
	ekran.duza_ikona.texture = null
	ekran.ilustracja.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


# ------------------------------------------------------------ KUPIEC: KRAM MARGI (szablon menu NightBrand, etap 2)
## Ekran na szablonie `ekran_menu.gd`: zakładki Kup / Sprzedaj łup, lista z belkami sekcji po lewej,
## szczegóły z ilustracją, tabelą par i przyciskiem akcji po prawej. Ceny i reguły kupna bez zmian.
## Zablokowane i za drogie towary da się wybrać i przeczytać, dlaczego nie można kupić.
var tryb_kupca := "kup"
var _sz_nazwa: Label
var _sz_typ: Label
var _sz_porown: Label
var _sz_kom: Label
var _sz_akcja: Button
var _kram_akcja := Callable()
var _kram_ostatni: Button

const SEKCJE_KRAMU := [["weapon", "Broń biała"], ["shield", "Tarcze"], ["bow", "Łuki i strzały"], ["armor", "Pancerze"], ["elixir", "Mikstury"]]


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
	_stopka("Kup" if tryb_kupca == "kup" else "Sprzedaj", [["lt/rt", "Z / C", "Kup / Sprzedaj"]])
	# podzakładki Kup / Sprzedaj łup (LT/RT, Z/C albo klik)
	var pz := HBoxContainer.new()
	pz.add_theme_constant_override("separation", 8)
	for t in [["kup", "Kup"], ["sprzedaj", "Sprzedaj łup"]]:
		var tid: String = t[0]
		var b := Ui.przycisk_menu(("◆ " if tryb_kupca == tid else "") + t[1])
		b.custom_minimum_size = Vector2(170, 40)
		b.focus_mode = Control.FOCUS_NONE
		if tryb_kupca == tid:
			b.add_theme_color_override("font_color", Ui.M_ZLOTO2)
		b.pressed.connect(func(): _kram_tryb(tid))
		pz.add_child(b)
	kram.lista.add_child(pz)
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
		var wk := Ui.wiersz_listy(_ikona_lub(Dane.ikona("runic_ring"), "hud:sakwa"), "Sprzedaj wszystkie kosztowności", "Surowce zostają na rozbudowę Warowni", "+%d zł" % suma, suma == 0)
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
					Dzwiek.monety()
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
	_czysc_szczegoly()
	kram.ilustracja.texture = load("res://zasoby/ui/menu/tlo_menu_1.webp")
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
	_czysc_szczegoly()
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
	Dzwiek.monety()
	_zmiana()


# ------------------------------------------------------------ WAROWNIA (rozbudowa; wzór: Kaplica NightBrand 1:1)
const ILUSTRACJE_BUDYNKOW := {"forge": "tlo_menu_1", "alchemist": "rozdzial_5", "altar": "kaplica", "vault": "rozdzial_2"}
const IKONY_BUDYNKOW := {"forge": "ikona:steel_kordelas", "alchemist": "ikona:ember_flask", "altar": "menu:ikona_kaplica", "vault": "menu:ikona_kronika"}


func _ikona(n: String) -> Texture2D:
	if n.begins_with("ikona:"):
		return Dane.ikona(n.substr(6))
	return load("res://zasoby/ui/menu/%s.webp" % n.substr(5))


func _warownia() -> void:
	_stopka("Rozbuduj")
	ekran.stopka_listy.text = "Żelazo %d  ·  Popiół %d  ·  Relikty %d" % [Profil.licz_surowiec("iron"), Profil.licz_surowiec("ash"), Profil.licz_surowiec("relic")]
	ekran.lista.add_child(Ui.belka_sekcji("Budynki Warowni"))
	for id in Dane.warownia:
		var up: Dictionary = Dane.warownia[id]
		var lv := Profil.budynek(id)
		var maks := int(up["maxLv"])
		var bid: String = id
		var stac := lv < maks and _stac_na(up["costs"][lv])
		var w := Ui.wiersz_listy(_ikona(IKONY_BUDYNKOW.get(id, "menu:ikona_kronika")), str(up["name"]), "maks. poziom" if lv >= maks else ("można rozbudować" if stac else "brakuje surowców"), "%d / %d" % [lv, maks], false, Ui.M_ZLOTO if lv < maks else Ui.M_ZIELONY)
		w.set_meta("klucz", "up_" + id)
		w.pressed.connect(func(): _rozbuduj(bid))
		_kram_wiersz(w, func(): _pokaz_budynek(bid))
	var pierwszy: String = Dane.warownia.keys()[0]
	_pokaz_budynek(pierwszy)


func _stac_na(k: Dictionary) -> bool:
	return Profil.d["gold"] >= int(k["gold"]) and Profil.licz_surowiec("iron") >= int(k["iron"]) \
		and Profil.licz_surowiec("ash") >= int(k["ash"]) and Profil.licz_surowiec("relic") >= int(k["relic"])


func _koszt_tekst(k: Dictionary) -> String:
	var koszt := "%d zł" % int(k["gold"])
	if int(k["iron"]) > 0: koszt += "  ·  %d żelaza" % int(k["iron"])
	if int(k["ash"]) > 0: koszt += "  ·  %d popiołu" % int(k["ash"])
	if int(k["relic"]) > 0: koszt += "  ·  %d reliktów" % int(k["relic"])
	return koszt


func _pokaz_budynek(id: String) -> void:
	_czysc_szczegoly()
	var up: Dictionary = Dane.warownia[id]
	var lv := Profil.budynek(id)
	var maks := int(up["maxLv"])
	ekran.ilustracja.texture = load("res://zasoby/ui/menu/%s.webp" % ILUSTRACJE_BUDYNKOW.get(id, "tlo_menu_1"))
	ekran.duza_ikona.texture = _ikona(IKONY_BUDYNKOW.get(id, "menu:ikona_kronika"))
	ekran.szczegoly.add_child(Ui.naglowek_menu("POZIOM %d / %d" % [lv, maks], 11, Ui.M_ZAR, 3))
	_sz_nazwa = Ui.naglowek_menu(str(up["name"]), 26, Ui.M_JASNY)
	ekran.szczegoly.add_child(_sz_nazwa)
	var o := Ui.tekst_menu(str(up["desc"]), 14, Ui.M_TEKST)
	o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ekran.szczegoly.add_child(o)
	if lv >= maks:
		ekran.szczegoly.add_child(Ui.para("Następny poziom", "maksymalny poziom osiągnięty", Ui.M_ZIELONY))
		_kram_dol("", Callable(), true)
		return
	var k: Dictionary = up["costs"][lv]
	var stac := _stac_na(k)
	ekran.szczegoly.add_child(Ui.para("Następny poziom", "%d" % (lv + 1)))
	ekran.szczegoly.add_child(Ui.para("Koszt", _koszt_tekst(k), Ui.M_ZLOTO2 if stac else Ui.M_OSTRZ))
	_kram_dol("Rozbuduj do poziomu %d" % (lv + 1), (func(): _rozbuduj(id)) if stac else Callable(), false, "" if stac else "Brakuje surowców na rozbudowę.")


func _rozbuduj(bid: String) -> void:
	var up: Dictionary = Dane.warownia[bid]
	var lv := Profil.budynek(bid)
	_fokus_klucz = "up_" + bid
	if lv >= int(up["maxLv"]):
		return
	var k: Dictionary = up["costs"][lv]
	if not _stac_na(k):
		_info("Brakuje surowców na rozbudowę.")
		return
	Profil.d["gold"] -= int(k["gold"])
	Profil.zuzyj_surowiec("iron", int(k["iron"]))
	Profil.zuzyj_surowiec("ash", int(k["ash"]))
	Profil.zuzyj_surowiec("relic", int(k["relic"]))
	Profil.d["stronghold"][bid] = Profil.budynek(bid) + 1
	Dzwiek.ekstrakcja()
	_info("Ulepszono: %s (poziom %d)!" % [up["name"], Profil.budynek(bid)])
	Profil.zapisz()
	odswiez()


# ------------------------------------------------------------ UMIEJĘTNOŚCI (biegłości rosną w walce, nie kupuje się ich)
func _umiejetnosci() -> void:
	_stopka("Wybierz")
	ekran.stopka_listy.text = "Biegłości rosną w walce, przy parowaniu, unikach, strzelaniu i przeszukiwaniu."
	ekran.lista.add_child(Ui.belka_sekcji("Biegłości rycerza"))
	var pierwszy := ""
	for id in Dane.umiejetnosci:
		var u: Dictionary = Dane.umiejetnosci[id]
		var sk: Dictionary = Profil.d["skills"][id]
		var uid: String = id
		if pierwszy == "":
			pierwszy = id
		var w := Ui.wiersz_listy(_ikona(IKONY_UMIEJ.get(id, "menu:ikona_instrukcja")), str(u["name"]), "%d / %d PD" % [int(sk["xp"]), int(sk["lv"]) * 100], "poz. %d" % int(sk["lv"]))
		w.set_meta("klucz", "um_" + id)
		_kram_wiersz(w, func(): _pokaz_umiejetnosc(uid))
	if pierwszy != "":
		_pokaz_umiejetnosc(pierwszy)


const IKONY_UMIEJ := {"melee": "ikona:rusty_sword", "parry": "ikona:wood_buckler", "endurance": "ikona:stamina_tonic", "archery": "ikona:hunter_bow", "scavenger": "menu:ikona_instrukcja"}


func _pokaz_umiejetnosc(id: String) -> void:
	_czysc_szczegoly()
	_portret()
	var u: Dictionary = Dane.umiejetnosci[id]
	var sk: Dictionary = Profil.d["skills"][id]
	var wym := int(sk["lv"]) * 100
	ekran.duza_ikona.texture = _ikona(IKONY_UMIEJ.get(id, "menu:ikona_instrukcja"))
	ekran.szczegoly.add_child(Ui.naglowek_menu("POZIOM %d" % int(sk["lv"]), 11, Ui.M_ZAR, 3))
	_sz_nazwa = Ui.naglowek_menu(str(u["name"]), 26, Ui.M_JASNY)
	ekran.szczegoly.add_child(_sz_nazwa)
	ekran.szczegoly.add_child(Ui.para("Premia", str(u["bonusDesc"])))
	ekran.szczegoly.add_child(Ui.para("Doświadczenie", "%d / %d PD" % [int(sk["xp"]), wym]))
	var pas := Ui.pasek(Color("c26a2c"), 8)
	pas.max_value = wym
	pas.value = float(sk["xp"])
	ekran.szczegoly.add_child(pas)
	_kram_dol("", Callable(), true)
