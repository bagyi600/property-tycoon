extends Control

@onready var play_button: Button = $MainContainer/ButtonContainer/PlayButton
@onready var multiplayer_button: Button = $MainContainer/ButtonContainer/MultiplayerButton
@onready var settings_button: Button = $MainContainer/ButtonContainer/SettingsButton
@onready var shop_button: Button = $MainContainer/ButtonContainer/ShopButton
@onready var exit_button: Button = $MainContainer/ButtonContainer/ExitButton

func _ready():
	# Connect button signals
	play_button.pressed.connect(_on_play_button_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
	# Initialize game managers
	GameManager.initialize()
	AudioManager.play_music("main_menu")
	
	# Check for saved games
	_check_saved_games()

func _on_play_button_pressed():
	AudioManager.play_sound("button_click")
	GameManager.start_single_player()
	get_tree().change_scene_to_file("res://scenes/game/game_lobby.tscn")

func _on_multiplayer_button_pressed():
	AudioManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/game/multiplayer_lobby.tscn")

func _on_settings_button_pressed():
	AudioManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")

func _on_shop_button_pressed():
	AudioManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")

func _on_exit_button_pressed():
	AudioManager.play_sound("button_click")
	# On Android, minimize instead of quitting
	if OS.has_feature("android"):
		OS.minimize_window()
	else:
		get_tree().quit()

func _check_saved_games():
	# Check if there are saved games to continue
	if GameManager.has_saved_game():
		# Could add a "Continue" button
		pass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Handle Android back button
		if OS.has_feature("android"):
			_on_exit_button_pressed()
		else:
			get_tree().quit()

func _process(delta):
	# Handle Android back button
	if Input.is_action_just_pressed("ui_cancel"):
		_on_exit_button_pressed()