extends "res://scripts/weapons/weapon_base.gd"

# ─── Escopeta de combate ─────────────────────────────────────
# Dispara un abanico de perdigones con fuerte retroceso a corta distancia.
const BULLET_SCENE = preload("res://scenes/weapons/bullet.tscn")

const FIRE_RATE   := 0.7
const RECOIL      := 360.0
const PELLETS     := 5
const SPREAD_DEG  := 22.0   # apertura total del abanico
const PELLET_DMG  := 12.0
const PELLET_SPEED := 1000.0

var can_shoot: bool = true

func _ready():
	super._ready()
	max_ammo = 6
	current_ammo = 6
	reload_time = 1.8

func shoot():
	if not can_shoot or not try_shoot():
		return

	can_shoot = false

	var base_dir := Vector2(owner_player.facing, 0)
	for i in PELLETS:
		var t: float = 0.0 if PELLETS == 1 else float(i) / float(PELLETS - 1)
		var angle := deg_to_rad(lerp(-SPREAD_DEG * 0.5, SPREAD_DEG * 0.5, t))

		var bullet = BULLET_SCENE.instantiate()
		get_tree().root.add_child(bullet)
		bullet.global_position    = owner_player.gun_point.global_position
		bullet.direction          = base_dir.rotated(angle)
		bullet.owner_player_index = owner_player.player_index
		bullet.damage             = PELLET_DMG
		bullet.speed              = PELLET_SPEED

	owner_player.velocity.x += -owner_player.facing * RECOIL

	await get_tree().create_timer(FIRE_RATE).timeout
	can_shoot = true
