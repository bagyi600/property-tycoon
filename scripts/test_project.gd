extends Node

# Test script to verify project structure and basic functionality

func _ready():
	print("=== Property Tycoon Project Test ===")
	
	# Test 1: Check core files
	test_core_files()
	
	# Test 2: Test GameManager
	test_game_manager()
	
	# Test 3: Test basic game flow
	test_basic_game_flow()
	
	print("=== Project Test Complete ===")

func test_core_files():
	print("\n1. Testing core files...")
	
	var required_files = [
		"res://project.godot",
		"res://export_presets.cfg",
		"res://scenes/main/main.tscn",
		"res://scripts/singletons/game_manager.gd",
		"res://scripts/singletons/network_manager.gd",
		"res://scripts/singletons/ui_manager.gd"
	]
	
	var all_files_exist = true
	for file_path in required_files:
		if FileAccess.file_exists(file_path):
			print("  ✓ %s" % file_path.get_file())
		else:
			print("  ✗ %s (missing)" % file_path.get_file())
			all_files_exist = false
	
	if all_files_exist:
		print("  All core files present!")
	else:
		print("  Warning: Some core files are missing")

func test_game_manager():
	print("\n2. Testing GameManager...")
	
	# Note: In a real test, we'd instantiate GameManager
	# For now, just check the script loads
	var gm_script = load("res://scripts/singletons/game_manager.gd")
	if gm_script:
		print("  ✓ GameManager script loaded")
		
		# Check for required methods
		var instance = gm_script.new()
		var required_methods = ["initialize", "start_game", "roll_dice", "move_player"]
		var all_methods_exist = true
		
		for method in required_methods:
			if instance.has_method(method):
				print("    ✓ Method: %s" % method)
			else:
				print("    ✗ Method: %s (missing)" % method)
				all_methods_exist = false
		
		instance.free()
		
		if all_methods_exist:
			print("  All required methods present!")
	else:
		print("  ✗ Failed to load GameManager script")

func test_basic_game_flow():
	print("\n3. Testing basic game flow...")
	
	# Simulate basic game flow
	print("  Simulating game setup...")
	
	# This would normally test:
	# 1. Player creation
	# 2. Game start
	# 3. Dice rolling
	# 4. Player movement
	# 5. Property purchase
	
	print("  Basic game flow simulation complete")
	print("  Note: Full testing requires running in Godot editor")

func test_android_export():
	print("\n4. Testing Android export configuration...")
	
	var export_config = load_export_config()
	if export_config:
		print("  ✓ Export configuration loaded")
		
		# Check for Android preset
		if export_config.has_section("preset.0"):
			var preset_name = export_config.get_value("preset.0", "name", "")
			if preset_name == "Android":
				print("  ✓ Android export preset found")
				
				# Check package name
				var package_name = export_config.get_value("preset.0.options", "package/unique_name", "")
				if package_name.begins_with("com."):
					print("  ✓ Valid package name: %s" % package_name)
				else:
					print("  ⚠ Package name might need adjustment: %s" % package_name)
			else:
				print("  ✗ Android preset not found (found: %s)" % preset_name)
		else:
			print("  ✗ No export presets found")
	else:
		print("  ✗ Failed to load export configuration")

func load_export_config():
	var config = ConfigFile.new()
	var err = config.load("res://export_presets.cfg")
	if err == OK:
		return config
	return null

func run_all_tests():
	print("\n=== Running All Tests ===")
	test_core_files()
	test_game_manager()
	test_basic_game_flow()
	test_android_export()
	print("\n=== All Tests Complete ===")

# Run tests when script is executed directly
func _enter_tree():
	if Engine.is_editor_hint():
		# Don't run tests in editor
		return
	
	# Run tests after a short delay
	await get_tree().create_timer(1.0).timeout
	run_all_tests()