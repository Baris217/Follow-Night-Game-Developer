extends CharacterBody2D

enum State { IDLE, WALK, RUN, JUMP, LEDGE_GRAB, WALL_SLIDE }
var current_state = State.IDLE

const WALK_SPEED = 150.0
const RUN_SPEED = 300.0
const JUMP_VELOCITY = -450.0
const DOUBLE_JUMP_VELOCITY = -400.0

# --- DUVAR MEKANİĞİ AYARLARI ---
const WALL_SLIDE_SPEED = 80.0 
const WALL_JUMP_PUSH = 400.0  
const WALL_JUMP_LOCK_TIME = 0.2 # Duvardan zıpladıktan sonra tuşların kilitli kalacağı süre
var wall_jump_lock_timer = 0.0 # Geri sayım sayacımız
# -------------------------------

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_double_jump = true 
var facing_direction = 1 

@onready var top_ray = $TopRay
@onready var bottom_ray = $BottomRay

func _physics_process(delta):
	if wall_jump_lock_timer > 0:
		wall_jump_lock_timer -= delta

	if current_state != State.LEDGE_GRAB:
		if not is_on_floor():
			velocity.y += gravity * delta
			
			if current_state == State.WALL_SLIDE:
				velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		else:
			can_double_jump = true 
			
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			facing_direction = sign(direction)
			top_ray.target_position.x = 20 * facing_direction
			bottom_ray.target_position.x = 20 * facing_direction

	match current_state:
		State.IDLE:
			idle_state()
		State.WALK:
			walk_state()
		State.RUN:
			run_state()
		State.JUMP:
			jump_state()
		State.LEDGE_GRAB:
			ledge_grab_state()
		State.WALL_SLIDE:
			wall_slide_state()

	move_and_slide()

# durum fonksiyonları

func idle_state():
	velocity.x = move_toward(velocity.x, 0, RUN_SPEED)

	if not is_on_floor():
		current_state = State.JUMP
	elif Input.is_action_just_pressed("jump"):
		start_jump()
	elif Input.get_axis("ui_left", "ui_right") != 0:
		if Input.is_action_pressed("run"): 
			current_state = State.RUN
		else:
			current_state = State.WALK

func walk_state():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * WALK_SPEED
	else:
		current_state = State.IDLE

	if not is_on_floor():
		current_state = State.JUMP
	elif Input.is_action_pressed("run"):
		current_state = State.RUN
	elif Input.is_action_just_pressed("jump"):
		start_jump()

func run_state():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * RUN_SPEED
	else:
		current_state = State.IDLE

	if not is_on_floor():
		current_state = State.JUMP
	elif not Input.is_action_pressed("run"):
		current_state = State.WALK
	elif Input.is_action_just_pressed("jump"):
		start_jump()

func jump_state():
	var direction = Input.get_axis("ui_left", "ui_right")
	var current_air_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED

	# Eğer kilit süresi bittiyse oyuncu yönü belirleyebilir
	if wall_jump_lock_timer <= 0:
		if direction:
			velocity.x = direction * current_air_speed 
		else:
			velocity.x = move_toward(velocity.x, 0, current_air_speed)


	if velocity.y > 0 and direction != 0:
		if bottom_ray.is_colliding() and not top_ray.is_colliding():
			current_state = State.LEDGE_GRAB
			can_double_jump = true 
			return 

	if is_on_wall() and velocity.y > 0 and direction != 0:
		current_state = State.WALL_SLIDE
		can_double_jump = true 
		return

	if Input.is_action_just_pressed("jump") and can_double_jump:
		velocity.y = DOUBLE_JUMP_VELOCITY
		can_double_jump = false

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5 

	if is_on_floor():
		if direction != 0:
			current_state = State.RUN if Input.is_action_pressed("run") else State.WALK
		else:
			current_state = State.IDLE

func ledge_grab_state():
	velocity = Vector2.ZERO 
	
	if Input.is_action_just_pressed("ui_down"):
		current_state = State.JUMP
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY * 0.8 
		velocity.x = facing_direction * WALK_SPEED 
		current_state = State.JUMP

func wall_slide_state():
	var direction = Input.get_axis("ui_left", "ui_right")
	var wall_normal = get_wall_normal().x 
	
	if Input.is_action_just_pressed("jump"):
		velocity.x = wall_normal * WALL_JUMP_PUSH
		velocity.y = JUMP_VELOCITY
		
	
		wall_jump_lock_timer = WALL_JUMP_LOCK_TIME 
		
		current_state = State.JUMP
		return
		
	if direction == 0 or not is_on_wall():
		current_state = State.JUMP
		
	if is_on_floor():
		current_state = State.IDLE

func start_jump():
	velocity.y = JUMP_VELOCITY
	current_state = State.JUMP
