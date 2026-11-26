#!/usr/bin/env python3
"""Grafiki menu z pakietu NightBrand (PAKIET_MENU_NIGHTBRAND.zip, autor gry) -> godot/zasoby/ui/menu/.

Ramki 9-slice są w pakiecie „do druku”; skalujemy je tak, by róg miał ok. 16–20 px przy 720p
(tabela w INSTRUKCJA_PRZEBUDOWY_MENU_WAROWNIA_2026-11-26.md §1.3). Tła zmniejszamy do 1280 px szerokości.

Użycie: python3 narzedzia/menu_zasoby.py <rozpakowany_pakiet> [godot/zasoby/ui/menu]
"""
import os
import sys

from PIL import Image

SKALE = {
    "ui/rama_panelu_18px.webp": ("rama_panelu.webp", 0.36),
    "ui/ramka_karta_slice85.webp": ("ramka_karta.webp", 0.25),
    "ui/ramka_okno_slice155.webp": ("ramka_okno.webp", 0.12),
    "ui/rama_zakladki.webp": ("rama_zakladki.webp", 0.4),
    "ui/rama_zakladki_aktywna.webp": ("rama_zakladki_aktywna.webp", 0.4),
    "ui/przycisk_zwykly.webp": ("przycisk_zwykly.webp", 0.3),
    "ui/przycisk_glowny_graj.webp": ("przycisk_glowny.webp", 0.42),
    "ui/separator_z_pietnem.webp": ("separator_z_pietnem.webp", 300 / 640),
    "ui/urna_popiolow.webp": ("urna_popiolow.webp", 0.5),
    "ui/pietno.webp": ("pietno.webp", 1.0),
    "ui/poswiata_przycisku_fokus.webp": ("poswiata_fokus.webp", 0.5),
    "tla/tlo_menu_1.webp": ("tlo_menu_1.webp", 1280 / 1672),
    "tla/rozdzial_1.webp": ("rozdzial_1.webp", 1280 / 1672),
    "tla/rozdzial_4.webp": ("rozdzial_4.webp", 1280 / 1672),
}


def main() -> None:
    zrodlo = sys.argv[1]
    cel = sys.argv[2] if len(sys.argv) > 2 else "godot/zasoby/ui/menu"
    os.makedirs(cel, exist_ok=True)
    for wej, (wyj, skala) in SKALE.items():
        im = Image.open(os.path.join(zrodlo, wej))
        nowy = (max(1, round(im.width * skala)), max(1, round(im.height * skala)))
        if nowy != im.size:
            im = im.resize(nowy, Image.LANCZOS)
        im.save(os.path.join(cel, wyj), "WEBP", quality=92, method=6)
        print(f"{wej} -> {wyj} {im.size}")


if __name__ == "__main__":
    main()
