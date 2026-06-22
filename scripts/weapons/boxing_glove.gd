extends "res://scripts/weapons/weapon_base.gd"

# ─── Guante de boxeo ─────────────────────────────────────────
# Golpe cuerpo a cuerpo: poco daño pero muchísimo empuje. Ideal para
# mandar rivales al vacío estilo Duck Game. Sin munición.
const DAMAGE     := 18.0
const RANGE      := 40.0
const FIRE_RATE  := 0.45
const KNOCK_X    := 520.0
const KNOCK_Y    := -260.0

var can_punch: bool = true

func _ready():
	super._ready()
	max_ammo = 1
	current_ammo = 1

func shoot():
	if not can_punch or owner_player == null:
		return
	can_punch = false

	for p in get_tree().get_nodes_in_group("players"):
		if p == owner_player or p.is_dead:
			continue
		if p.global_position.distance_to(global_position) <= RANGE:
			p.take_damage(DAMAGE, Vector2(owner_player.facing * KNOCK_X, KNOCK_Y))

	await get_tree().create_timer(FIRE_RATE).timeout
	can_punch = true
