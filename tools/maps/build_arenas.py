#!/usr/bin/env python3
"""Genera los 3 .tscn de arenas de Brawl-Heads de forma programatica.
Piso fisico full-width, estructuras tematicas diversificadas, decoracion y
spawns repartidos. Reutiliza item-scenes existentes + assets generados.
"""
import hashlib, os

ROOT = "/Users/santi/Documents/proyecto-godot/Brawl-Heads"
_ALPH = "0123456789abcdefghijklmnopqrstuvwxyz"

def G(name):  # uid deterministico de un asset generado (igual que gen_assets.py)
    h = hashlib.md5(("brawlheads:" + name).encode()).digest()
    n = int.from_bytes(h[:8], "big"); s = ""
    for _ in range(13):
        s += _ALPH[n % 36]; n //= 36
    return "uid://" + s

# ── uids de assets/escenas existentes ──
TEX = {
    "crate": ("uid://csiaji183srpq", "res://assets/items-map/crate.png"),
    "bigcrate": ("uid://lsji7h1t34kx", "res://assets/items-map/bigItemCrate.png"),
    "desk": ("uid://clai84dly6rra", "res://assets/items-map/desk.png"),
    "altar": ("uid://dluiklebt7pbd", "res://assets/items-map/altar.png"),
    "barrel": ("uid://dg5noqilpxmu3", "res://assets/items-map/blueBarrel.png"),
    "door": ("uid://cd1osudu8su0c", "res://assets/items-map/doorFrame.png"),
    "arcframe": ("uid://v5ii5xvox1ku", "res://assets/items-map/arcadeFrame01.png"),
    "arclight": ("uid://cu2t1s20mmni8", "res://assets/items-map/arcadeLight.png"),
    "bgtiles": ("uid://b6ty5qxhq2wo1", "res://assets/items-map/backgroundTiles01.png"),
    "billboard": ("uid://456lfybh6us2", "res://assets/items-map/billboard.png"),
    "bg_industrial": ("uid://0jo1ute5mnwk", "res://resources/maps/industrial.png"),
    "bg_pyramid": ("uid://1o18bb1tayjc", "res://resources/maps/pyramid.png"),
    "bg_virtual": ("uid://eop41wlkuj11", "res://resources/maps/virtual.png"),
}
SCN = {
    "barrel": ("uid://wvst1ef5wf7l", "res://resources/items-maps/barrel.tscn"),
    "desk": ("uid://1r282n6dm5g2", "res://resources/items-maps/desk.tscn"),
    "crate_strip": ("uid://f07so87xatd7", "res://resources/items-maps/crate.tscn"),
    "platbrick": ("uid://cxqm1lq8o2w3j", "res://resources/items-maps/platform_brick.tscn"),
    "door": ("uid://bdnefaj0jb0yj", "res://resources/items-maps/door_frame.tscn"),
    "altar": ("uid://rh7yirkvf5hl", "res://resources/items-maps/altar.tscn"),
    "billboard": ("uid://di1ylgjps6iot", "res://resources/items-maps/billboard.tscn"),
    "arcscreen": ("uid://d04gud2b5udij", "res://resources/items-maps/arcade_screen.tscn"),
    "arclight": ("uid://uc5i64vn6p76", "res://resources/items-maps/arcade_light.tscn"),
}

FLOOR_TOP = 210         # superficie del piso (y mundo)
WALL_X = 648
CEIL_Y = -390

PLAT_W = {"s": 96, "m": 160, "l": 224, "xl": 320}

# edificios generados: ancho total, alto cuerpo, alto techo, techo plano(=pisable)
BLD = {
    "ind_tower": dict(w=140, body=214, roof=26, solid=True),
    "ind_shed":  dict(w=218, body=104, roof=26, solid=True),
    "tmp_shrine": dict(w=196, body=150, roof=48, solid=False),
    "tmp_obelisk": dict(w=68, body=250, roof=48, solid=False),
    "arc_tower": dict(w=124, body=252, roof=24, solid=True),
    "arc_block": dict(w=204, body=132, roof=24, solid=True),
}

SCENE_UID = {
    "ArenaFabrica": "uid://t6mi0r8grw0f",
    "ArenaTemplo": "uid://cp4jgmlep7fqe",
    "ArenaArcade": "uid://b12mqyg78tiqg",
}

class Scene:
    def __init__(self, root, bg_key, bg_scale):
        self.ext_order = []      # list of (idname, type, uid, path)
        self.ext_by_uid = {}
        self.subs = []           # (id, text)
        self.nodes = []
        self.root = root
        self.script_id = self._ext("Script", None, "res://scripts/maps/arena.gd")
        self.bg_uid, self.bg_path = TEX[bg_key]
        self.bg_id = self._ext("Texture2D", self.bg_uid, self.bg_path)
        self.bg_scale = bg_scale

    def _ext(self, typ, uid, path):
        key = uid or path
        if key in self.ext_by_uid:
            return self.ext_by_uid[key]
        idn = f"e{len(self.ext_order)+1}"
        self.ext_order.append((idn, typ, uid, path))
        self.ext_by_uid[key] = idn
        return idn

    def tex(self, uid, path):
        return self._ext("Texture2D", uid, path)

    def scn(self, uid, path):
        return self._ext("PackedScene", uid, path)

    def rect(self, w, h):
        rid = f"r{len(self.subs)+1}"
        self.subs.append((rid, f'[sub_resource type="RectangleShape2D" id="{rid}"]\nsize = Vector2({w}, {h})\n'))
        return rid

    # ── nodos ──
    def add(self, text):
        self.nodes.append(text.rstrip("\n"))

    def deco(self, name, uid, path, x, y, scale, region=None, flip=False, z=None, rot=0):
        idn = self.tex(uid, path)
        sx = -scale if flip else scale
        t = f'[node name="{name}" type="Sprite2D" parent="."]\n'
        t += f'position = Vector2({x}, {y})\n'
        if rot:
            t += f'rotation = {rot}\n'
        t += f'scale = Vector2({sx}, {scale})\n'
        if z is not None:
            t += f'z_index = {z}\n'
        t += f'texture = ExtResource("{idn}")\n'
        if region:
            t += f'region_enabled = true\nregion_rect = Rect2({region[0]}, {region[1]}, {region[2]}, {region[3]})\n'
        self.add(t)

    def solid(self, name, uid, path, cx, cy, scale, coll_w, coll_h, region=None,
              spr_dx=0, spr_dy=0, flip=False, coll_dy=0):
        idn = self.tex(uid, path)
        rid = self.rect(coll_w, coll_h)
        sx = -scale if flip else scale
        t = f'[node name="{name}" type="StaticBody2D" parent="."]\n'
        t += f'position = Vector2({cx}, {cy})\n'
        t += f'[node name="{name}S" type="Sprite2D" parent="{name}"]\n'
        if spr_dx or spr_dy:
            t += f'position = Vector2({spr_dx}, {spr_dy})\n'
        t += f'scale = Vector2({sx}, {scale})\n'
        t += f'texture = ExtResource("{idn}")\n'
        if region:
            t += f'region_enabled = true\nregion_rect = Rect2({region[0]}, {region[1]}, {region[2]}, {region[3]})\n'
        t += f'[node name="{name}C" type="CollisionShape2D" parent="{name}"]\n'
        if coll_dy:
            t += f'position = Vector2(0, {coll_dy})\n'
        t += f'shape = SubResource("{rid}")\n'
        self.add(t)

    # edificios compuestos (muro+techo+ventanas+puerta). Reposan el cuerpo en ground_y.
    def building(self, name, key, x, ground_y):
        b = BLD[key]
        uid = G(f"bld_{key}.png")
        path = f"res://assets/items-map/generated/bld_{key}.png"
        H = b["body"] + b["roof"]
        cy = ground_y - H / 2.0
        if b["solid"]:                      # techo plano: colision = caja entera
            self.solid(name, uid, path, x, cy, 1, b["w"] - 2, H)
            return ground_y - H             # superficie pisable (techo)
        else:                               # fronton: colision solo el cuerpo
            self.solid(name, uid, path, x, cy, 1, b["w"] - 2, b["body"],
                       coll_dy=b["roof"] / 2.0)
            return ground_y - b["body"]     # superficie pisable (cornisa)

    def inst(self, name, uid, path, x, y, scale=None):
        idn = self.scn(uid, path)
        t = f'[node name="{name}" parent="." instance=ExtResource("{idn}")]\n'
        t += f'position = Vector2({x}, {y})\n'
        if scale:
            t += f'scale = Vector2({scale[0]}, {scale[1]})\n'
        self.add(t)

    # ── piezas tematicas ──
    def platform(self, theme, size, x, surface_y, name):
        w = PLAT_W[size]
        uid = G(f"plat_{theme}_{size}.png")
        path = f"res://assets/items-map/generated/plat_{theme}_{size}.png"
        cy = surface_y + 15            # sprite/coll 30 alto, top en surface
        self.solid(name, uid, path, x, cy, 1, w - 2, 30, region=None)

    def crate(self, x, rest_y, name, dmg=0):
        # caja simple 16x16 -> escala 4 = 64px ; coll 58
        reg = (16 * dmg, 0, 16, 16)
        cy = rest_y - 29
        self.solid(name, *TEX["crate"], x, cy, 4, 58, 58, region=reg)
        return rest_y - 58            # nueva superficie arriba

    def bigcrate(self, x, rest_y, name, col=0, open=False):
        row = 33 if open else 0
        reg = (32 * col, row, 32, 33)
        cy = rest_y - 46
        self.solid(name, *TEX["bigcrate"], x, cy, 3, 88, 90, region=reg)
        return rest_y - 90

    # ── boilerplate ──
    def header(self):
        steps = 1 + len(self.ext_order) + len(self.subs)
        uid = SCENE_UID.get(self.root, "")
        return f'[gd_scene load_steps={steps} format=3 uid="{uid}"]\n'

    def render(self):
        out = [self.header(), ""]
        for idn, typ, uid, path in self.ext_order:
            if uid:
                out.append(f'[ext_resource type="{typ}" uid="{uid}" path="{path}" id="{idn}"]')
            else:
                out.append(f'[ext_resource type="{typ}" path="{path}" id="{idn}"]')
        out.append("")
        for rid, txt in self.subs:
            out.append(txt.rstrip("\n"))
            out.append("")
        # root
        out.append(f'[node name="{self.root}" type="Node2D"]')
        out.append(f'script = ExtResource("{self.script_id}")')
        out.append("")
        # BG
        out.append('[node name="BG" type="Sprite2D" parent="."]')
        out.append(f'scale = Vector2({self.bg_scale[0]}, {self.bg_scale[1]})')
        out.append(f'texture = ExtResource("{self.bg_id}")')
        out.append("")
        for n in self.nodes:
            out.append(n)
            out.append("")
        return "\n".join(out)

    # bordes (paredes / techo) + piso fisico
    def boundaries(self):
        rid_w = self.rect(60, 1100)
        for nm, x in [("WallLeft", -WALL_X), ("WallRight", WALL_X)]:
            self.add(f'[node name="{nm}" type="StaticBody2D" parent="."]\n'
                     f'[node name="C" type="CollisionShape2D" parent="{nm}"]\n'
                     f'position = Vector2({x}, 0)\nshape = SubResource("{rid_w}")\n')
        rid_c = self.rect(1360, 60)
        self.add(f'[node name="Ceiling" type="StaticBody2D" parent="."]\n'
                 f'[node name="C" type="CollisionShape2D" parent="Ceiling"]\n'
                 f'position = Vector2(0, {CEIL_Y})\nshape = SubResource("{rid_c}")\n')

    def floor(self, theme):
        uid = G(f"floor_{theme}.png")
        path = f"res://assets/items-map/generated/floor_{theme}.png"
        idn = self.tex(uid, path)
        rid = self.rect(1360, 220)
        spr_cy = FLOOR_TOP + 81        # strip 162 alto
        coll_cy = FLOOR_TOP + 110
        self.add(
            f'[node name="Floor" type="StaticBody2D" parent="."]\n'
            f'[node name="FloorS" type="Sprite2D" parent="Floor"]\n'
            f'position = Vector2(0, {spr_cy})\n'
            f'texture = ExtResource("{idn}")\n'
            f'[node name="FloorC" type="CollisionShape2D" parent="Floor"]\n'
            f'position = Vector2(0, {coll_cy})\nshape = SubResource("{rid}")\n')

    def spawns(self, players, weapons):
        ps = '[node name="PlayerSpawns" type="Node2D" parent="."]\n'
        for i, (x, y) in enumerate(players):
            ps += f'[node name="S{i+1}" type="Marker2D" parent="PlayerSpawns"]\nposition = Vector2({x}, {y})\n'
        self.add(ps)
        ws = '[node name="WeaponSpawns" type="Node2D" parent="."]\n'
        for i, (x, y) in enumerate(weapons):
            ws += f'[node name="W{i+1}" type="Marker2D" parent="WeaponSpawns"]\nposition = Vector2({x}, {y})\n'
        self.add(ws)
        self.add('[node name="Camera2D" type="Camera2D" parent="."]\n')


def DECO(s, key, x, y, scale, flip=False, z=None, rot=0):
    uid = G(f"deco_{key}.png")
    path = f"res://assets/items-map/generated/deco_{key}.png"
    s.deco(f"Deco_{key}_{x}_{y}".replace('-', 'm'), uid, path, x, y, scale,
           flip=flip, z=z, rot=rot)


# ════════════════════════ FÁBRICA ════════════════════════
def build_fabrica():
    # ESENCIA: interior de un edificio fabril de varios pisos (decks apilados)
    # con dos construcciones de acero (torre de control + galpon) y maquinaria.
    s = Scene("ArenaFabrica", "bg_industrial", (4, 3))
    F = FLOOR_TOP
    s.boundaries()
    s.floor("industrial")

    # --- edificios de acero ---
    roofT = s.building("Tower", "ind_tower", -512, F)   # techo pisable en -30
    roofS = s.building("Shed", "ind_shed", 472, F)       # techo pisable en +80
    DECO(s, "gear", -512, F-150, 4); DECO(s, "gear", -452, F-58, 3)
    DECO(s, "panel", 472, F-150, 4); DECO(s, "warning", -512, -52, 3)

    # --- planta baja: cintas (mesas), cajas, barriles ---
    s.inst("Conv1", *SCN["desk"], -250, F-12)
    s.inst("Conv2", *SCN["desk"], 150, F-12)
    s.bigcrate(-330, F, "BgL", col=1)
    t = s.crate(-388, F, "CkL1"); s.crate(-388, t, "CkL2")   # escalon a deck1
    s.crate(-10, F, "Cc0"); s.bigcrate(70, F, "BgC", col=0)
    s.inst("BarA", *SCN["barrel"], -150, F-20)
    s.inst("BarB", *SCN["barrel"], 250, F-20)
    s.crate(330, F, "CrR0")

    # --- DECKS del edificio, cada ~80px (saltables) ---
    s.platform("industrial", "l", -330, F-80, "D1a")     # deck1 +130
    s.platform("industrial", "m", 110, F-80, "D1b")
    s.platform("industrial", "s", 340, F-80, "D1c")
    s.platform("industrial", "m", -170, F-160, "D2a")    # deck2 +50
    s.platform("industrial", "l", 250, F-160, "D2b")
    s.platform("industrial", "m", -332, F-240, "D3a")    # deck3 -30 (techo torre)
    s.platform("industrial", "l", 70, F-240, "D3b")
    s.platform("industrial", "s", 360, F-240, "D3c")
    s.platform("industrial", "l", -190, F-320, "D4a")    # deck4 -110
    s.platform("industrial", "m", 280, F-320, "D4b")
    s.platform("industrial", "s", -360, F-398, "D5a")    # top -188
    s.platform("industrial", "m", 80, F-398, "D5b")
    s.platform("industrial", "s", 380, F-398, "D5c")

    # --- maquinaria / colgantes / techo ---
    DECO(s, "pipe", -628, 70, 4); DECO(s, "pipe", 628, 70, 4)
    DECO(s, "pipe", -360, -362, 5, rot=1.5708); DECO(s, "pipe", 220, -362, 5, rot=1.5708)
    for lx in (-200, 60, 320):
        DECO(s, "chain", lx, F-352, 3)
    for lx in (-450, -130, 180, 450):
        DECO(s, "lamp", lx, -334, 3)
    DECO(s, "panel", -170, F-178, 3); DECO(s, "gear", 250, F-178, 3)
    DECO(s, "warning", 624, F-46, 3)

    players = [(-512, roofT-26), (472, roofS-26), (-330, F-94),
               (250, F-174), (70, F-254), (-190, F-334)]
    weapons = [(-512, roofT-22), (472, roofS-22), (-10, F-20), (110, F-94),
               (-170, F-174), (70, F-254), (80, F-412)]
    s.spawns(players, weapons)
    return s


# ════════════════════════ TEMPLO ════════════════════════
def build_templo():
    # ESENCIA: complejo monumental — santuario central con fronton, obeliscos
    # de piedra en los flancos y terrazas que ascienden a una cumbre con altar.
    s = Scene("ArenaTemplo", "bg_pyramid", (4, 3.6))
    F = FLOOR_TOP
    s.boundaries()
    s.floor("temple")

    # --- obeliscos (torres de piedra) en los flancos ---
    obL = s.building("ObL", "tmp_obelisk", -498, F)   # cornisa -40
    obR = s.building("ObR", "tmp_obelisk", 498, F)
    DECO(s, "banner", -498, F-150, 4); DECO(s, "banner", 498, F-150, 4)

    # --- santuario central con fronton ---
    shr = s.building("Shrine", "tmp_shrine", 0, F)     # cornisa +60
    DECO(s, "idol", 0, F-24, 3)
    DECO(s, "brazier", -120, F-20, 3); DECO(s, "brazier", 120, F-20, 3)

    # --- escalinatas simetricas que ascienden a la cumbre (el santuario queda a la vista) ---
    s.platform("temple", "m", -235, F-70, "L1")    # +140
    s.platform("temple", "m", 235, F-70, "R1")
    s.platform("temple", "m", -335, F-150, "L2")   # +60 (al costado del techo)
    s.platform("temple", "m", 335, F-150, "R2")
    s.platform("temple", "m", -250, F-230, "L3")   # -20
    s.platform("temple", "m", 250, F-230, "R3")
    s.platform("temple", "m", -170, F-310, "L4")   # -100
    s.platform("temple", "m", 170, F-310, "R4")
    s.platform("temple", "l", 0, F-380, "Summit")  # -170 (puente sobre el santuario)
    s.inst("AltarTop", *SCN["altar"], 0, F-426)    # altar de la cumbre
    s.platform("temple", "s", -325, F-380, "PkL")  # perchas altas
    s.platform("temple", "s", 325, F-380, "PkR")

    # --- columnas + decoracion densa ---
    for i, cx in enumerate([-380, -150, 150, 380]):
        s.inst(f"Col{i}", *SCN["door"], cx, F-42)
    for (tx, ty) in [(-235, F-100), (235, F-100), (-250, F-260), (250, F-260),
                     (-325, F-410), (325, F-410), (-170, F-340), (170, F-340)]:
        DECO(s, "torch", tx, ty, 3)
    DECO(s, "sun", 0, F-300, 3)
    DECO(s, "sun", -335, F-180, 3); DECO(s, "sun", 335, F-180, 3)
    DECO(s, "glyph", -624, F-58, 4); DECO(s, "glyph", 624, F-58, 4)
    DECO(s, "glyph", -150, F-58, 3); DECO(s, "glyph", 150, F-58, 3)

    # cajas de suministro + urnas
    s.crate(-300, F, "CrL"); s.crate(300, F, "CrR")
    s.inst("UrnL", *SCN["barrel"], -210, F-20)
    s.inst("UrnR", *SCN["barrel"], 210, F-20)

    players = [(-235, F-96), (235, F-96), (0, F-156), (-170, F-336),
               (170, F-336), (0, F-406)]
    weapons = [(0, F-90), (-335, F-176), (335, F-176), (-250, F-256),
               (250, F-256), (0, F-406), (0, F-156)]
    s.spawns(players, weapons)
    return s


# ════════════════════════ ARCADE ════════════════════════
def build_arcade():
    # ESENCIA: skyline de rascacielos neon (estilo Tron) de alturas variadas,
    # con plataformas flotantes para saltar entre edificios y marquesina arriba.
    s = Scene("ArenaArcade", "bg_virtual", (4, 2.57))
    F = FLOOR_TOP
    s.boundaries()
    s.floor("arcade")

    # --- torres del skyline (alturas alternadas) ---
    rTL = s.building("TowerL", "arc_tower", -470, F)   # techo -66
    rBL = s.building("BlockL", "arc_block", -175, F)    # techo +54
    rTC = s.building("TowerC", "arc_tower", 175, F)     # techo -66 (lleva marquesina)
    rBR = s.building("BlockR", "arc_block", 472, F)     # techo +54
    s.inst("Marquee", *SCN["billboard"], 175, rTC-94)

    DECO(s, "crt", -470, F-150, 4); DECO(s, "crt", 175, F-150, 4)
    DECO(s, "cabinet", -300, F-30, 4); DECO(s, "cabinet", 300, F-30, 4)
    DECO(s, "neon", -566, -150, 4); DECO(s, "neon", 566, -150, 4, flip=True)
    DECO(s, "speaker", -626, F-28, 4); DECO(s, "speaker", 626, F-28, 4)

    # --- escalones a los techos + plataformas flotantes entre edificios ---
    t = s.crate(-360, F, "StpL1"); s.crate(-360, t, "StpL2")   # sube a TowerL/BlockL
    t = s.crate(360, F, "StpR1"); s.crate(360, t, "StpR2")
    s.platform("arcade", "m", 0, F-90, "PMidLo")     # +120 entre bloques centrales
    s.platform("arcade", "s", -300, F-150, "PaL")    # +60 hacia techo BlockL
    s.platform("arcade", "s", 300, F-150, "PaR")
    s.platform("arcade", "m", -150, F-228, "PbL")    # -18 (nivel techo torre)
    s.platform("arcade", "m", 150, F-228, "PbR")
    s.platform("arcade", "l", 0, F-300, "PbC")       # -90
    s.platform("arcade", "m", -330, F-310, "PcL")    # -100 (cerca techo torreL)
    s.platform("arcade", "m", 330, F-310, "PcR")
    s.platform("arcade", "s", 0, F-380, "Ptop")      # -170

    # --- coins, cabinas, luces, barriles ---
    for lx in (-300, 0, 300):
        s.inst(f"Lt{lx}".replace('-', 'm'), *SCN["arclight"], lx, -352)
    for (cx, cy) in [(-300, F-190), (300, F-190), (0, F-130), (-150, F-268),
                     (150, F-268), (0, F-340), (0, F-420)]:
        DECO(s, "coin", cx, cy, 3, z=1)
    s.inst("BarL", *SCN["barrel"], -60, F-20)
    s.inst("BarR", *SCN["barrel"], 60, F-20)

    players = [(-470, rTL-26), (175, rTC-26), (-175, rBL-26), (472, rBR-26),
               (0, F-120), (0, F-330)]
    weapons = [(0, F-120), (-300, F-180), (300, F-180), (-150, F-258),
               (150, F-258), (0, F-330), (0, F-410)]
    s.spawns(players, weapons)
    return s


def write(scene, fname):
    path = os.path.join(ROOT, "scenes/maps", fname)
    with open(path, "w") as f:
        f.write(scene.render())
    print("wrote", path)

if __name__ == "__main__":
    write(build_fabrica(), "arena_fabrica.tscn")
    write(build_templo(), "arena_templo.tscn")
    write(build_arcade(), "arena_arcade.tscn")
