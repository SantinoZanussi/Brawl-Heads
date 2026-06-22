extends "res://scripts/weapons/weapon_base.gd"

# ─── Motosierra ──────────────────────────────────────────────
# Arma cuerpo a cuerpo: mientras se mantiene el disparo, hace daño
# continuo a cualquier jugador cercano. Sin munición.
const TICK_DAMAGE := 9.0
const RANGE       := 48.0
const TICK_RATE   := 0.12

var can_hit: bool = true

func _ready():
	super._ready()
	max_ammo = 1
	current_ammo = 1

func shoot():
	if not can_hit or owner_player == null:
		return
	can_hit = false

	for p in get_tree().get_nodes_in_group("players"):
		if p == owner_player or p.is_dead:
			continue
		if p.global_position.distance_to(global_position) <= RANGE:
			var knock := Vector2(owner_player.facing * 220.0, -140.0)
			p.take_damage(TICK_DAMAGE, knock)

	await get_tree().create_timer(TICK_RATE).timeout
	can_hit = true
