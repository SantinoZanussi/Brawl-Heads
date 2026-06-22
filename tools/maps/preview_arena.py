#!/usr/bin/env python3
"""Previsualizador de arenas Brawl-Heads.

Compone un .tscn de arena a PNG usando los sprites reales, para iterar la
estetica sin abrir Godot. Dibuja: fondo, props (instancias de item-scenes y
Sprite2D directos), colisiones (rojo semi-transp), spawns de jugadores (verde)
y de armas (amarillo).

Uso: python3 /tmp/preview_arena.py scenes/maps/arena_fabrica.tscn [out.png]
"""
import re, sys, os
from PIL import Image, ImageDraw

ROOT = "/Users/santi/Documents/proyecto-godot/Brawl-Heads"

# ---- mundo -> pixel ----
VIEW_W, VIEW_H = 1500, 860
OX, OY = VIEW_W // 2, VIEW_H // 2
def w2p(x, y):
    return (int(round(OX + x)), int(round(OY + y)))

def res_path(p):
    return os.path.join(ROOT, p.replace("res://", ""))

def parse_tscn(path):
    """Devuelve (ext{id:dict}, sub{id:dict}, nodes[list of dict])."""
    with open(path) as f:
        text = f.read()
    ext, sub, nodes = {}, {}, []
    # ext_resources
    for m in re.finditer(r'\[ext_resource ([^\]]+)\]', text):
        attrs = dict(re.findall(r'(\w+)="([^"]+)"', m.group(1)))
        ext[attrs.get("id")] = attrs
    # bloques (sub_resource / node) con sus propiedades
    blocks = re.split(r'\n(?=\[)', text)
    for b in blocks:
        head = re.match(r'\[(\w+)\s+([^\]]*)\]', b)
        if not head:
            continue
        kind = head.group(1)
        attrs = dict(re.findall(r'(\w+)="([^"]+)"', head.group(2)))
        inst = re.search(r'instance=ExtResource\("([^"]+)"\)', head.group(2))
        body = b[head.end():]
        def gv2(key):
            mm = re.search(key + r'\s*=\s*Vector2\(([^)]+)\)', body)
            if mm:
                a, c = mm.group(1).split(",")
                return (float(a), float(c))
            return None
        def grect(key):
            mm = re.search(key + r'\s*=\s*Rect2\(([^)]+)\)', body)
            if mm:
                v = [float(x) for x in mm.group(1).split(",")]
                return v
            return None
        def gfloat(key):
            mm = re.search(key + r'\s*=\s*(-?[0-9.]+)', body)
            return float(mm.group(1)) if mm else 0.0
        if kind == "sub_resource":
            sub[attrs.get("id")] = {"type": attrs.get("type"), "size": gv2("size")}
        elif kind == "node":
            tex = re.search(r'texture\s*=\s*ExtResource\("([^"]+)"\)', body)
            shp = re.search(r'shape\s*=\s*SubResource\("([^"]+)"\)', body)
            nodes.append({
                "name": attrs.get("name"), "type": attrs.get("type"),
                "parent": attrs.get("parent"),
                "instance": inst.group(1) if inst else None,
                "position": gv2("position") or (0.0, 0.0),
                "scale": gv2("scale"),
                "rotation": gfloat("rotation"),
                "texture": tex.group(1) if tex else None,
                "region": grect("region_rect") if "region_enabled = true" in body else None,
                "shape": shp.group(1) if shp else None,
            })
    return ext, sub, nodes

def global_pos(node, by_path):
    """Suma posiciones de los padres."""
    x, y = node["position"]
    parent = node["parent"]
    while parent and parent != ".":
        pn = by_path.get(parent)
        if not pn:
            break
        x += pn["position"][0]
        y += pn["position"][1]
        parent = pn["parent"]
    return x, y

def load_sprite_img(tex_path, scale, region):
    img = Image.open(res_path(tex_path)).convert("RGBA")
    if region:
        x, y, w, h = region
        img = img.crop((int(x), int(y), int(x + w), int(y + h)))
    sx, sy = scale
    nw, nh = max(1, int(round(img.width * abs(sx)))), max(1, int(round(img.height * abs(sy))))
    img = img.resize((nw, nh), Image.NEAREST)
    if sx < 0: img = img.transpose(Image.FLIP_LEFT_RIGHT)
    if sy < 0: img = img.transpose(Image.FLIP_TOP_BOTTOM)
    return img

def resolve_instance(ext_path):
    """Carga una item-scene; devuelve (tex_path, scale, region, sprite_offset)."""
    p = res_path(ext_path)
    e2, s2, n2 = parse_tscn(p)
    spr = next((n for n in n2 if n["type"] == "Sprite2D"), None)
    if not spr or not spr["texture"]:
        return None
    tex = e2[spr["texture"]]["path"]
    scale = spr["scale"] or (1.0, 1.0)
    return tex, scale, spr["region"], spr["position"]

def paste_centered(canvas, img, wx, wy):
    px, py = w2p(wx, wy)
    canvas.alpha_composite(img, (px - img.width // 2, py - img.height // 2))

def render(tscn):
    ext, sub, nodes = parse_tscn(tscn)
    by_path = {}
    for n in nodes:
        if not n["parent"] or n["parent"] == ".":
            path = n["name"]
        else:
            path = n["parent"] + "/" + n["name"]
        by_path[path] = n

    canvas = Image.new("RGBA", (VIEW_W, VIEW_H), (20, 20, 24, 255))

    # fondo (primer Sprite2D hijo del root, normalmente "BG")
    bg = next((n for n in nodes if n["type"] == "Sprite2D" and n["texture"] and n["parent"] == "."), None)
    if bg:
        img = load_sprite_img(ext[bg["texture"]]["path"], bg["scale"] or (1, 1), bg["region"])
        paste_centered(canvas, img, *bg["position"])

    overlay = Image.new("RGBA", (VIEW_W, VIEW_H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)

    # props
    for n in nodes:
        if n is bg:
            continue
        gx, gy = global_pos(n, by_path)
        if n["instance"]:
            info = resolve_instance(ext[n["instance"]]["path"])
            if info:
                tex, scale, region, soff = info
                if n["scale"]:
                    scale = (scale[0] * n["scale"][0], scale[1] * n["scale"][1])
                img = load_sprite_img(tex, scale, region)
                paste_centered(canvas, img, gx + soff[0], gy + soff[1])
        elif n["type"] == "Sprite2D" and n["texture"]:
            img = load_sprite_img(ext[n["texture"]]["path"], n["scale"] or (1, 1), n["region"])
            if n.get("rotation"):
                import math as _m
                img = img.rotate(-_m.degrees(n["rotation"]), expand=True, resample=Image.NEAREST)
            paste_centered(canvas, img, gx, gy)

    # colisiones
    for n in nodes:
        if n["type"] == "CollisionShape2D" and n["shape"]:
            sh = sub.get(n["shape"])
            if not sh or not sh["size"]:
                continue
            gx, gy = global_pos(n, by_path)
            w, h = sh["size"]
            p0 = w2p(gx - w / 2, gy - h / 2)
            p1 = w2p(gx + w / 2, gy + h / 2)
            od.rectangle([p0, p1], outline=(255, 40, 40, 255), width=2,
                         fill=(255, 40, 40, 45))

    # spawns
    for n in nodes:
        if n["type"] != "Marker2D":
            continue
        gx, gy = global_pos(n, by_path)
        px, py = w2p(gx, gy)
        is_player = (n["parent"] or "").startswith("PlayerSpawns")
        col = (60, 230, 90, 255) if is_player else (255, 220, 40, 255)
        r = 9 if is_player else 6
        od.ellipse([px - r, py - r, px + r, py + r], fill=col, outline=(0, 0, 0, 255))
        od.text((px + r, py - r), n["name"], fill=col)

    canvas.alpha_composite(overlay)
    # marco del area jugable (paredes)
    d2 = ImageDraw.Draw(canvas)
    d2.rectangle([w2p(-640, -360), w2p(640, 360)], outline=(120, 160, 255, 160), width=1)
    return canvas.convert("RGB")

if __name__ == "__main__":
    tscn = sys.argv[1] if len(sys.argv) > 1 else "scenes/maps/arena_fabrica.tscn"
    if not os.path.isabs(tscn):
        tscn = os.path.join(ROOT, tscn)
    out = sys.argv[2] if len(sys.argv) > 2 else "/tmp/zoom/preview.png"
    render(tscn).save(out)
    print("OK ->", out)
