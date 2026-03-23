extends Node2D
# --- Nodes ---
@onready var map_sprite = $Map
@onready var camera = $Camera2D


# --- Camera Controller Variable ---
var camera_controller: CameraController
@onready var ownership_layer = $OwnershipLayer


# --- Highlight Sprites ---
var highlight_sprite: Sprite2D
var highlight_sprite_old: Sprite2D
var fade_duration: float = 0.5


# --- Nation Manager ---
var nation_manager = preload("res://scripts/NationManager.gd").new()


# --- Region Data ---
var color_to_region: Dictionary = {} # Hex color -> region name
var region_masks: Dictionary = {}    # region name -> texture


# --- UI Panel ---
@onready var info_panel: RegionInfoPanel = $UI/RegionInfoPanel
@onready var top_bar: TopBar = $UI/TopBar


# --- UI Top Bar
var player_nation_name: String = "France"  # Temporary Player until selection initalised
var player_nation = null


# --- Date Panel
@onready var date_label: Label = $UI/DatePanel/DateLabel
@onready var calendar = $UI/DatePanel  # Attach Calendar.gd to DatePanel


# ArmiesManager node in scene tree
@onready var armies_manager = $ArmiesLayer as ArmiesManager










#--- Game Speed
var accumulated_time: float = 0.0
var tick_interval: float = 1.0  # seconds per tick; smaller = faster population growth


var game_day = 1
var game_month = 1
var game_year = 1
var game_speed = "Slow" # "Slow", "Normal", "Fast" Speeds available




var elapsed_seconds: float =0.0
var is_paused: bool = false






# --- READY FUNCTION "Enables most functions at start"---
func _ready():
	# Load JSON and masks
	load_region_data()
	load_region_masks()
	
	# Initialize NationManager
	nation_manager.create_nations()
	
	# Draw ownership overlays
	show_all_ownership()
	
	# Initialize Camera
	camera_controller = CameraController.new(camera)
	
	# Initialize highlight sprites
	highlight_sprite = Sprite2D.new()
	add_child(highlight_sprite)
	highlight_sprite.visible = false
	highlight_sprite.z_index = 10
	
	highlight_sprite_old = Sprite2D.new()
	add_child(highlight_sprite_old)
	highlight_sprite_old.visible = false
	highlight_sprite_old.z_index = 9
	
	# Set up player nation
	player_nation = nation_manager.nations.get(player_nation_name, null)
	if player_nation == null:
		push_error("❌ Player nation not found: " + player_nation_name)
	else:
		print("✅ Player nation set to:", player_nation.name)
		
	
	nation_manager.region_data = {}
	for key in color_to_region.keys():
		var region_info = color_to_region[key]
		var region_name = region_info.get("name", "Unknown")
		nation_manager.region_data[region_name] = region_info
	
	update_player_resources()
	# --- Start pop growtha t beginning
	for region_name in nation_manager.region_data.keys():
		var region = nation_manager.region_data[region_name]
		region["population_float"] = float(region.get("population", 0))
	
	# --- Putting a test army on Paris ---
	var start_region = "Rize"


	# Get global position of the region center
	var global_pos = get_region_center(start_region)


	# Convert to ArmiesLayer local coordinates
	var army_pos = $ArmiesLayer.to_local(global_pos)


	# Spawn the army
	var army = $ArmiesLayer.spawn_army(army_pos, start_region)
	print("Spawned army at:", army.position)
	
	# Click able spawn army
	armies_manager.main_ref = self


	


# --- LOAD REGION DATA ---
func load_region_data():
	var file = FileAccess.open("res://scripts/Regions.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json_dict = JSON.parse_string(text)
		if typeof(json_dict) == TYPE_DICTIONARY:
			color_to_region.clear()
			for key in json_dict.keys():
				color_to_region[key.to_upper()] = json_dict[key]
			print("✅ Loaded regions:", color_to_region.size())
		else:
			push_error("❌ Failed to parse JSON!")
		file.close()


# --- LOAD REGION MASKS ---
func load_region_masks():
	var dir_path = "res://pictures/RegionHighlights/"
	var dir = DirAccess.open(dir_path)
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".png"):
				var region_name = file_name.get_basename()
				var texture_path = dir_path + file_name
				region_masks[region_name] = load(texture_path)
		print("✅ Loaded region masks:", region_masks.size())
	else:
		push_error("❌ Could not open RegionHighlight folder!")


# --- HANDLE MOUSE INPUT ---
func _unhandled_input(event):
	# --- Zoom handled by CameraController ---
	camera_controller.handle_zoom(event)
	var army_clicked := false
	if event is InputEventMouseButton and event.pressed:
		var world_pos = camera.get_global_mouse_position()
		# --- RIGHT CLICK: select army OR move selected army ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			fade_out_highlight()
			for army in armies_manager.armies:
				var dist = army.global_position.distance_to(world_pos)
				if dist <= 32:
					# Select this army
					if armies_manager.selected_army and armies_manager.selected_army != army:
						armies_manager.selected_army.deselect()
					armies_manager.selected_army = army
					army.select()
					print("Right-clicked army:", army.name)
					army_clicked = true
					break
					
			# --- select region / show panel ---
			if not army_clicked:
				if armies_manager.selected_army != null:
					armies_manager.selected_army.deselect()
					armies_manager.selected_army = null
				var local_pos = map_sprite.to_local(world_pos)
				var tex_size = map_sprite.texture.get_size()
				var pivot_offset = tex_size / 2 if map_sprite.centered else Vector2()
				var pixel_pos = local_pos + pivot_offset
				pixel_pos.x = clamp(pixel_pos.x, 0, tex_size.x - 1)
				pixel_pos.y = clamp(pixel_pos.y, 0, tex_size.y - 1)
				pixel_pos = Vector2i(pixel_pos)


				var pixel_color = map_sprite.texture.get_image().get_pixelv(pixel_pos)
				var hex_color = "#" + pixel_color.to_html(false).to_upper()


				if hex_color in color_to_region:
					var region_info = color_to_region[hex_color]
					var region_name = region_info.get("name", "Unknown")
					show_highlight(region_name)
					var show_panel_owner = nation_manager.get_region_owner(region_name)
					var population = int(region_info.get("population", 0))
					var gdp = int(float(region_info.get("gdp", region_info.get("GDP", 0))))
					var oil = float(region_info.get("oil", 0))
					info_panel.show_panel(region_name, show_panel_owner, population, oil, gdp)
				else:
					print("Unknown color clicked")
					fade_out_highlight()
					info_panel.hide_panel()
		# --- If no army was clicked but one is selected, move it to clicked region ---
		if event.button_index == MOUSE_BUTTON_RIGHT and not army_clicked and armies_manager.selected_army:
			# Determine which region was clicked
			var local_pos = map_sprite.to_local(world_pos)
			var tex_size = map_sprite.texture.get_size()
			var pivot_offset = tex_size / 2 if map_sprite.centered else Vector2()
			var pixel_pos = local_pos + pivot_offset
			pixel_pos.x = clamp(pixel_pos.x, 0, tex_size.x - 1)
			pixel_pos.y = clamp(pixel_pos.y, 0, tex_size.y - 1)
			pixel_pos = Vector2i(pixel_pos)


			var pixel_color = map_sprite.texture.get_image().get_pixelv(pixel_pos)
			var hex_color = "#" + pixel_color.to_html(false).to_upper()


			if hex_color in color_to_region:
				var region_info = color_to_region[hex_color]
				var region_name = region_info.get("name", "Unknown")
				armies_manager.move_selected_army_to_region(region_name)
			else:
				print("Unknown clicked")
				fade_out_highlight()
				info_panel.hide_panel()
				if armies_manager.selected_army != null:
					armies_manager.selected_army.deselect()
					armies_manager.selected_army = null
					
	elif event.is_action_pressed("army_cancel"):
		print("Herseyi kapa")
		fade_out_highlight()
		info_panel.hide_panel()
		if armies_manager.selected_army != null:
			armies_manager.selected_army.deselect()
			armies_manager.selected_army = null















# --- SHOW ALL OWNERSHIP OVERLAYS ---
func show_all_ownership():
	for region_name in nation_manager.region_to_owner.keys():
		var nation = nation_manager.region_to_owner[region_name]
		if region_name in region_masks:
			var ownership_sprite = Sprite2D.new()
			ownership_sprite.texture = region_masks[region_name]
			ownership_sprite.position = map_sprite.position
			ownership_sprite.centered = map_sprite.centered
			ownership_sprite.scale = map_sprite.scale
			ownership_sprite.rotation = map_sprite.rotation
			ownership_sprite.modulate = nation.color
			ownership_sprite.name = region_name
			ownership_sprite.z_index = 5
			ownership_layer.add_child(ownership_sprite)


# --- UPDATE REGION COLOR ---
func update_region_color(region_name: String, new_color: Color):
	for child in ownership_layer.get_children():
		if child.name == region_name:
			child.modulate = new_color
			return




#----Update Region Panel with resources
func show_region_info_by_color(hex_color: String):
	if hex_color in color_to_region:
		var region_info = color_to_region[hex_color]
		var region_name = region_info.get("name", "Unknown")
		var population = int(float(region_info.get("population", 0))) # safe cast
		var gdp = int(float(region_info.get("GDP", 0)))                # already safe
		var oil = float(region_info.get("oil", 0))
		var region_colour_owner = nation_manager.get_region_owner(region_name)
		
		info_panel.show_panel(region_name, region_colour_owner, population, oil, gdp)
##---------------------------------------


# --- Show Panel Function "Moved from top to here at this stage to clear code---
func show_region_info(region_name: String):
	var show_owner = nation_manager.get_region_owner(region_name)
	if show_owner == null:
		print("⚠️ Region has no owner: ", region_name) # Will have no owner as rebel nations but will leave for now
		info_panel.show_panel(region_name, null)       # handle null in the panel
		return


func update_player_resources():
	if player_nation:
		var totals = nation_manager.get_total_resources(player_nation.name)
		top_bar.update_top_bar(player_nation.name, totals.population, totals.oil, totals.gdp)




# --- CAPTURE REGION ---
func capture_region(region_name: String):
	if player_nation == null:
		push_error("❌ Player nation not set, cannot capture region")
		return


	var new_owner = player_nation
	nation_manager.change_region_owner(region_name, new_owner)
	update_region_color(region_name, new_owner.color)
	


func set_game_speed(speed: String):
	game_speed = speed
	is_paused = speed == "Pause"






#------------------------------
#--- Enable Buttons for set_game_speed
func on_fast_button_pressed():
	set_game_speed("Fast")


func on_normal_button_pressed():
	set_game_speed("Normal")


func on_slow_button_pressed():
	set_game_speed("Slow")


func on_pause_button_pressed():
	set_game_speed("Pause")
#-----


# --- Speed multipliers in days per tick
var speed_multiplier_map = {
	"Fast": 3.0,    # advance 10 days per tick
	"Normal": 2.0,   # advance 1 day per tick
	"Slow": 1.0,     # advance 0.1 days per tick
	"Pause": 0.0
}


# --- Increment Timer
func _on_GameTimer_timeout():
	if is_paused:
		return


	# --- Get multiplier for current speed ---
	var days_elapsed = speed_multiplier_map.get(game_speed, 1.0)


	# --- Update calendar ---
	calendar.add_days(int(days_elapsed))


	# --- Update population based on actual days elapsed ---
	increase_population_per_day(days_elapsed)








# --- Function for increasing Population based on time


func increase_population_per_day(days_elapsed: float):
	for region_name in nation_manager.region_data.keys():
		var region = nation_manager.region_data[region_name]


		# Initialize float population if not exists
		if not region.has("population_float"):
			region["population_float"] = float(region.get("population", 0))


		# --- Daily growth rate applied to actual days elapsed ---
		var yearly_growth_rate = 0.001            # 10% per year
		var daily_growth_rate = yearly_growth_rate / 360.0


		region["population_float"] *= pow(1 + daily_growth_rate, days_elapsed)
		region["population"] = int(region["population_float"])  # for TopBar / panel


	# --- Update TopBar for player nation ---
	if player_nation:
		var totals = nation_manager.get_total_resources(player_nation.name)
		top_bar.update_top_bar(player_nation.name, totals.population, totals.oil, totals.gdp)


	# --- Update RegionInfoPanel if visible ---
	if info_panel.visible:
		var region_info = nation_manager.region_data.get(info_panel.current_region_name, null)
		if region_info:
			info_panel.update_population(region_info["population"])








# --- HIGHLIGHT FUNCTIONS ---
func show_highlight(region_name: String):
	if region_name in region_masks:
		if highlight_sprite.visible:
			highlight_sprite_old.texture = highlight_sprite.texture
			highlight_sprite_old.position = highlight_sprite.position
			highlight_sprite_old.centered = highlight_sprite.centered
			highlight_sprite_old.scale = highlight_sprite.scale
			highlight_sprite_old.rotation = highlight_sprite.rotation
			highlight_sprite_old.visible = true
			highlight_sprite_old.modulate.a = highlight_sprite.modulate.a
			
			var tween_out = highlight_sprite_old.create_tween()
			tween_out.tween_property(highlight_sprite_old, "modulate:a", 0.0, fade_duration)
			tween_out.tween_callback(highlight_sprite_old.hide)
		
		highlight_sprite.texture = region_masks[region_name]
		highlight_sprite.position = map_sprite.position
		highlight_sprite.centered = map_sprite.centered
		highlight_sprite.scale = map_sprite.scale
		highlight_sprite.rotation = map_sprite.rotation
		highlight_sprite.modulate.a = 0.0
		highlight_sprite.visible = true
		
		var tween_in = highlight_sprite.create_tween()
		tween_in.tween_property(highlight_sprite, "modulate:a", 1.0, fade_duration)
	else:
		fade_out_highlight()


func fade_out_highlight(duration: float = fade_duration):
	if highlight_sprite.visible:
		highlight_sprite_old.texture = highlight_sprite.texture
		highlight_sprite_old.position = highlight_sprite.position
		highlight_sprite_old.centered = highlight_sprite.centered
		highlight_sprite_old.scale = highlight_sprite.scale
		highlight_sprite_old.rotation = highlight_sprite.rotation
		highlight_sprite_old.visible = true
		highlight_sprite_old.modulate.a = highlight_sprite.modulate.a
		
		var tween_out = highlight_sprite_old.create_tween()
		tween_out.tween_property(highlight_sprite_old, "modulate:a", 0.0, duration)
		tween_out.tween_callback(highlight_sprite_old.hide)
		
		highlight_sprite.visible = false


#--- date label function
func update_date_label():
	# Format the date as Day / Month / Year
	date_label.text = "Day: %d  Month: %d  Year: %d" % [game_day, game_month, game_year]






# --- CAMERA MOVEMENT ---
# Camera code moved to CameraController.gd
# Physics process still here to grab movement and smoothing functions
func _physics_process(delta):
	camera_controller.handle_movement(delta)
	camera_controller.apply_smoothing()


	# --- Game timer logic for population growth ---
	accumulated_time += delta
	if accumulated_time >= tick_interval:
		accumulated_time = 0.0
		_on_GameTimer_timeout()




func get_region_center(region_name: String) -> Vector2:
	for region_info in color_to_region.values():
		if region_info.get("name") == region_name:
			var center_data = region_info["center"]
			if center_data.size() == 2:
				var center = Vector2(center_data[0], center_data[1])
				var tex_size = map_sprite.texture.get_size()
				var pivot_offset = tex_size / 2 if map_sprite.centered else Vector2()
				return map_sprite.position - pivot_offset * map_sprite.scale + center * map_sprite.scale
	return Vector2.ZERO
