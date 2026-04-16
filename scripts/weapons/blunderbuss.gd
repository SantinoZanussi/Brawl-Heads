extends "res://scripts/weapons/weapon_base.gd"

const BULLET_SCENE = preload("res://scenes/weapons/bullet_big.tscn")

const FIRE_RATE := 1.0
const RECOIL    := 800.0

var can_shoot: bool = true

func _ready():
	super._ready()
	max_ammo = 5
	current_ammo = 5
	reload_time = 3.5

func shoot():
	if not can_shoot or not try_shoot():
		return

	can_shoot = false

	var bullet = BULLET_SCENE.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position    = owner_player.gun_point.global_position
	bullet.direction          = Vector2(owner_player.facing, 0)
	bullet.owner_player_index = owner_player.player_index

	owner_player.velocity.x += -owner_player.facing * RECOIL

	await get_tree().create_timer(FIRE_RATE).timeout
	can_shoot = true
