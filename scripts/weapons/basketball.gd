extends "res://scripts/weapons/weapon_base.gd"

const FIRE_RATE  := 1.0
const KILL_SPEED := 150.0

var can_shoot: bool = true
var is_launched: bool = false
var launcher_index: int = -1

func shoot():
	if not can_shoot or is_launched:
		return
	can_shoot   = false
	is_launched = true
	launcher_index = owner_player.player_index

	owner_player.drop_weapon()

	await get_tree().process_frame

	linear_velocity = Vector2.ZERO
	apply_central_impulse(Vector2(0, -900))

	if not body_entered.is_connected(_on_hit):
		body_entered.connect(_on_hit)

func _on_hit(body):
	if not is_launched:
		return

	# Mata si cae con suficiente velocidad
	if body.has_method("die") and body.get("player_index") != launcher_index:
		if linear_velocity.y >= KILL_SPEED:
			body.die()

	# Tocó algo (suelo, pared, jugador) → resetea todo para poder volver a usar
	is_launched = false
	can_shoot   = true   # ← este era el fix que faltaba
	if body_entered.is_connected(_on_hit):
		body_entered.disconnect(_on_hit)
