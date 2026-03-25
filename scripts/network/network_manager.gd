extends Node

const DEFAULT_PORT := 7777
const MAX_PLAYERS  := 4
const BROADCAST_PORT := 7778

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed
signal server_found(info: Dictionary)

var players: Dictionary = {}   # peer_id → datos del jugador
var room_info: Dictionary = {} # info de la sala actual

var _broadcast_timer: SceneTreeTimer = null
var _udp_server: PacketPeerUDP = null
var _udp_client: PacketPeerUDP = null

# ── CREAR SALA ────────────────────────────────────────────────

func create_room(room_name: String, password: String, max_players: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(DEFAULT_PORT, max_players)
	if err != OK:
		push_error("No se pudo crear el servidor: %d" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	room_info = {
		"name":        room_name,
		"password":    password,
		"max_players": max_players,
		"host":        IP.get_local_addresses()[0],
	}

	players[1] = { "id": 1, "ready": false }
	_start_broadcasting()

# ── UNIRSE A SALA ─────────────────────────────────────────────

func join_room(ip: String, password: String) -> void:
	if password != room_info.get("password", ""):
		push_warning("Contraseña incorrecta")
		return

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, DEFAULT_PORT)
	if err != OK:
		push_error("No se pudo conectar: %d" % err)
		connection_failed.emit()
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func disconnect_room() -> void:
	_stop_broadcasting()
	_stop_discovery()
	multiplayer.multiplayer_peer = null
	players.clear()
	room_info.clear()

# ── BROADCAST LAN (descubrimiento) ───────────────────────────

func _start_broadcasting() -> void:
	_udp_server = PacketPeerUDP.new()
	_udp_server.bind(BROADCAST_PORT)
	set_process(true)

func _stop_broadcasting() -> void:
	if _udp_server:
		_udp_server.close()
		_udp_server = null

func start_discovery() -> void:
	_udp_client = PacketPeerUDP.new()
	_udp_client.bind(BROADCAST_PORT + 1)
	set_process(true)
	# Enviar broadcast cada 2 segundos
	_send_discovery_ping()
	_broadcast_timer = get_tree().create_timer(2.0)
	_broadcast_timer.timeout.connect(start_discovery)

func _stop_discovery() -> void:
	if _udp_client:
		_udp_client.close()
		_udp_client = null

func _send_discovery_ping() -> void:
	var ping := PacketPeerUDP.new()
	ping.set_broadcast_enabled(true)
	ping.set_dest_address("255.255.255.255", BROADCAST_PORT)
	ping.put_packet("BRAWL_HEADS_DISCOVER".to_utf8_buffer())
	ping.close()

func _process(_delta: float) -> void:
	# Servidor responde a pings
	if _udp_server and _udp_server.get_available_packet_count() > 0:
		var _data := _udp_server.get_packet()
		var sender_ip := _udp_server.get_packet_ip()
		var response := JSON.stringify(room_info)
		var reply := PacketPeerUDP.new()
		reply.set_dest_address(sender_ip, BROADCAST_PORT + 1)
		reply.put_packet(response.to_utf8_buffer())
		reply.close()

	# Cliente recibe respuestas
	if _udp_client and _udp_client.get_available_packet_count() > 0:
		var data := _udp_client.get_packet().get_string_from_utf8()
		var info: Dictionary = JSON.parse_string(data)
		if info and not _room_already_listed(info):
			server_found.emit(info)

func _room_already_listed(info: Dictionary) -> bool:
	# Evita duplicados — lo manejás en el menú con un dict por IP
	return false  # el menú lleva el control

# ── CALLBACKS MULTIPLAYER ────────────────────────────────────

func _on_peer_connected(id: int) -> void:
	players[id] = { "id": id, "ready": false }
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	var my_id := multiplayer.get_unique_id()
	players[my_id] = { "id": my_id, "ready": false }
	player_connected.emit(my_id)

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

signal player_list_updated
signal chat_message_received(sender_id: int, text: String)

func get_player_count() -> int:
	return players.size()

func is_host() -> bool:
	return multiplayer.is_server()

func set_player_ready(id: int, ready: bool) -> void:
	if players.has(id):
		players[id]["ready"] = ready
		player_list_updated.emit()

func all_players_ready() -> bool:
	for id in players:
		if not players[id].get("ready", false):
			return false
	return true
