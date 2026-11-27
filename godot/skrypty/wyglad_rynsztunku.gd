extends RefCounted
## Wyłącznie wygląd wyposażenia. Ceny, ochrona, obrażenia i sterowanie pozostają w regułach gry.

const SCENA := "res://zasoby/3d/rynsztunek/hadraen_rynsztunek.glb"
const BRONIE := ["rusty_sword", "steel_falchion", "warden_glaive", "ash_greatsword", "executioner_axe"]
const TARCZE := ["wood_buckler", "iron_kite", "ash_aegis"]
const LUKI := ["hunter_bow", "yew_longbow", "shadow_bow"]
const PANCERZE := ["leather_jerkin", "chainmail_hauberk", "ash_plate"]

var wezly: Dictionary = {}
var korzen: Node3D

func przygotuj(model: Node3D) -> void:
	korzen = model
	for n in model.find_children("*", "MeshInstance3D", true, false):
		wezly[str(n.name)] = n
		if str(n.name).begins_with("sprzet_") or str(n.name).begins_with("odlozona_") or str(n.name).begins_with("pochwa_") or str(n.name).begins_with("pancerz_") or str(n.name).begins_with("bron_"):
			n.visible = false

func _pokaz(nazwa: String, pokaz: bool) -> void:
	if wezly.has(nazwa):
		(wezly[nazwa] as Node3D).visible = pokaz

static func id_slotu(rynsztunek: Dictionary, slot: String) -> String:
	var przedmiot = rynsztunek.get(slot)
	return str(przedmiot.get("id", "")) if przedmiot is Dictionary else ""

func odswiez(rynsztunek: Dictionary, zestaw: String, luk_w_rece := false, strzala_na_cieciwie := false, naciagniecie := 0.0) -> void:
	var bron := id_slotu(rynsztunek, "weapon")
	var tarcza := id_slotu(rynsztunek, "shield")
	var luk := id_slotu(rynsztunek, "bow")
	_pokaz("cialo", true)
	_pokaz("cialo_pod_pancerzem", false)
	for id in PANCERZE:
		_pokaz("pancerz_" + id, false)
	for id in BRONIE:
		_pokaz("sprzet_" + id, id == bron and not luk_w_rece)
		_pokaz("odlozona_" + id, id == bron and luk_w_rece)
		_pokaz("pochwa_" + id, id == bron)
	var tarcza_w_rece: bool = zestaw == "miecz_tarcza" and not luk_w_rece
	for id in TARCZE:
		_pokaz("sprzet_" + id, id == tarcza and tarcza_w_rece)
		_pokaz("odlozona_" + id, id == tarcza and not tarcza_w_rece)
	for id in LUKI:
		_pokaz("sprzet_" + id, id == luk and luk_w_rece)
		_pokaz("odlozona_" + id, id == luk and not luk_w_rece)
		var n: MeshInstance3D = wezly.get("sprzet_" + id)
		if n and n.mesh.get_blend_shape_count() > 0:
			n.set_blend_shape_value(0, clampf(naciagniecie, 0.0, 1.0))
	_pokaz("sprzet_quiver", luk in LUKI)
	_pokaz("sprzet_iron_arrow", luk in LUKI and luk_w_rece and strzala_na_cieciwie)

static func celuje_z_luku(p) -> bool:
	return not id_slotu(p.rynsztunek, "bow").is_empty() and not p.martwy and p.unik_czas <= 0.0 and p.zamach_anim <= 0.0 and not p.blok and (p.luk_cd > 0.0 or Input.is_action_pressed("luk"))
