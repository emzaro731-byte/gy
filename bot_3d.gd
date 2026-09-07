extends CharacterBody3D

var target: Node3D
var health := 100.0
var alive := true
var speed := 3.6
var fire_timer := 0.0
var game: Node
var rng := RandomNumberGenerator.new()
var rig: Node3D
var head: Node3D
var torso: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var t := 0.0

func setup(player: Node3D, owner_game: Node) -> void:
    target = player
    game = owner_game
    rng.randomize()
    _build_robot()

func _mat(c: Color, metal := 0.0, rough := 0.5, glow := Color.TRANSPARENT) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    if glow.a > 0.0:
        m.emission_enabled = true
        m.emission = glow
        m.emission_energy_multiplier = 2.5
    return m

func _box(p: Node3D, s: Vector3, at: Vector3, m: Material) -> Node3D:
    var n := MeshInstance3D.new()
    var x := BoxMesh.new()
    x.size = s
    n.mesh = x
    n.position = at
    n.material_override = m
    p.add_child(n)
    return n

func _sphere(p: Node3D, r: float, at: Vector3, m: Material) -> Node3D:
    var n := MeshInstance3D.new()
    var x := SphereMesh.new()
    x.radius = r
    x.height = r * 2.0
    n.mesh = x
    n.position = at
    n.material_override = m
    p.add_child(n)
    return n

func _build_robot() -> void:
    rig = Node3D.new()
    rig.position.y = 0.05
    add_child(rig)
    var armor := _mat(Color("#46515a"), 0.85, 0.25)
    var dark := _mat(Color("#10171d"), 0.95, 0.18)
    var edge := _mat(Color("#9aa4aa"), 0.9, 0.18)
    var joint := _mat(Color("#050709"), 1.0, 0.12)
    var gold := _mat(Color("#c79c45"), 0.7, 0.25)
    var eye := _mat(Color("#c7fbff"), 0.1, 0.1, Color("#28dfff"))
    torso = Node3D.new()
    torso.position.y = 1.05
    rig.add_child(torso)
    _box(torso, Vector3(1.0, 1.1, 0.58), Vector3.ZERO, armor)
    _box(torso, Vector3(0.68, 0.38, 0.62), Vector3(0,0.25,-0.04), dark)
    _box(torso, Vector3(0.13,0.65,0.64), Vector3(-0.4,0,-0.03), edge)
    _box(torso, Vector3(0.13,0.65,0.64), Vector3(0.4,0,-0.03), edge)
    _box(torso, Vector3(0.3,0.12,0.62), Vector3(0,-0.37,-0.03), gold)
    head = Node3D.new()
    head.position.y = 1.82
    rig.add_child(head)
    _box(head, Vector3(0.66,0.55,0.55), Vector3.ZERO, dark)
    _box(head, Vector3(0.54,0.19,0.06), Vector3(0,0.02,-0.31), eye)
    _box(head, Vector3(0.12,0.43,0.09), Vector3(-0.34,0,0), edge)
    _box(head, Vector3(0.12,0.43,0.09), Vector3(0.34,0,0), edge)
    _sphere(head, 0.045, Vector3(0,0.34,0), gold)
    arm_l = _limb(-1.0, armor, dark, joint, edge)
    arm_r = _limb(1.0, armor, dark, joint, edge)
    leg_l = _leg(-1.0, armor, dark, joint, edge)
    leg_r = _leg(1.0, armor, dark, joint, edge)
    var pack := Node3D.new()
    pack.position = Vector3(0,1.05,0.34)
    rig.add_child(pack)
    _box(pack, Vector3(0.5,0.62,0.18), Vector3.ZERO, dark)
    _box(pack, Vector3(0.28,0.18,0.04), Vector3(0,0.05,0.1), gold)

func _limb(side: float, armor: Material, dark: Material, joint: Material, edge: Material) -> Node3D:
    var n := Node3D.new()
    n.position = Vector3(0.65*side,1.42,0)
    rig.add_child(n)
    _sphere(n,0.16,Vector3.ZERO,joint)
    _box(n,Vector3(0.3,0.5,0.36),Vector3(0,-0.25,0),armor)
    _sphere(n,0.13,Vector3(0,-0.54,0),joint)
    _box(n,Vector3(0.25,0.46,0.32),Vector3(0,-0.79,0),dark)
    _box(n,Vector3(0.28,0.12,0.36),Vector3(0,-1.03,-0.03),edge)
    return n

func _leg(side: float, armor: Material, dark: Material, joint: Material, edge: Material) -> Node3D:
    var n := Node3D.new()
    n.position = Vector3(0.3*side,0.5,0)
    rig.add_child(n)
    _sphere(n,0.17,Vector3.ZERO,joint)
    _box(n,Vector3(0.35,0.56,0.4),Vector3(0,-0.31,0),armor)
    _sphere(n,0.14,Vector3(0,-0.64,0),joint)
    _box(n,Vector3(0.32,0.6,0.36),Vector3(0,-0.96,0),dark)
    _box(n,Vector3(0.44,0.16,0.64),Vector3(0,-1.3,-0.1),edge)
    return n

func _physics_process(delta: float) -> void:
    if not alive or not is_instance_valid(target):
        return
    t += delta
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
    var walking := Vector2(velocity.x, velocity.z).length() > 0.4
    var swing := sin(t * 8.0) * 0.4 if walking else 0.0
    if arm_l: arm_l.rotation.x = -swing * 0.55
    if arm_r: arm_r.rotation.x = swing * 0.55
    if leg_l: leg_l.rotation.x = swing
    if leg_r: leg_r.rotation.x = -swing
    if torso: torso.position.y = 1.05 + sin(t * 16.0) * 0.015 if walking else 1.05
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
