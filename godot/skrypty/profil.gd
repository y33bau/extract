extends Node
## Trwały profil gracza: złoto, Warownia, umiejętności, rynsztunek, skrytka. Zapis w user://.

signal awans(umiejetnosc: String, poziom: int)
signal zmiana

const SCIEZKA := "user://warownia_zapis_v1.json"
const SAKWA_MAX := 12

var d: Dictionary = {}
var sciezka := SCIEZKA  # testy mogą podmienić


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--zapis="):
			sciezka = a.substr(8)
	wczytaj()


func nowy_przedmiot(id: String, ilosc: int = -1) -> Dictionary:
	var def := Dane.p(id)
	var inst := {"uid": "%x%x" % [randi(), Time.get_ticks_usec()], "id": id}
	if def.get("type") == "arrow":
		inst["qty"] = ilosc if ilosc >= 0 else int(def["stackSize"])
	if def.get("type") == "armor":
		inst["durability"] = float(def["maxDurability"])
	return inst


func domyslny() -> Dictionary:
	var sk := {}
	for k in ["melee", "parry", "endurance", "archery", "scavenger"]:
		sk[k] = {"lv": 1, "xp": 0.0}
	return {
		"gold": 650,
		"stats": {"raids": 0, "survived": 0, "kills": 0, "parries": 0},
		"stronghold": {"forge": 0, "alchemist": 0, "altar": 0, "vault": 0},
		"skills": sk,
		"loadout": {
			"weapon": nowy_przedmiot("rusty_sword"),
			"shield": nowy_przedmiot("wood_buckler"),
			"bow": nowy_przedmiot("hunter_bow"),
			"armor": nowy_przedmiot("leather_jerkin"),
			"backpack": [nowy_przedmiot("iron_arrows", 16), nowy_przedmiot("ember_flask"), nowy_przedmiot("ember_flask"),
				nowy_przedmiot("stamina_tonic"), nowy_przedmiot("ash_salve")],
			"reliquary": [nowy_przedmiot("ember_flask")],
		},
		"kontrakty": nowe_kontrakty(3),
		"stash": [nowy_przedmiot("steel_falchion"), nowy_przedmiot("iron_arrows", 16), nowy_przedmiot("ember_flask"),
			nowy_przedmiot("iron_ingot"), nowy_przedmiot("ash_essence"), nowy_przedmiot("silver_goblet")],
	}


func wczytaj() -> void:
	if FileAccess.file_exists(sciezka):
		var f := FileAccess.open(sciezka, FileAccess.READ)
		var w: Variant = JSON.parse_string(f.get_as_text())
		if w is Dictionary and w.has("loadout") and w.has("stronghold") and w.has("skills"):
			d = w
			if not d.has("kontrakty"):  # migracja zapisu sprzed kontraktów (25.11.2026)
				d["kontrakty"] = nowe_kontrakty(3)
			_napraw_liczby()
			return
	d = domyslny()


func _napraw_liczby() -> void:
	# JSON zamienia liczby całkowite na zmiennoprzecinkowe: przywracamy
	d["gold"] = int(d["gold"])
	for k in d["stats"]:
		d["stats"][k] = int(d["stats"][k])
	for k in d["stronghold"]:
		d["stronghold"][k] = int(d["stronghold"][k])
	for k in d["skills"]:
		d["skills"][k]["lv"] = int(d["skills"][k]["lv"])
	for k in d.get("kontrakty", []):
		for pole in ["cel", "postep", "nagroda"]:
			k[pole] = int(k[pole])
	for lista in [d["stash"], d["loadout"]["backpack"], d["loadout"]["reliquary"]]:
		for it in lista:
			if it.has("qty"):
				it["qty"] = int(it["qty"])


func zapisz() -> void:
	var f := FileAccess.open(sciezka, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
	zmiana.emit()


func resetuj() -> void:
	d = domyslny()
	zapisz()


func max_skrytka() -> int:
	return 24 + int(d["stronghold"]["vault"]) * 8


func max_relikwiarz() -> int:
	return 2 + int(d["stronghold"]["vault"])


func poziom(umiejetnosc: String) -> int:
	return int(d["skills"][umiejetnosc]["lv"])


func budynek(id: String) -> int:
	return int(d["stronghold"][id])


func licz_surowiec(rodzaj: String) -> int:
	var n := 0
	for lista in [d["stash"], d["loadout"]["backpack"], d["loadout"]["reliquary"]]:
		for it in lista:
			if Dane.p(it["id"]).get("matKind") == rodzaj:
				n += 1
	return n


func zuzyj_surowiec(rodzaj: String, ile: int) -> void:
	for lista in [d["stash"], d["loadout"]["backpack"], d["loadout"]["reliquary"]]:
		var i: int = lista.size() - 1
		while i >= 0 and ile > 0:
			if Dane.p(lista[i]["id"]).get("matKind") == rodzaj:
				lista.remove_at(i)
				ile -= 1
			i -= 1


func dodaj_xp(umiejetnosc: String, ile: float) -> void:
	var sk: Dictionary = d["skills"][umiejetnosc]
	sk["xp"] = float(sk["xp"]) + ile
	var wymagane := int(sk["lv"]) * 100
	if sk["xp"] >= wymagane:
		sk["xp"] -= wymagane
		sk["lv"] = int(sk["lv"]) + 1
		awans.emit(umiejetnosc, sk["lv"])


# ---------------------------------------------------------------- USTAWIENIA (osobno od profilu: reset postaci ich nie kasuje)
const PLIK_USTAWIEN := "user://ustawienia.cfg"
const JAKOSCI := ["Niska", "Średnia", "Wysoka", "Ultra"]


## Jakość grafiki 0..3 (domyślnie Wysoka).
func jakosc() -> int:
	var c := ConfigFile.new()
	if c.load(PLIK_USTAWIEN) != OK:
		return 2
	return clampi(int(c.get_value("grafika", "jakosc", 2)), 0, 3)


func ustaw_jakosc(j: int) -> void:
	var c := ConfigFile.new()
	c.load(PLIK_USTAWIEN)
	c.set_value("grafika", "jakosc", clampi(j, 0, 3))
	c.save(PLIK_USTAWIEN)


# ---------------------------------------------------------------- KONTRAKTY CHOJRAKA (KONCEPCJE pkt 1, runda 5)
## Kontrakt liczy się tylko po udanej ekstrakcji (śmierć = nic, jak w Tarkovie). Nagrody: DO STROJENIA przez autora.
const NAGRODA_ZA_WROGA := 40
const NAGRODA_ZA_PAROWANIE := 60
const NAGRODA_EKSTRAKCJA := {"catacombs": 150, "outskirts": 250, "crypt": 400}


func nowy_kontrakt() -> Dictionary:
	var kr: Array = []
	for k in Dane.krainy:
		kr.append(k["id"])
	var kraina: String = kr[randi() % kr.size()]
	match randi() % 3:
		0:
			var n := 3 + randi() % 4
			return {"typ": "zabij", "kraina": kraina, "cel": n, "postep": 0, "nagroda": n * NAGRODA_ZA_WROGA}
		1:
			var n2 := 2 + randi() % 3
			return {"typ": "parowania", "kraina": "", "cel": n2, "postep": 0, "nagroda": n2 * NAGRODA_ZA_PAROWANIE}
		_:
			return {"typ": "ekstrakcja", "kraina": kraina, "cel": 1, "postep": 0, "nagroda": int(NAGRODA_EKSTRAKCJA.get(kraina, 200))}


func nowe_kontrakty(ile: int) -> Array:
	var l: Array = []
	for i in ile:
		l.append(nowy_kontrakt())
	return l


func opis_kontraktu(k: Dictionary) -> String:
	var nazwa := ""
	for kr in Dane.krainy:
		if kr["id"] == k.get("kraina", ""):
			nazwa = kr["name"]
	match str(k["typ"]):
		"zabij": return "Pokonaj %d wrogów: %s" % [int(k["cel"]), nazwa]
		"parowania": return "Sparuj %d ciosów w jednej wyprawie" % int(k["cel"])
		_: return "Wróć żywy z wyprawy: %s" % nazwa


## Rozliczenie po wyprawie. Zwraca opisy wykonanych kontraktów (złoto już dodane).
func rozlicz_kontrakty(kraina: String, zabici: int, parowania: int, przezyl: bool) -> Array:
	var wykonane: Array = []
	if not przezyl:
		return wykonane
	var lista: Array = d.get("kontrakty", [])
	for i in lista.size():
		var k: Dictionary = lista[i]
		match str(k["typ"]):
			"zabij":
				if k["kraina"] == kraina:
					k["postep"] = mini(int(k["cel"]), int(k["postep"]) + zabici)
			"parowania":
				if parowania >= int(k["cel"]):
					k["postep"] = int(k["cel"])
			_:
				if k["kraina"] == kraina:
					k["postep"] = 1
		if int(k["postep"]) >= int(k["cel"]):
			d["gold"] = int(d["gold"]) + int(k["nagroda"])
			wykonane.append("%s  (+%d zł)" % [opis_kontraktu(k), int(k["nagroda"])])
			lista[i] = nowy_kontrakt()
	d["kontrakty"] = lista
	return wykonane
