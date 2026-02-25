extends Node

# Network Manager Singleton
# Handles multiplayer connectivity and game synchronization

signal connected_to_server()
signal connection_failed()
signal player_joined(player_id: int, player_name: String)
signal player_left(player_id: int)
signal game_state_received(state: Dictionary)
signal chat_message_received(player_id: int, message: String)
signal game_invite_received(inviter_id: int, game_id: String)

enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	IN_GAME
}

# Network configuration
var server_url: String = "ws://your-vps-ip:8080"  # Update with your VPS IP
var reconnect_attempts: int = 0
var max_reconnect_attempts: int = 5
var reconnect_delay: float = 2.0

# Connection state
var connection_state: ConnectionState = ConnectionState.DISCONNECTED
var websocket: WebSocketPeer
var player_id: int = -1
var player_name: String = ""
var room_id: String = ""
var game_id: String = ""

# Game state cache
var remote_players: Dictionary = {}
var remote_game_state: Dictionary = {}

func _ready():
	# Initialize WebSocket
	websocket = WebSocketPeer.new()
	
	# Load player name from settings
	var settings = _load_settings()
	player_name = settings.get("player_name", "Player_" + str(randi() % 1000))

func _process(delta):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.poll()
		var state = websocket.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while websocket.get_available_packet_count():
				_handle_message(websocket.get_packet())
		elif state == WebSocketPeer.STATE_CLOSING:
			# Wait for close
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			var code = websocket.get_close_code()
			var reason = websocket.get_close_reason()
			print("WebSocket closed with code: %d, reason: %s" % [code, reason])
			connection_state = ConnectionState.DISCONNECTED
			_attempt_reconnect()

# Connection management
func connect_to_server():
	if connection_state != ConnectionState.DISCONNECTED:
		print("Already connected or connecting")
		return false
	
	print("Connecting to server: ", server_url)
	connection_state = ConnectionState.CONNECTING
	
	var err = websocket.connect_to_url(server_url)
	if err != OK:
		print("Failed to connect: ", err)
		connection_failed.emit()
		connection_state = ConnectionState.DISCONNECTED
		return false
	
	return true

func disconnect_from_server():
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.close()
	connection_state = ConnectionState.DISCONNECTED
	player_id = -1
	room_id = ""
	game_id = ""
	remote_players.clear()
	print("Disconnected from server")

func _attempt_reconnect():
	if reconnect_attempts >= max_reconnect_attempts:
		print("Max reconnection attempts reached")
		connection_failed.emit()
		return
	
	reconnect_attempts += 1
	print("Attempting reconnect (", reconnect_attempts, "/", max_reconnect_attempts, ")")
	
	await get_tree().create_timer(reconnect_delay).timeout
	
	if connection_state == ConnectionState.DISCONNECTED:
		connect_to_server()

# Message handling
func _handle_message(message: PackedByteArray):
	var json = JSON.new()
	var error = json.parse(message.get_string_from_utf8())
	
	if error != OK:
		print("Failed to parse message: ", error)
		return
	
	var data = json.get_data()
	var message_type = data.get("type", "")
	
	match message_type:
		"connection_established":
			_handle_connection_established(data)
		"player_joined":
			_handle_player_joined(data)
		"player_left":
			_handle_player_left(data)
		"game_state":
			_handle_game_state(data)
		"chat_message":
			_handle_chat_message(data)
		"game_invite":
			_handle_game_invite(data)
		"error":
			_handle_error(data)
		_:
			print("Unknown message type: ", message_type)

func _handle_connection_established(data: Dictionary):
	player_id = data.get("player_id", -1)
	connection_state = ConnectionState.CONNECTED
	reconnect_attempts = 0
	
	print("Connected to server. Player ID: ", player_id)
	connected_to_server.emit()
	
	# Send player info
	send_player_info()

func _handle_player_joined(data: Dictionary):
	var joined_player_id = data.get("player_id", -1)
	var joined_player_name = data.get("player_name", "")
	
	if joined_player_id != player_id:  # Don't add ourselves
		remote_players[joined_player_id] = {
			"name": joined_player_name,
			"ready": false
		}
		player_joined.emit(joined_player_id, joined_player_name)
		print("Player joined: ", joined_player_name, " (ID: ", joined_player_id, ")")

func _handle_player_left(data: Dictionary):
	var left_player_id = data.get("player_id", -1)
	
	if remote_players.has(left_player_id):
		var player_name = remote_players[left_player_id].name
		remote_players.erase(left_player_id)
		player_left.emit(left_player_id)
		print("Player left: ", player_name, " (ID: ", left_player_id, ")")

func _handle_game_state(data: Dictionary):
	remote_game_state = data.get("state", {})
	game_state_received.emit(remote_game_state)
	
	# Update local game manager if in game
	if connection_state == ConnectionState.IN_GAME:
		GameManager.load_remote_state(remote_game_state)

func _handle_chat_message(data: Dictionary):
	var sender_id = data.get("player_id", -1)
	var message = data.get("message", "")
	
	chat_message_received.emit(sender_id, message)
	
	# Show in-game chat if available
	if UIManager:
		UIManager.show_chat_message(sender_id, message)

func _handle_game_invite(data: Dictionary):
	var inviter_id = data.get("inviter_id", -1)
	var invite_game_id = data.get("game_id", "")
	
	game_invite_received.emit(inviter_id, invite_game_id)
	print("Game invite received from player ", inviter_id)

func _handle_error(data: Dictionary):
	var error_code = data.get("code", 0)
	var error_message = data.get("message", "Unknown error")
	
	print("Server error: ", error_message, " (code: ", error_code, ")")
	
	# Handle specific errors
	match error_code:
		1:  # Room full
			UIManager.show_error("Room is full")
		2:  # Game already started
			UIManager.show_error("Game has already started")
		3:  # Invalid action
			UIManager.show_error("Invalid action")

# Sending messages
func send_player_info():
	var message = {
		"type": "player_info",
		"player_id": player_id,
		"player_name": player_name,
		"version": GameManager.game_version
	}
	_send_message(message)

func join_room(target_room_id: String):
	room_id = target_room_id
	var message = {
		"type": "join_room",
		"player_id": player_id,
		"room_id": room_id
	}
	_send_message(message)

func create_room(room_name: String, max_players: int = 6, password: String = ""):
	var message = {
		"type": "create_room",
		"player_id": player_id,
		"room_name": room_name,
		"max_players": max_players,
		"password": password
	}
	_send_message(message)

func leave_room():
	var message = {
		"type": "leave_room",
		"player_id": player_id,
		"room_id": room_id
	}
	_send_message(message)
	room_id = ""

func set_player_ready(is_ready: bool):
	var message = {
		"type": "player_ready",
		"player_id": player_id,
		"room_id": room_id,
		"ready": is_ready
	}
	_send_message(message)

func start_game():
	var message = {
		"type": "start_game",
		"player_id": player_id,
		"room_id": room_id
	}
	_send_message(message)
	connection_state = ConnectionState.IN_GAME

func send_game_action(action: String, data: Dictionary = {}):
	var message = {
		"type": "game_action",
		"player_id": player_id,
		"game_id": game_id,
		"action": action,
		"data": data,
		"timestamp": Time.get_unix_time_from_system()
	}
	_send_message(message)

func send_chat_message(message_text: String):
	var message = {
		"type": "chat_message",
		"player_id": player_id,
		"room_id": room_id,
		"message": message_text
	}
	_send_message(message)

func send_game_invite(target_player_id: int):
	var message = {
		"type": "game_invite",
		"from_player_id": player_id,
		"to_player_id": target_player_id,
		"game_id": game_id if game_id else "new_game"
	}
	_send_message(message)

func _send_message(data: Dictionary):
	if websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("Cannot send message: WebSocket not open")
		return
	
	var json = JSON.stringify(data)
	websocket.send_text(json)

# Game action helpers
func send_roll_dice():
	send_game_action("roll_dice")

func send_move_player(steps: int):
	send_game_action("move_player", {"steps": steps})

func send_purchase_property(property_id: String):
	send_game_action("purchase_property", {"property_id": property_id})

func send_end_turn():
	send_game_action("end_turn")

func send_trade_request(to_player_id: int, offer: Dictionary, request: Dictionary):
	send_game_action("trade_request", {
		"to_player_id": to_player_id,
		"offer": offer,
		"request": request
	})

# Room management
func get_room_players() -> Dictionary:
	return remote_players.duplicate()

func get_player_info(player_id: int) -> Dictionary:
	return remote_players.get(player_id, {})

func is_player_ready(player_id: int) -> bool:
	var player_info = get_player_info(player_id)
	return player_info.get("ready", false) if player_info else false

func are_all_players_ready() -> bool:
	for player_info in remote_players.values():
		if not player_info.get("ready", false):
			return false
	return true

# Utility functions
func is_connected() -> bool:
	return connection_state == ConnectionState.CONNECTED or connection_state == ConnectionState.IN_GAME

func is_in_game() -> bool:
	return connection_state == ConnectionState.IN_GAME

func get_player_count_in_room() -> int:
	return remote_players.size() + 1  # +1 for ourselves

func _load_settings() -> Dictionary:
	var settings_file = FileAccess.open("user://settings.dat", FileAccess.READ)
	if settings_file:
		var settings = settings_file.get_var()
		settings_file.close()
		return settings if settings else {}
	return {}

func save_settings():
	var settings = {
		"player_name": player_name,
		"server_url": server_url
	}
	
	var settings_file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	if settings_file:
		settings_file.store_var(settings)
		settings_file.close()

# Cleanup
func _exit_tree():
	disconnect_from_server()