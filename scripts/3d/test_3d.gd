extends Node3D

# Simple 3D test script

func _ready():
	print("3D test scene loaded")
	print("Dice model: ", $Dice3D.mesh != null)
	print("Token model: ", $Token3D.mesh != null)
	
	# Simple rotation animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($Dice3D, "rotation_degrees:y", 360, 4.0)
