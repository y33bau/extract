extends RefCounted
## Rzut izometryczny: świat (pola) <-> ekran (piksele). Ten sam wzór co w wersji JS.

const KAFEL_W := 64.0
const KAFEL_H := 32.0

static func ekran(w: Vector2) -> Vector2:
	return Vector2((w.x - w.y) * KAFEL_W * 0.5, (w.x + w.y) * KAFEL_H * 0.5)

static func swiat(e: Vector2) -> Vector2:
	var a := e.x / (KAFEL_W * 0.5)
	var b := e.y / (KAFEL_H * 0.5)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)

## Kierunek z ekranu (drążek, WASD) na kierunek w świecie
static func ekran_na_swiat_kierunek(v: Vector2) -> Vector2:
	var w := Vector2(v.x + v.y, v.y - v.x)
	return w.normalized() if w.length() > 0.01 else Vector2.ZERO

## Który rząd arkusza: 0 przód, 1 bok, 2 tył; odbicie dla boku w lewo
static func kierunek_arkusza(kat: float) -> Dictionary:
	var c := cos(kat)
	var s := sin(kat)
	var sdx := c - s
	var sdy := (c + s) * 0.5
	if absf(sdx) > absf(sdy) * 1.6:
		return {"rzad": 1, "sdx": sdx}
	return {"rzad": 0 if sdy >= 0.0 else 2, "sdx": sdx}
