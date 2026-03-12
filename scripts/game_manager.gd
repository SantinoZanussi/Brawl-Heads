extends Node

# ─── Configuración de partida ────────────────────────────────
var total_rounds: int = 5        # personalizable desde el menú
var current_round: int = 1
var num_players: int = 2         # personalizable desde el menú

# ─── Puntos por jugador [p1, p2, p3, p4] ────────────────────
var scores: Array[int] = [0, 0, 0, 0]

# ─── Estado de la ronda actual ───────────────────────────────
var players_alive: Array[int] = []   # índices de jugadores vivos
var round_in_progress: bool = false

# ─── Señales ─────────────────────────────────────────────────
signal round_ended(results: Dictionary)
signal game_ended(winner: int)
signal scores_updated(scores: Array)

# ─────────────────────────────────────────────────────────────
func start_game(p_players: int, p_rounds: int):
	num_players = p_players
	total_rounds = p_rounds
	scores = [0, 0, 0, 0]
	current_round = 1
	start_round()

func start_round():
	players_alive.clear()
	for i in num_players:
		players_alive.append(i)
	round_in_progress = true
	print("─── Ronda %d / %d ───" % [current_round, total_rounds])

func on_player_died(player_index: int):
	if not round_in_progress:
		return
	
	players_alive.erase(player_index)
	print("Jugador %d eliminado. Vivos: %s" % [player_index + 1, players_alive])
	
	# Verificar si la ronda terminó
	if players_alive.size() <= 1:
		_end_round()

func _end_round():
	round_in_progress = false
	
	# ─── Asignar puntos ──────────────────────────────────────
	# players_alive tiene al ganador (si quedó uno)
	# El orden de muerte determina el resto
	
	if num_players == 2:
		# Solo 2 jugadores: 1 punto al ganador
		if players_alive.size() == 1:
			scores[players_alive[0]] += 1
	else:
		# 3-4 jugadores: 3 al ganador, 2 al segundo, 1 al resto
		var points = [3, 2, 1, 1]
		if players_alive.size() == 1:
			scores[players_alive[0]] += points[0]
	
	emit_signal("scores_updated", scores)
	print("Puntos: ", scores)
	
	# Esperar 2 segundos y continuar
	await get_tree().create_timer(2.0).timeout
	
	if current_round >= total_rounds:
		_end_game()
	else:
		current_round += 1
		# Aquí después recargaremos la escena del nivel
		start_round()

func _end_game():
	# Encontrar al ganador (mayor puntaje)
	var winner = 0
	for i in num_players:
		if scores[i] > scores[winner]:
			winner = i
	
	print("¡Juego terminado! Ganador: Jugador %d con %d puntos" % [winner + 1, scores[winner]])
	emit_signal("game_ended", winner)

func get_scores() -> Array:
	return scores.slice(0, num_players)
