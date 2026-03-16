extends Node2D

const PARTICLE_COLORS := [
	Color("#FFD700"), Color("#00F5FF"),
	Color("#AAFF00"), Color("#FF2D78"), Color("#FF6B35"),
	Color("#E63946"), Color("#F0EAD6"), Color("#FF6B35"),
	Color("#FFD700"), Color("#00F5FF")  # más peso a los principales
]

var particles: Array = []
const COUNT := 120  # muchas más

func _ready():
	z_index = 100
	for i in COUNT:
		particles.append(_new_particle(true))

func _new_particle(random_y: bool = false) -> Dictionary:
	return {
		"pos": Vector2(randf() * 1280, 800.0 if not random_y else randf() * 720),
		"vel": Vector2(randf_range(-30, 30), randf_range(-180, -80)),
		"size": randi_range(3, 9),
		"color": PARTICLE_COLORS[randi() % PARTICLE_COLORS.size()],
		"alpha": 0.0,
		"life": randf() if random_y else 0.0,
		"duration": randf_range(3.0, 6.0),
		"glow": randf_range(0.7, 1.0)  # brillo variable
	}

func _process(delta: float):
	for i in particles.size():
		var p = particles[i]
		p["life"] += delta
		if p["life"] > p["duration"] or p["pos"].y < -20:
			particles[i] = _new_particle()
			continue
		var t: float = p["life"] / p["duration"]
		p["alpha"] = sin(t * PI) * p["glow"]
		p["pos"] += p["vel"] * delta
	queue_redraw()

func _draw():
	for p in particles:
		var c: Color = p["color"]
		c.a = p["alpha"] * 0.4  # era 1.0, ahora más sutil
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"], Vector2(s, s)), c)
