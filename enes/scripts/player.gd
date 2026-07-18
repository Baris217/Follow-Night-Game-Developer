extends CharacterBody2D

# 1. Durumlarımızı (State) tanımlıyoruz
enum State { IDLE, WALK, RUN, JUMP }
var current_state = State.IDLE

# Hollow Knight tarzı keskin hareket değerleri
const WALK_SPEED = 150.0
const RUN_SPEED = 300.0
const JUMP_VELOCITY = -450.0

# Godot'nun varsayılan yerçekimini alıyoruz
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Yerçekimi her durumda geçerli
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. State Machine Kontrolcüsü
	match current_state:
		State.IDLE:
			idle_state()
		State.WALK:
			walk_state()
		State.RUN:
			run_state()
		State.JUMP:
			jump_state()

	move_and_slide()

# --- DURUM FONKSİYONLARI ---

func idle_state():
	# Keskin duruş
	velocity.x = move_toward(velocity.x, 0, RUN_SPEED)

	# Durum Geçişleri
	if Input.is_action_just_pressed("jump") and is_on_floor():
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

	# Yürürken koşmaya veya zıplamaya geçiş
	if Input.is_action_pressed("run"):
		current_state = State.RUN
	if Input.is_action_just_pressed("jump") and is_on_floor():
		start_jump()

func run_state():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * RUN_SPEED
	else:
		current_state = State.IDLE

	# Koşuyu bırakıp yürümeye veya zıplamaya geçiş
	if not Input.is_action_pressed("run"):
		current_state = State.WALK
	if Input.is_action_just_pressed("jump") and is_on_floor():
		start_jump()

func jump_state():
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Havadayken koşma tuşuna basılıp basılmadığına göre hızı belirliyoruz
	var current_air_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED

	if direction:
		# Havada belirlenen güncel hıza göre hareket et
		velocity.x = direction * current_air_speed 
	else:
		# Tuşu bırakınca yine o hıza orantılı olarak yavaşla
		velocity.x = move_toward(velocity.x, 0, current_air_speed)

	# Hollow Knight Zıplama Mekaniği (Tuşu erken bırakırsan alçak zıplar)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5 

	# Yere değdiğimizde diğer durumlara dön
	if is_on_floor():
		if direction != 0:
			current_state = State.RUN if Input.is_action_pressed("run") else State.WALK
		else:
			current_state = State.IDLE

# Zıplamayı başlatan yardımcı fonksiyon
func start_jump():
	velocity.y = JUMP_VELOCITY
	current_state = State.JUMP
