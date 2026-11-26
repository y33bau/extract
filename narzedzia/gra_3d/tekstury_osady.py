# Tekstury Spalonej Osady z magazynu NightBrand (magazyn/nightbrand/tekstury) -> PBR dla Godota.
# Stan na 2026-11-26, rola gamedev. Ten sam przepis co tekstury_swiat.py (albedo, normal, rh).
# Użycie: python3 narzedzia/gra_3d/tekstury_osady.py   (z katalogu repo)
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tekstury_swiat import zrob

ZRODLO = 'magazyn/nightbrand/tekstury'
WYJ = 'godot/zasoby/3d/swiat'
# nazwa w grze -> (plik w magazynie, rozmiar, siła normalnej)
OSADA = {
    'os_popiol': ('cc0_ash.webp', 2048, 4.0),        # plac i podwórza: popiół, osmalona ziemia
    'os_ziemia': ('cc0_dirt2.webp', 2048, 3.0),      # ulice: ubita, wydeptana ziemia
    'os_wegiel': ('cc0_charcoal.webp', 2048, 4.0),   # przy zgliszczach: węgiel z żarem
    'os_palisada': ('wl_palisada.webp', 1024, 6.0),  # zabudowa: osmalona palisada i płoty
    'os_bale': ('wl_chata.webp', 1024, 6.0),         # mury spalonych chat: zwęglone bale
    'os_deski': ('wl_plank.webp', 1024, 4.0),        # podłoga chat: deski
}

if __name__ == '__main__':
    for nazwa, (plik, rozm, sila) in OSADA.items():
        zrob(os.path.join(ZRODLO, plik), nazwa, WYJ, rozm, sila)
