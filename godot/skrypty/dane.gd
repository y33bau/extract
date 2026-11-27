extends Node
## Dane gry z plików JSON (wyeksportowane z prototypu JS: narzedzia/eksport_z_js.py).

var ekonomia: Dictionary = {}
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
	ekonomia = _json("res://dane/ekonomia.json")
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


## Przyjmuje identyfikator (stare wywołania) albo instancję z ilością i stanem.
func cena_skupu(przedmiot: Variant) -> int:
	var inst: Dictionary = przedmiot if przedmiot is Dictionary else {"id": str(przedmiot)}
	if bool(inst.get("dar_margi", false)):
		return 0
	var def: Dictionary = p(str(inst.get("id", "")))
	var stawki: Dictionary = ekonomia.get("sellRates", {})
	var wartosc: float = float(def.get("price", 0)) * float(stawki.get(str(def.get("type", "")), 0.65))
	if def.get("type") == "arrow":
		wartosc *= maxf(0.0, float(inst.get("qty", def.get("stackSize", 1)))) / maxf(1.0, float(def.get("stackSize", 1)))
	if def.get("type") == "armor":
		wartosc *= 0.25 + 0.75 * stan_pancerza(inst)
	return maxi(0, floori(wartosc))


func dwureczna(rynsztunek: Dictionary) -> bool:
	var bron: Dictionary = rynsztunek.get("weapon") if rynsztunek.get("weapon") is Dictionary else {}
	return int(p(str(bron.get("id", ""))).get("hands", 1)) == 2


func aktywna_tarcza(rynsztunek: Dictionary) -> Dictionary:
	if dwureczna(rynsztunek):
		return {}
	return rynsztunek.get("shield") if rynsztunek.get("shield") is Dictionary else {}


func postura_broni(def: Dictionary) -> float:
	return float(def.get("postureDmg", def.get("dmg", 10)))


func stan_pancerza(inst: Dictionary) -> float:
	var maks: float = float(p(str(inst.get("id", ""))).get("maxDurability", 0))
	if maks <= 0.0:
		return 0.0
	return clampf(float(inst.get("durability", maks)) / maks, 0.0, 1.0)


func ochrona_pancerza(inst: Dictionary) -> float:
	return float(p(str(inst.get("id", ""))).get("reduction", 0.0)) * stan_pancerza(inst)


func koszt_uniku(rynsztunek: Dictionary, poziom: int) -> float:
	var pancerz: Dictionary = rynsztunek.get("armor") if rynsztunek.get("armor") is Dictionary else {}
	return maxf(12.0, 22.0 - (poziom - 1) * 1.2) + float(p(str(pancerz.get("id", ""))).get("dodgeCost", 0.0))


func cena_naprawy(inst: Dictionary) -> int:
	var def: Dictionary = p(str(inst.get("id", "")))
	if def.get("type") != "armor":
		return 0
	return ceili(float(def.get("price", 0)) * float(ekonomia.get("repairRate", 0.35)) * (1.0 - stan_pancerza(inst)))


func ikona(id: String) -> Texture2D:
	if not _ikony.has(id):
		var sc := "res://zasoby/ikony/%s.png" % id
		_ikony[id] = load(sc) if ResourceLoader.exists(sc) else null
	return _ikony[id]


func opis_statystyk(inst: Dictionary) -> String:
	var d := p(inst["id"])
	var t := "Wartość skupu: %d zł" % cena_skupu(inst)
	match str(d.get("type", "")):
		"weapon":
			t += "\nObrażenia: %d   Stamina: %d\nChwyt: %dH   Postura: %d" % [d["dmg"], d["stamina"], int(d.get("hands", 1)), roundi(postura_broni(d))]
		"shield":
			t += "\nBlok: %d%%   Parowanie: +%d ms" % [roundi(d["blockRed"] * 100), roundi(d["parryBonus"] * 1000)]
		"bow":
			t += "\nObrażenia: %d" % d["dmg"]
		"armor":
			t += "\nWytrzymałość: %d / %d   Redukcja: %d%% (Kl. %d)" % [
				ceili(float(inst.get("durability", 0))), d["maxDurability"], roundi(ochrona_pancerza(inst) * 100), d["tier"]]
			t += "\nKoszt uniku: +%d staminy   Naprawa: %d zł" % [int(d.get("dodgeCost", 0)), cena_naprawy(inst)]
		"arrow":
			t += "\nIlość: %d szt." % int(inst.get("qty", 0))
	if bool(inst.get("dar_margi", false)):
		t += "\nDar Margi — bez wartości skupu"
	return t
