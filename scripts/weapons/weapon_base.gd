extends RigidBody2D

@onready var sprite      = $Sprite2D
@onready var pickup_area = $Area2D
@onready var reload_bar = $ReloadBar

var is_held: bool = false
var owner_player = null
var nearby_player = null

var max_ammo    : int   = 10
var current_ammo: int   = 10
var reload_time : float = 1.5
var is_reloading: bool  = false

func _ready():
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)
	gravity_scale = 2.5
	linear_damp   = 0.5
	angular_damp  = 1.5
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce   = 0.3
	physics_material_override.friction = 0.8
	
	if reload_bar:
		reload_bar.max_value = 1.0
		reload_bar.value     = 1.0
		reload_bar.visible   = false

func try_shoot() -> bool:
	if is_reloading or current_ammo <= 0:
		return false
	current_ammo -= 1
	if current_ammo == 0:
		start_reload()
	return true

func start_reload():
	if is_reloading:
		return
	is_reloading = true
	if reload_bar:
		reload_bar.visible = true
	_reload_progress(0.0)

func _reload_progress(elapsed: float):
	if not is_reloading:
		return
	var t = elapsed / reload_time
	if reload_bar:
		reload_bar.value = t
	if t >= 1.0:
		current_ammo = max_ammo
		is_reloading = false
		if reload_bar:
			reload_bar.visible = false
		return
	get_tree().create_timer(0.05).timeout.connect(func(): _reload_progress(elapsed + 0.05))

func _on_body_entered(body):
	if body.has_method("pick_up_weapon") and not is_held:
		nearby_player = body

func _on_body_exited(body):
	if body == nearby_player:
		nearby_player = null

func on_picked_up(player):
	owner_player = player
	is_held      = true
	freeze       = true
	scale        = Vector2.ONE   # ← resetea cualquier scale roto
	collision_layer = 0
	collision_mask  = 0
	#visible = false

func on_dropped(impulse: Vector2):
	owner_player = null
	is_held      = false
	freeze       = false
	#scale        = Vector2.ONE   # ← por las dudas
	gravity_scale = 2.5
	linear_damp   = 0.5
	angular_damp  = 1.5
	collision_layer = 1
	collision_mask  = 1
	apply_torque_impulse(randf_range(-80.0, 80.0))
	#apply_central_impulse(impulse)
	call_deferred("apply_central_impulse", impulse)

func _physics_process(delta):
	if is_held and owner_player != null:
		var flipped = owner_player.facing == -1
		sprite.flip_h = flipped
		sprite.offset.x = -16 if flipped else 0

func shoot():
	pass
