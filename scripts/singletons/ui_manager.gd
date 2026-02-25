extends CanvasLayer

# UI Manager Singleton
# Handles all UI interactions, popups, and screen transitions

signal ui_initialized()
signal screen_changed(screen_name: String)
signal popup_closed(popup_name: String)

# UI references
var current_screen: Control = null
var popup_stack: Array = []
var ui_theme: Theme

# UI configuration
var ui_config = {
	"screen_transition_duration": 0.3,
	"popup_animation_duration": 0.2,
	"button_click_sound": "button_click",
	"notification_duration": 3.0,
	"chat_max_messages": 50
}

func _ready():
	_load_ui_theme()
	_initialize_ui()
	ui_initialized.emit()

func _load_ui_theme():
	# Load UI theme
	ui_theme = Theme.new()
	
	# Load theme from file if exists
	var theme_file = "res://assets/ui/theme.tres"
	if ResourceLoader.exists(theme_file):
		ui_theme = load(theme_file)
	else:
		_create_default_theme()

func _create_default_theme():
	# Create default theme for the game
	var default_font = load("res://assets/fonts/main_font.ttf")
	
	# Button styles
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.2, 0.3)
	button_style.border_color = Color(0.3, 0.3, 0.4)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = Color(0.3, 0.3, 0.4)
	
	var button_pressed_style = button_style.duplicate()
	button_pressed_style.bg_color = Color(0.1, 0.1, 0.2)
	
	# Add styles to theme
	ui_theme.set_stylebox("normal", "Button", button_style)
	ui_theme.set_stylebox("hover", "Button", button_hover_style)
	ui_theme.set_stylebox("pressed", "Button", button_pressed_style)
	ui_theme.set_stylebox("focus", "Button", button_style)
	
	# Set fonts
	ui_theme.set_font("font", "Button", default_font)
	ui_theme.set_font("font", "Label", default_font)
	ui_theme.set_font_size("font_size", "Button", 24)
	ui_theme.set_font_size("font_size", "Label", 20)

func _initialize_ui():
	# Set theme
	get_tree().root.theme = ui_theme
	
	# Initialize audio for UI
	AudioManager.initialize()

# Screen management
func change_screen(screen_path: String):
	AudioManager.play_sound(ui_config.button_click_sound)
	
	# Fade out current screen
	if current_screen:
		_fade_out_screen(current_screen)
		await get_tree().create_timer(ui_config.screen_transition_duration).timeout
		current_screen.queue_free()
	
	# Load and show new screen
	var new_screen = load(screen_path).instantiate()
	add_child(new_screen)
	_fade_in_screen(new_screen)
	
	current_screen = new_screen
	screen_changed.emit(screen_path.get_file().get_basename())

func _fade_in_screen(screen: Control):
	screen.modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(screen, "modulate", Color.WHITE, ui_config.screen_transition_duration)

func _fade_out_screen(screen: Control):
	var tween = create_tween()
	tween.tween_property(screen, "modulate", Color.TRANSPARENT, ui_config.screen_transition_duration)

# Popup management
func show_popup(popup_path: String, data: Dictionary = {}) -> Control:
	AudioManager.play_sound("popup_open")
	
	# Load popup
	var popup_scene = load(popup_path)
	var popup = popup_scene.instantiate()
	
	# Pass data to popup if it has a set_data method
	if popup.has_method("set_data"):
		popup.set_data(data)
	
	# Add to scene
	add_child(popup)
	popup_stack.append(popup)
	
	# Animate in
	_animate_popup_in(popup)
	
	return popup

func close_popup(popup: Control = null):
	if popup_stack.is_empty():
		return
	
	var popup_to_close = popup if popup else popup_stack[-1]
	
	if popup_stack.has(popup_to_close):
		AudioManager.play_sound("popup_close")
		_animate_popup_out(popup_to_close)
		
		await get_tree().create_timer(ui_config.popup_animation_duration).timeout
		
		popup_stack.erase(popup_to_close)
		popup_to_close.queue_free()
		popup_closed.emit(popup_to_close.name)

func close_all_popups():
	for popup in popup_stack:
		close_popup(popup)

func _animate_popup_in(popup: Control):
	popup.scale = Vector2(0.8, 0.8)
	popup.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "scale", Vector2.ONE, ui_config.popup_animation_duration)
	tween.tween_property(popup, "modulate", Color.WHITE, ui_config.popup_animation_duration)

func _animate_popup_out(popup: Control):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "scale", Vector2(0.8, 0.8), ui_config.popup_animation_duration)
	tween.tween_property(popup, "modulate", Color.TRANSPARENT, ui_config.popup_animation_duration)

# Specific popups
func show_property_purchase(property_id: String, price: int):
	var data = {
		"property_id": property_id,
		"price": price,
		"property_name": GameManager.board.get(property_id, {}).get("name", "Unknown")
	}
	
	return show_popup("res://scenes/ui/popups/property_purchase.tscn", data)

func show_trade_request(from_player_id: int, offer: Dictionary, request: Dictionary):
	var from_player = GameManager.get_player(from_player_id)
	var data = {
		"from_player_id": from_player_id,
		"from_player_name": from_player.name if from_player else "Unknown",
		"offer": offer,
		"request": request
	}
	
	return show_popup("res://scenes/ui/popups/trade_request.tscn", data)

func show_game_over(winner_id: int):
	var winner = GameManager.get_player(winner_id)
	var data = {
		"winner_id": winner_id,
		"winner_name": winner.name if winner else "Unknown",
		"winner_money": winner.money if winner else 0
	}
	
	return show_popup("res://scenes/ui/popups/game_over.tscn", data)

func show_error(message: String, duration: float = -1):
	var notification = show_popup("res://scenes/ui/popups/error_notification.tscn", {"message": message})
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		close_popup(notification)

func show_success(message: String, duration: float = 3.0):
	var notification = show_popup("res://scenes/ui/popups/success_notification.tscn", {"message": message})
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		close_popup(notification)

func show_confirmation(title: String, message: String, confirm_text: String = "Confirm", cancel_text: String = "Cancel") -> bool:
	var popup = show_popup("res://scenes/ui/popups/confirmation.tscn", {
		"title": title,
		"message": message,
		"confirm_text": confirm_text,
		"cancel_text": cancel_text
	})
	
	# Wait for user decision
	await popup.decision_made
	var result = popup.result
	
	close_popup(popup)
	return result

# In-game UI
func update_player_info(player_id: int):
	# Update player info in HUD
	var hud = get_node_or_null("HUD")
	if hud and hud.has_method("update_player_info"):
		hud.update_player_info(player_id)

func update_game_state():
	# Update game state in HUD
	var hud = get_node_or_null("HUD")
	if hud and hud.has_method("update_game_state"):
		hud.update_game_state()

func show_chat_message(player_id: int, message: String):
	var hud = get_node_or_null("HUD")
	if hud and hud.has_method("show_chat_message"):
		hud.show_chat_message(player_id, message)

func show_dice_roll(dice_values: Array, player_id: int):
	var player = GameManager.get_player(player_id)
	var data = {
		"dice_values": dice_values,
		"player_name": player.name if player else "Unknown",
		"total": dice_values[0] + dice_values[1] if dice_values.size() >= 2 else 0
	}
	
	return show_popup("res://scenes/ui/popups/dice_roll.tscn", data)

# HUD management
func show_hud():
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	move_child(hud, 0)  # Move to back

func hide_hud():
	var hud = get_node_or_null("HUD")
	if hud:
		hud.queue_free()

# Utility functions
func get_current_popup() -> Control:
	if popup_stack.is_empty():
		return null
	return popup_stack[-1]

func is_popup_open() -> bool:
	return not popup_stack.is_empty()

func vibrate(duration_ms: int = 100):
	# Only works on mobile devices
	if OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(duration_ms)

func show_toast(message: String, duration: float = 2.0):
	# Simple toast notification
	var toast = Label.new()
	toast.text = message
	toast.name = "Toast"
	toast.theme = ui_theme
	toast.add_theme_font_size_override("font_size", 16)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	toast.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toast.position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y - 100)
	toast.size = Vector2(200, 50)
	
	add_child(toast)
	
	# Animate
	toast.modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(toast, "modulate", Color.WHITE, 0.3)
	await get_tree().create_timer(duration).timeout
	tween = create_tween()
	tween.tween_property(toast, "modulate", Color.TRANSPARENT, 0.3)
	await tween.finished
	toast.queue_free()

# Screen adaptation for mobile
func adapt_for_mobile():
	if OS.has_feature("mobile"):
		# Adjust UI for mobile screens
		ui_config.button_click_sound = "mobile_button_click"
		
		# Increase button sizes for touch
		var button_style = ui_theme.get_stylebox("normal", "Button")
		if button_style:
			button_style.content_margin_left = 20
			button_style.content_margin_right = 20
			button_style.content_margin_top = 15
			button_style.content_margin_bottom = 15

# Cleanup
func _exit_tree():
	close_all_popups()