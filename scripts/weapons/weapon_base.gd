extends RigidBody2D

@onready var sprite      = $Sprite2D
@onready var pickup_area = $Area2D

var is_held: bool = false
var owner_player = null
var nearby_player = null

func _ready():
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)
	gravity_scale = 2.5
	linear_damp   = 0.5
	angular_damp  = 1.5
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce  = 0.3
	physics_material_override.friction = 0.8

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
