extends Node3D

const SAVE_PATH := "user://battle_zone_profile.cfg"

var xp := 0
var level := 1
var credits := 1200
var selected_weapon := 0
var owned := [true, true, false, false]
var mission_progress := [3, 7, 12]
var claimed := [false, false, false, false, false]
var selected_mode := "BATTLE ROYALE"
var pet_equipped := "NOVA DRONE"
var guild_name := "IRON GUARD"
var role := "RIFLER"
var weapons := [
    {"name":"ASSAULT MK-IV", "type":"ASSAULT RIFLE", "damage":25, "rate":"HIGH", "range":"MEDIUM", "cost":0},
    {"name":"VOLT SMG-9", "type":"SMG", "damage":18, "rate":"VERY HIGH", "range":"SHORT", "cost":650},
    {"name":"RAVEN DMR", "type":"MARKSMAN", "damage":42, "rate":"MEDIUM", "range":"LONG", "cost":900},
    {"name":"HAMMER-12", "type":"SHOTGUN", "damage":68, "rate":"LOW", "range":"CLOSE", "cost":1200}
]
var mission_names := ["FIELD TEST", "SURVIVOR", "SCAVENGER"]
var mission_desc := ["Complete 5 eliminations", "Survive for 10 minutes", "Collect 20 supply items"]
var mission_goals := [5, 10, 20]
var mission_rewards := [300, 500, 700]
var pass_rewards := ["100 CREDITS", "TACTICAL SKIN", "250 CREDITS", "XP BOOST", "VOLT SMG-9"]

var character: Node3D
var weapon_display: Node3D
var main_content: VBoxContainer
var status_label: Label
var profile_label: Label
var currency_label: Label
var pulse := 0.0
var current_tab := "SHOWROOM"

func _ready() -> void:
    _load_profile()
    _make_showroom()
    _make_ui()
    _refresh()

func _process(delta: float) -> void:
    pulse += delta
    if character: character.rotation.y += delta * 0.18
    if weapon_display: weapon_display.rotation.y += delta * 0.55
    if status_label: status_label.modulate.a = 0.82 + sin(pulse * 2.0) * 0.16

func _load_profile() -> void:
    var c := ConfigFile.new()
    if c.load(SAVE_PATH) == OK:
        xp = int(c.get_value("profile", "xp", 0))
        level = int(c.get_value("profile", "level", 1))
        credits = int(c.get_value("profile", "credits", 1200))
        selected_weapon = int(c.get_value("profile", "selected_weapon", 0))
        owned = c.get_value("profile", "owned", owned)
        mission_progress = c.get_value("profile", "missions", mission_progress)
        claimed = c.get_value("profile", "claimed", claimed)
        selected_mode = str(c.get_value("profile", "mode", "BATTLE ROYALE"))
        pet_equipped = str(c.get_value("profile", "pet", "NOVA DRONE"))
        guild_name = str(c.get_value("profile", "guild", "IRON GUARD"))
        role = str(c.get_value("profile", "role", "RIFLER"))
    level = clampi(int(xp / 500) + 1, 1, 100)

func _save_profile() -> void:
    var c := ConfigFile.new()
    c.set_value("profile", "xp", xp)
    c.set_value("profile", "level", level)
    c.set_value("profile", "credits", credits)
    c.set_value("profile", "selected_weapon", selected_weapon)
    c.set_value("profile", "owned", owned)
    c.set_value("profile", "missions", mission_progress)
    c.set_value("profile", "claimed", claimed)
    c.set_value("profile", "mode", selected_mode)
    c.set_value("profile", "pet", pet_equipped)
    c.set_value("profile", "guild", guild_name)
    c.set_value("profile", "role", role)
    c.save(SAVE_PATH)

func _mat(c: Color, metal := 0.0, rough := 0.5, glow := Color.TRANSPARENT) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    if glow.a > 0.0:
        m.emission_enabled = true
        m.emission = glow
        m.emission_energy_multiplier = 2.0
    return m

func _part(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
    var n := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = mat
    parent.add_child(n)

func _make_showroom() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#050b14")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#9db8d2")
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env_node.environment = env
    add_child(env_node)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -30, 0)
    sun.light_energy = 1.5
    sun.shadow_enabled = true
    add_child(sun)
    var floor := MeshInstance3D.new()
    var fm := CylinderMesh.new()
    fm.top_radius = 6.5
    fm.bottom_radius = 6.5
    fm.height = 0.3
    floor.mesh = fm
    floor.position.y = -0.15
    floor.material_override = _mat(Color("#101c2a"), 0.65, 0.3)
    add_child(floor)
    character = Node3D.new()
    character.position = Vector3(-1.0, 0, 0)
    add_child(character)
    var armor := _mat(Color("#405366"), 0.85, 0.22)
    var dark := _mat(Color("#090f16"), 0.95, 0.18)
    var gold := _mat(Color("#c99b42"), 0.65, 0.25, Color("#5c3e10"))
    _part(character, Vector3(1.05,1.3,0.62), Vector3(0,1.25,0), armor)
    _part(character, Vector3(0.72,0.6,0.58), Vector3(0,2.15,0), dark)
    _part(character, Vector3(0.48,0.08,0.06), Vector3(0,2.16,-0.32), gold)
    _part(character, Vector3(0.38,1.0,0.42), Vector3(-0.35,0.2,0), dark)
    _part(character, Vector3(0.38,1.0,0.42), Vector3(0.35,0.2,0), dark)
    _part(character, Vector3(0.4,0.9,0.45), Vector3(-0.65,0.9,0), armor)
    _part(character, Vector3(0.4,0.9,0.45), Vector3(0.65,0.9,0), armor)
    _part(character, Vector3(0.45,0.9,0.45), Vector3(-0.3,-0.25,0), dark)
    _part(character, Vector3(0.45,0.9,0.45), Vector3(0.3,-0.25,0), dark)
    _part(character, Vector3(0.6,0.15,0.75), Vector3(-0.3,-0.72,-0.1), gold)
    _part(character, Vector3(0.6,0.15,0.75), Vector3(0.3,-0.72,-0.1), gold)
    weapon_display = Node3D.new()
    weapon_display.position = Vector3(2.0, 1.3, 0)
    add_child(weapon_display)
    _part(weapon_display, Vector3(2.2,0.2,0.25), Vector3(0,0,0), dark)
    _part(weapon_display, Vector3(0.75,0.3,0.3), Vector3(-0.65,-0.16,0), armor)
    _part(weapon_display, Vector3(0.34,0.72,0.28), Vector3(-0.25,-0.42,0), dark)
    _part(weapon_display, Vector3(0.32,0.18,0.32), Vector3(0.65,0,0), gold)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 2.5, 9)
    camera.look_at_from_position(camera.position, Vector3(0.4,1.0,0), Vector3.UP)
    camera.current = true
    add_child(camera)

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var shade := ColorRect.new()
    shade.color = Color(0.01,0.025,0.05,0.78)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(shade)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    layer.add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
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
    sub.text = "COMMAND CENTER // OFFLINE"
    sub.add_theme_font_size_override("font_size", 11)
    sub.add_theme_color_override("font_color", Color("5dc8ff"))
    brand.add_child(sub)
    var pbox := VBoxContainer.new()
    pbox.custom_minimum_size.x = 350
    header.add_child(pbox)
    profile_label = Label.new()
    profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    profile_label.add_theme_font_size_override("font_size", 17)
    pbox.add_child(profile_label)
    currency_label = Label.new()
    currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    currency_label.add_theme_color_override("font_color", Color("f3bd55"))
    pbox.add_child(currency_label)
    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 6)
    root.add_child(tabs)
    for tab in ["SHOWROOM","INVENTORY","RANK","MISSIONS","BATTLE PASS","FEATURES"]:
        var b := Button.new()
        b.text = tab
        b.custom_minimum_size.y = 46
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(_select.bind(tab))
        tabs.add_child(b)
    main_content = VBoxContainer.new()
    main_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_content.add_theme_constant_override("separation", 8)
    root.add_child(main_content)
    status_label = Label.new()
    status_label.text = "● LOCAL PROFILE SAVED  |  COMMAND SYSTEM ONLINE"
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_color_override("font_color", Color("5df2a3"))
    root.add_child(status_label)

func _select(tab: String) -> void:
    current_tab = tab
    _refresh()

func _clear() -> void:
    for c in main_content.get_children(): c.queue_free()

func _box(title_text: String) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var style := StyleBoxFlat.new()
    style.bg_color = Color("0a1726")
    style.border_color = Color("24435e")
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
    var h := Label.new()
    h.text = title_text
    h.add_theme_font_size_override("font_size", 18)
    h.add_theme_color_override("font_color", Color("5dc8ff"))
    box.add_child(h)
    return box

func _refresh() -> void:
    _clear()
    profile_label.text = "OPERATIVE 01   •   RANK %02d" % level
    currency_label.text = "%d XP   •   %d CREDITS" % [xp, credits]
    match current_tab:
        "SHOWROOM": _showroom_tab()
        "INVENTORY": _inventory_tab()
        "RANK": _rank_tab()
        "MISSIONS": _missions_tab()
        "BATTLE PASS": _pass_tab()
        "FEATURES": _features_tab()

func _showroom_tab() -> void:
    var b := _box("3D ARMORY SHOWROOM")
    var w: Dictionary = weapons[selected_weapon]
    var l := Label.new()
    l.text = "OPERATIVE MK-IV\n\nEQUIPPED: %s\n%s  •  DAMAGE %d  •  RATE %s  •  RANGE %s" % [w.name,w.type,w.damage,w.rate,w.range]
    l.add_theme_font_size_override("font_size", 20)
    b.add_child(l)
    var play := Button.new()
    play.text = "DEPLOY WITH %s   ▶" % w.name
    play.custom_minimum_size.y = 60
    play.add_theme_font_size_override("font_size", 21)
    play.pressed.connect(_start_battle)
    b.add_child(play)

func _inventory_tab() -> void:
    var b := _box("ARMORY / INVENTORY")
    var h := Label.new()
    h.text = "OWNED LOADOUTS • EQUIP OR PURCHASE WEAPONS"
    b.add_child(h)
    for i in weapons.size():
        var w: Dictionary = weapons[i]
        var button := Button.new()
        var state := "EQUIPPED" if i == selected_weapon else ("OWNED" if owned[i] else str(w.cost) + " CREDITS")
        button.text = w.name + "   |   " + w.type + "   |   " + state
        button.custom_minimum_size.y = 48
        button.pressed.connect(_equip.bind(i))
        b.add_child(button)

func _equip(i: int) -> void:
    if not owned[i]:
        if credits < int(weapons[i].cost):
            status_label.text = "● NOT ENOUGH CREDITS"
            return
        credits -= int(weapons[i].cost)
        owned[i] = true
    selected_weapon = i
    _save_profile()
    status_label.text = "● LOADOUT EQUIPPED"
    _refresh()

func _rank_tab() -> void:
    var b := _box("RANK / OPERATIVE PROGRESSION")
    var l := Label.new()
    l.text = "RANK %02d  •  %s\n%d / 500 XP TO NEXT RANK" % [level,_rank_name(level),xp % 500]
    l.add_theme_font_size_override("font_size", 25)
    l.add_theme_color_override("font_color", Color("f3bd55"))
    b.add_child(l)
    var bar := ProgressBar.new()
    bar.value = float(xp % 500) / 5.0
    bar.show_percentage = false
    bar.custom_minimum_size.y = 14
    b.add_child(bar)
    var info := Label.new()
    info.text = "CAREER XP: %d\nCREDITS: %d\nROLE: %s\nNEXT CLASS: %s" % [xp,credits,role,_rank_name(level + 1)]
    b.add_child(info)

func _rank_name(n: int) -> String:
    if n >= 50: return "VANGUARD"
    if n >= 30: return "ELITE"
    if n >= 15: return "OPERATIVE"
    if n >= 5: return "SPECIALIST"
    return "RECRUIT"

func _missions_tab() -> void:
    var b := _box("MISSIONS / OBJECTIVES")
    for i in 3:
        var p := min(mission_progress[i],mission_goals[i])
        var l := Label.new()
        l.text = "%s\n%s   •   %d/%d   •   +%d XP" % [mission_names[i],mission_desc[i],p,mission_goals[i],mission_rewards[i]]
        b.add_child(l)
        var bar := ProgressBar.new()
        bar.value = float(p) / float(mission_goals[i]) * 100.0
        bar.show_percentage = false
        bar.custom_minimum_size.y = 8
        b.add_child(bar)

func _pass_tab() -> void:
    var b := _box("BATTLE PASS / SEASON 01")
    var h := Label.new()
    h.text = "FREE OFFLINE SEASON TRACK\nCURRENT TIER %02d / 05" % min(level,5)
    b.add_child(h)
    for i in 5:
        var button := Button.new()
        var unlock := level >= i + 1
        var mark := "✓" if claimed[i] else ("🔓" if unlock else "🔒")
        button.text = "%s  TIER %02d  —  %s" % [mark,i+1,pass_rewards[i]]
        button.custom_minimum_size.y = 44
        button.pressed.connect(_claim.bind(i))
        b.add_child(button)

func _claim(i: int) -> void:
    if claimed[i]: return
    if level < i + 1:
        status_label.text = "● TIER LOCKED — EARN MORE XP"
        return
    claimed[i] = true
    credits += 100 + i * 50
    if i == 4: owned[1] = true
    _save_profile()
    status_label.text = "● BATTLE PASS REWARD CLAIMED"
    _refresh()

func _features_tab() -> void:
    var b := _box("BATTLE ZONE // MODES & SYSTEMS")
    var intro := Label.new()
    intro.text = "EXPANDED COMMAND SYSTEM — ORIGINAL BATTLE ZONE FEATURES"
    intro.add_theme_color_override("font_color", Color("a8bdd0"))
    b.add_child(intro)
    for mode in ["BATTLE ROYALE", "CLASH SQUAD", "TRAINING RANGE", "ZOMBIE HUNT"]:
        var m := Button.new()
        m.text = ("✓ " if selected_mode == mode else "") + mode
        m.custom_minimum_size.y = 42
        m.pressed.connect(_select_mode.bind(mode))
        b.add_child(m)
    var systems := Label.new()
    systems.text = "\nVEHICLES        ✓ OFF-ROAD SCOUT\nTHROWABLES      ✓ FRAG / SMOKE / EMP\nREVIVAL         ✓ REVIVE BEACON\nAIR DROPS       ✓ SUPPLY POD EVENTS\nCHARACTER       ✓ SKILL LOADOUTS\nPET COMPANION   ✓ %s\nGUILD           ✓ %s\nROLE            ✓ %s\nCRAFT ZONE      ✓ FIELD WORKSHOP\nSOCIAL          ✓ PROFILE / TITLES / STATUS" % [pet_equipped,guild_name,role]
    systems.add_theme_font_size_override("font_size", 16)
    systems.add_theme_color_override("font_color", Color("d9e8f4"))
    b.add_child(systems)
    var deploy := Button.new()
    deploy.text = "DEPLOY %s   ▶" % selected_mode
    deploy.custom_minimum_size.y = 55
    deploy.pressed.connect(_start_battle)
    b.add_child(deploy)

func _select_mode(mode: String) -> void:
    selected_mode = mode
    _save_profile()
    _refresh()

func _start_battle() -> void:
    _save_profile()
    get_tree().change_scene_to_file("res://Game3D.tscn")
