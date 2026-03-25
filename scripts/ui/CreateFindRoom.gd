extends Control

@onready var player_list:   VBoxContainer = $Screen/Left/PlayerList
@onready var btn_ready:     Button        = $Screen/Left/BtnReady
@onready var btn_start:     Button        = $Screen/Left/BtnStart
@onready var btn_leave:     Button        = $Screen/Left/BtnLeave
@onready var lbl_room_name: Label         = $Screen/Left/LblRoomName

@onready var chat_log:      RichTextLabel = $Screen/Right/ChatLog
@onready var chat_input:    LineEdit      = $Screen/Right/ChatInput
@onready var btn_send:      Button        = $Screen/Right/BtnSend

var _my_ready: bool = false

func _ready() -> void:
	# Solo el host ve el botón de iniciar
	btn_start.visible = NetworkManager.is_host()
	btn_start.disabled = true

	lbl_room_name.text = NetworkManager.room_info.get("name", "Sala")

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.player_list_updated.connect(_refresh_player_list)

	btn_ready.pressed.connect(_on_ready_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_leave.pressed.connect(_on_leave_pressed)
	btn_send.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(func(_t): _on_send_pressed())

	_refresh_player_list()
	_log_chat("Sistema", "Bienvenido al lobby.")

# ── LISTA DE JUGADORES ────────────────────────────────────────

func _refresh_player_list() -> void:
	for child in player_list.get_children():
		child.queue_free()

	for id in NetworkManager.players:
		var data: Dictionary = NetworkManager.players[id]
		var is_me:   bool = id == multiplayer.get_unique_id()
		var is_host: bool = id == 1

		var row := HBoxContainer.new()

		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_str := "Jugador %d" % id
		if is_host:
			name_str += " [HOST]"
		if is_me:
			name_str += " (vos)"
		lbl.text = name_str

		var lbl_ready := Label.new()
		lbl_ready.text = "✓ Listo" if data.get("ready", false) else "✗ Esperando"
		lbl_ready.custom_minimum_size = Vector2(90, 0)

		row.add_child(lbl)
		row.add_child(lbl_ready)

		# Botón de kick — solo el host lo ve, no puede kickearse a sí mismo
		if NetworkManager.is_host() and not is_me:
			var btn_kick := Button.new()
			btn_kick.text = "Expulsar"
			btn_kick.custom_minimum_size = Vector2(80, 0)
			btn_kick.pressed.connect(_on_kick_pressed.bind(id))
			row.add_child(btn_kick)

		player_list.add_child(row)

	# Habilitar inicio si todos listos (y hay más de 1 jugador)
	if NetworkManager.is_host():
		btn_start.disabled = not NetworkManager.all_players_ready() \
			or NetworkManager.get_player_count() < 2

func _on_player_connected(id: int) -> void:
	_refresh_player_list()
	_log_chat("Sistema", "Jugador %d se unió." % id)

func _on_player_disconnected(id: int) -> void:
	_refresh_player_list()
	_log_chat("Sistema", "Jugador %d se fue." % id)

# ── LISTO ─────────────────────────────────────────────────────

func _on_ready_pressed() -> void:
	_my_ready = not _my_ready
	btn_ready.text = "Cancelar listo" if _my_ready else "Listo"
	_rpc_set_ready.rpc(multiplayer.get_unique_id(), _my_ready)

@rpc("any_peer", "reliable")
func _rpc_set_ready(id: int, ready: bool) -> void:
	NetworkManager.set_player_ready(id, ready)

# ── KICK ──────────────────────────────────────────────────────

func _on_kick_pressed(peer_id: int) -> void:
	_rpc_kick.rpc_id(peer_id)
	NetworkManager.multiplayer.multiplayer_peer.disconnect_peer(peer_id)
	_log_chat("Sistema", "Jugador %d fue expulsado." % peer_id)

@rpc("authority", "reliable")
func _rpc_kick() -> void:
	# Llega al cliente expulsado
	NetworkManager.disconnect_room()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

# ── CHAT ──────────────────────────────────────────────────────

func _on_send_pressed() -> void:
	var text := chat_input.text.strip_edges()
	if text.is_empty():
		return
	chat_input.text = ""
	_rpc_chat.rpc(multiplayer.get_unique_id(), text)

@rpc("any_peer", "call_local", "reliable")
func _rpc_chat(sender_id: int, text: String) -> void:
	var name_str := "Host" if sender_id == 1 else "Jugador %d" % sender_id
	_log_chat(name_str, text)

func _log_chat(sender: String, text: String) -> void:
	chat_log.append_text("[b]%s:[/b] %s\n" % [sender, text])

# ── INICIAR / SALIR ───────────────────────────────────────────

func _on_start_pressed() -> void:
	_rpc_start_game.rpc()

@rpc("authority", "call_local", "reliable")
func _rpc_start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game/TestLevel.tscn")

func _on_leave_pressed() -> void:
	NetworkManager.disconnect_room()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
