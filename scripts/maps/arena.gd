extends Node2D

# ─────────────────────────────────────────────────────────────
# Controlador genérico de arena.
#
# Espera dos nodos hijos:
#   • PlayerSpawns  → varios Marker2D, posibles puntos de aparición.
#   • WeaponSpawns  → varios Marker2D, donde cae un arma aleatoria.
#
# En cada partida los jugadores aparecen en spawns ALEATORIOS y cada
# punto de armas recibe un arma ALEATORIA de la lista.
#
# Multijugador (LAN): si hay una sesión de red activa, spawnea un
# personaje por peer y le asigna la autoridad de red correspondiente,
# así cada cliente controla solo el suyo. Offline (botón "JUGAR TEST")
# spawnea `offline_players` y solo el primero es controlable.
# ─────────────────────────────────────────────────────────────

const PLAYER_SCENE := preload("res://scenes/characters/player.tscn")

const WEAPON_SCENES: Array[PackedScene] = [
	preload("res://scenes/weapons/ak47.tscn"),
	preload("res://scenes/weapons/pistol.tscn"),
	preload("res://scenes/weapons/blunderbuss.tscn"),
	preload("res://scenes/weapons/minigun.tscn"),
	preload("res://scenes/weapons/basketball.tscn"),
	preload("res://scenes/weapons/bazooka.tscn"),
	preload("res://scenes/weapons/shotgun.tscn"),
	preload("res://scenes/weapons/chainsaw.tscn"),
	preload("res://scenes/weapons/boxing_glove.tscn"),
]

@export var rounds: int = 3
@export var player_scale: Vector2 = Vector2(2, 2)
@export var offline_players: int = 4   # personajes a spawnear sin red

@onready var player_spawns: Node = $PlayerSpawns
@onready var weapon_spawns: Node = $WeaponSpawns

func _ready() -> void:
	randomize()
	_spawn_weapons()
	var count := _spawn_players()
	GameManager.start_game(count, rounds)

func _is_online() -> bool:
	return multiplayer.has_multiplayer_peer() and NetworkManager.players.size() > 0

# ─── Jugadores ───────────────────────────────────────────────
func _spawn_players() -> int:
	var points := player_spawns.get_children()
	if points.is_empty():
		push_warning("Arena '%s' sin PlayerSpawns" % name)
		return 0
	points.shuffle()

	if _is_online():
		var ids := NetworkManager.players.keys()
		for i in ids.size():
			_make_player(i, ids[i], true, points[i % points.size()].global_position)
		return ids.size()

	var n: int = min(offline_players, points.size())
	for i in n:
		_make_player(i, 1, i == 0, points[i].global_position)
	return n

func _make_player(index: int, authority: int, can_control: bool, pos: Vector2) -> void:
	var p := PLAYER_SCENE.instantiate()
	p.player_index = index
	p.peer_id = authority
	p.controllable = can_control
	p.scale = player_scale
	p.set_multiplayer_authority(authority)
	add_child(p)
	p.global_position = pos

# ─── Armas ───────────────────────────────────────────────────
func _spawn_weapons() -> void:
	if weapon_spawns == null:
		return
	for spawn in weapon_spawns.get_children():
		var scene: PackedScene = WEAPON_SCENES.pick_random()
		var w = scene.instantiate()
		add_child(w)
		w.global_position = spawn.global_position
