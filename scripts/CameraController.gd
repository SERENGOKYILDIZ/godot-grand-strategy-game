class_name CameraController extends Object

#--- Camera Variables
var camera: Camera2D
var pan_speed: float = 400.0
var zoom_smooth: float = 0.1
var zoom_speed: float = 0.1
var zoom_min: float = 0.5
var zoom_max: float = 2.0

# --- Allows us to make the zoom smoother 
var target_zoom: Vector2

# --- Initialize with camera reference ---
func _init(cam: Camera2D):
	camera = cam
	target_zoom = camera.zoom

# --- Exactly the same from Main, just moved here
func handle_movement(delta: float):
	var move_dir = Vector2.ZERO
	if Input.is_action_pressed("map_move_up"):
		move_dir.y -= 2
	if Input.is_action_pressed("map_move_down"):
		move_dir.y += 2
	if Input.is_action_pressed("map_move_left"):
		move_dir.x -= 2
	if Input.is_action_pressed("map_move_right"):
		move_dir.x += 2


	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		camera.position += move_dir * pan_speed * delta

# --- Zoom is moved from Main Function _unhandled_input
func handle_zoom(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom += Vector2(zoom_speed, zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom -= Vector2(zoom_speed, zoom_speed)


		target_zoom.x = clamp(target_zoom.x, zoom_min, zoom_max)
		target_zoom.y = clamp(target_zoom.y, zoom_min, zoom_max)

# --- Smooth zoom interpolation ---
func apply_smoothing():
	camera.zoom = camera.zoom.lerp(target_zoom, zoom_smooth)
