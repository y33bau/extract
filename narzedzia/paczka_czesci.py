#!/usr/bin/env python3
"""Dzieli duży zip z grą na części (domyślnie po 350 MB) i dopisuje ZLOZ_<nazwa>.bat.

Powód: narzędzie przesyłania plików do folderu autora przyjmuje najwyżej 400 MB na plik,
a autor chce paczek do 3 GB (decyzja 26.11.2026). U autora dwuklik na ZLOZ_<nazwa>.bat
skleja części (copy /b, wbudowane w Windows) i rozpakowuje zip (PowerShell Expand-Archive).

Użycie: python3 narzedzia/paczka_czesci.py <plik.zip> <katalog_wyjscia> [rozmiar_MB]
"""
import os
import sys


def podziel(zip_sciezka: str, wyjscie: str, rozmiar_mb: int = 350) -> list:
    os.makedirs(wyjscie, exist_ok=True)
    nazwa = os.path.basename(zip_sciezka)
    rdzen = nazwa[:-4] if nazwa.lower().endswith(".zip") else nazwa
    rozmiar = rozmiar_mb * 1024 * 1024
    czesci = []
    with open(zip_sciezka, "rb") as f:
        nr = 1
        while True:
            kawalek = f.read(rozmiar)
            if not kawalek:
                break
            cz = f"{nazwa}.{nr:03d}"
            with open(os.path.join(wyjscie, cz), "wb") as o:
                o.write(kawalek)
            czesci.append(cz)
            nr += 1
    if len(czesci) > 99:
        raise SystemExit("za dużo części")
    plus = "+".join(f'"{c}"' for c in czesci)
    bat = (
        "@echo off\r\n"
        f"REM Skleja {len(czesci)} czesci w {nazwa} i rozpakowuje do folderu {rdzen}\r\n"
        'cd /d "%~dp0"\r\n'
        f'copy /b {plus} "{nazwa}" >nul\r\n'
        f"powershell -NoProfile -Command \"Expand-Archive -Force -LiteralPath '{nazwa}' -DestinationPath '{rdzen}'\"\r\n"
        f"echo Gotowe: gra jest w folderze {rdzen}. Uruchom tam plik TEST_*.bat.\r\n"
        "pause\r\n"
    )
    bat_nazwa = f"ZLOZ_{rdzen}.bat"
    with open(os.path.join(wyjscie, bat_nazwa), "w", newline="") as o:
        o.write(bat)
    return czesci + [bat_nazwa]


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    pliki = podziel(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 350)
    print("\n".join(pliki))
