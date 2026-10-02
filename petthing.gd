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
var last_mouse_pos = Vector2()
var throw_velocity = Vector2()

var is_thrown = false
var bounce_count = 0
var max_bounces = 2
var rotation_speed = 12.0

var current_bezel = "bottom"

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D 

var window_position: Vector2

func _ready() -> void: 
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("walk")
	area.input_event.connect(_on_area_input)
	
	window_position = Vector2(DisplayServer.window_get_position())
	
	snap_to_nearest_bezel()
	

func maybe_idle():
	if randf() < 0.35:
		is_idling = true
		idle_timer = randf_range(2.0, 4.0)
		animated_sprite.play("idle")
		speed = 0.0
		
func land_and_idle():
	is_thrown = false
	is_idling = true
	idle_timer = 3.0
	animated_sprite.play("idle")
	speed = 0.0
	snap_to_nearest_bezel()
	
func snap_to_nearest_bezel():
	var dist_bottom = abs ((screen_size.y - window_size.y) -  window_position.y)
	var dist_top = abs(window_position.y)
	var dist_left = abs(window_position.x)
	var dist_right = abs((screen_size.x - window_size.x) - window_position.x)
	
	var min_dist = min(dist_bottom, min(dist_top, min (dist_left, dist_right )))
	
	if min_dist == dist_bottom:
		current_bezel = "bottom"
		window_position.y = screen_size.y - window_size.y
		direction = Vector2(-1,0) if randf() > 0.5 else Vector2(1,0)
	elif min_dist == dist_top:
		current_bezel = "top"
		window_position.y = 0.0
		direction = Vector2(1,0) if randf() > 0.5 else Vector2(-1,0)
	elif min_dist == dist_left:
		current_bezel = "left"
		window_position.x = 0.0
		direction = Vector2(0,1) if randf() > 0.5 else Vector2(0,-1)
	else:
		current_bezel = "right"
		window_position.x = screen_size.x - window_size.x
		direction = Vector2(0,1) if randf() > 0.5 else Vector2(0,-1)
		
	update_sprite_orientation()
	
func update_sprite_orientation():
		if is_thrown or is_dragging:
			return
			
		match current_bezel:
			"bottom":
				animated_sprite.rotation = 0.0
				animated_sprite.flip_h = (direction.x < 0)
			"top":
				animated_sprite.rotation = PI
				animated_sprite.flip_h = (direction.x > 0)
			"left":
				animated_sprite.rotation = PI / 2.0
				animated_sprite.flip_h = (direction.y < 0)
			"right":
				animated_sprite.rotation = -PI / 2.0
				animated_sprite.flip_h = (direction.y > 0)
		
func start_throw():
	if throw_velocity.length() > 60.0:
		is_thrown = true
		is_idling = false
		current_bezel = "floating"
		bounce_count = 0
		max_bounces = randi_range(1,2)
		speed = clamp(throw_velocity.length(),400.0, 900.0 )
		direction = throw_velocity.normalized()
		animated_sprite.play('flail')
	else:
		land_and_idle()
		
func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			current_bezel = "floating"
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
			last_mouse_pos = mouse_pos

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_dragging:
			is_dragging = false
			start_throw()
			
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			throw_velocity = Vector2(randf_range(-500,500), -600)
			start_throw()

func _physics_process(delta: float) -> void:
	if is_dragging: 
		var current_mouse_pos = Vector2(DisplayServer.mouse_get_position())
		if delta > 0:
			throw_velocity = (current_mouse_pos - last_mouse_pos) / delta
		last_mouse_pos = current_mouse_pos
		
		window_position = current_mouse_pos - drag_offset 
		DisplayServer.window_set_position(Vector2i(window_position))
		return
	
	if is_thrown:
		animated_sprite.rotation += rotation_speed * delta
		window_position += direction * speed * delta
		
		var hit_border = false
		
		if window_position.x <= 0 and direction.x < 0:
			direction.x *= -1
			window_position.x = 0
			hit_border = true
		elif window_position.x >= screen_size.x - window_size.x and direction.x > 0:
			direction.x *= -1
			window_position.x = screen_size.x - window_size.x 
			hit_border = true
			
		if window_position.y <= 0 and direction.y < 0:
			direction.y*= -1
			window_position.y = 0
			hit_border = true
		elif window_position.y >= screen_size.y - window_size.y and direction.y > 0:
			direction.y *= -1
			window_position.y = screen_size.y - window_size.y
			hit_border = true
		
		if hit_border:
			bounce_count += 1
			if bounce_count >= max_bounces:
				land_and_idle()
				return
				
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
	if walk_timer >= 4.0:
		walk_timer = 0.0
		maybe_idle()
			
	window_position += direction * speed * delta
	
	if current_bezel == "bottom" or current_bezel == "top":
		if window_position.x <= 0 and direction.x < 0:
			direction.x *= -1
			window_position.x = 0.0
			update_sprite_orientation()
		elif window_position.x >= screen_size.x - window_size.x and direction.x > 0:
			direction.x *= -1
			window_position.x = screen_size.x - window_size.x
			update_sprite_orientation()
	elif current_bezel == "left" or current_bezel == "right":
		if window_position.y <= 0 and direction.y < 0:
			direction.y *= -1
			window_position.y = 0.0
			update_sprite_orientation()
		elif window_position.y >= screen_size.y - window_size.y and direction.y > 0:
			direction.y *= -1
			window_position.y = screen_size.y - window_size.y
			update_sprite_orientation()
		
	DisplayServer.window_set_position(Vector2i(window_position))
