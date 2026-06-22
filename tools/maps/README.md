# Herramientas de mapas (arenas) — Brawl Heads

Sin Godot a mano, estos scripts en Python+Pillow permiten generar e iterar la
estética de las 3 arenas viendo el resultado como PNG.

## Pipeline

1. `python3 tools/maps/gen_assets.py`
   Genera los assets pixel-art temáticos en `assets/items-map/generated/`
   (pisos físicos seamless por tema, plataformas en 4 anchos, decoraciones) y
   sus archivos `.import` de Godot con uid estable. Vuelca contact-sheets en
   `/tmp/zoom/` para revisarlos.

2. `python3 tools/maps/build_arenas.py`
   Reconstruye `scenes/maps/arena_fabrica.tscn`, `arena_templo.tscn` y
   `arena_arcade.tscn` desde cero (piso full-width, estructuras, decoración,
   spawns). **OJO:** sobrescribe esos .tscn — si editás un mapa a mano en Godot,
   esos cambios se pierden al re-correr este script.

3. `python3 tools/maps/preview_arena.py scenes/maps/arena_fabrica.tscn out.png`
   Compone un .tscn a PNG con los sprites reales + overlay de colisiones (rojo),
   spawns de jugadores (verde) y de armas (amarillo). Para iterar sin abrir Godot.

Al abrir el proyecto en Godot, los PNG nuevos se importan automáticamente
(genera los `.ctex`), conservando los uid de los `.import`.
