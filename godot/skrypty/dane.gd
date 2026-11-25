extends Node
## Dane gry z plików JSON (wyeksportowane z prototypu JS: narzedzia/eksport_z_js.py).

var przedmioty: Dictionary = {}
var krainy: Array = []
var warownia: Dictionary = {}
var umiejetnosci: Dictionary = {}
var wyglad: Dictionary = {}  # wygląd Hadræna: arkusze, klatki, zestawy broni
var _ikony: Dictionary = {}

const NAZWY_TYPOW := {
	"weapon": "Broń biała", "shield": "Tarcza", "bow": "Łuk", "arrow": "Strzały",
	"armor": "Pancerz", "elixir": "Mikstura", "material": "Surowiec Warowni", "valuable": "Kosztowność"
}
const KOLORY_RZADKOSCI := {
	"common": Color("78736d"), "uncommon": Color("4ca676"), "rare": Color("4d88c7"),
	"epic": Color("c79c4c"), "legendary": Color("d43f49")
}


func _ready() -> void:
	przedmioty = _json("res://dane/przedmioty.json")
	krainy = _json("res://dane/krainy.json")
	warownia = _json("res://dane/warownia.json")
	umiejetnosci = _json("res://dane/umiejetnosci.json")
	wyglad = _json("res://dane/wyglad_bohatera.json")


func _json(sciezka: String) -> Variant:
	var f := FileAccess.open(sciezka, FileAccess.READ)
	if f == null:
		push_error("Brak pliku danych: " + sciezka)
		return {}
	return JSON.parse_string(f.get_as_text())


func p(id: String) -> Dictionary:
	return przedmioty.get(id, {})


func typ(id: String) -> String:
	return str(p(id).get("type", ""))


func kraina(id: String) -> Dictionary:
	for k in krainy:
		if k["id"] == id:
			return k
	return krainy[0]


func cena_skupu(id: String) -> int:
	return int(float(p(id).get("price", 0)) * 0.65)


func ikona(id: String) -> Texture2D:
	if not _ikony.has(id):
		var sc := "res://zasoby/ikony/%s.png" % id
		_ikony[id] = load(sc) if ResourceLoader.exists(sc) else null
	return _ikony[id]


func opis_statystyk(inst: Dictionary) -> String:
	var d := p(inst["id"])
	var t := "Wartość skupu: %d zł" % cena_skupu(inst["id"])
	match str(d.get("type", "")):
		"weapon":
			t += "\nObrażenia: %d   Stamina: %d" % [d["dmg"], d["stamina"]]
		"shield":
			t += "\nBlok: %d%%   Parowanie: +%d ms" % [roundi(d["blockRed"] * 100), roundi(d["parryBonus"] * 1000)]
		"bow":
			t += "\nObrażenia: %d" % d["dmg"]
		"armor":
			t += "\nWytrzymałość: %d / %d   Redukcja: %d%% (Kl. %d)" % [
				ceili(float(inst.get("durability", 0))), d["maxDurability"], roundi(d["reduction"] * 100), d["tier"]]
		"arrow":
			t += "\nIlość: %d szt." % int(inst.get("qty", 0))
	return t
