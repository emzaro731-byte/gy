extends Node3D

const PLAYER_SCRIPT = preload("res://player_3d.gd")
const BOT_SCRIPT = preload("res://bot_3d.gd")

var player: CharacterBody3D
var bots: Array[Node3D] = []
var bullets: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var zone_radius := 120.0
var zone_timer := 0.0
var elapsed := 0.0
var kills := 0
var ended := false
var won := false
var hud: CanvasLayer
var stats: Label
var message: Label
var weapon_label: Label

func _ready() -> void:
    randomize()
    _setup_world()
    _spawn_player()
    _spawn_bots(20)
    _spawn_pickups(55)
    _setup_hud()

func _setup_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#6e8799")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#c9d5df")
    environment.ambient_light_energy = 0.65
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -28, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 120.0
    add_child(sun)

    var ground := StaticBody3D.new()
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(280, 1, 280)
    mesh.mesh = box
    mesh.position.y = -0.5
    var ground_mat := StandardMaterial3D.new()
    ground_mat.albedo_color = Color("#4f6647")
    ground_mat.roughness = 1.0
    mesh.material_override = ground_mat
    ground.add_child(mesh)
    var shape := CollisionShape3D.new()
    var collision := BoxShape3D.new()
    collision.size = Vector3(280, 1, 280)
    shape.shape = collision
    shape.position.y = -0.5
    ground.add_child(shape)
    add_child(ground)

    for i in 48:
        var p := Vector3(randf_range(-125,125), 0, randf_range(-125,125))
        if p.length() < 18:
            continue
        _make_building(p)
    for i in 70:
        _make_tree(Vector3(randf_range(-132,132), 0, randf_range(-132,132)))

func _make_building(pos: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(randf_range(4,10), randf_range(3,7), randf_range(4,10))
    mesh.mesh = box
    mesh.position.y = box.size.y * 0.5
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#81786c")
    mat.roughness = 0.86
    mesh.material_override = mat
    body.add_child(mesh)
    var shape := CollisionShape3D.new()
    var collision := BoxShape3D.new()
    collision.size = box.size
    shape.shape = collision
    shape.position.y = box.size.y * 0.5
    body.add_child(shape)
    add_child(body)

func _make_tree(pos: Vector3) -> void:
    var trunk := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.height = 2.6
    cyl.top_radius = 0.22
    cyl.bottom_radius = 0.3
    trunk.mesh = cyl
    trunk.position = pos + Vector3.UP * 1.3
    var tm := StandardMaterial3D.new()
    tm.albedo_color = Color("#514238")
    tm.roughness = 1.0
    trunk.material_override = tm
    add_child(trunk)
    var crown := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.5
    sphere.height = 3.0
    crown.mesh = sphere
    crown.position = pos + Vector3.UP * 3.0
    var cm := StandardMaterial3D.new()
    cm.albedo_color = Color("#31533a")
    cm.roughness = 0.95
    crown.material_override = cm
    add_child(crown)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 1, 0)
    add_child(player)
    player.setup(self)

func _spawn_bots(count: int) -> void:
    for i in count:
        var bot := CharacterBody3D.new()
        bot.set_script(BOT_SCRIPT)
        var a := randf() * TAU
        var r := randf_range(35, 105)
        bot.position = Vector3(cos(a)*r, 1, sin(a)*r)
        add_child(bot)
        bot.setup(player, self)
        bots.append(bot)

func _spawn_pickups(count: int) -> void:
    for i in count:
        var pos := Vector3(randf_range(-125,125), 0.35, randf_range(-125,125))
        var roll := i % 5
        var kind := "ammo" if roll < 2 else ("medkit" if roll < 4 else "armor")
        var item := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.6,0.45,0.6)
        item.mesh = mesh
        item.position = pos
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color("#d4a94a") if kind == "ammo" else (Color("#56b879") if kind == "medkit" else Color("#4c9bd6"))
        mat.emission_enabled = true
        mat.emission = mat.albedo_color * 0.35
        item.material_override = mat
        add_child(item)
        pickups.append({"node":item,"kind":kind,"taken":false})

func _setup_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var panel := ColorRect.new()
    panel.position = Vector2(18,18)
    panel.size = Vector2(430,122)
    panel.color = Color(0.015,0.025,0.04,0.84)
    hud.add_child(panel)
    stats = Label.new()
    stats.position = Vector2(32,30)
    stats.add_theme_font_size_override("font_size",20)
    hud.add_child(stats)
    weapon_label = Label.new()
    weapon_label.position = Vector2(32,108)
    weapon_label.add_theme_font_size_override("font_size",16)
    weapon_label.add_theme_color_override("font_color", Color("#f3bd55"))
    hud.add_child(weapon_label)
    message = Label.new()
    message.set_anchors_preset(Control.PRESET_CENTER_TOP)
    message.position = Vector2(-360,20)
    message.size = Vector2(720,70)
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.add_theme_font_size_override("font_size",32)
    hud.add_child(message)
    _add_mobile_button("FIRE", Vector2(1060,570), Vector2(170,105), _mobile_fire)
    _add_mobile_button("RELOAD", Vector2(930,625), Vector2(115,58), _mobile_reload)
    _add_mobile_button("SPRINT", Vector2(45,625), Vector2(120,58), _mobile_sprint)
    _add_mobile_button("WEAPON", Vector2(785,625), Vector2(125,58), _mobile_weapon)

func _add_mobile_button(text: String, pos: Vector2, size: Vector2, action: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = size
    b.modulate = Color(1,1,1,0.78)
    b.add_theme_font_size_override("font_size",18)
    b.pressed.connect(action)
    hud.add_child(b)

func _mobile_fire() -> void:
    var target := _nearest_bot()
    if target:
        player.shoot((target.global_position + Vector3.UP * 1.1 - (player.global_position + Vector3.UP * 1.4)).normalized())

func _mobile_reload() -> void:
    player.reload()

func _mobile_weapon() -> void:
    player.switch_weapon()

func _mobile_sprint() -> void:
    player.speed = player.sprint_speed
    get_tree().create_timer(1.2).timeout.connect(func(): if is_instance_valid(player): player.speed = 5.8)

func _nearest_bot() -> Node3D:
    var best: Node3D = null
    var d := INF
    for bot in bots:
        if is_instance_valid(bot) and bot.alive:
            var bd := player.global_position.distance_squared_to(bot.global_position)
            if bd < d:
                d = bd
                best = bot
    return best

func player_shot(origin: Vector3, direction: Vector3, damage: float = 25.0) -> void:
    bullets.append({"pos":origin,"vel":direction.normalized()*55.0,"damage":damage,"player":true,"life":1.2})

func bot_shot(origin: Vector3, direction: Vector3) -> void:
    bullets.append({"pos":origin,"vel":direction.normalized()*38.0,"damage":8.0,"player":false,"life":1.5})

func _physics_process(delta: float) -> void:
    if ended:
        return
    elapsed += delta
    zone_timer += delta
    zone_radius = max(28.0, 120.0 - zone_timer * 0.32)
    _update_bullets(delta)
    _update_pickups()
    _update_zone(delta)
    _update_hud()
    if not player.alive:
        ended = true
        won = false
    elif _alive_bots() == 0:
        ended = true
        won = true

func _update_bullets(delta: float) -> void:
    for shot in bullets.duplicate():
        shot.pos += shot.vel * delta
        shot.life -= delta
        var removed := false
        if shot.player:
            for bot in bots:
                if is_instance_valid(bot) and bot.alive and shot.pos.distance_to(bot.global_position + Vector3.UP) < 1.0:
                    bot.damage(shot.damage)
                    if not bot.alive:
                        kills += 1
                    bullets.erase(shot)
                    removed = true
                    break
        else:
            if player.alive and shot.pos.distance_to(player.global_position + Vector3.UP) < 1.0:
                player.damage(shot.damage)
                bullets.erase(shot)
                removed = true
        if not removed and shot.life <= 0.0:
            bullets.erase(shot)
        elif not removed:
            var idx := bullets.find(shot)
            if idx >= 0:
                bullets[idx] = shot

func _update_pickups() -> void:
    for item in pickups:
        if item.taken or not is_instance_valid(item.node):
            continue
        item.node.rotate_y(0.02)
        if player.global_position.distance_to(item.node.global_position) < 2.0:
            item.taken = true
            item.node.queue_free()
            if item.kind == "ammo":
                player.reserve_ammo += 45
            elif item.kind == "medkit":
                player.heal(30)
            else:
                player.repair_armor(30)

func _update_zone(delta: float) -> void:
    var dist := Vector2(player.global_position.x, player.global_position.z).length()
    if dist > zone_radius:
        player.damage(7.0 * delta)
    for bot in bots:
        if is_instance_valid(bot) and bot.alive:
            var bd := Vector2(bot.global_position.x, bot.global_position.z).length()
            if bd > zone_radius:
                bot.damage(5.0 * delta)

func _alive_bots() -> int:
    var n := 0
    for bot in bots:
        if is_instance_valid(bot) and bot.alive:
            n += 1
    return n

func _update_hud() -> void:
    if not is_instance_valid(player):
        return
    var weapon: Dictionary = player.weapons[player.weapon_index]
    stats.text = "HP %d/100   ARMOR %d/50\nAMMO %d/%d   KILLS %d   ENEMIES %d\nZONE %dm" % [int(player.health), int(player.armor), player.ammo, player.reserve_ammo, kills, _alive_bots(), int(zone_radius)]
    weapon_label.text = "%s  •  DMG %d" % [weapon["name"], int(weapon["damage"])]
    message.text = "REALISTIC BATTLE ZONE" if not ended else ("VICTORY" if won else "ELIMINATED")
