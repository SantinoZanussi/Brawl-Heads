extends "res://scripts/weapons/weapon_base.gd"

const BULLET_SCENE = preload("res://scenes/weapons/bullet.tscn")

# Stats del AK
const FIRE_RATE   := 0.1   # segundos entre balas
const RECOIL      := 180.0 # impulso hacia atrás al disparar

var can_shoot: bool = true

func shoot():
	if not can_shoot:
		return
	
	can_shoot = false
	
	# Instanciar bala
	var bullet = BULLET_SCENE.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = global_position
	
	# Dirección según hacia donde mira el jugador
	var dir = Vector2(owner_player.facing, 0)
	bullet.direction = dir
	bullet.owner_player_index = owner_player.player_index
	
	# Flip del sprite del arma según dirección
	sprite.flip_h = owner_player.facing == -1
	
	# Retroceso al jugador
	owner_player.velocity.x += -owner_player.facing * RECOIL
	
	# Timer para el fire rate
	await get_tree().create_timer(FIRE_RATE).timeout
	can_shoot = true
