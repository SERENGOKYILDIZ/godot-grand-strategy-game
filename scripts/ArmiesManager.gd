extends Node2D
class_name ArmiesManager


@export var ArmyScene: PackedScene
var armies: Array = []
var selected_army: Node2D = null
var main_ref: Node = null






func spawn_army(region_position: Vector2, region_name: String) -> Node2D:
	var army = ArmyScene.instantiate()
	add_child(army)


	army.position = region_position
	army.current_region_name = region_name


	var sprite = army.get_node("ArmySprite")
	sprite.z_index = 50
	var sprite_light = army.get_node("LightArmy")
	sprite_light.z_index = 50


	armies.append(army)


	# Connect signals
	army.connect("army_selected", Callable(self, "_on_army_selected"))
	army.connect("army_reached_region", Callable(self, "_on_army_reached_region"))


	return army




# -------------------------
# SELECTION LOGIC
# -------------------------
func _on_army_selected(army):
	if selected_army and selected_army != army:
		selected_army.deselect()


	selected_army = army
	selected_army.select()




func deselect_army():
	if selected_army:
		selected_army.deselect()
		selected_army = null




# -------------------------
# MOVEMENT ORDER
# -------------------------
func move_selected_army_to_region(region_name: String):
	if not selected_army:
		return


	# Get world coordinates from Main
	var target_global = main_ref.get_region_center(region_name)
	var target_local = self.to_local(target_global)


	selected_army.move_to(target_local, region_name)




# -------------------------
# ARRIVAL HANDLING
# -------------------------
func _on_army_reached_region(army, region_name):
	army.current_region_name = region_name


	# Tell Main to update ownership
	if main_ref:
		main_ref.capture_region(region_name)
