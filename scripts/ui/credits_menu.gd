extends Control

# ─── Paleta ──────────────────────────────────────────────────
const C_VOID        := Color("#0D0D0D")
const C_NAVY        := Color("#1A1A2E")
const C_SLATE       := Color("#16213E")
const C_YELLOW      := Color("#FFD700")
const C_CYAN        := Color("#00F5FF")
const C_WHITE       := Color("#F0EAD6")
const C_GRAY        := Color("#8B8FA8")
const C_STEEL       := Color("#2E2E3A")
const C_LIME        := Color("#AAFF00")
const C_MAGENTA     := Color("#FF2D78")
const C_ORANGE      := Color("#FF6B35")

# ─── Nodos UI ────────────────────────────────────────────────
@onready var btn_back     = $Screen/MarginContainer/VBoxContainer/Buttons/BtnBack
@onready var title_label  = $Screen/MarginContainer/VBoxContainer/TitleArea/Title
@onready var screen       = $Screen

# ─── Glow del título ─────────────────────────────────────────
var glow_time: float = 0.0

# ─── Scanlines ───────────────────────────────────────────────
var scanline_canvas: ColorRect

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	
	_setup_scanlines()
	
	move_child(scanline_canvas, get_child_count() - 1)

# ─── Loop principal ──────────────────────────────────────────
func _process(delta: float):
	_update_title_glow(delta)
	queue_redraw()

# ─── Glow del título ─────────────────────────────────────────
func _update_title_glow(delta: float):
	glow_time += delta
	var glow_alpha := (sin(glow_time * 1.5) + 1.0) / 2.0
	var base_color := C_YELLOW
	base_color.a = 0.6 + glow_alpha * 0.4
	title_label.add_theme_color_override("font_color", base_color)

func _setup_scanlines():
	scanline_canvas = ColorRect.new()
	scanline_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanline_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanline_canvas.z_index = 100
	# Shader de scanlines
	var shader_mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float line = mod(FRAGCOORD.y, 4.0);
	float alpha = line < 2.0 ? 0.0 : 0.12;
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""
	shader_mat.shader = shader
	scanline_canvas.material = shader_mat
	add_child(scanline_canvas)

# ─── Hover de botones con efecto cyan ────────────────────────
func _setup_button_hover():
	var buttons = [btn_back]
	for btn in buttons:
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))

func _on_btn_hover(btn: Button):
	var mat := btn.material as ShaderMaterial
	if mat:
		var tween := create_tween()
		tween.tween_method(
			func(v): mat.set_shader_parameter("glow_intensity", v),
			1.0, 2.5, 0.08
		)
		tween.parallel().tween_method(
			func(v): mat.set_shader_parameter("glow_color", v),
			Color("#FFD700"), Color("#00F5FF"), 0.08
		)
	btn.modulate = Color("#00F5FF")

func _on_btn_unhover(btn: Button):
	var mat := btn.material as ShaderMaterial
	if mat:
		var tween := create_tween()
		tween.tween_method(
			func(v): mat.set_shader_parameter("glow_intensity", v),
			2.5, 1.0, 0.08
		)
		tween.parallel().tween_method(
			func(v): mat.set_shader_parameter("glow_color", v),
			Color("#00F5FF"), Color("#FFD700"), 0.08
		)
	btn.modulate = Color("#F0EAD6")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
