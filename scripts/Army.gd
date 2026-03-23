extends Node2D


signal army_selected(army)
signal army_reached_region(army, region_name)


@export var move_speed := 200.0


var current_region_name: String = ""
var target_region_name: String = ""
var target_position: Vector2
var is_moving := false


@onready var sprite := $ArmySprite
@onready var select_ring := $SelectRing      
@onready var collision := $ClickArea/CollisionShape2D  
@onready var light_army :=  $LightArmy
@onready var line: Line2D = $Line2D
@onready var target_marker: Sprite2D = $TargetMarker


func _ready():
	select_ring.visible = false
	light_army.visible = false


# -------------------------
# SELECTION
# -------------------------
func select():
	select_ring.visible = true
	light_army.visible = true


func deselect():
	select_ring.visible = false
	light_army.visible = false


# -------------------------
# INPUT EVENT
# -------------------------
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Army clicked!")  # debug
		emit_signal("army_selected", self)


# -------------------------
# MOVEMENT
# -------------------------
func move_to(target: Vector2, region_name: String):
	target_region_name = region_name
	target_position = target
	is_moving = true
	
	# The TargetMarker
	target_marker.z_index = 49
	target_marker.global_position = target
	target_marker.show()

	# The Line
	line.z_index = 48
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED # Dokunun tekrar etmesini zorunlu kılar
	line.show()
	line.clear_points()
	line.add_point(global_position) # Ordunun kendi merkezi (0,0)
	line.add_point(target) # Hedefin orduya göre konumu


func _process(delta):
	if is_moving:
		position = position.move_toward(target_position, move_speed * delta)
		
		# Ordu ilerledikçe başlangıç noktasını askerin altında tut
		line.set_point_position(0, global_position)
		
		# Shader kullanıyorsan mesafe güncellemeyi unutma
		var dist = global_position.distance_to(target_position)
		if line.material:
			line.material.set_shader_parameter("current_distance", dist)
		
		if position == target_position:
			is_moving = false
			line.hide() # Hedefe varınca çizgiyi gizle
			target_marker.hide() # Hedefe varınca çarpıyı gizle
			emit_signal("army_reached_region", self, target_region_name)
