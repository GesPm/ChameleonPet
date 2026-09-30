extends Node2D

var speed = 300.0
var direction = Vector2(1, 0)
var screen_size = Vector2()
var window_size = Vector2(64, 64)

var idle_timer = 0.0
var is_idling = false
var walk_timer = 0.0

var is_dragging = false
var drag_offset = Vector2()

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D 

var window_position: Vector2

func _ready() -> void: 
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("walk")
	area.input_event.connect(_on_area_input)
	window_position = Vector2(DisplayServer.window_get_position())
	window_position.x = clamp(window_position.x, 0, screen_size.x - window_size.x)
	window_position.y = clamp(window_position.y, 0, screen_size.y - window_size.y)

func maybe_idle():
	if randf() < 0.2:
		is_idling = true
		idle_timer = randf_range(2.0, 4.0)
		animated_sprite.play("idle")
		speed = 0.0

func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			is_dragging = false

func _physics_process(delta: float) -> void:
	if is_dragging: 
		var mouse_pos = Vector2(DisplayServer.mouse_get_position())
		window_position = mouse_pos - drag_offset 
		DisplayServer.window_set_position(Vector2i(window_position))
		return
	
	if is_idling:
		idle_timer -= delta
		if idle_timer <= 0:
			is_idling = false
			speed = 300.0
			animated_sprite.play("walk")
		return

	walk_timer += delta
	if walk_timer >= 2.5:
		walk_timer = 0.0
		maybe_idle()
			
	window_position += direction * speed * delta
	
	
	if window_position.x <= 0 and direction.x < 0:
		direction.x *= -1
		animated_sprite.flip_h = !animated_sprite.flip_h
		window_position.x = 0.0
	elif window_position.x >= screen_size.x - window_size.x and direction.x > 0:
		direction.x *= -1
		animated_sprite.flip_h = !animated_sprite.flip_h
		window_position.x = screen_size.x - window_size.x
		
	
	if window_position.y <= 0 and direction.y < 0:
		direction.y *= -1
		window_position.y = 0.0
	elif window_position.y >= screen_size.y - window_size.y and direction.y > 0:
		direction.y *= -1
		window_position.y = screen_size.y - window_size.y
		
	DisplayServer.window_set_position(Vector2i(window_position))
