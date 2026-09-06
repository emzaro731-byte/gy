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
var yaw := 0.0
var pitch := -0.12
var camera: Camera3D
var muzzle: MeshInstance3D
var game: Node

func setup(owner_game: Node) -> void:
    game = owner_game
    camera = Camera3D.new()
    camera.position = Vector3(0, 2.2, 5.2)
    camera.rotation_degrees = Vector3(-7, 0, 0)
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
    mat.roughness = 0.72
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
            var need := 30 - ammo
            var take := min(need, reserve_ammo)
            ammo += take
            reserve_ammo -= take

    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := Vector3(input.x, 0, input.y)
    if dir.length() > 0.0:
        dir = dir.normalized()
        var basis_dir := global_transform.basis * dir
        basis_dir.y = 0
        basis_dir = basis_dir.normalized()
        velocity.x = basis_dir.x * speed
        velocity.z = basis_dir.z * speed
        if Input.is_key_pressed(KEY_SHIFT):
            velocity.x = basis_dir.x * sprint_speed
            velocity.z = basis_dir.z * sprint_speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0, speed * 8.0 * delta)

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2
    move_and_slide()

func shoot(direction: Vector3) -> bool:
    if not alive or ammo <= 0 or fire_timer > 0.0 or reload_timer > 0.0:
        return false
    ammo -= 1
    fire_timer = 0.105
    if game:
        game.player_shot(global_position + Vector3.UP * 1.45, direction)
    return true

func reload() -> void:
    if alive and reload_timer <= 0.0 and ammo < 30 and reserve_ammo > 0:
        reload_timer = 1.35

func damage(amount: float) -> void:
    if not alive:
        return
    health = max(0.0, health - amount)
    if health <= 0.0:
        alive = false
        velocity = Vector3.ZERO

func heal(amount: float) -> void:
    health = min(max_health, health + amount)
