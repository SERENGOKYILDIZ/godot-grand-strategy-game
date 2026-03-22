extends Node2D

@onready var map_sprite: Sprite2D = $Map 		# 	Tam harita

# --> Data Mappings
var color_to_region : Dictionary = {} 			# 16'lık piksel renklerini bölge adları ile işler
var region_masks : Dictionary = {} 				# dokuları vurgulayan maskeler (PNG)

# --> Highlight Sprites
var highlight_sprite : Sprite2D 				# Anlık bölge vurgusu
var highlight_sprite_old : Sprite2D 			# Önceki bölge vurgusu

# --> Fade Settings
var fade_duration: float = 0.5 					# Saniye cinsinden geçiş süresi

func _ready() -> void:
	load_region_data() 							# jsondaki verileri yükler 
	load_region_masks() 						# mask verilerini yükler
	
	highlight_sprite = Sprite2D.new()
	add_child(highlight_sprite)
	highlight_sprite.visible = false
	highlight_sprite.z_index = 10 				# İndex'ini yukarı taşımak için
	
	highlight_sprite_old = Sprite2D.new()
	add_child(highlight_sprite_old)
	highlight_sprite_old.visible = false
	highlight_sprite_old.z_index = 9 			# Normalin hemen arkasında olacak
	
func load_region_data() -> void:
	var file = FileAccess.open("res://scripts/Regions.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json_dict = JSON.parse_string(text)
		if typeof(json_dict) == TYPE_DICTIONARY:
			color_to_region = json_dict
			print("✅ Bölgeler yüklendi: ", color_to_region.size())
		else:
			push_error("❌ Bölgeler okunamadı!")
		file.close()
		
func load_region_masks() -> void:
	var dir_path = "res://pictures/RegionHighlights/"
	var dir = DirAccess.open(dir_path)
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".png"):
				var region_name = file_name.get_basename()
				var texture_path = dir_path + file_name
				region_masks[region_name] = load(texture_path)
		print("✅ Bölge Kaplamaları yüklendi: ", region_masks.size())
	else:
		push_error("❌ Bölgeler Kaplamaları okunamadı!")

func _unhandled_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_pos = map_sprite.to_local(event.position)
		var tex_size = map_sprite.texture.get_size()
		var pivot_offset = tex_size / 2 if map_sprite.centered else Vector2()
		
		var pixel_pos = local_pos + pivot_offset
		pixel_pos.x = clamp(pixel_pos.x, 0, tex_size.x - 1)
		pixel_pos.y = clamp(pixel_pos.y, 0, tex_size.y - 1)
		pixel_pos = Vector2i(pixel_pos)
		
		var img: Image = map_sprite.texture.get_image()
		var pixel_color: Color = img.get_pixelv(pixel_pos)
		var hex_color = "#" + pixel_color.to_html(false).strip_edges()
		
		if hex_color in color_to_region:
			var region_name = color_to_region[hex_color]
			print("✵ Clicked region: ", region_name)
			show_highlight(region_name)
		else:
			print("? Bilinmeyen renk: ", hex_color)
			fade_out_highlight()
			
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
		tween_out.tween_property(highlight_sprite_old, "modulate:a", 0.0, fade_duration)
		tween_out.tween_callback(highlight_sprite_old.hide)
		
		highlight_sprite.visible = false
		
