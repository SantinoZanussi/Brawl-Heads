extends "res://scripts/weapons/weapon_base.gd"

# ─── Bazooka ─────────────────────────────────────────────────
# Cohete lento y demoledor: poca munición, mucho retroceso y daño alto.
const BULLET_SCENE = preload("res://scenes/weapons/bullet_big.tscn")

const FIRE_RATE := 1.2
const RECOIL    := 650.0
const DAMAGE    := 65.0
const BULLET_SPEED := 800.0

var can_shoot: bool = true

func _ready():
	super._ready()
	max_ammo = 3
	current_ammo = 3
	reload_time = 4.0

func shoot():
	if not can_shoot or not try_shoot():
		return

	can_shoot = false

	var bullet = BULLET_SCENE.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position    = owner_player.gun_point.global_position
	bullet.direction          = Vector2(owner_player.facing, 0)
	bullet.owner_player_index = owner_player.player_index
	bullet.damage             = DAMAGE
	bullet.speed              = BULLET_SPEED

	owner_player.velocity.x += -owner_player.facing * RECOIL
	owner_player.velocity.y -= 120.0  # patada hacia arriba estilo Duck Game

	await get_tree().create_timer(FIRE_RATE).timeout
	can_shoot = true
