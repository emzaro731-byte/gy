extends Node3D

const PROFILE_PATH := "user://battle_zone_profile.cfg"

var profile := {
    "xp": 0,
    "level": 1,
    "credits": 1200,
    "selected_weapon": 0,
    "owned_weapons": [true, true, false, false],
    "mission_progress": [3, 7, 12],
    "claimed_rewards": [false, false, false, false, false]
}

var weapons := [
    {"name":"ASSAULT MK-IV", "type":"ASSAULT RIFLE", "damage":25, "rate":"HIGH", "range":"MEDIUM", "cost":0},
    {"name":"VOLT SMG-9", "type":"SMG", "damage":18, "rate":"VERY HIGH", "range":"SHORT", "cost":650},
    {"name":"RAVEN DMR", "type":"MARKSMAN", "damage":42, "rate":"MEDIUM", "range":"LONG", "cost":900},
    {"name":"HAMMER-12", "type":"SHOTGUN", "damage":68, "rate":"LOW", "range":"CLOSE", "cost":1200}
]

var missions := [
    {"name":"FIELD TEST", "desc":"Complete 5 eliminations", "goal":5, "reward":300},
    {"name":"SURVIVOR", "desc":"Survive for 10 minutes", "goal":10, "reward":500},
    {"name":"SCAVENGER", "desc":"Collect 20 supply items", "goal":20, "reward":700}
]

var battle_pass := [
    {"level":1, "reward":"100 CREDITS"},
    {"level":2, "reward":"TACTICAL SKIN"},
    {"level":3, "reward":"250 CREDITS"},
    {"level":4, "reward":"XP BOOST"},
    {"level":5, "reward":"VOLT SMG-9"}
]

var character: Node3D
var weapon_display: Node3D
var camera: Camera3D
var status_label: Label
var main_content: VBoxContainer
var selected_tab := "SHOWROOM"
var pulse := 0.0

func _ready() -> void:
    _load_profile()
    _build_3d_showroom()
    _build_interface()
    _refresh_content()

func _process(delta: float) -> void:
    pulse += delta
    if character:
        character.rotation.y += delta * 0.22
    if weapon_display:
        weapon_display.rotation.y += delta * 0.55
    if status_label:
        status_label.modulate.a = 0.82 + sin(pulse * 2.0) * 0.16

func _load_profile() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PROFILE_PATH) == OK:
        profile.xp = int(cfg.get_value("profile", "xp", 0))
        profile.level = int(cfg.get_value("profile", "level", 1))
        profile.credits = int(cfg.get_value("profile", "credits", 1200))
        profile.selected_weapon = int(cfg.get_value("profile", "selected_weapon", 0))
        profile.owned_weapons = cfg.get_value("profile", "owned_weapons", [true, true, false, false])
        profile.mission_progress = cfg.get_value("profile", "mission_progress", [3, 7, 12])
        profile.claimed_rewards = cfg.get_value("profile", "claimed_rewards", [false, false, false, false, false])
    _recalculate_level()

func _save_profile() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("profile", "xp", profile.xp)
    cfg.set_value("profile", "level", profile.level)
    cfg.set_value("profile", "credits", profile.credits)
    cfg.set_value("profile", "selected_weapon", profile.selected_weapon)
    cfg.set_value("profile", "owned_weapons", profile.owned_weapons)
    cfg.set_value("profile", "mission_progress", profile.mission_progress)
    cfg.set_value("profile", "claimed_rewards", profile.claimed_rewards)
    cfg.save(PROFILE_PATH)

func _recalculate_level() -> void:
    profile.level = clampi(int(profile.xp / 500) + 1, 1, 100)

func _build_3d_showroom() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#050b14")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#9db8d2")
    env.ambient_light_energy = 0.72
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env_node.environment = env
    add_child(env_node)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48, -32, 0)
    key.light_energy = 1.5
    key.shadow_enabled = true
    add_child(key)

    var rim := OmniLight3D.new()
    rim.position = Vector3(3, 4, 2)
    rim.light_energy = 5.0
    rim.omni_range = 12.0
    add_child(rim)

    var floor := MeshInstance3D.new()
    var floor_mesh := CylinderMesh.new()
    floor_mesh.top_radius = 6.0
    floor_mesh.bottom_radius = 6.0
    floor_mesh.height = 0.35
    floor.mesh = floor_mesh
    floor.position.y = -0.18
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color("#101d2b")
    floor_mat.metallic = 0.55
    floor_mat.roughness = 0.3
    floor.material_override = floor_mat
    add_child(floor)

    character = Node3D.new()
    character.position = Vector3(-0.5, 0, 0)
    add_child(character)
    _build_character()

    weapon_display = Node3D.new()
    weapon_display.position = Vector3(2.0, 1.0, 0)
    add_child(weapon_display)
    _build_weapon_display()

    camera = Camera3D.new()
    camera.position = Vector3(0, 2.2, 8.8)
    camera.look_at_from_position(camera.position, Vector3(0.6, 1.0, 0), Vector3.UP)
    camera.current = true
    add_child(camera)

func _mat(color: Color, metal := 0.0, rough := 0.55, emission := Color.TRANSPARENT) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    if emission.a > 0.0:
        m.emission_enabled = true
        m.emission = emission
        m.emission_energy_multiplier = 2.0
    return m

func _part(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = mat
    parent.add_child(n)
    return n

func _build_character() -> void:
    var armor := _mat(Color("#3b4b5c"), 0.8, 0.25)
    var dark := _mat(Color("#0a1119"), 0.9, 0.2)
    var trim := _mat(Color("#c79b42"), 0.65, 0.25, Color("#6a4a14"))
    _part(character, Vector3(1.0,1.25,0.62), Vector3(0,1.2,0), armor)
    _part(character, Vector3(0.7,0.4,0.68), Vector3(0,1.48,-0.05), dark)
    _part(character, Vector3(0.72,0.58,0.58), Vector3(0,2.08,0), dark)
    _part(character, Vector3(0.5,0.08,0.08), Vector3(0,2.08,-0.32), trim)
    _part(character, Vector3(0.34,1.0,0.42), Vector3(-0.34,0.25,0), armor)
    _part(character, Vector3(0.34,1.0,0.42), Vector3(0.34,0.25,0), armor)
    _part(character, Vector3(0.38,0.85,0.44), Vector3(-0.62,0.85,0), armor)
    _part(character, Vector3(0.38,0.85,0.44), Vector3(0.62,0.85,0), armor)
    _part(character, Vector3(0.42,0.9,0.48), Vector3(-0.28,-0.25,0), dark)
    _part(character, Vector3(0.42,0.9,0.48), Vector3(0.28,-0.25,0), dark)
    _part(character, Vector3(0.58,0.16,0.8), Vector3(-0.28,-0.7,-0.12), trim)
    _part(character, Vector3(0.58,0.16,0.8), Vector3(0.28,-0.7,-0.12), trim)

func _build_weapon_display() -> void:
    var dark := _mat(Color("#171e25"), 0.92, 0.2)
    var metal := _mat(Color("#66717a"), 0.85, 0.22)
    var accent := _mat(Color("#c79b42"), 0.7, 0.25, Color("#5b3f12"))
    _part(weapon_display, Vector3(2.1,0.22,0.25), Vector3(0,0,0), dark)
    _part(weapon_display, Vector3(0.75,0.32,0.3), Vector3(-0.65,-0.15,0), metal)
    _part(weapon_display, Vector3(0.34,0.72,0.28), Vector3(-0.25,-0.43,0), dark)
    _part(weapon_display, Vector3(0.32,0.18,0.32), Vector3(0.62,0,0), accent)
    _part(weapon_display, Vector3(0.65,0.12,0.16), Vector3(0.55,0.22,0), metal)

func _build_interface() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var bg := ColorRect.new()
    bg.color = Color(0.015,0.03,0.055,0.76)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 22)
    margin.add_theme_constant_override("margin_bottom", 22)
    layer.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 12)
    margin.add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 62
    root.add_child(header)
    var brand := VBoxContainer.new()
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(brand)
    var title := Label.new()
    title.text = "BATTLE ZONE"
    title.add_theme_font_size_override("font_size", 31)
    title.add_theme_color_override("font_color", Color("eaf4ff"))
    brand.add_child(title)
    var sub := Label.new()
    sub.text = "TACTICAL COMMAND // OFFLINE"
    sub.add_theme_font_size_override("font_size", 11)
    sub.add_theme_color_override("font_color", Color("5dc8ff"))
    brand.add_child(sub)

    var profile_box := VBoxContainer.new()
    profile_box.custom_minimum_size.x = 330
    header.add_child(profile_box)
    var profile := Label.new()
    profile.text = "OPERATIVE 01   •   RANK %02d" % profile.level
    profile.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    profile.add_theme_font_size_override("font_size", 17)
    profile_box.add_child(profile)
    var xp := Label.new()
    xp.text = "%d XP   •   %d CREDITS" % [profile.xp, profile.credits]
    xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    xp.add_theme_color_override("font_color", Color("f3bd55"))
    profile_box.add_child(xp)

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 8)
    root.add_child(tabs)
    for tab in ["SHOWROOM", "INVENTORY", "RANK", "MISSIONS", "BATTLE PASS"]:
        var b := Button.new()
        b.text = tab
        b.custom_minimum_size = Vector2(0, 46)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(_select_tab.bind(tab))
        tabs.add_child(b)

    main_content = VBoxContainer.new()
    main_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_content.add_theme_constant_override("separation", 10)
    root.add_child(main_content)

    status_label = Label.new()
    status_label.text = "● LOCAL PROFILE SAVED  |  ARMORY ONLINE"
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 11)
    status_label.add_theme_color_override("font_color", Color("5df2a3"))
    root.add_child(status_label)

func _clear_content() -> void:
    for child in main_content.get_children():
        child.queue_free()

func _select_tab(tab: String) -> void:
    selected_tab = tab
    _refresh_content()

func _refresh_content() -> void:
    _clear_content()
    match selected_tab:
        "SHOWROOM": _show_showroom()
        "INVENTORY": _show_inventory()
        "RANK": _show_rank()
        "MISSIONS": _show_missions()
        "BATTLE PASS": _show_battle_pass()

func _panel(title_text: String) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var style := StyleBoxFlat.new()
    style.bg_color = Color("0b1726")
    style.border_color = Color("23425c")
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 14
    style.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel", style)
    main_content.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    var heading := Label.new()
    heading.text = title_text
    heading.add_theme_font_size_override("font_size", 18)
    heading.add_theme_color_override("font_color", Color("5dc8ff"))
    box.add_child(heading)
    return box

func _show_showroom() -> void:
    var box := _panel("3D ARMORY SHOWROOM")
    var info := Label.new()
    info.text = "ASSAULT MK-IV // OPERATIVE MK-IV\nLIVE 3D DISPLAY  •  ROTATING WEAPON  •  EQUIPPED LOADOUT"
    info.add_theme_font_size_override("font_size", 20)
    info.add_theme_color_override("font_color", Color("e6f1fb"))
    box.add_child(info)
    var stats := Label.new()
    var w: Dictionary = weapons[profile.selected_weapon]
    stats.text = "WEAPON: %s\nTYPE: %s   DAMAGE: %d   FIRE RATE: %s   RANGE: %s" % [w.name, w.type, w.damage, w.rate, w.range]
    stats.add_theme_color_override("font_color", Color("a8bdd0"))
    box.add_child(stats)
    var deploy := Button.new()
    deploy.text = "DEPLOY WITH %s   ▶" % w.name
    deploy.custom_minimum_size.y = 58
    deploy.add_theme_font_size_override("font_size", 20)
    deploy.pressed.connect(_start_battle)
    box.add_child(deploy)

func _show_inventory() -> void:
    var box := _panel("ARMORY / INVENTORY")
    var hint := Label.new()
    hint.text = "OWNED WEAPONS • EQUIP A LOADOUT FOR YOUR NEXT DROP"
    hint.add_theme_color_override("font_color", Color("9ab1c4"))
    box.add_child(hint)
    for i in weapons.size():
        var w: Dictionary = weapons[i]
        var b := Button.new()
        var owned: bool = profile.owned_weapons[i]
        b.text = ("✓ " if i == profile.selected_weapon else "  ") + w.name + "   |   " + w.type + ("   [OWNED]" if owned else "   [" + str(w.cost) + " CREDITS]")
        b.custom_minimum_size.y = 48
        b.pressed.connect(_equip_weapon.bind(i))
        box.add_child(b)

func _equip_weapon(index: int) -> void:
    if not profile.owned_weapons[index]:
        var cost: int = weapons[index].cost
        if profile.credits < cost:
            status_label.text = "● NOT ENOUGH CREDITS"
            return
        profile.credits -= cost
        profile.owned_weapons[index] = true
    profile.selected_weapon = index
    _save_profile()
    _refresh_content()
    status_label.text = "● LOADOUT UPDATED"

func _show_rank() -> void:
    var box := _panel("RANK / OPERATIVE PROGRESSION")
    var level_xp := profile.xp % 500
    var rank := Label.new()
    rank.text = "RANK %02d  •  %s\n%d / 500 XP TO NEXT RANK" % [profile.level, _rank_name(profile.level), level_xp]
    rank.add_theme_font_size_override("font_size", 25)
    rank.add_theme_color_override("font_color", Color("f3bd55"))
    box.add_child(rank)
    var bar := ProgressBar.new()
    bar.value = level_xp / 5.0
    bar.show_percentage = false
    bar.custom_minimum_size.y = 14
    box.add_child(bar)
    var rewards := Label.new()
    rewards.text = "NEXT REWARD: %s\nCAREER XP: %d\nCREDITS: %d" % [_rank_name(profile.level + 1), profile.xp, profile.credits]
    rewards.add_theme_color_override("font_color", Color("a8bdd0"))
    box.add_child(rewards)

func _rank_name(level: int) -> String:
    if level >= 50: return "VANGUARD"
    if level >= 30: return "ELITE"
    if level >= 15: return "OPERATIVE"
    if level >= 5: return "SPECIALIST"
    return "RECRUIT"

func _show_missions() -> void:
    var box := _panel("DAILY / CAREER MISSIONS")
    for i in missions.size():
        var m: Dictionary = missions[i]
        var progress: int = min(int(profile.mission_progress[i]), int(m.goal))
        var row := VBoxContainer.new()
        var label := Label.new()
        label.text = "%s\n%s   •   %d/%d   •   +%d XP" % [m.name, m.desc, progress, m.goal, m.reward]
        label.add_theme_color_override("font_color", Color("e5f0fa"))
        row.add_child(label)
        var bar := ProgressBar.new()
        bar.value = float(progress) / float(m.goal) * 100.0
        bar.show_percentage = false
        bar.custom_minimum_size.y = 8
        row.add_child(bar)
        box.add_child(row)

func _show_battle_pass() -> void:
    var box := _panel("BATTLE PASS // SEASON 01")
    var intro := Label.new()
    intro.text = "OFFLINE SEASON TRACK   •   PROGRESS WITH XP\nCURRENT TIER: %02d / %02d" % [min(profile.level, 5), 5]
    intro.add_theme_color_override("font_color", Color("a8bdd0"))
    box.add_child(intro)
    for i in battle_pass.size():
        var reward: Dictionary = battle_pass[i]
        var unlocked: bool = profile.level >= int(reward.level)
        var claimed: bool = profile.claimed_rewards[i]
        var b := Button.new()
        b.text = ("✓ " if claimed else ("🔓 " if unlocked else "🔒 ")) + "TIER %02d   —   %s" % [reward.level, reward.reward]
        b.custom_minimum_size.y = 45
        b.pressed.connect(_claim_pass_reward.bind(i))
        box.add_child(b)

func _claim_pass_reward(index: int) -> void:
    if profile.claimed_rewards[index]:
        return
    var reward_level: int = battle_pass[index].level
    if profile.level < reward_level:
        status_label.text = "● TIER LOCKED — EARN MORE XP"
        return
    profile.claimed_rewards[index] = true
    profile.credits += 100 + index * 50
    if index == 4:
        profile.owned_weapons[1] = true
    _save_profile()
    _refresh_content()
    status_label.text = "● BATTLE PASS REWARD CLAIMED"

func _start_battle() -> void:
    _save_profile()
    get_tree().change_scene_to_file("res://Game3D.tscn")
