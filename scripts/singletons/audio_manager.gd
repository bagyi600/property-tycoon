extends Node

# Audio Manager Singleton
# Handles sound effects and background music

signal music_changed(track_name: String)
signal volume_changed(bus_name: String, volume: float)

# Audio configuration
var config = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"ui_volume": 1.0,
	"music_enabled": true,
	"sfx_enabled": true
}

# Current state
var current_music: AudioStreamPlayer = null
var music_tracks: Dictionary = {}
var sfx_players: Array = []
var max_sfx_players: int = 10

func _ready():
	initialize()

func initialize():
	# Create audio buses if they don't exist
	_create_audio_buses()
	
	# Load configuration
	_load_config()
	
	# Create SFX players pool
	_create_sfx_pool()
	
	print("Audio Manager initialized")

func _create_audio_buses():
	# Master bus
	if not AudioServer.get_bus_index("Master") >= 0:
		AudioServer.add_bus(0)
		AudioServer.set_bus_name(0, "Master")
	
	# Music bus
	if not AudioServer.get_bus_index("Music") >= 0:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "Music")
		AudioServer.set_bus_send(1, "Master")
	
	# SFX bus
	if not AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, "SFX")
		AudioServer.set_bus_send(2, "Master")
	
	# UI bus
	if not AudioServer.get_bus_index("UI") >= 0:
		AudioServer.add_bus(3)
		AudioServer.set_bus_name(3, "UI")
		AudioServer.set_bus_send(3, "Master")

func _create_sfx_pool():
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.name = "SFXPlayer_%d" % i
		add_child(player)
		sfx_players.append(player)

func _load_config():
	var config_file = FileAccess.open("user://audio_config.dat", FileAccess.READ)
	if config_file:
		var saved_config = config_file.get_var()
		config_file.close()
		
		if saved_config:
			config = saved_config
			
			# Apply saved volumes
			set_bus_volume("Master", config.master_volume)
			set_bus_volume("Music", config.music_volume)
			set_bus_volume("SFX", config.sfx_volume)
			set_bus_volume("UI", config.ui_volume)

func save_config():
	var config_file = FileAccess.open("user://audio_config.dat", FileAccess.WRITE)
	if config_file:
		config_file.store_var(config)
		config_file.close()

# Music management
func play_music(track_name: String, fade_duration: float = 1.0):
	if not config.music_enabled:
		return
	
	# Stop current music with fade
	if current_music and current_music.playing:
		_fade_out_music(current_music, fade_duration)
	
	# Load and play new track
	var track = _load_music_track(track_name)
	if track:
		current_music = AudioStreamPlayer.new()
		current_music.stream = track
		current_music.bus = "Music"
		current_music.volume_db = linear_to_db(config.music_volume)
		current_music.autoplay = true
		add_child(current_music)
		
		# Fade in
		_fade_in_music(current_music, fade_duration)
		
		music_changed.emit(track_name)
		print("Playing music: ", track_name)

func stop_music(fade_duration: float = 1.0):
	if current_music and current_music.playing:
		_fade_out_music(current_music, fade_duration)
		current_music = null

func _load_music_track(track_name: String) -> AudioStream:
	# Try to load from assets/music/
	var track_path = "res://assets/music/%s.ogg" % track_name
	if ResourceLoader.exists(track_path):
		return load(track_path)
	
	# Try .mp3
	track_path = "res://assets/music/%s.mp3" % track_name
	if ResourceLoader.exists(track_path):
		return load(track_path)
	
	# Try .wav
	track_path = "res://assets/music/%s.wav" % track_name
	if ResourceLoader.exists(track_path):
		return load(track_path)
	
	print("Music track not found: ", track_name)
	return null

func _fade_in_music(player: AudioStreamPlayer, duration: float):
	player.volume_db = -80  # Start silent
	player.play()
	
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(config.music_volume), duration)

func _fade_out_music(player: AudioStreamPlayer, duration: float):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80, duration)
	tween.tween_callback(player.queue_free)

# Sound effects
func play_sound(sound_name: String, pitch_variation: float = 0.0):
	if not config.sfx_enabled:
		return
	
	var player = _get_available_sfx_player()
	if not player:
		return
	
	var sound = _load_sound_effect(sound_name)
	if sound:
		player.stream = sound
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
		player.play()

func play_ui_sound(sound_name: String):
	if not config.sfx_enabled:
		return
	
	var player = _get_available_sfx_player()
	if not player:
		return
	
	var sound = _load_sound_effect(sound_name)
	if sound:
		player.stream = sound
		player.bus = "UI"
		player.play()
		# Reset bus for next use
		player.bus = "SFX"

func _load_sound_effect(sound_name: String) -> AudioStream:
	# Try to load from assets/sounds/
	var sound_path = "res://assets/sounds/%s.wav" % sound_name
	if ResourceLoader.exists(sound_path):
		return load(sound_path)
	
	# Try .ogg
	sound_path = "res://assets/sounds/%s.ogg" % sound_name
	if ResourceLoader.exists(sound_path):
		return load(sound_path)
	
	print("Sound effect not found: ", sound_name)
	return null

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	
	# All players busy, create a new one (temporary)
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	add_child(player)
	sfx_players.append(player)
	return player

# Volume control
func set_bus_volume(bus_name: String, volume: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		# Clamp volume between 0 and 1
		volume = clamp(volume, 0.0, 1.0)
		
		# Convert linear volume to dB
		var db_volume = linear_to_db(volume)
		AudioServer.set_bus_volume_db(bus_index, db_volume)
		
		# Update config
		match bus_name:
			"Master": config.master_volume = volume
			"Music": config.music_volume = volume
			"SFX": config.sfx_volume = volume
			"UI": config.ui_volume = volume
		
		volume_changed.emit(bus_name, volume)
		save_config()

func get_bus_volume(bus_name: String) -> float:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		var db_volume = AudioServer.get_bus_volume_db(bus_index)
		return db_to_linear(db_volume)
	return 0.0

# Toggle functions
func toggle_music(enabled: bool = true):
	config.music_enabled = enabled
	
	if not config.music_enabled and current_music:
		current_music.stop()
	
	save_config()
	return config.music_enabled

func toggle_sfx(enabled: bool = true):
	config.sfx_enabled = enabled
	
	save_config()
	return config.sfx_enabled

# Utility functions
func is_music_playing() -> bool:
	return current_music != null and current_music.playing

func get_current_music_track() -> String:
	if current_music:
		# Extract track name from stream resource path
		var path = current_music.stream.resource_path
		if path:
			return path.get_file().get_basename()
	return ""

# Cleanup
func _exit_tree():
	# Save configuration
	save_config()
	
	# Stop all audio
	if current_music:
		current_music.stop()
	
	for player in sfx_players:
		if player.playing:
			player.stop()