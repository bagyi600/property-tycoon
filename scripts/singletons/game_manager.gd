extends Node

# Game Manager Singleton
# Handles game state, saving, loading, and core game logic

signal game_state_changed(state: String)
signal player_turn_changed(player_id: int)
signal game_over(winner_id: int)
signal money_changed(player_id: int, amount: int)
signal property_purchased(player_id: int, property_id: String)

enum GameState {
	LOBBY,
	PLAYING,
	PAUSED,
	GAME_OVER
}

enum PlayerType {
	HUMAN,
	AI_EASY,
	AI_MEDIUM,
	AI_HARD
}

# Game configuration
var config = {
	"starting_money": 1500,
	"max_players": 6,
	"min_players": 2,
	"max_houses": 4,
	"hotel_price": 200,
	"jail_fine": 50,
	"income_tax": 200,
	"luxury_tax": 100,
	"salary": 200,
	"double_salary_on_go": false
}

# Game state
var game_state: GameState = GameState.LOBBY
var current_player_index: int = 0
var players: Array = []
var board: Dictionary = {}
var properties: Dictionary = {}
var chance_cards: Array = []
var community_chest_cards: Array = []
var game_id: String = ""
var is_online: bool = false
var game_version: String = "1.0.0"

# Player data structure
class PlayerData:
	var id: int
	var name: String
	var type: PlayerType
	var money: int
	var position: int
	var properties: Array = []
	var houses: Dictionary = {}
	var hotels: Dictionary = {}
	var in_jail: bool = false
	var jail_turns: int = 0
	var color: Color
	var token: String
	var is_bankrupt: bool = false
	
	func _init(player_id: int, player_name: String, player_type: PlayerType, player_color: Color, player_token: String):
		id = player_id
		name = player_name
		type = player_type
		money = 1500
		position = 0
		color = player_color
		token = player_token

# Initialize the game manager
func initialize():
	_load_config()
	_generate_board()
	_generate_cards()
	game_id = _generate_game_id()
	print("Game Manager initialized. Game ID: ", game_id)

func _load_config():
	# Load configuration from file or use defaults
	var config_file = FileAccess.open("res://config/game_config.json", FileAccess.READ)
	if config_file:
		var json = JSON.new()
		var error = json.parse(config_file.get_as_text())
		if error == OK:
			config = json.get_data()
		config_file.close()

func _generate_board():
	# Generate board spaces (40 spaces like Monopoly)
	board = {
		"0": {"name": "GO", "type": "special", "action": "collect_salary"},
		"1": {"name": "Mediterranean Avenue", "type": "property", "color": "brown", "price": 60, "rent": [2, 10, 30, 90, 160, 250], "house_cost": 50},
		"2": {"name": "Community Chest", "type": "special", "action": "draw_community_chest"},
		"3": {"name": "Baltic Avenue", "type": "property", "color": "brown", "price": 60, "rent": [4, 20, 60, 180, 320, 450], "house_cost": 50},
		# ... Add all 40 spaces
		"39": {"name": "Boardwalk", "type": "property", "color": "blue", "price": 400, "rent": [50, 200, 600, 1400, 1700, 2000], "house_cost": 200}
	}
	
	# Initialize properties
	for space_id in board:
		var space = board[space_id]
		if space.type == "property":
			properties[space_id] = {
				"owner": null,
				"mortgaged": false,
				"houses": 0,
				"hotel": false
			}

func _generate_cards():
	# Generate chance cards
	chance_cards = [
		{"text": "Advance to Go. Collect $200.", "action": "move_to", "target": 0, "money": 200},
		{"text": "Bank error in your favor. Collect $200.", "action": "add_money", "amount": 200},
		{"text": "Go to Jail. Go directly to Jail. Do not pass Go. Do not collect $200.", "action": "go_to_jail"},
		# ... Add more cards
	]
	
	# Generate community chest cards
	community_chest_cards = [
		{"text": "Doctor's fee. Pay $50.", "action": "pay_money", "amount": 50},
		{"text": "From sale of stock you get $50.", "action": "add_money", "amount": 50},
		{"text": "Get Out of Jail Free.", "action": "get_out_of_jail_free"},
		# ... Add more cards
	]
	
	# Shuffle cards
	chance_cards.shuffle()
	community_chest_cards.shuffle()

func _generate_game_id() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)

# Player management
func add_player(name: String, type: PlayerType = PlayerType.HUMAN, color: Color = Color.WHITE, token: String = "default"):
	var player_id = players.size()
	var player = PlayerData.new(player_id, name, type, color, token)
	players.append(player)
	print("Player added: ", name, " (ID: ", player_id, ")")
	return player_id

func remove_player(player_id: int):
	if player_id < players.size():
		players.remove_at(player_id)
		print("Player removed: ID ", player_id)

func get_player(player_id: int) -> PlayerData:
	if player_id < players.size():
		return players[player_id]
	return null

# Game flow
func start_game():
	if players.size() < config.min_players:
		print("Not enough players to start game")
		return false
	
	game_state = GameState.PLAYING
	current_player_index = 0
	game_state_changed.emit("playing")
	player_turn_changed.emit(players[current_player_index].id)
	print("Game started with ", players.size(), " players")
	return true

func start_single_player():
	# Add AI players for single player
	players.clear()
	
	# Add human player
	add_player("You", PlayerType.HUMAN, Color.RED, "car")
	
	# Add AI players
	var ai_names = ["AI Player 1", "AI Player 2", "AI Player 3"]
	var ai_colors = [Color.BLUE, Color.GREEN, Color.YELLOW]
	var ai_tokens = ["hat", "dog", "ship"]
	
	for i in range(3):
		add_player(ai_names[i], PlayerType.AI_MEDIUM, ai_colors[i], ai_tokens[i])
	
	return start_game()

func next_turn():
	if game_state != GameState.PLAYING:
		return
	
	var current_player = players[current_player_index]
	
	# Check if player is bankrupt
	if current_player.is_bankrupt:
		_skip_bankrupt_player()
		return
	
	# Move to next player
	current_player_index = (current_player_index + 1) % players.size()
	player_turn_changed.emit(players[current_player_index].id)
	
	# Check if only one player remains
	if _get_active_players_count() <= 1:
		end_game()
		return

func roll_dice() -> Array:
	var die1 = randi() % 6 + 1
	var die2 = randi() % 6 + 1
	return [die1, die2]

func move_player(player_id: int, steps: int):
	var player = get_player(player_id)
	if not player or player.is_bankrupt:
		return
	
	var old_position = player.position
	player.position = (player.position + steps) % 40
	
	print("Player ", player.name, " moved from ", old_position, " to ", player.position)
	_handle_space_landing(player_id, player.position)

func _handle_space_landing(player_id: int, position: int):
	var player = get_player(player_id)
	var space = board.get(str(position), {})
	
	match space.get("type", ""):
		"property":
			_handle_property_landing(player_id, str(position))
		"special":
			_handle_special_space(player_id, space.get("action", ""))
		"tax":
			_pay_tax(player_id, space.get("amount", 0))
		"railroad":
			_handle_railroad_landing(player_id, str(position))
		"utility":
			_handle_utility_landing(player_id, str(position))

func _handle_property_landing(player_id: int, property_id: String):
	var property_data = properties.get(property_id, {})
	var space = board.get(property_id, {})
	
	if property_data.owner == null:
		# Property is available for purchase
		UIManager.show_property_purchase(property_id, space.price)
	elif property_data.owner != player_id:
		# Pay rent to owner
		var rent = _calculate_rent(property_id)
		_transfer_money(player_id, property_data.owner, rent)

func purchase_property(player_id: int, property_id: String) -> bool:
	var player = get_player(player_id)
	var space = board.get(property_id, {})
	
	if not player or player.money < space.price:
		return false
	
	# Check if property is already owned
	if properties[property_id].owner != null:
		return false
	
	# Purchase property
	player.money -= space.price
	properties[property_id].owner = player_id
	player.properties.append(property_id)
	
	money_changed.emit(player_id, player.money)
	property_purchased.emit(player_id, property_id)
	
	print("Player ", player.name, " purchased ", space.name, " for $", space.price)
	return true

func _calculate_rent(property_id: String) -> int:
	var property_data = properties[property_id]
	var space = board[property_id]
	var rent_level = property_data.houses
	
	if property_data.hotel:
		rent_level = 5  # Hotel rent is index 5 in rent array
	
	return space.rent[rent_level]

func _transfer_money(from_player_id: int, to_player_id: int, amount: int):
	var from_player = get_player(from_player_id)
	var to_player = get_player(to_player_id)
	
	if not from_player or not to_player:
		return
	
	from_player.money -= amount
	to_player.money += amount
	
	money_changed.emit(from_player_id, from_player.money)
	money_changed.emit(to_player_id, to_player.money)
	
	# Check for bankruptcy
	if from_player.money < 0:
		_declare_bankruptcy(from_player_id)

func _declare_bankruptcy(player_id: int):
	var player = get_player(player_id)
	if not player:
		return
	
	player.is_bankrupt = true
	print("Player ", player.name, " is bankrupt!")
	
	# Transfer all properties to bank (auction in real Monopoly)
	for property_id in player.properties:
		properties[property_id].owner = null
	
	# Check if game should end
	if _get_active_players_count() <= 1:
		end_game()

func _get_active_players_count() -> int:
	var count = 0
	for player in players:
		if not player.is_bankrupt:
			count += 1
	return count

func _skip_bankrupt_player():
	# Skip to next non-bankrupt player
	var original_index = current_player_index
	var attempts = 0
	
	while attempts < players.size():
		current_player_index = (current_player_index + 1) % players.size()
		if not players[current_player_index].is_bankrupt:
			player_turn_changed.emit(players[current_player_index].id)
			return
		attempts += 1
	
	# All players bankrupt (shouldn't happen)
	end_game()

func end_game():
	game_state = GameState.GAME_OVER
	
	# Find winner (player with most money)
	var winner_id = -1
	var max_money = -1
	
	for player in players:
		if not player.is_bankrupt and player.money > max_money:
			max_money = player.money
			winner_id = player.id
	
	game_over.emit(winner_id)
	print("Game over! Winner: Player ", winner_id)
	
	# Save game statistics
	_save_game_stats(winner_id)

func _save_game_stats(winner_id: int):
	# Save game statistics to file
	var stats = {
		"game_id": game_id,
		"winner": winner_id,
		"players": players.size(),
		"duration": Time.get_unix_time_from_system() - int(game_id.split("_")[0]),
		"version": game_version
	}
	
	# In a real implementation, save to file or send to server
	print("Game stats: ", stats)

# Save/Load functionality
func save_game():
	var save_data = {
		"game_id": game_id,
		"game_state": game_state,
		"current_player": current_player_index,
		"players": [],
		"properties": properties,
		"version": game_version
	}
	
	# Save player data
	for player in players:
		save_data.players.append({
			"id": player.id,
			"name": player.name,
			"type": player.type,
			"money": player.money,
			"position": player.position,
			"properties": player.properties,
			"in_jail": player.in_jail,
			"jail_turns": player.jail_turns,
			"is_bankrupt": player.is_bankrupt
		})
	
	# Save to file
	var save_file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()
		print("Game saved successfully")
		return true
	
	return false

func load_game() -> bool:
	var save_file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if not save_file:
		return false
	
	var save_data = save_file.get_var()
	save_file.close()
	
	# Validate save data
	if not save_data.has("version") or save_data.version != game_version:
		print("Save file version mismatch")
		return false
	
	# Load game data
	game_id = save_data.game_id
	game_state = save_data.game_state
	current_player_index = save_data.current_player
	properties = save_data.properties
	
	# Load players
	players.clear()
	for player_data in save_data.players:
		var player = PlayerData.new(
			player_data.id,
			player_data.name,
			player_data.type,
			Color.WHITE,  # Color not saved in this example
			"default"     # Token not saved in this example
		)
		player.money = player_data.money
		player.position = player_data.position
		player.properties = player_data.properties
		player.in_jail = player_data.in_jail
		player.jail_turns = player_data.jail_turns
		player.is_bankrupt = player_data.is_bankrupt
		players.append(player)
	
	print("Game loaded successfully")
	game_state_changed.emit("loaded")
	return true

func has_saved_game() -> bool:
	return FileAccess.file_exists("user://save_game.dat")

# Utility functions
func get_player_count() -> int:
	return players.size()

func get_current_player() -> PlayerData:
	if players.size() > 0:
		return players[current_player_index]
	return null

func get_player_money(player_id: int) -> int:
	var player = get_player(player_id)
	return player.money if player else 0

func get_player_properties(player_id: int) -> Array:
	var player = get_player(player_id)
	return player.properties if player else []

func is_game_active() -> bool:
	return game_state == GameState.PLAYING

func get_game_state() -> String:
	match game_state:
		GameState.LOBBY: return "lobby"
		GameState.PLAYING: return "playing"
		GameState.PAUSED: return "paused"
		GameState.GAME_OVER: return "game_over"
		_: return "unknown"