extends RigidBody2D

@onready var sprite        = $Sprite2D
@onready var pickup_area   = $Area2D

var is_held: bool = false
var owner_player = null
var nearby_player = null   # ← jugador que está en rango

func _ready():
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("pick_up_weapon") and not is_held:
		nearby_player = body   # ← solo guarda referencia

func _on_body_exited(body):
	if body == nearby_player:
		nearby_player = null

func on_picked_up(player):
	owner_player = player
	is_held = true
	freeze = true
	collision_layer = 0
	collision_mask  = 0

func on_dropped(impulse: Vector2):
	owner_player = null
	is_held = false
	freeze = false
	collision_layer = 1
	collision_mask  = 1
	apply_central_impulse(impulse)

func shoot():
	pass
