extends Control
class_name RegionInfoPanel


# --- Panel state ---
var current_player_nation = null
var dragging := false
var drag_offset := Vector2.ZERO


# --- Node references ---
@onready var vbox = $VBoxContainer
@onready var region_name_label = $VBoxContainer/RegionNameLabel
@onready var owner_label = $VBoxContainer/OwnerLabel
@onready var extra_info_label = $VBoxContainer/ExtraInfoLabel
@onready var close_button = $CloseButton


# --- Timer Crash avoider


var current_region_name: String = ""




func _ready():
	# Connect close button
	close_button.pressed.connect(self.hide_panel)

	# Set font sizes
	region_name_label.add_theme_font_size_override("font_size", 28)
	owner_label.add_theme_font_size_override("font_size", 22)
	extra_info_label.add_theme_font_size_override("font_size", 20)
	close_button.add_theme_font_size_override("font_size", 20)


	# Minimum size for panel
	custom_minimum_size = Vector2(600, 400)


	# Center the panel after it enters the scene tree
	call_deferred("move_to_center_safe")




# --- Show/Hide logic ---
func show_panel(region_name: String, nation_owner, population: int = 0, oil: float = 0, gdp: int = 0):
	
	# --- Added to avoid crashes
	self.current_region_name = region_name  # store for updates
	# ---
	
	region_name_label.text = "🏙️ " + region_name


	if nation_owner != null:
		owner_label.text = "🏁 Controlled by: " + nation_owner.name
		owner_label.add_theme_color_override("font_color", nation_owner.color)
	else:
		owner_label.text = "🏁 Controlled by: Unowned"
		owner_label.add_theme_color_override("font_color", Color.WHITE)


	extra_info_label.text = "📊 Population: " + str(population) + \
		"\n🛢️ Oil: " + str(oil) + \
		"\n💰 GDP: " + str(gdp) + " billion USD"


	visible = true
	modulate.a = 0.0  # start transparent
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)  # fade in over 0.3s
	call_deferred("move_to_center_safe")  # ensure viewport is ready




func hide_panel():
	var main: Node2D = $"../.."
	main.fade_out_highlight()
	# Create a tween for fade-out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)  # 0.3s fade
	tween.tween_callback(func():
		visible = false
		modulate.a = 1.0  # reset for next show
	)




# --- Center the panel safely ---
func move_to_center_safe():
	if not is_inside_tree():
		return
	var viewport_size = get_viewport().get_visible_rect().size
	position = (viewport_size - size) / 2  # use 'size', not 'rect_size'




# --- Dragging logic ---
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if get_global_rect().has_point(get_global_mouse_position()):
					dragging = true
					drag_offset = get_global_mouse_position() - global_position
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset


#---- Updates Population
func update_population(new_population: int):
	# Split the text into an Array of Strings
	var lines: Array = extra_info_label.text.split("\n")
	
	# Update the first line (Population)
	if lines.size() >= 1:
		lines[0] = "📊 Population: " + str(new_population)
	
	# Join lines manually
	extra_info_label.text = ""
	for i in range(lines.size()):
		extra_info_label.text += lines[i]
		if i < lines.size() - 1:
			extra_info_label.text += "\n"
