extends Node

var game: Node
var player: CharacterBody3D
var hud: CanvasLayer
var feature_label: Label
var grenades := 3
var emp_charges := 1
var revive_tokens := 1
var grenade_cooldown := 0.0
var ability_cooldown := 0.0
var airdrop_timer := 18.0
var airdrops: Array[Node3D] = []
var vehicle_pads: Array[Node3D] = []
var saved_mode := "BATTLE ROYALE"

func _ready() -> void:
    game = get_parent()
    var cfg := ConfigFile.new()
    if cfg.load("user://battle_zone_profile.cfg") == OK:
        saved_mode = str(cfg.get_value("profile", "mode", "BATTLE ROYALE"))
    call_deferred("_initialize")

func _initialize() -> void:
    if not is_instance_valid(game): return
    player = game.player
    _add_vehicle_pads()
    _add_feature_hud()
    if saved_mode == "TRAINING RANGE":
        _clear_bots_for_training()
    elif saved_mode == "CLASH SQUAD":
        _reduce_bots_for_squad()
    elif saved_mode == "ZOMBIE HUNT":
        game._spawn_bots(5)
    feature_label.text = "MODE %s  •  FRAG %d  EMP %d  REVIVE %d" % [saved_mode, grenades, emp_charges, revive_tokens]

func _process(delta: float) -> void:
    grenade_cooldown = max(0.0, grenade_cooldown - delta)
    ability_cooldown = max(0.0, ability_cooldown - delta)
    airdrop_timer -= delta
    if airdrop_timer <= 0.0 and is_instance_valid(player) and not game.ended:
        _spawn_airdrop()
        airdrop_timer = 42.0
    for pod in airdrops.duplicate():
        if is_instance_valid(pod) and player.global_position.distance_to(pod.global_position) < 2.3:
            _collect_airdrop(pod)
    for pad in vehicle_pads:
        if is_instance_valid(pad) and player.global_position.distance_to(pad.global_position) < 3.0:
            player.speed = player.sprint_speed + 3.0
        elif is_instance_valid(player):
            player.speed = min(player.speed, 5.8)
    if not player.alive and revive_tokens > 0 and not game.ended:
        revive_tokens -= 1
        await get_tree().create_timer(4.0).timeout
        if is_instance_valid(player):
            player.alive = true
            player.health = 45.0
            player.armor = 20.0
            player.global_position = Vector3.ZERO
            feature_label.text = "REVIVE BEACON ACTIVATED  •  GET BACK IN"
    if is_instance_valid(feature_label):
        feature_label.text = "MODE %s  •  FRAG %d  EMP %d  REVIVE %d" % [saved_mode, grenades, emp_charges, revive_tokens]

func _add_feature_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    feature_label = Label.new()
    feature_label.position = Vector2(18, 145)
    feature_label.add_theme_font_size_override("font_size", 14)
    feature_label.add_theme_color_override("font_color", Color("#72d8ff"))
    hud.add_child(feature_label)
    _button("FRAG", Vector2(600,625), Vector2(100,58), _throw_frag)
    _button("ABILITY", Vector2(690,625), Vector2(105,58), _use_ability)

func _button(text: String, pos: Vector2, size: Vector2, action: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = size
    b.modulate = Color(1,1,1,0.82)
    b.add_theme_font_size_override("font_size", 16)
    b.pressed.connect(action)
    hud.add_child(b)

func _throw_frag() -> void:
    if grenades <= 0 or grenade_cooldown > 0.0 or not player.alive: return
    grenades -= 1
    grenade_cooldown = 1.0
    var center := game._nearest_bot()
    if center == null: return
    var blast_pos: Vector3 = center.global_position
    for bot in game.bots:
        if is_instance_valid(bot) and bot.alive and bot.global_position.distance_to(blast_pos) < 7.0:
            bot.damage(55.0)
            if not bot.alive: game.kills += 1
    feature_label.text = "FRAG DETONATED  •  AREA DAMAGE"

func _use_ability() -> void:
    if ability_cooldown > 0.0 or not player.alive: return
    ability_cooldown = 18.0
    player.heal(28.0)
    player.repair_armor(18.0)
    player.speed = player.sprint_speed + 1.5
    get_tree().create_timer(4.0).timeout.connect(func(): if is_instance_valid(player): player.speed = 5.8)
    feature_label.text = "TACTICAL OVERDRIVE  •  HP +28  ARMOR +18"

func _spawn_airdrop() -> void:
    if not is_instance_valid(player): return
    var pod := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.8,1.2,1.8)
    pod.mesh = mesh
    pod.position = player.global_position + Vector3(randf_range(-12,12),0.8,randf_range(-12,12))
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#c58f32")
    mat.emission_enabled = true
    mat.emission = Color("#7a5010")
    mat.emission_energy_multiplier = 1.8
    pod.material_override = mat
    game.add_child(pod)
    airdrops.append(pod)
    feature_label.text = "SUPPLY POD INBOUND  •  CHECK YOUR MAP"

func _collect_airdrop(pod: Node3D) -> void:
    if not is_instance_valid(pod): return
    pod.queue_free()
    airdrops.erase(pod)
    player.reserve_ammo += 90
    player.heal(35.0)
    player.repair_armor(30.0)
    grenades = min(5, grenades + 1)
    feature_label.text = "SUPPLY POD SECURED  •  AMMO +90  MED +35  ARMOR +30"

func _add_vehicle_pads() -> void:
    for pos in [Vector3(18,0.04,18), Vector3(-22,0.04,-16)]:
        var pad := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 2.2
        mesh.bottom_radius = 2.2
        mesh.height = 0.08
        pad.mesh = mesh
        pad.position = pos
        pad.material_override = _mat(Color("#285e73"), Color("#4bd7ff"))
        game.add_child(pad)
        vehicle_pads.append(pad)

func _mat(base: Color, glow: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = base
    m.emission_enabled = true
    m.emission = glow
    m.emission_energy_multiplier = 1.4
    return m

func _clear_bots_for_training() -> void:
    for bot in game.bots:
        if is_instance_valid(bot): bot.queue_free()
    game.bots.clear()

func _reduce_bots_for_squad() -> void:
    while game.bots.size() > 4:
        var bot = game.bots.pop_back()
        if is_instance_valid(bot): bot.queue_free()
