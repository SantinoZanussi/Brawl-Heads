extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 1200.0
var damage: float = 20.0
var owner_player_index: int = -1  # Para no dañar al que disparó

func _physics_process(delta: float):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		# Evita dañar al jugador que disparó
		if body.get("player_index") == owner_player_index:
			return
		body.take_damage(damage, direction * 300)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()  # Se borra si sale de pantalla
