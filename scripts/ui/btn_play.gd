extends Button

var tween: Tween
var is_focused := false

func _ready():
	focus_entered.connect(func(): is_focused = true; _start_pulse())
	focus_exited.connect(func(): is_focused = false; _stop_pulse())
	mouse_entered.connect(func(): grab_focus())

func _start_pulse():
	if tween:
		tween.kill()
	tween = create_tween().set_loops()
	tween.tween_method(_set_glow, 1.0, 2.5, 0.4)
	tween.tween_method(_set_glow, 2.5, 1.0, 0.4)

func _stop_pulse():
	if tween:
		tween.kill()
	_set_glow(1.0)

func _set_glow(value: float):
	if material:
		material.set_shader_parameter("glow_intensity", value)
