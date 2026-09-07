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

func _mat(color: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    m.metallic = metallic
    return m

func _setup_world() -> void:
    var env_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("#101c2d")
    sky_mat.sky_horizon_color = Color("#9bb0bd")
    sky_mat.ground_bottom_color = Color("#182018")
    sky_mat.ground_horizon_color = Color("#6f806d")
    sky_mat.sun_angle_max = 18.0
    sky.sky_material = sky_mat
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.72
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 0.7
    environment.fog_enabled = true
    environment.fog_light_color = Color("#9eabb0")
    environment.fog_light_energy = 0.55
    environment.fog_density = 0.006
    environment.fog_sky_affect = 0.35
    env_node.environment = environment
    add_child(env_node)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_color = Color("#fff1d2")
    sun.light_energy = 1.55
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 180.0
    sun.directional_shadow_split_1 = 0.08
    sun.directional_shadow_split_2 = 0.25
    sun.directional_shadow_split_3 = 0.55
    add_child(sun)

    var moon_fill := DirectionalLight3D.new()
    moon_fill.rotation_degrees = Vector3(-25, 145, 0)
    moon_fill.light_color = Color("#9fb8d0")
    moon_fill.light_energy = 0.16
    moon_fill.shadow_enabled = false
    add_child(moon_fill)

    _make_ground()
    _make_roads()
    for i in 42:
        var p := Vector3(randf_range(-125,125), 0, randf_range(-125,125))
        if p.length() < 22:
            continue
        _make_building(p)
    for i in 95:
        _make_tree(Vector3(randf_range(-132,132), 0, randf_range(-132,132)))
    for p in [Vector3(12,0,-8), Vector3(-34,0,28), Vector3(58,0,45), Vector3(-72,0,-52)]:
        _make_street_light(p)

func _make_ground() -> void:
    var ground := StaticBody3D.new()
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(280, 1, 280)
    mesh.mesh = box
    mesh.position.y = -0.5
    mesh.material_override = _mat(Color("#4b5b43"), 1.0)
    ground.add_child(mesh)
    var shape := CollisionShape3D.new()
    var collision := BoxShape3D.new()
    collision.size = Vector3(280, 1, 280)
    shape.shape = collision
    shape.position.y = -0.5
    ground.add_child(shape)
    add_child(ground)

    for x in range(-135, 136, 15):
        var strip := MeshInstance3D.new()
        var plane := BoxMesh.new()
        plane.size = Vector3(0.045, 0.012, 270)
        strip.mesh = plane
        strip.position = Vector3(x, 0.01, 0)
        strip.material_override = _mat(Color(0.20,0.25,0.18), 1.0)
        add_child(strip)
    for z in range(-135, 136, 15):
        var strip := MeshInstance3D.new()
        var plane := BoxMesh.new()
        plane.size = Vector3(270, 0.012, 0.045)
        strip.mesh = plane
        strip.position = Vector3(0, 0.012, z)
        strip.material_override = _mat(Color(0.20,0.25,0.18), 1.0)
        add_child(strip)

func _make_roads() -> void:
    for p in [Vector3(0,0.025,0), Vector3(0,0.03,55), Vector3(0,0.03,-55)]:
        var road := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(10, 0.05, 280)
        road.mesh = box
        road.position = p
        road.material_override = _mat(Color("#252a2b"), 0.95)
        add_child(road)
    for p in [Vector3(55,0.03,0), Vector3(-55,0.03,0)]:
        var road := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(280, 0.05, 10)
        road.mesh = box
        road.position = p
        road.material_override = _mat(Color("#252a2b"), 0.95)
        add_child(road)

func _make_building(pos: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var sx := randf_range(5.5, 12.0)
    var sy := randf_range(3.5, 8.0)
    var sz := randf_range(5.5, 12.0)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(sx, sy, sz)
    mesh.mesh = box
    mesh.position.y = sy * 0.5
    mesh.material_override = _mat(Color("#66645e"), 0.9, 0.05)
    body.add_child(mesh)

    var roof := MeshInstance3D.new()
    var roof_box := BoxMesh.new()
    roof_box.size = Vector3(sx + 0.35, 0.22, sz + 0.35)
    roof.mesh = roof_box
    roof.position.y = sy + 0.12
    roof.material_override = _mat(Color("#292d30"), 0.72, 0.25)
    body.add_child(roof)

    for side in [-1.0, 1.0]:
        for row in range(1, max(2, int(sy / 2.0))):
            var window := MeshInstance3D.new()
            var w := BoxMesh.new()
            w.size = Vector3(max(0.55, sx * 0.16), 0.72, 0.06)
            window.mesh = w
            window.position = Vector3(side * (sx * 0.5 + 0.031), row * 1.65, 0)
            window.rotation_degrees.y = 90
            var glass := _mat(Color("#6e9bb0"), 0.12, 0.35)
            glass.emission_enabled = true
            glass.emission = Color("#263e4a")
            glass.emission_energy_multiplier = 0.7
            window.material_override = glass
            body.add_child(window)
    var door := MeshInstance3D.new()
    var door_box := BoxMesh.new()
    door_box.size = Vector3(0.9, 1.8, 0.08)
    door.mesh = door_box
    door.position = Vector3(0, 0.9, sz * 0.5 + 0.04)
    door.material_override = _mat(Color("#22262a"), 0.75)
    body.add_child(door)

    var shape := CollisionShape3D.new()
    var collision := BoxShape3D.new()
    collision.size = box.size
    shape.shape = collision
    shape.position.y = sy * 0.5
    body.add_child(shape)
    add_child(body)

func _make_tree(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    add_child(root)
    var trunk := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.height = randf_range(2.5, 4.0)
    cyl.top_radius = 0.18
    cyl.bottom_radius = 0.34
    trunk.mesh = cyl
    trunk.position.y = cyl.height * 0.5
    trunk.material_override = _mat(Color("#3f342b"), 1.0)
    root.add_child(trunk)
    for y in [2.6, 3.5, 4.25]:
        var crown := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = randf_range(1.15, 1.7)
        sphere.height = sphere.radius * 2.0
        crown.mesh = sphere
        crown.position = Vector3(randf_range(-0.25,0.25), y, randf_range(-0.25,0.25))
        crown.scale = Vector3(1.0, randf_range(0.75,1.2), 1.0)
        crown.material_override = _mat(Color("#25442e"), 1.0)
        root.add_child(crown)

func _make_street_light(pos: Vector3) -> void:
    var pole := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.height = 5.5
    cyl.top_radius = 0.07
    cyl.bottom_radius = 0.11
    pole.mesh = cyl
    pole.position = pos + Vector3.UP * 2.75
    pole.material_override = _mat(Color("#24282a"), 0.35, 0.8)
    add_child(pole)
    var lamp := OmniLight3D.new()
    lamp.position = pos + Vector3.UP * 5.3
    lamp.light_color = Color("#ffd98a")
    lamp.light_energy = 1.6
    lamp.omni_range = 10.0
    add_child(lamp)
    var bulb := MeshInstance3D.new()
    var s := SphereMesh.new()
    s.radius = 0.14
    s.height = 0.28
    bulb.mesh = s
    bulb.position = lamp.position
    var mat := _mat(Color("#fff0b0"), 0.2, 0.1)
    mat.emission_enabled = true
    mat.emission = Color("#ffcf6e")
    mat.emission_energy_multiplier = 4.0
    bulb.material_override = mat
    add_child(bulb)

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
        var mat := _mat(Color("#d4a94a") if kind == "ammo" else (Color("#56b879") if kind == "medkit" else Color("#4c9bd6")), 0.35)
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
    _make_tracer(origin, direction, Color("#ffd36a"))

func bot_shot(origin: Vector3, direction: Vector3) -> void:
    bullets.append({"pos":origin,"vel":direction.normalized()*38.0,"damage":8.0,"player":false,"life":1.5})
    _make_tracer(origin, direction, Color("#ff6a52"))

func _make_tracer(origin: Vector3, direction: Vector3, color: Color) -> void:
    var tracer := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.035, 0.035, 0.65)
    tracer.mesh = box
    tracer.global_position = origin + direction.normalized() * 0.32
    tracer.look_at(tracer.global_position + direction, Vector3.UP)
    var mat := _mat(color, 0.2)
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 3.0
    tracer.material_override = mat
    add_child(tracer)
    get_tree().create_timer(0.055).timeout.connect(func(): if is_instance_valid(tracer): tracer.queue_free())

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
        item.node.position.y = 0.35 + sin(elapsed * 2.5 + item.node.position.x) * 0.08
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
    message.text = "BATTLE ZONE" if not ended else ("VICTORY" if won else "ELIMINATED")
