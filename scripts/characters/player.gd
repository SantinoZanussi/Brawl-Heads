extends CharacterBody2D

# ─── Constantes de movimiento ───────────────────────────────
const SPEED          := 320.0
const ACCELERATION   := 3000.0
const FRICTION       := 2500.0
const JUMP_FORCE     := -560.0
const GRAVITY        := 1800.0
const FALL_GRAVITY   := 2800.0  # más pesado al caer = feel de Duck Game
const MAX_FALL_SPEED := 900.0

# ─── Variables de estado ─────────────────────────────────────
var player_index: int = 0       # 0,1,2,3 → determina qué input leer
var is_dead: bool = false
var is_crouching: bool = false
var facing: int = 1             # 1 = derecha, -1 = izquierda
var held_weapon = null

# ─── Referencias a nodos ─────────────────────────────────────
@onready var sprite          = $Sprite2D
@onready var stand_collision = $PlayerCollision
@onready var crouch_collision= $CrouchCollision
@onready var gun_point       = $GunPoint

# ─────────────────────────────────────────────────────────────
func _ready():
	#crouch_collision.disabled = true
	pass

func _physics_process(delta: float):
	if is_dead:
		return
	
	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_jump()
	_handle_crouch()
	_update_facing()
	
	move_and_slide()

# ─── Gravedad ────────────────────────────────────────────────
func _apply_gravity(delta: float):
	if not is_on_floor():
		# Caída más pesada que la subida
		var grav = FALL_GRAVITY if velocity.y > 0 else GRAVITY
		velocity.y += grav * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

# ─── Movimiento horizontal ───────────────────────────────────
func _handle_movement(delta: float):
	var dir := _get_axis("left", "right")
	
	if dir != 0:
		velocity.x = move_toward(velocity.x, dir * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

# ─── Salto ───────────────────────────────────────────────────
func _handle_jump():
	if _just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE

# ─── Agacharse ───────────────────────────────────────────────
func _handle_crouch():
	var want_crouch := _is_pressed("duck")
	
	if want_crouch and not is_crouching and is_on_floor():
		is_crouching = true
		var shape = stand_collision.shape as RectangleShape2D
		shape.size = Vector2(20, 16)
		stand_collision.position.y = 6
	elif not want_crouch and is_crouching:
		is_crouching = false
		var shape = stand_collision.shape as RectangleShape2D
		shape.size = Vector2(20, 28)
		stand_collision.position.y = 0
	#var want_crouch := _is_pressed("duck")
	#
	#if want_crouch and not is_crouching and is_on_floor():
		#is_crouching = true
		#stand_collision.disabled = true
		#crouch_collision.disabled = false
	#elif not want_crouch and is_crouching:
		#is_crouching = false
		#stand_collision.disabled = false
		#crouch_collision.disabled = true
	

# ─── Dirección que mira ──────────────────────────────────────
func _update_facing():
	var dir := _get_axis("left", "right")
	if dir != 0:
		facing = int(dir)
		sprite.flip_h = facing == -1

# ─── Muerte / Ragdoll ────────────────────────────────────────
func die(impulse: Vector2):
	if is_dead:
		return
	is_dead = true
	
	# Deshabilitar física del personaje
	set_physics_process(false)
	stand_collision.disabled  = true
	crouch_collision.disabled = true
	
	# Lanzar sprite como rigidbody (ragdoll simple)
	var ragdoll = RigidBody2D.new()
	var shape   = CollisionShape2D.new()
	var spr     = sprite.duplicate()
	
	shape.shape  = stand_collision.shape
	ragdoll.add_child(shape)
	ragdoll.add_child(spr)
	ragdoll.gravity_scale = 2.0
	ragdoll.global_position = global_position
	
	get_parent().add_child(ragdoll)
	ragdoll.apply_central_impulse(impulse)
	
	# Ocultar el pato original
	visible = false
	
	# Avisar al GameManager
	GameManager.on_player_died(player_index)

# ─── Helpers de input (lee según player_index) ───────────────
func _get_axis(neg: String, pos: String) -> float:
	return Input.get_axis("p%d_%s" % [player_index + 1, neg],
						   "p%d_%s" % [player_index + 1, pos])

func _just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed("p%d_%s" % [player_index + 1, action])

func _is_pressed(action: String) -> bool:
	return Input.is_action_pressed("p%d_%s" % [player_index + 1, action])
