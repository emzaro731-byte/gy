extends CharacterBody3D

var target: Node3D
var health := 70.0
var alive := true
var speed := 3.2
var fire_timer := 0.0
var game: Node
var rng := RandomNumberGenerator.new()

func setup(player: Node3D, owner_game: Node) -> void:
    target = player
    game = owner_game
    rng.randomize()
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.height = 1.55
    capsule.radius = 0.38
    body.mesh = capsule
    body.position.y = 0.9
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#7b3035")
    mat.roughness = 0.82
    body.material_override = mat
    add_child(body)
    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.29
    sphere.height = 0.58
    head.mesh = sphere
    head.position.y = 1.78
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color("#9c654d")
    skin.roughness = 0.9
    head.material_override = skin
    add_child(head)

func _physics_process(delta: float) -> void:
    if not alive or not is_instance_valid(target):
        return
    fire_timer = max(0.0, fire_timer - delta)
    var to_target := target.global_position - global_position
    to_target.y = 0
    var distance := to_target.length()
    if distance > 13.0:
        var dir := to_target.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        look_at(global_position + dir, Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0, speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0, speed * 5.0 * delta)
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = -0.2
    move_and_slide()
    if distance < 32.0 and fire_timer <= 0.0:
        fire_timer = 0.75 + rng.randf_range(0.0, 0.55)
        var aim := (target.global_position + Vector3.UP * 1.1 - (global_position + Vector3.UP * 1.2)).normalized()
        if game:
            game.bot_shot(global_position + Vector3.UP * 1.2, aim)

func damage(amount: float) -> void:
    if not alive:
        return
    health = max(0.0, health - amount)
    if health <= 0.0:
        alive = false
        queue_free()
