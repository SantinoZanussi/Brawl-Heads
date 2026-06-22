#!/usr/bin/env python3
"""Genera pisos fisicos y decoraciones pixel-art para las arenas de Brawl-Heads.
Paletas muestreadas de los fondos reales para que todo combine.
Salida: assets/items-map/generated/*.png  (+ contact sheet en /tmp/zoom)
"""
import os, math, random
from PIL import Image, ImageDraw

ROOT = "/Users/santi/Documents/proyecto-godot/Brawl-Heads"
OUT = os.path.join(ROOT, "assets/items-map/generated")
os.makedirs(OUT, exist_ok=True)
os.makedirs("/tmp/zoom", exist_ok=True)  # solo para las contact-sheets de preview
random.seed(7)

def C(*a):  # rgba helper
    return tuple(a) if len(a) == 4 else (a[0], a[1], a[2], 255)

def save(im, name):
    im.save(os.path.join(OUT, name))
    return im

def grid(rows, pal):
    h = len(rows); w = max(len(r) for r in rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != "." and ch in pal:
                px[x, y] = pal[ch]
    return im

def tile_to_width(tile, width):
    h = tile.height
    strip = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    x = 0
    while x < width:
        strip.alpha_composite(tile, (x, 0))
        x += tile.width
    return strip

# ───────────────────────── FLOORS ─────────────────────────
FH = 162   # alto del piso (superficie arriba, llega hasta el borde inferior)

def floor_industrial():
    """Acero oscuro con remaches + borde superior con franja de peligro naranja."""
    w = 64
    im = Image.new("RGBA", (w, FH), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base = C(52, 52, 60); dark = C(33, 33, 40); light = C(78, 78, 90)
    deep = C(20, 20, 26); rivet = C(96, 96, 108); rdark = C(40, 40, 48)
    orange = C(210, 96, 24); oglow = C(255, 150, 40); oshad = C(120, 48, 12)
    # cuerpo
    d.rectangle([0, 0, w, FH], fill=base)
    # paneles verticales (costura cada 32)
    for sx in (0, 32):
        d.rectangle([sx, 14, sx + 31, FH], fill=base)
        d.line([(sx, 14), (sx, FH)], fill=deep)            # costura izq
        d.line([(sx + 1, 14), (sx + 1, FH)], fill=light)   # brillo
        d.line([(sx + 31, 14), (sx + 31, FH)], fill=dark)  # sombra der
        # remaches
        for rx in (sx + 5, sx + 26):
            for ry in (24, FH - 12):
                d.rectangle([rx, ry, rx + 1, ry + 1], fill=rivet)
                d.point((rx + 1, ry + 1), fill=rdark)
        # placa diamante (textura sutil)
        for ry in range(30, FH - 4, 10):
            for rx in range(sx + 8, sx + 28, 10):
                d.point((rx, ry), fill=light)
                d.point((rx + 5, ry + 5), fill=light)
    # costura horizontal media
    d.line([(0, 70), (w, 70)], fill=dark)
    d.line([(0, 71), (w, 71)], fill=light)
    # ── borde superior: lip de acero + franja de peligro ──
    d.rectangle([0, 0, w, 4], fill=light)            # lip brillante
    d.rectangle([0, 4, w, 6], fill=base)
    d.rectangle([0, 6, w, 13], fill=C(28, 28, 34))   # banda oscura para hazard
    for hx in range(-FH, w, 14):                      # franjas diagonales naranja
        d.polygon([(hx, 13), (hx + 7, 6), (hx + 14, 6), (hx + 7, 13)], fill=orange)
    d.line([(0, 6), (w, 6)], fill=oglow)             # glow superior
    d.line([(0, 13), (w, 13)], fill=oshad)
    return im

def floor_temple():
    """Sillares de arenisca escalonados + superficie de arena clara arriba."""
    w = 96
    im = Image.new("RGBA", (w, FH), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    brick = C(107, 70, 54); light = C(140, 100, 74); dark = C(75, 49, 40)
    mortar = C(52, 35, 31); sand = C(156, 122, 88); sand_d = C(120, 92, 66)
    shadow = C(40, 27, 24)
    d.rectangle([0, 0, w, FH], fill=mortar)
    ch_h = 22; bw = 48
    y = 14
    course = 0
    while y < FH:
        off = (bw // 2) if course % 2 else 0
        x = -off
        while x < w:
            x0, x1 = x + 1, x + bw - 1
            y0, y1 = y + 1, y + ch_h - 1
            d.rectangle([max(0, x0), y0, min(w - 1, x1), y1], fill=brick)
            if x0 >= 0:
                d.line([(x0, y0), (x0, y1)], fill=light)      # borde izq claro
            d.line([(max(0, x0), y0), (min(w - 1, x1), y0)], fill=light)  # arriba claro
            d.line([(max(0, x0), y1), (min(w - 1, x1), y1)], fill=dark)   # abajo oscuro
            if x1 <= w:
                d.line([(min(w - 1, x1), y0), (min(w - 1, x1), y1)], fill=dark)
            # alguna grieta
            if (course + x) % 3 == 0:
                cx = x + bw // 2
                d.line([(cx, y0 + 3), (cx + 2, y1 - 3)], fill=shadow)
            x += bw
        y += ch_h
        course += 1
    # superficie de arena (capa superior 14px)
    d.rectangle([0, 0, w, 11], fill=sand)
    for i in range(0, w, 1):
        if random.random() < 0.18:
            d.point((i, 9 - random.randint(0, 3)), fill=sand_d)
    d.line([(0, 11), (w, 11)], fill=sand_d)
    d.line([(0, 12), (w, 12)], fill=shadow)
    return im

def floor_arcade():
    """Placa de circuito cyber + viga superior con rayas de peligro cyan/amarillo."""
    w = 64
    im = Image.new("RGBA", (w, FH), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base = C(34, 36, 50); dark = C(20, 21, 32); panel = C(44, 47, 64)
    cyan = C(90, 214, 232); mag = C(210, 90, 200); line = C(58, 120, 140)
    metal = C(150, 150, 160); mdark = C(70, 72, 86)
    yellow = C(240, 205, 60); steel = C(96, 100, 120)
    d.rectangle([0, 0, w, FH], fill=base)
    # paneles
    for sx in (0, 32):
        d.rectangle([sx + 1, 16, sx + 30, FH - 2], fill=panel)
        d.line([(sx, 16), (sx, FH)], fill=dark)
        d.line([(sx + 31, 16), (sx + 31, FH)], fill=dark)
    # trazas de circuito
    for ry in range(26, FH - 6, 16):
        d.line([(2, ry), (w - 3, ry)], fill=line)
        for nx in range(6, w, 14):
            d.rectangle([nx, ry - 1, nx + 1, ry + 1], fill=cyan)
    for rx in range(10, w, 20):
        d.line([(rx, 20), (rx, FH - 4)], fill=line)
    for (mx, my) in [(20, 40), (48, 64), (12, 90), (52, 104)]:
        d.rectangle([mx, my, mx + 2, my + 2], fill=mag)
    # ── viga superior estilo hazard (como las del fondo) ──
    d.rectangle([0, 0, w, 15], fill=steel)
    d.rectangle([0, 0, w, 2], fill=metal)
    d.rectangle([0, 13, w, 15], fill=mdark)
    for hx in range(-FH, w, 16):
        d.polygon([(hx, 12), (hx + 8, 3), (hx + 16, 3), (hx + 8, 12)], fill=yellow)
    for hx in range(-FH + 8, w, 16):
        d.polygon([(hx, 12), (hx + 8, 3), (hx + 16, 3), (hx + 8, 12)], fill=cyan)
    return im

# generar floors + strips
for nm, fn in [("industrial", floor_industrial), ("temple", floor_temple), ("arcade", floor_arcade)]:
    tile = fn()
    save(tile, f"floor_{nm}_tile.png")
    strip = tile_to_width(tile, 1312)
    save(strip, f"floor_{nm}.png")

# ───────────────────────── PLATFORMS ─────────────────────────
PLAT_H = 30
def plat(theme, w):
    im = Image.new("RGBA", (w, PLAT_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if theme == "industrial":
        base = C(52, 52, 60); dark = C(33, 33, 40); light = C(82, 82, 94)
        deep = C(18, 18, 24); rivet = C(110, 110, 122)
        orange = C(214, 100, 26); oglow = C(255, 150, 44)
        d.rectangle([0, 4, w - 1, PLAT_H - 1], fill=base)
        d.rectangle([0, 0, w - 1, 3], fill=light)            # lip
        d.line([(0, 4), (w - 1, 4)], fill=oglow)             # glow
        for hx in range(0, w, 12):                            # franja peligro
            d.polygon([(hx, 9), (hx + 6, 4), (hx + 12, 4), (hx + 6, 9)], fill=orange)
        d.line([(0, 9), (w - 1, 9)], fill=deep)
        d.line([(0, PLAT_H - 1), (w - 1, PLAT_H - 1)], fill=deep)  # sombra inf
        for rx in range(8, w - 6, 16):                        # remaches
            d.rectangle([rx, 16, rx + 1, 17], fill=rivet)
            d.rectangle([rx, 24, rx + 1, 25], fill=rivet)
        for cx in (0, w - 4):                                 # caps
            d.rectangle([cx, 4, cx + 3, PLAT_H - 1], fill=dark)
            d.rectangle([cx + 1, 13, cx + 2, 14], fill=rivet)
            d.rectangle([cx + 1, 22, cx + 2, 23], fill=rivet)
    elif theme == "temple":
        brick = C(107, 70, 54); light = C(146, 108, 80); dark = C(72, 47, 38)
        sand = C(160, 126, 92); mortar = C(52, 35, 31); shadow = C(38, 25, 22)
        d.rectangle([0, 0, w - 1, PLAT_H - 1], fill=brick)
        d.rectangle([0, 0, w - 1, 5], fill=sand)             # superficie clara
        d.line([(0, 6), (w - 1, 6)], fill=light)
        for bx in range(0, w, 28):                            # juntas verticales
            d.line([(bx, 7), (bx, PLAT_H - 2)], fill=mortar)
            d.line([(bx + 1, 7), (bx + 1, PLAT_H - 2)], fill=light)
        d.line([(0, PLAT_H - 2), (w - 1, PLAT_H - 2)], fill=dark)
        d.line([(0, PLAT_H - 1), (w - 1, PLAT_H - 1)], fill=shadow)
        for cx in (0, w - 3):                                 # caps
            d.rectangle([cx, 0, cx + 2, PLAT_H - 1], fill=dark)
        d.rectangle([0, 0, w - 1, 1], fill=sand)
    else:  # arcade
        base = C(34, 36, 50); dark = C(18, 19, 30); panel = C(46, 49, 66)
        cyan = C(90, 220, 240); mag = C(214, 92, 204); deep = C(12, 12, 20)
        d.rectangle([0, 3, w - 1, PLAT_H - 1], fill=panel)
        d.rectangle([0, 0, w - 1, 2], fill=base)
        d.line([(0, 3), (w - 1, 3)], fill=cyan)              # neon superior
        d.line([(0, 4), (w - 1, 4)], fill=C(40, 120, 140))
        for nx in range(8, w - 6, 18):                        # nodos
            d.rectangle([nx, 12, nx + 1, 13], fill=cyan)
            d.rectangle([nx + 9, 20, nx + 10, 21], fill=mag)
        d.line([(0, PLAT_H - 2), (w - 1, PLAT_H - 2)], fill=deep)
        d.line([(0, PLAT_H - 1), (w - 1, PLAT_H - 1)], fill=C(40, 120, 140))  # underglow
        for cx in (0, w - 3):                                 # caps
            d.rectangle([cx, 2, cx + 2, PLAT_H - 1], fill=dark)
    return im

for theme in ("industrial", "temple", "arcade"):
    for tag, w in [("s", 96), ("m", 160), ("l", 224), ("xl", 320)]:
        save(plat(theme, w), f"plat_{theme}_{tag}.png")

# ───────────────────────── DECORATIONS ─────────────────────────
# Temple: torch, brazier, glyph stele
def deco_torch():
    P = {"H": C(70, 48, 36), "h": C(100, 70, 52), "m": C(150, 150, 160),
         "f": C(255, 170, 40), "y": C(255, 230, 120), "o": C(220, 90, 20),
         "k": C(40, 26, 20)}
    rows = [
        "...yy...",
        "..yffy..",
        "..fooy..",
        ".yfffoy.",
        ".yooffy.",
        "..foy...",
        "..oo....",
        "..km....",
        "..hH....",
        ".mhHhm..",
        "..hHk...",
        "..hHk...",
        "..hHk...",
        "..kHk...",
        "..hHk...",
        "..mhm...",
    ]
    return grid(rows, P)

def deco_brazier():
    P = {"S": C(90, 62, 50), "s": C(120, 86, 66), "d": C(58, 40, 32),
         "f": C(255, 170, 40), "y": C(255, 235, 130), "o": C(220, 90, 20),
         "k": C(40, 26, 20), "m": C(150, 150, 160)}
    rows = [
        "...y..y....",
        "..yfyyfy...",
        ".yfoyyofy..",
        ".yffyyffy..",
        "..fooooy...",
        "...oooo....",
        ".mssssssm..",
        ".dSssssSd..",
        "..dSssSd...",
        "...dSSd....",
        "...k..k....",
        "..k....k...",
        ".k......k..",
    ]
    return grid(rows, P)

def deco_glyph():
    P = {"S": C(120, 92, 70), "s": C(96, 70, 54), "d": C(60, 42, 36),
         "g": C(200, 170, 110), "k": C(40, 28, 24)}
    rows = [
        ".SSSSSS.",
        "SssssssS",
        "SsgggdsS",
        "Ssdgdgsd",
        "Ssgddgsd",
        "Ssdgdgsd",
        "SsggggsS",
        "Ssdksdsd",
        "SsgddgsS",
        "Ssgdggsd",
        "SssssssS",
        "SsgggdsS",
        "Ssddggsd",
        "SssssssS",
        ".dSSSSd.",
        ".k.dd.k.",
    ]
    return grid(rows, P)

# Industrial: pipe+valve, caged lamp, warning sign, gear
def deco_pipe():
    P = {"M": C(96, 100, 110), "m": C(60, 64, 72), "l": C(140, 146, 158),
         "d": C(38, 40, 46), "r": C(190, 70, 40), "k": C(24, 26, 30)}
    rows = [
        ".dMMMMd.",
        ".dlMMmd.",
        ".dlMMmd.",
        "ddlMMmdd",
        "dlMMMMmd",
        ".dlMMmd.",
        ".dlMMmd.",
        ".dlMMmd.",
        "rl.MM.lr",
        "rrlMMlrr",
        "rl.MM.lr",
        ".dlMMmd.",
        ".dlMMmd.",
        ".dlMMmd.",
        "ddlMMmdd",
        ".dlMMmd.",
    ]
    return grid(rows, P)

def deco_lamp():
    P = {"M": C(60, 64, 72), "l": C(150, 156, 168), "d": C(34, 36, 42),
         "y": C(255, 230, 120), "o": C(255, 180, 50), "k": C(24, 26, 30)}
    rows = [
        "...d....",
        "...d....",
        ".dMMMd..",
        ".MlllM..",
        ".dMMMd..",
        "dMyyyMd.",
        "Myoyoym.",
        "Myyoyym.",
        "Myoyoym.",
        "dMyyyMd.",
        ".dooom..",
        "..ddd...",
    ]
    return grid(rows, P)

def deco_warning():
    P = {"y": C(240, 205, 60), "k": C(20, 20, 24), "d": C(150, 128, 30),
         "M": C(70, 74, 82), "m": C(40, 42, 50)}
    rows = [
        "....y....",
        "...yyy...",
        "..yykyy..",
        "..yykyy..",
        ".yyykyyy.",
        ".yyykyyy.",
        "yyyyyyyyy",
        "yyykkkyyy",
        "ddddddddd",
        "...MmM...",
        "...MmM...",
        "...MmM...",
        "..mMmMm..",
    ]
    return grid(rows, P)

# Arcade: neon arrow, coin, speaker
def deco_neon():
    P = {"c": C(90, 220, 240), "C": C(180, 250, 255), "m": C(230, 90, 210),
         "M": C(255, 160, 240), "k": C(20, 22, 32)}
    rows = [
        "....C........",
        "....Cc.......",
        "....Ccc......",
        "CCCCCcccc....",
        "ccccccccccc..",
        "CCCCCcccc.MMM",
        "....Ccc...MmM",
        "....Cc....MMM",
        "....C........",
    ]
    return grid(rows, P)

def deco_coin():
    P = {"y": C(255, 225, 90), "o": C(220, 160, 30), "w": C(255, 250, 200),
         "k": C(120, 80, 10)}
    rows = [
        "..oooo..",
        ".oywwyo.",
        "oywooyyo",
        "oywooywo",
        "oywooywo",
        "oyywwyyo",
        ".oyyyyo.",
        "..oooo..",
    ]
    return grid(rows, P)

def deco_speaker():
    P = {"M": C(50, 40, 60), "m": C(34, 28, 42), "l": C(90, 80, 110),
         "c": C(90, 220, 240), "d": C(20, 16, 26), "g": C(70, 60, 86)}
    rows = [
        "dMMMMMMd",
        "MllllllM",
        "Mlg..glM",
        "Ml.cc.lM",
        "Ml.cc.lM",
        "Mlg..glM",
        "MllllllM",
        "Mlg..glM",
        "Ml.cc.lM",
        "Ml.cc.lM",
        "Mlg..glM",
        "MllllllM",
        "dMMMMMMd",
    ]
    return grid(rows, P)

decos = {
    "torch": deco_torch(), "brazier": deco_brazier(), "glyph": deco_glyph(),
    "pipe": deco_pipe(), "lamp": deco_lamp(), "warning": deco_warning(),
    "neon": deco_neon(), "coin": deco_coin(), "speaker": deco_speaker(),
}
for nm, im in decos.items():
    save(im, f"deco_{nm}.png")

# ───────────────────── DECORACIONES EXTRA ─────────────────────
def deco_gear():
    P = {"M": C(120, 124, 134), "l": C(170, 174, 184), "d": C(70, 74, 82),
         "k": C(34, 36, 42)}
    rows = [
        "..k..k..k..",
        ".kMk.kMk.k.",
        "kMMMkMMMMMk",
        ".MMlllllMM.",
        ".MllddlllM.",
        "kMldkkdllMk",
        "MMldkkdllMM",
        "kMlddddllMk",
        ".MlllllllM.",
        ".MMlllllMM.",
        "kMMMkMMMMMk",
        ".kMk.kMk.k.",
        "..k..k..k..",
    ]
    return grid(rows, P)

def deco_panel():
    P = {"M": C(54, 58, 66), "d": C(28, 30, 36), "c": C(80, 220, 230),
         "y": C(255, 210, 70), "r": C(230, 80, 60), "g": C(90, 220, 110)}
    rows = [
        "dddddddddd",
        "dMMMMMMMMd",
        "dMccccccMd",
        "dMcddddcMd",
        "dMccccccMd",
        "dMMMMMMMMd",
        "dMrygMrgyMd"[:10],
        "dMMMMMMMMd",
        "dddddddddd",
    ]
    return grid(rows, P)

def deco_chain():
    P = {"l": C(150, 154, 164), "d": C(70, 74, 82), "k": C(34, 36, 42)}
    rows = ["dld", "lkl", "dld", "lkl", "dld", "lkl", "dld", "lkl",
            "dld", "lkl", "dld", "lkl"]
    return grid(rows, P)

def deco_idol():
    P = {"S": C(120, 92, 70), "s": C(96, 70, 54), "d": C(60, 42, 36),
         "g": C(206, 176, 112), "k": C(40, 28, 24)}
    rows = [
        "..ggg..",
        ".gSsSg.",
        ".gkSkg.",
        ".sSSSs.",
        "..sSs..",
        ".dSsSd.",
        "dSsssSd",
        "dSsgsSd",
        "dSsssSd",
        "dSsssSd",
        "dddddddd"[:7],
        ".kSSSk.",
    ]
    return grid(rows, P)

def deco_sun():
    P = {"g": C(230, 195, 90), "y": C(255, 230, 140), "o": C(200, 140, 40),
         "k": C(120, 80, 20)}
    rows = [
        "..k.g.k..",
        "k.ggggg.k",
        ".gygygyg.",
        "g.gyyyg.g",
        "gggyyygggg"[:9],
        "g.gyyyg.g",
        ".gygygyg.",
        "k.ggggg.k",
        "..k.g.k..",
    ]
    return grid(rows, P)

def deco_banner():
    P = {"r": C(150, 60, 50), "R": C(190, 80, 64), "g": C(206, 176, 112),
         "d": C(90, 36, 30), "k": C(40, 26, 24)}
    rows = [
        "kgggggk",
        "dRRRRRd",
        "dRgggRd",
        "dRgkgRd",
        "dRgggRd",
        "dRRRRRd",
        "dRgggRd",
        "dRRRRRd",
        "dRgkgRd",
        "dRRRRRd",
        ".d.d.d.",
        "..d.d..",
    ]
    return grid(rows, P)

def deco_cabinet():
    P = {"M": C(46, 38, 58), "m": C(30, 24, 40), "l": C(90, 80, 110),
         "c": C(90, 220, 240), "y": C(245, 210, 70), "r": C(230, 80, 70),
         "k": C(16, 12, 24)}
    rows = [
        ".kMMMMk.",
        ".MlllllM",
        ".MccccM.",
        ".McllcM.",
        ".MccccM.",
        ".MlllllM",
        ".Myrykm.",
        ".MmmmmM.",
        ".MlcclM.",
        ".MmmmmM.",
        ".MmmmmM.",
        ".kMMMMk.",
    ]
    return grid(rows, P)

def deco_crt():
    P = {"M": C(54, 50, 64), "d": C(28, 24, 36), "c": C(90, 220, 240),
         "m": C(210, 90, 200), "k": C(16, 12, 24)}
    rows = [
        "ddddddddd",
        "dMMMMMMMd",
        "dMcmcmcMd",
        "dMmcmcmMd",
        "dMcmcmcMd",
        "dMMMMMMMd",
        "ddd.k.ddd",
        "..ddddd..",
    ]
    return grid(rows, P)

decos2 = {
    "gear": deco_gear(), "panel": deco_panel(), "chain": deco_chain(),
    "idol": deco_idol(), "sun": deco_sun(), "banner": deco_banner(),
    "cabinet": deco_cabinet(), "crt": deco_crt(),
}
for nm, im in decos2.items():
    save(im, f"deco_{nm}.png")
decos.update(decos2)

# ───────────────────── ARQUITECTURA (muros/techos/casas) ─────────────────────
IND = dict(base=(52, 52, 60), dark=(33, 33, 40), light=(82, 82, 94),
           rivet=(110, 110, 122), deep=(18, 18, 24), orange=(214, 100, 26),
           glow=(255, 150, 44), winlit=(255, 178, 70), windk=(40, 28, 16))
TMP = dict(brick=(107, 70, 54), light=(146, 108, 80), dark=(72, 47, 38),
           sand=(160, 126, 92), mortar=(52, 35, 31), shadow=(38, 25, 22),
           gold=(206, 176, 112), windk=(28, 20, 18))
ARC = dict(base=(34, 36, 50), dark=(18, 19, 30), panel=(46, 49, 66),
           cyan=(90, 220, 240), mag=(214, 92, 204), deep=(12, 12, 20))

def tile_box(unit, w, h):
    box = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(0, h, unit.height):
        for x in range(0, w, unit.width):
            cw = min(unit.width, w - x); ch = min(unit.height, h - y)
            box.alpha_composite(unit.crop((0, 0, cw, ch)), (x, y))
    return box

def wall_industrial():
    w = h = 64; im = Image.new("RGBA", (w, h)); d = ImageDraw.Draw(im); p = IND
    d.rectangle([0, 0, w, h], fill=C(*p['base']))
    for sx in (0, 32):
        d.line([(sx, 0), (sx, h)], fill=C(*p['deep']))
        d.line([(sx + 1, 0), (sx + 1, h)], fill=C(*p['light']))
        d.line([(sx + 31, 0), (sx + 31, h)], fill=C(*p['dark']))
        for ry in (5, 27, 37, 59):
            for rx in (sx + 6, sx + 25):
                d.rectangle([rx, ry, rx + 1, ry + 1], fill=C(*p['rivet']))
    for hy in (0, 32):
        d.line([(0, hy), (w, hy)], fill=C(*p['dark']))
        d.line([(0, hy + 1), (w, hy + 1)], fill=C(*p['light']))
    return im

def wall_temple():
    w = h = 64; im = Image.new("RGBA", (w, h)); d = ImageDraw.Draw(im); p = TMP
    d.rectangle([0, 0, w, h], fill=C(*p['mortar']))
    ch = 16; bw = 32
    for ci, y in enumerate(range(0, h, ch)):
        off = 16 if ci % 2 else 0
        for x in range(-off, w, bw):
            x0, x1 = x + 1, x + bw - 1; y0, y1 = y + 1, y + ch - 1
            d.rectangle([max(0, x0), y0, min(w - 1, x1), y1], fill=C(*p['brick']))
            d.line([(max(0, x0), y0), (min(w - 1, x1), y0)], fill=C(*p['light']))
            d.line([(max(0, x0), y1), (min(w - 1, x1), y1)], fill=C(*p['dark']))
    return im

def wall_arcade():
    w = h = 64; im = Image.new("RGBA", (w, h)); d = ImageDraw.Draw(im); p = ARC
    d.rectangle([0, 0, w, h], fill=C(*p['base']))
    for sx in (0, 32):
        d.rectangle([sx + 2, 2, sx + 29, h - 2], fill=C(*p['panel']))
        d.line([(sx, 0), (sx, h)], fill=C(*p['deep']))
    for sy in range(0, h, 16):
        d.line([(0, sy), (w, sy)], fill=C(*p['dark']))
    for sx in (8, 40, 56, 24):
        d.line([(sx, 0), (sx, h)], fill=C(58, 120, 140))
    for (mx, my) in [(20, 24), (50, 8), (12, 52), (44, 40)]:
        d.rectangle([mx, my, mx + 1, my + 1], fill=C(*p['mag']))
    return im

def roof_industrial(w):
    h = 26; im = Image.new("RGBA", (w, h)); d = ImageDraw.Draw(im); p = IND
    d.rectangle([0, 8, w - 1, h - 1], fill=C(*p['base']))
    d.rectangle([0, 4, w - 1, 8], fill=C(*p['light']))     # lip overhang
    for x in range(0, w, 6):
        d.line([(x, 9), (x, h - 4)], fill=C(*p['light']))
        d.line([(x + 3, 9), (x + 3, h - 4)], fill=C(*p['dark']))
    d.line([(0, 8), (w - 1, 8)], fill=C(*p['glow']))
    d.rectangle([0, h - 3, w - 1, h - 1], fill=C(*p['deep']))
    vx = w // 2 - 9                                          # caja de ventilacion
    d.rectangle([vx, 0, vx + 18, 8], fill=C(*p['dark']))
    d.rectangle([vx + 2, 2, vx + 16, 6], fill=C(*p['deep']))
    return im

def roof_temple(w):
    h = 48; im = Image.new("RGBA", (w, h)); d = ImageDraw.Draw(im); p = TMP
    d.rectangle([0, h - 14, w - 1, h - 1], fill=C(*p['brick']))   # cornisa
    d.rectangle([0, h - 14, w - 1, h - 12], fill=C(*p['sand']))
    d.rectangle([4, h - 20, w - 5, h - 14], fill=C(*p['dark']))   # friso
    d.line([(0, h - 1), (w - 1, h - 1)], fill=C(*p['shadow']))
    apex = (w // 2, 1); left = (5, h - 20); right = (w - 6, h - 20)
    d.polygon([apex, left, right], fill=C(*p['brick']))           # fronton
    d.line([apex, left], fill=C(*p['light'])); d.line([apex, right], fill=C(*p['dark']))
    d.line([left, right], fill=C(*p['sand']))
    cx, cy = w // 2, h - 30                                       # disco solar
    d.ellipse([cx - 6, cy - 5, cx + 6, cy + 7], fill=C(*p['gold']))
    d.ellipse([cx - 3, cy - 2, cx + 3, cy + 4], fill=C(*p['sand']))
    return im

def roof_arcade(w):
    h = 24; im = Image.new("RGBA", (w, h)); d = ImageDraw.Draw(im); p = ARC
    d.rectangle([0, 6, w - 1, h - 1], fill=C(*p['panel']))
    d.rectangle([0, 2, w - 1, 6], fill=C(*p['base']))
    d.line([(0, 6), (w - 1, 6)], fill=C(*p['cyan']))
    sx = w // 2 - 22                                              # cartel
    d.rectangle([sx, 0, sx + 44, 11], fill=C(*p['dark']))
    d.rectangle([sx + 2, 2, sx + 42, 9], fill=C(*p['mag']))
    d.rectangle([sx + 2, 2, sx + 42, 3], fill=C(255, 170, 240))
    d.line([(0, h - 1), (w - 1, h - 1)], fill=C(58, 120, 140))
    for ax in (sx - 6, sx + 50):
        d.line([(ax, 0), (ax, 6)], fill=C(*p['cyan']))
    return im

def win_industrial():
    P = {"f": C(40, 42, 50), "l": C(96, 100, 112), "y": C(255, 184, 78),
         "o": C(220, 130, 40), "k": C(20, 16, 12)}
    rows = ["ffffff", "fyoooyf"[:6], "foyyof", "foyyof", "fyoooyf"[:6], "ffffff"]
    return grid(rows, P)

def win_temple():
    P = {"s": C(96, 70, 54), "l": C(146, 108, 80), "k": C(24, 18, 16),
         "d": C(40, 28, 24)}
    rows = ["..ll..", ".lkkl.", "lkkkkl", "lkddkl", "lkddkl", "lkddkl",
            "lkddkl", "lkddkl", "lddddl", "llllll"]
    return grid(rows, P)

def win_arcade(col="c"):
    cc = C(90, 220, 240) if col == "c" else C(214, 92, 204)
    hi = C(180, 250, 255) if col == "c" else C(255, 170, 240)
    P = {"d": cc, "h": hi, "f": C(20, 22, 34)}
    rows = ["dddddd", "dffffd", "dfhhfd", "dfhhfd", "dffffd", "dddddd"]
    return grid(rows, P)

def door_industrial():
    P = {"M": C(60, 64, 72), "l": C(110, 114, 126), "d": C(30, 32, 38),
         "k": C(16, 18, 22), "y": C(230, 150, 50)}
    rows = ["dddddddd", "dMMMMMMd", "dMllllMd", "dMl..lMd", "dMl..lMd",
            "dMl..lMd", "dMlyylMd", "dMl..lMd", "dMl..lMd", "dMllllMd",
            "dMMMMMMd", "dddddddd"]
    return grid(rows, P)

def door_temple():
    P = {"s": C(120, 92, 70), "d": C(60, 42, 36), "k": C(20, 14, 12),
         "g": C(206, 176, 112)}
    rows = ["..gggg..", ".gskksg.", "gskkkksg", "sk.kk.ks", "sk.kk.ks",
            "sk.kk.ks", "sk.kk.ks", "sk.kk.ks", "sk.kk.ks", "skgkkgks",
            "sk.kk.ks", "ssssssss"]
    return grid(rows, P)

def door_arcade():
    P = {"M": C(40, 44, 60), "c": C(90, 220, 240), "d": C(18, 20, 32),
         "k": C(12, 12, 20), "m": C(214, 92, 204)}
    rows = ["cccccccc", "cMMMMMMc", "cMddddMc", "cMdkkdMc", "cMdkkdMc",
            "cMdkkdMc", "cMdmmdMc", "cMdkkdMc", "cMdkkdMc", "cMddddMc",
            "cMMMMMMc", "cccccccc"]
    return grid(rows, P)

WALLS = {"industrial": wall_industrial, "temple": wall_temple, "arcade": wall_arcade}
ROOFS = {"industrial": roof_industrial, "temple": roof_temple, "arcade": roof_arcade}
WINS = {"industrial": win_industrial, "temple": win_temple, "arcade": win_arcade}
DOORS = {"industrial": door_industrial, "temple": door_temple, "arcade": door_arcade}

def building(theme, w, body_h, door=True):
    wall = WALLS[theme]()
    body = tile_box(wall, w, body_h)
    d = ImageDraw.Draw(body)
    edge = {"industrial": C(*IND['deep']), "temple": C(*TMP['shadow']),
            "arcade": C(*ARC['deep'])}[theme]
    d.rectangle([0, 0, w - 1, body_h - 1], outline=edge, width=2)
    # ventanas en grilla
    win = WINS[theme]()
    gx = max(28, (w - 28) // max(1, (w // 44)))
    cols = list(range(14, w - 14 - win.width, 38))
    rows_ = list(range(14, body_h - 46, 40))
    for ry in rows_:
        for rx in cols:
            wim = win
            if theme == "arcade":
                wim = win_arcade("c" if (rx + ry) % 80 < 40 else "m")
            body.alpha_composite(wim, (rx, ry))
    # puerta abajo al centro
    if door:
        dr = DOORS[theme]()
        body.alpha_composite(dr, (w // 2 - dr.width // 2, body_h - dr.height - 2))
    # techo
    rf = ROOFS[theme](w + 8)
    H = rf.height + body_h
    canvas = Image.new("RGBA", (w + 8, H), (0, 0, 0, 0))
    canvas.alpha_composite(body, (4, rf.height))
    canvas.alpha_composite(rf, (0, 0))
    return canvas

# specs: (theme, w_body, body_h) ; el ancho total = w_body+8
BUILD_SPECS = {
    "ind_tower": ("industrial", 132, 214),
    "ind_shed":  ("industrial", 210, 104),
    "tmp_shrine": ("temple", 188, 150),
    "tmp_obelisk": ("temple", 60, 250),
    "arc_tower": ("arcade", 116, 252),
    "arc_block": ("arcade", 196, 132),
}
for nm, (th, w, bh) in BUILD_SPECS.items():
    save(building(th, w, bh), f"bld_{nm}.png")

# muros sueltos (tileables) por si quiero torres/paredes a medida
for th in ("industrial", "temple", "arcade"):
    save(WALLS[th](), f"wall_{th}.png")

# ── contact sheet ──
items = [("floor_industrial_tile", Image.open(f"{OUT}/floor_industrial_tile.png")),
         ("floor_temple_tile", Image.open(f"{OUT}/floor_temple_tile.png")),
         ("floor_arcade_tile", Image.open(f"{OUT}/floor_arcade_tile.png"))]
items += [(nm, im) for nm, im in decos.items()]
pad = 16; scale = 5
cw = max(im.width for _, im in items) * scale + pad * 2
maxh = max(im.height for _, im in items) * scale
cols = 4
rows_n = (len(items) + cols - 1) // cols
sheet = Image.new("RGBA", (cw * cols, (maxh + 40) * rows_n), (30, 30, 36, 255))
sd = ImageDraw.Draw(sheet)
for i, (nm, im) in enumerate(items):
    cx = (i % cols) * cw; cy = (i // cols) * (maxh + 40)
    big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    sheet.alpha_composite(big, (cx + pad, cy + 30))
    sd.text((cx + pad, cy + 8), f"{nm} {im.width}x{im.height}", fill=(255, 255, 255, 255))
sheet.convert("RGB").save("/tmp/zoom/gen_sheet.png")
print("Generated", len(items), "assets ->", OUT)
print("Sheet -> /tmp/zoom/gen_sheet.png")

# ───────────── .import de Godot para cada PNG (uid estable) ─────────────
import hashlib
ALPH = "0123456789abcdefghijklmnopqrstuvwxyz"
def uid_for(name):
    h = hashlib.md5(("brawlheads:" + name).encode()).digest()
    n = int.from_bytes(h[:8], "big"); s = ""
    for _ in range(13):
        s += ALPH[n % 36]; n //= 36
    return "uid://" + s

IMPORT_TPL = '''[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{base}-{hash}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://{src}"
dest_files=["res://.godot/imported/{base}-{hash}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
'''
nimp = 0
for f in sorted(os.listdir(OUT)):
    if not f.endswith(".png"):
        continue
    src = f"assets/items-map/generated/{f}"
    fakehash = hashlib.md5(src.encode()).hexdigest()
    with open(os.path.join(OUT, f + ".import"), "w") as out:
        out.write(IMPORT_TPL.format(uid=uid_for(f), base=f, hash=fakehash, src=src))
    nimp += 1
print("Wrote", nimp, ".import files")
