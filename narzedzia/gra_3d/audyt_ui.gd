extends SceneTree
## Zrzuty ekranów i pomiar tekstów. Uruchamiać WYŁĄCZNIE z osobnym --zapis.
## Wymagane: --wyniki, --zapis, --podglad-audyt. Dwa rozmiary okna: --resolution 1280x720 / 1920x1080.
var gra
var profil
var dane
var sterowanie
var out := ""
var raport: Array = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--wyniki="):out = arg.trim_prefix("--wyniki=")
	call_deferred("audyt")

func klatki() -> void:
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw

func teksty(n: Node, lista: Array) -> void:
	if n is Control and n.is_visible_in_tree() and (n is Label or n is Button):
		var tekst: String = n.text
		var rect: Rect2 = n.get_global_rect()
		var widoczny := rect.intersection(root.get_visible_rect())
		var rodzic := n.get_parent()
		while rodzic is Control:
			if rodzic.clip_contents:widoczny = widoczny.intersection(rodzic.get_global_rect())
			rodzic = rodzic.get_parent()
		if tekst != "" and widoczny.has_area():
			var font: Font = n.get_theme_font("font")
			var px: int = n.get_theme_font_size("font_size")
			var szer := 0.0
			for linia in tekst.split("\n"):szer = maxf(szer, font.get_string_size(linia, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
			lista.append({"tekst": tekst, "wezel": str(n.get_path()), "font": font.get_font_name(), "px": px,
				"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "szerokosc_tekstu": szer,
				"zawijanie": n.autowrap_mode if n is Label else -1,
				"elipsa": n.text_overrun_behavior, "poza_ekranem": not root.get_visible_rect().encloses(rect)})
	for c in n.get_children():teksty(c, lista)

func zrzut(nazwa: String) -> void:
	await klatki()
	root.get_texture().get_image().save_png(out.path_join(nazwa + ".png"))
	var lista: Array = []
	teksty(gra, lista)
	raport.append({"ekran": nazwa, "viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "teksty": lista})
	print("AUDYT ", nazwa, " — teksty ", lista.size())

func audyt() -> void:
	var osobny_zapis := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zapis="):osobny_zapis = true
	if out == "" or not osobny_zapis:
		push_error("Audyt wymaga --wyniki i osobnego --zapis; nie zmieniamy profilu gracza.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	profil = root.get_node("Profil")
	dane = root.get_node("Dane")
	sterowanie = root.get_node("Sterowanie")
	root.gui_embed_subwindows = true
	gra = load("res://gra.tscn").instantiate()
	root.add_child(gra)
	current_scene = gra
	await klatki()
	profil.resetuj()
	gra.pokaz_tytul()
	await zrzut("01_tytul")
	gra.tytul.dialog_wyjscia.popup_centered()
	await zrzut("02_tytul_wyjscie")
	gra.tytul.dialog_wyjscia.hide()
	gra.zamknij_tytul()
	gra.przystan.poz = gra.przystan.MIEJSCA["marga"][2] + Vector2(0, 1.2)
	await zrzut("03_npc_klawiatura")
	sterowanie.pad_aktywny = true
	await zrzut("04_npc_pad")
	sterowanie.pad_aktywny = false
	for i in 5:
		gra.otworz_menu(i)
		await zrzut("05_menu_%d" % i)
		if i == 0:
			gra.hub._pokaz_kraine(dane.kraina("spalona_osada"))
			await zrzut("06_wyprawa_osada")
			gra.hub._pytaj_o_start()
			await zrzut("07_wyprawa_potwierdzenie")
			gra.hub.dialog_startu.hide()
		if i == 2:
			gra.hub._pokaz_szczegoly("executioner_axe", profil.nowy_przedmiot("executioner_axe"), int(dane.p("executioner_axe")["price"]))
			await zrzut("08_kupiec_zablokowany")
			gra.hub._kram_tryb("sprzedaj")
			await zrzut("09_kupiec_sprzedaz")
			gra.hub._kram_tryb("kup")
		if i == 3:
			gra.hub._pokaz_budynek("alchemist")
			await zrzut("10_warownia_koszt")
		if i == 4:
			gra.hub._pokaz_umiejetnosc("parry")
			await zrzut("11_bieglosc_parowanie")
	profil.d["stronghold"]["vault"] = 3
	profil.d["gold"] = 123456
	profil.d["loadout"]["enhancements"] = []
	for k in ["ruch", "ochrona", "odnowa"]:
		profil.d["loadout"]["enhancements"].append(profil.nowy_przedmiot("ulepszenie_%s_legendary" % k))
	for k in ["ruch", "ochrona", "odnowa", "unik"]:
		for r in ["common", "rare", "epic", "legendary"]:
			profil.d["stash"].append(profil.nowy_przedmiot("ulepszenie_%s_%s" % [k, r]))
	gra.otworz_menu(1)
	await zrzut("12_ekwipunek_dodatki")
	gra.hub._pokaz_przedmiot(profil.nowy_przedmiot("ulepszenie_odnowa_legendary"), "Załóż przed wyprawą", Callable())
	gra.hub.ekran.przewijanie_listy.scroll_vertical = 10000
	await zrzut("13_skrytka_pelna")
	sterowanie.pad_aktywny = true
	gra.hub.odswiez()
	await zrzut("14_ekwipunek_pad")
	gra.zamknij_menu()
	gra.otworz_pauze()
	for i in 3:
		gra.pauza.zakladki.current_tab = i
		if i == 0:
			gra.pauza._ustaw_podzakladke(false)
			await zrzut("15_pauza_klawiatura")
			gra.pauza._ustaw_podzakladke(true)
		await zrzut("16_pauza_%d" % i)
	gra.pauza.dialog_reset.popup_centered()
	await zrzut("17_usuniecie_zapisu")
	gra.pauza.dialog_reset.hide()
	gra.pauza.zamknij()
	gra.rozpocznij_rajd("czarnobor", "AUDYT_UI")
	await klatki()
	for en in gra.rajd.wrogowie:en.uspiony = true
	await zrzut("18_hud")
	var poj: Dictionary = gra.rajd.mapa.skrzynie[0]
	gra.rajd.gracz.w = poj["w"] + Vector2(0, 0.8)
	gra.rajd._kamera(1.0)
	gra.rajd.kamera.force_update_scroll()
	gra.rajd._licz_widok()
	await zrzut("19_podpowiedz_lup")
	gra.rajd.otworz(poj)
	await zrzut("20_lup_szukanie")
	for wpis in poj["przedmioty"]:wpis["odkryty"] = true
	gra.okno.odswiez()
	await zrzut("21_lup_odkryty")
	poj["przedmioty"] = []
	gra.okno.odswiez()
	await zrzut("22_lup_pusty")
	gra.okno.zamknij_okno()
	gra.rajd.otworz(null)
	await zrzut("23_sakwa_bez_pojemnika")
	gra.okno.zamknij_okno()
	gra.otworz_pauze()
	await zrzut("24_pauza_rajd")
	gra.pauza.dialog_porzuconego_rajdu.popup_centered()
	await zrzut("25_porzucony_rajd")
	gra.pauza.dialog_porzuconego_rajdu.hide()
	gra.pauza.zamknij()
	gra.rajd.set_process(false)
	var wynik := {"czas": 1199, "kraina": "Spalona Osada", "kraina_id": "spalona_osada", "ziarno": "AUDYT", "zabici": 48,
		"parowania": 27, "wartosc": 12345, "awanse": [["melee", 12], ["parry", 8]],
		"kontrakty": ["Wróć żywy ze Spalonej Osady (+250 zł)", "Sparuj 5 ciosów w jednej wyprawie (+300 zł)"],
		"lup": ["ulepszenie_odnowa_legendary", "ulepszenie_ochrona_epic", "golden_idol", "steel_falchion"]}
	gra._koniec_rajdu(true, "Dotarłeś do Przystani z łupem.", wynik)
	await zrzut("26_wynik_sukces")
	gra.wynik.queue_free()
	gra.wynik = null
	await klatki()
	wynik["awanse"] = []
	wynik["kontrakty"] = []
	wynik["lup"] = []
	gra._koniec_rajdu(false, "Ciemność pochłonęła ruiny — czas wyprawy minął.", wynik)
	await zrzut("27_wynik_smierc")
	var f := FileAccess.open(out.path_join("pomiary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(raport, "\t"))
	print("AUDYT GOTOWY: ", raport.size(), " ekranów")
	quit()
