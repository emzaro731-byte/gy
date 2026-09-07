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
var weapon: Node3D
var muzzle: OmniLight3D
var t := 0.0
var strafe_sign := 1.0
var strafe_timer := 0.0
var hit_flash := 0.0

func setup(player: Node3D, owner_game: Node) -> void:
    target = player
    game = owner_game
    rng.randomize()
    strafe_sign = -1.0 if rng.randf() < 0.5 else 1.0
    _build_tactical_rig()

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

func _build_tactical_rig() -> void:
    rig = Node3D.new()
    rig.position.y = 0.05
    add_child(rig)
    var vest := _mat(Color("#34403f"), 0.15, 0.78)
    var fabric := _mat(Color("#1b2426"), 0.0, 0.92)
    var plate := _mat(Color("#59615f"), 0.55, 0.48)
    var joint := _mat(Color("#090d0e"), 0.35, 0.3)
    var skin := _mat(Color("#8a6a55"), 0.0, 0.95)
    var visor := _mat(Color("#243b42"), 0.55, 0.2, Color("#173a44"))
    torso = Node3D.new()
    torso.position.y = 1.05
    rig.add_child(torso)
    _box(torso, Vector3(0.82, 0.9, 0.48), Vector3.ZERO, vest)
    _box(torso, Vector3(0.62, 0.42, 0.52), Vector3(0,0.18,-0.03), plate)
    for x in [-0.24, 0.24]:
        _box(torso, Vector3(0.2,0.26,0.08), Vector3(x,0.05,-0.29), fabric)
    head = Node3D.new()
    head.position.y = 1.76
    rig.add_child(head)
    _sphere(head, 0.29, Vector3.ZERO, skin)
    _box(head, Vector3(0.62,0.2,0.52), Vector3(0,0.2,0), fabric)
    _box(head, Vector3(0.52,0.16,0.06), Vector3(0,0.01,-0.29), visor)
    arm_l = _limb(-1.0, vest, fabric, joint, skin)
    arm_r = _limb(1.0, vest, fabric, joint, skin)
    leg_l = _leg(-1.0, fabric, joint)
    leg_r = _leg(1.0, fabric, joint)
    weapon = Node3D.new()
    weapon.position = Vector3(0.22,1.28,-0.38)
    weapon.rotation_degrees.x = -8
    rig.add_child(weapon)
    _box(weapon, Vector3(0.12,0.12,0.9), Vector3(0,0,-0.35), _mat(Color("#101516"),0.85,0.3))
    _box(weapon, Vector3(0.16,0.28,0.18), Vector3(0,-0.12,0), _mat(Color("#242b2b"),0.55,0.4))
    _box(weapon, Vector3(0.08,0.1,0.2), Vector3(0,0,0.12), _mat(Color("#59615d"),0.6,0.4))
    muzzle = OmniLight3D.new()
    muzzle.light_color = Color("#ffb84d")
    muzzle.light_energy = 0.0
    muzzle.omni_range = 3.5
    muzzle.position = Vector3(0,0,-0.82)
    weapon.add_child(muzzle)

func _limb(side: float, vest: Material, fabric: Material, joint: Material, skin: Material) -> Node3D:
    var n := Node3D.new()
    n.position = Vector3(0.55*side,1.38,0)
    rig.add_child(n)
    _sphere(n,0.12,Vector3.ZERO,joint)
    _box(n,Vector3(0.24,0.42,0.25),Vector3(0,-0.22,0),vest)
    _sphere(n,0.11,Vector3(0,-0.48,0),joint)
    _box(n,Vector3(0.2,0.42,0.22),Vector3(0,-0.7,0),fabric)
    _sphere(n,0.11,Vector3(0,-0.93,0),skin)
    return n

func _leg(side: float, fabric: Material, joint: Material) -> Node3D:
    var n := Node3D.new()
    n.position = Vector3(0.22*side,0.55,0)
    rig.add_child(n)
    _sphere(n,0.13,Vector3.ZERO,joint)
    _box(n,Vector3(0.28,0.52,0.28),Vector3(0,-0.28,0),fabric)
    _sphere(n,0.11,Vector3(0,-0.58,0),joint)
    _box(n,Vector3(0.25,0.52,0.26),Vector3(0,-0.84,0),fabric)
    _box(n,Vector3(0.3,0.12,0.48),Vector3(0,-1.12,-0.08),_mat(Color("#111719"),0.3,0.75))
    return n

func _physics_process(delta: float) -> void:
    if not alive or not is_instance_valid(target):
        return
    t += delta
    fire_timer = max(0.0, fire_timer - delta)
    strafe_timer -= delta
    hit_flash = max(0.0, hit_flash - delta)
    if muzzle:
        muzzle.light_energy = 4.5 if fire_timer > 0.66 else 0.0
    var to_target := target.global_position - global_position
    to_target.y = 0
    var distance := to_target.length()
    if strafe_timer <= 0.0:
        strafe_timer = rng.randf_range(1.4, 3.2)
        if rng.randf() < 0.35:
            strafe_sign *= -1.0
    var dir := to_target.normalized()
    if distance > 15.0:
        var move_dir := dir
        if distance < 30.0:
            move_dir = (dir + dir.cross(Vector3.UP) * strafe_sign * 0.42).normalized()
        velocity.x = move_dir.x * speed
        velocity.z = move_dir.z * speed
        look_at(global_position + dir, Vector3.UP)
    else:
        var side_dir := dir.cross(Vector3.UP) * strafe_sign
        velocity.x = side_dir.x * speed * 0.65
        velocity.z = side_dir.z * speed * 0.65
        look_at(global_position + dir, Vector3.UP)
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = -0.2
    move_and_slide()
    var walking := Vector2(velocity.x, velocity.z).length() > 0.4
    var swing := sin(t * 8.0) * 0.42 if walking else 0.0
    if arm_l: arm_l.rotation.x = -swing * 0.45
    if arm_r: arm_r.rotation.x = swing * 0.45
    if leg_l: leg_l.rotation.x = swing
    if leg_r: leg_r.rotation.x = -swing
    if torso: torso.position.y = 1.05 + sin(t * 16.0) * 0.012 if walking else 1.05
    if distance < 32.0 and fire_timer <= 0.0:
        fire_timer = 0.78 + rng.randf_range(0.0, 0.55)
        var aim := (target.global_position + Vector3.UP * 1.1 - (global_position + Vector3.UP * 1.2)).normalized()
        if game:
            game.bot_shot(global_position + Vector3.UP * 1.2, aim)

func damage(amount: float) -> void:
    if not alive:
        return
    health = max(0.0, health - amount)
    hit_flash = 0.12
    if health <= 0.0:
        alive = false
        queue_free()
