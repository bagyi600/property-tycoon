extends Control

# Game Board Controller
# Handles board rendering, player movement, and space interactions

@onready var spaces_node: Node2D = $BoardContainer/Spaces
@onready var players_node: Node2D = $BoardContainer/Players
@onready var dice1: TextureRect = $DiceContainer/Dice1
@onready var dice2: TextureRect = $DiceContainer/Dice2
@onready var roll_button: Button = $DiceContainer/RollButton
@onready var current_player_label: Label = $PlayerInfo/CurrentPlayer
@onready var player_money_label: Label = $PlayerInfo/PlayerMoney
@onready var player_properties_label: Label = $PlayerInfo/PlayerProperties

# Board configuration
var space_positions: Array = []
var space_nodes: Array = []
var player_tokens: Dictionary = {}
var dice_textures: Array = []

func _ready():
	# Load dice textures
	_load_dice_textures()
	
	# Initialize board
	_setup_board()
	
	# Connect signals
	roll_button.pressed.connect(_on_roll_button_pressed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.player_turn_changed.connect(_on_player_turn_changed)
	GameManager.money_changed.connect(_on_money_changed)
	
	# Update UI
	_update_player_info()

func _load_dice_textures():
	# Load dice face textures (1-6)
	for i in range(1, 7):
		var texture_path = "res://assets/ui/dice_%d.png" % i
		if ResourceLoader.exists(texture_path):
			dice_textures.append(load(texture_path))
		else:
			# Create placeholder
			dice_textures.append(null)

func _setup_board():
	# Calculate positions for 40 spaces in a square board
	var board_size = min(size.x, size.y) - 100
	var center = Vector2(size.x / 2, size.y / 2)
	var radius = board_size / 2
	
	# Create positions for a Monopoly-style board
	# This is a simplified version - in a real game, you'd have precise positions
	for i in range(40):
		var angle = (i / 40.0) * 2 * PI
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		space_positions.append(pos)
		
		# Create space visual (simplified)
		var space = _create_space_node(i, pos)
		space_nodes.append(space)

func _create_space_node(space_id: int, position: Vector2) -> Control:
	var space = Control.new()
	space.name = "Space_%d" % space_id
	space.position = position - Vector2(25, 25)  # Center the 50x50 space
	space.size = Vector2(50, 50)
	
	# Add background
	var bg = ColorRect.new()
	bg.color = Color(0.9, 0.9, 0.9, 0.8)
	bg.size = Vector2(50, 50)
	space.add_child(bg)
	
	# Add space number
	var label = Label.new()
	label.text = str(space_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(50, 50)
	space.add_child(label)
	
	spaces_node.add_child(space)
	return space

func add_player(player_id: int, color: Color, token_texture: Texture2D = null):
	# Create player token
	var token = Sprite2D.new()
	token.name = "Player_%d" % player_id
	
	if token_texture:
		token.texture = token_texture
	else:
		# Create colored circle as fallback
		var circle = CircleShape2D.new()
		circle.radius = 15
		var shape = CollisionShape2D.new()
		shape.shape = circle
		token.add_child(shape)
	
	token.modulate = color
	token.position = space_positions[0]  # Start at GO
	
	players_node.add_child(token)
	player_tokens[player_id] = token
	
	# Position token based on number of players at this space
	_update_token_positions()

func _update_token_positions():
	# Position tokens so they don't overlap
	var tokens_at_space = {}
	
	for player_id in player_tokens:
		var token = player_tokens[player_id]
		var space_id = _get_space_from_position(token.position)
		
		if not tokens_at_space.has(space_id):
			tokens_at_space[space_id] = []
		tokens_at_space[space_id].append(player_id)
	
	# Position tokens around their space
	for space_id in tokens_at_space:
		var tokens = tokens_at_space[space_id]
		var base_position = space_positions[space_id]
		
		for i in range(tokens.size()):
			var player_id = tokens[i]
			var token = player_tokens[player_id]
			
			# Position in a circle around the space
			var angle = (i / float(tokens.size())) * 2 * PI
			var offset = Vector2(cos(angle), sin(angle)) * 30
			token.position = base_position + offset

func _get_space_from_position(position: Vector2) -> int:
	# Find the closest space to the given position
	var closest_space = 0
	var closest_distance = INF
	
	for i in range(space_positions.size()):
		var distance = position.distance_to(space_positions[i])
		if distance < closest_distance:
			closest_distance = distance
			closest_space = i
	
	return closest_space

func move_player_to_space(player_id: int, space_id: int, animate: bool = true):
	var token = player_tokens.get(player_id)
	if not token:
		return
	
	var target_position = space_positions[space_id]
	
	if animate:
		# Animate movement
		var tween = create_tween()
		tween.tween_property(token, "position", target_position, 0.5)
		tween.tween_callback(_update_token_positions)
	else:
		token.position = target_position
		_update_token_positions()

func move_player_by_steps(player_id: int, steps: int):
	var current_space = _get_player_space(player_id)
	var target_space = (current_space + steps) % 40
	
	# Animate movement through each space
	var tween = create_tween()
	
	for step in range(1, steps + 1):
		var intermediate_space = (current_space + step) % 40
		var pos = space_positions[intermediate_space]
		tween.tween_property(player_tokens[player_id], "position", pos, 0.1)
	
	tween.tween_callback(_update_token_positions)
	
	# Return final space
	return target_space

func _get_player_space(player_id: int) -> int:
	var token = player_tokens.get(player_id)
	if token:
		return _get_space_from_position(token.position)
	return 0

func show_dice_roll(dice_values: Array):
	if dice_values.size() >= 1 and dice_values[0] <= dice_textures.size():
		dice1.texture = dice_textures[dice_values[0] - 1]
	
	if dice_values.size() >= 2 and dice_values[1] <= dice_textures.size():
		dice2.texture = dice_textures[dice_values[1] - 1]
	
	# Animate dice roll
	dice1.modulate = Color.TRANSPARENT
	dice2.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dice1, "modulate", Color.WHITE, 0.3)
	tween.tween_property(dice2, "modulate", Color.WHITE, 0.3)

func clear_dice():
	dice1.texture = null
	dice2.texture = null

func _update_player_info():
	var current_player = GameManager.get_current_player()
	if current_player:
		current_player_label.text = "Current Player: %s" % current_player.name
		player_money_label.text = "Money: $%d" % current_player.money
		player_properties_label.text = "Properties: %d" % current_player.properties.size()
		
		# Enable/disable roll button based on turn
		roll_button.disabled = (GameManager.player_id != current_player.id or 
							   not GameManager.is_game_active())

# Signal handlers
func _on_roll_button_pressed():
	AudioManager.play_sound("dice_roll")
	
	# Roll dice
	var dice_values = GameManager.roll_dice()
	show_dice_roll(dice_values)
	
	# Move current player
	var current_player = GameManager.get_current_player()
	if current_player:
		var final_space = move_player_by_steps(current_player.id, dice_values[0] + dice_values[1])
		
		# Handle space landing after animation
		await get_tree().create_timer(0.5 * (dice_values[0] + dice_values[1])).timeout
		GameManager.move_player(current_player.id, dice_values[0] + dice_values[1])

func _on_game_state_changed(state: String):
	match state:
		"playing":
			roll_button.visible = true
			_update_player_info()
		"game_over":
			roll_button.visible = false
			# Show game over screen
			UIManager.show_game_over(GameManager.get_winner_id())
		_:
			roll_button.visible = false

func _on_player_turn_changed(player_id: int):
	_update_player_info()
	clear_dice()
	
	# Highlight current player's token
	for pid in player_tokens:
		var token = player_tokens[pid]
		if pid == player_id:
			# Highlight current player
			var tween = create_tween()
			tween.tween_property(token, "scale", Vector2(1.2, 1.2), 0.2)
			tween.tween_property(token, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.5)
		else:
			token.scale = Vector2(1.0, 1.0)

func _on_money_changed(player_id: int, amount: int):
	if player_id == GameManager.get_current_player().id:
		_update_player_info()

# Property visualization
func update_property_ownership(property_id: String, owner_id: int):
	var space_id = int(property_id)
	if space_id < space_nodes.size():
		var space = space_nodes[space_id]
		
		# Change background color based on owner
		if owner_id >= 0:
			var owner = GameManager.get_player(owner_id)
			if owner:
				# Find the ColorRect child
				for child in space.get_children():
					if child is ColorRect:
						child.color = owner.color * 0.7  # Darker version of player color
						break
		else:
			# Reset to default
			for child in space.get_children():
				if child is ColorRect:
					child.color = Color(0.9, 0.9, 0.9, 0.8)
					break

# Cleanup
func _exit_tree():
	# Disconnect signals
	if GameManager.game_state_changed.is_connected(_on_game_state_changed):
		GameManager.game_state_changed.disconnect(_on_game_state_changed)
	if GameManager.player_turn_changed.is_connected(_on_player_turn_changed):
		GameManager.player_turn_changed.disconnect(_on_player_turn_changed)
	if GameManager.money_changed.is_connected(_on_money_changed):
		GameManager.money_changed.disconnect(_on_money_changed)