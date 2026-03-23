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


func _process(delta):
	if is_moving:
		position = position.move_toward(target_position, move_speed * delta)
		if position == target_position:
			is_moving = false
			emit_signal("army_reached_region", self, target_region_name)
