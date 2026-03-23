extends Control


@onready var main = get_tree().get_first_node_in_group("Main")


func _ready():
	$HBoxContainer/SlowButton.pressed.connect(func(): change_speed("Slow"))
	$HBoxContainer/NormalButton.pressed.connect(func(): change_speed("Normal"))
	$HBoxContainer/FastButton.pressed.connect(func(): change_speed("Fast"))
	$HBoxContainer/PauseButton.pressed.connect(func(): change_speed("Pause"))


func change_speed(speed: String):
	if main:
		main.set_game_speed(speed)
		print("⏩ Game speed set to:", speed)
