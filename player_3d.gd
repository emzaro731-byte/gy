extends CharacterBody3D

var speed := 5.8
var sprint_speed := 8.0
var health := 100.0
var max_health := 100.0
var ammo := 30
var reserve_ammo := 120
var fire_timer := 0.0
var reload_timer := 0.0
var alive := true
var gravity := 18.0
var camera: Camera3D
var game: Node
var touch_move := Vector2.ZERO

func setup(owner_game: Node) -> void:
    game = owner_game
    camera = Camera3D.new()
    camera.position = Vector3(0, 2.4, 5.4)
    camera.rotation_degrees = Vector3(-9, 0, 0)
    camera.current = true
    add_child(camera)

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.height = 1.55
    capsule.radius = 0.38
    body.mesh = capsule
    body.position.y = 0.9
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#26374a")
    mat.metallic = 0.08
    mat.roughness = 0.68
    body.material_override = mat
    add_child(body)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.29
    sphere.height = 0.58
    head.mesh = sphere
    head.position = Vector3(0, 1.78, 0)
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color("#b98262")
    skin.roughness = 0.9
    head.material_override = skin
    add_child(head)

func _physics_process(delta: float) -> void:
    if not alive:
        return
    fire_timer = max(0.0, fire_timer - delta)
    if reload_timer > 0.0:
        reload_timer -= delta
        if reload_timer <= 0.0:
            var need: int = 30 - ammo
            var take: int = min(need, reserve_ammo)
            ammo += take
            reserve_ammo -= take

    var input := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input.y += 1.0
    if touch_move.length() > 0.0: input = touch_move
    var dir := Vector3(input.x, 0, input.y)
    if dir.length() > 0.0:
        dir = dir.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        if Input.is_key_pressed(KEY_SHIFT):
            velocity.x = dir.x * sprint_speed
            velocity.z = dir.z * sprint_speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0, speed * 8.0 * delta)
    if not is_on_floor(): velocity.y -= gravity * delta
    else: velocity.y = -0.2
    move_and_slide()

func shoot(direction: Vector3) -> bool:
    if not alive or ammo <= 0 or fire_timer > 0.0 or reload_timer > 0.0: return false
    ammo -= 1
    fire_timer = 0.105
    if game: game.player_shot(global_position + Vector3.UP * 1.45, direction)
    return true

func reload() -> void:
    if alive and reload_timer <= 0.0 and ammo < 30 and reserve_ammo > 0: reload_timer = 1.35

func damage(amount: float) -> void:
    if not alive: return
    health = max(0.0, health - amount)
    if health <= 0.0:
        alive = false
        velocity = Vector3.ZERO

func heal(amount: float) -> void:
    health = min(max_health, health + amount)
