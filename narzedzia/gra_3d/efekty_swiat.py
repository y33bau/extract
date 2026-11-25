# Efekty walki z arkuszy NightBrand (GRAFIKI_SWIAT/efekty) -> paski klatek PNG dla Godota.
# Arkusze 2560x2880 to siatka 8x9 komórek po 320 px; arkusz krwi 1774x887 to 4x2.
import sys, os
from PIL import Image
SRC, WYJ = sys.argv[1], sys.argv[2]
A7 = 'f86141e6be400f946b0ac1228df014b642838f615a1553b7b82bce44520078ba.webp'  # cięcia
A6 = 'b3ff692e2e82fbcef6a4532e54adea9eda780565db1a2ae91590ab212a55a0cc.webp'  # rozbłyski, iskry
A4 = 'ec46e83d933a2db80e3e82c795ba3a9ec7e50910bbdd085df486bc0be2b26d3e.png'   # krew
# nazwa -> (arkusz, kolumny, wiersze, wiersz, kolumny klatek)
PASKI = {
    'ciecie':      (A7, 8, 9, 4, [0, 1, 2, 3]),   # białe cięcie
    'ciecie_zar':  (A7, 8, 9, 5, [0, 1, 2, 3]),   # ogniste cięcie (ciężki cios, Piętno)
    'ciecie_krew': (A7, 8, 9, 6, [4, 5, 6, 7]),   # krwawe cięcie (trafienie)
    'parowanie':   (A6, 8, 9, 7, [2, 3, 4, 5]),   # gwiazda i pierścień iskier
    'riposta':     (A6, 8, 9, 6, [6, 7, 7, 7]),   # wybuch iskier
    'krew_bryzg':  (A4, 4, 2, 1, [0, 1, 2, 3]),   # bryzgi (warianty, nie animacja)
    'krew_kaluza': (A4, 4, 2, 0, [0, 1, 2, 3]),   # kałuże (warianty)
}
K = 256
os.makedirs(WYJ, exist_ok=True)
for nazwa, (ark, kol, wie, w, kl) in PASKI.items():
    im = Image.open(os.path.join(SRC, ark)).convert('RGBA')
    cw, ch = im.width // kol, im.height // wie
    pasek = Image.new('RGBA', (K * len(kl), K), (0, 0, 0, 0))
    for i, c in enumerate(kl):
        kom = im.crop((c * cw, w * ch, (c + 1) * cw, (w + 1) * ch))
        s = K / max(cw, ch)
        kom = kom.resize((int(cw * s), int(ch * s)), Image.LANCZOS)
        pasek.paste(kom, (i * K + (K - kom.width) // 2, (K - kom.height) // 2))
    pasek.save(os.path.join(WYJ, nazwa + '.png'))
    print('EFEKT', nazwa, len(kl))

# kałuże krwi jako osobne obrazy (Decal potrzebuje całej tekstury)
k = Image.open(os.path.join(WYJ, 'krew_kaluza.png'))
for i in range(4):
    k.crop((i * K, 0, (i + 1) * K, K)).save(os.path.join(WYJ, 'krew_kaluza_%d.png' % i))
