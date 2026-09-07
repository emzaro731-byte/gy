extends Control

var settings_panel: PanelContainer
var status_label: Label
var pulse_time := 0.0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_lobby()

func _process(delta: float) -> void:
    pulse_time += delta
    if status_label:
        var pulse := 0.75 + sin(pulse_time * 2.2) * 0.2
        status_label.modulate.a = pulse

func _build_lobby() -> void:
    var bg := ColorRect.new()
    bg.color = Color("07111f")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var top_glow := ColorRect.new()
    top_glow.color = Color("102b45")
    top_glow.position = Vector2(0, 0)
    top_glow.size = Vector2(1280, 170)
    top_glow.modulate.a = 0.7
    add_child(top_glow)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 42)
    margin.add_theme_constant_override("margin_right", 42)
    margin.add_theme_constant_override("margin_top", 30)
    margin.add_theme_constant_override("margin_bottom", 30)
    add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 18)
    margin.add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 70
    root.add_child(header)

    var brand := VBoxContainer.new()
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(brand)

    var title := Label.new()
    title.text = "BATTLE ZONE"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color("e9f3ff"))
    brand.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "OFFLINE // TACTICAL SURVIVAL"
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", Color("5dc8ff"))
    brand.add_child(subtitle)

    var profile := PanelContainer.new()
    profile.custom_minimum_size = Vector2(260, 66)
    header.add_child(profile)
    var profile_box := VBoxContainer.new()
    profile.add_child(profile_box)
    var player_name := Label.new()
    player_name.text = "OPERATIVE 01"
    player_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    player_name.add_theme_font_size_override("font_size", 17)
    profile_box.add_child(player_name)
    var rank := Label.new()
    rank.text = "RANK 01  •  RECRUIT"
    rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rank.add_theme_font_size_override("font_size", 12)
    rank.add_theme_color_override("font_color", Color("f3bd55"))
    profile_box.add_child(rank)

    var content := HBoxContainer.new()
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 20)
    root.add_child(content)

    var character := _make_panel("OPERATIVE", 0.36)
    content.add_child(character)
    var char_box := character.get_child(0) as VBoxContainer

    var soldier := Label.new()
    soldier.text = "ASSAULT\nMK-IV"
    soldier.add_theme_font_size_override("font_size", 30)
    soldier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    char_box.add_child(soldier)

    var silhouette := Label.new()
    silhouette.text = "◉\n╱█╲\n╱ ╲"
    silhouette.add_theme_font_size_override("font_size", 42)
    silhouette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    silhouette.add_theme_color_override("font_color", Color("9ab2c7"))
    char_box.add_child(silhouette)

    _add_stat(char_box, "ARMOR", 82)
    _add_stat(char_box, "MOBILITY", 74)
    _add_stat(char_box, "POWER", 88)

    var center := _make_panel("DEPLOYMENT", 0.64)
    content.add_child(center)
    var center_box := center.get_child(0) as VBoxContainer

    var mode := Label.new()
    mode.text = "BATTLE ROYALE"
    mode.add_theme_font_size_override("font_size", 28)
    mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mode.add_theme_color_override("font_color", Color("f3bd55"))
    center_box.add_child(mode)

    var desc := Label.new()
    desc.text = "SOLO  •  21 OPERATIVES  •  LAST SURVIVOR WINS"
    desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_color_override("font_color", Color("a9c0d3"))
    center_box.add_child(desc)

    var ready := Label.new()
    ready.text = "READY TO DEPLOY"
    ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ready.add_theme_font_size_override("font_size", 19)
    ready.add_theme_color_override("font_color", Color("5df2a3"))
    center_box.add_child(ready)

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    center_box.add_child(spacer)

    var play := Button.new()
    play.text = "  PLAY BATTLE  ▶  "
    play.custom_minimum_size.y = 76
    play.add_theme_font_size_override("font_size", 24)
    play.add_theme_color_override("font_color", Color("07111f"))
    play.pressed.connect(_start_battle)
    center_box.add_child(play)

    var hint := Label.new()
    hint.text = "20 BOTS  •  SHRINKING ZONE  •  LOOT  •  MOBILE CONTROLS"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 11)
    hint.add_theme_color_override("font_color", Color("7894aa"))
    center_box.add_child(hint)

    var side := _make_panel("SYSTEM", 0.0)
    content.add_child(side)
    var side_box := side.get_child(0) as VBoxContainer
    var system := Label.new()
    system.text = "SYSTEM ONLINE"
    system.add_theme_color_override("font_color", Color("5df2a3"))
    system.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    side_box.add_child(system)
    _add_info(side_box, "MODE", "OFFLINE")
    _add_info(side_box, "MAP", "IRON VALLEY")
    _add_info(side_box, "WEATHER", "CLEAR")
    _add_info(side_box, "VERSION", "1.0")

    var settings := Button.new()
    settings.text = "⚙ SETTINGS"
    settings.custom_minimum_size.y = 54
    settings.pressed.connect(_toggle_settings)
    side_box.add_child(settings)

    status_label = Label.new()
    status_label.text = "● SERVER: LOCAL  |  CONNECTION: STABLE"
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 12)
    status_label.add_theme_color_override("font_color", Color("5dc8ff"))
    root.add_child(status_label)

    var footer := Label.new()
    footer.text = "BATTLE ZONE: OFFLINE     •     ORIGINAL GAME     •     v1.0"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 10)
    footer.add_theme_color_override("font_color", Color("536b80"))
    root.add_child(footer)

func _make_panel(heading: String, _width_hint: float) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _panel_style())
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    panel.add_child(box)
    var label := Label.new()
    label.text = heading
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 13)
    label.add_theme_color_override("font_color", Color("5dc8ff"))
    box.add_child(label)
    return panel

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("0d1c2d")
    style.border_color = Color("23415b")
    style.set_border_width_all(1)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    style.content_margin_left = 20
    style.content_margin_right = 20
    style.content_margin_top = 18
    style.content_margin_bottom = 18
    return style

func _add_stat(parent: VBoxContainer, name: String, value: int) -> void:
    var label := Label.new()
    label.text = name + "   " + str(value) + "%"
    label.add_theme_font_size_override("font_size", 12)
    parent.add_child(label)
    var bar := ProgressBar.new()
    bar.value = value
    bar.show_percentage = false
    bar.custom_minimum_size.y = 7
    parent.add_child(bar)

func _add_info(parent: VBoxContainer, key: String, value: String) -> void:
    var label := Label.new()
    label.text = key + "\n" + value
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", Color("9bb1c4"))
    parent.add_child(label)

func _start_battle() -> void:
    get_tree().change_scene_to_file("res://Game3D.tscn")

func _toggle_settings() -> void:
    if settings_panel:
        settings_panel.queue_free()
        settings_panel = null
        return

    settings_panel = PanelContainer.new()
    settings_panel.position = Vector2(350, 180)
    settings_panel.size = Vector2(580, 360)
    settings_panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(settings_panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 16)
    settings_panel.add_child(box)
    var title := Label.new()
    title.text = "SYSTEM SETTINGS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    box.add_child(title)

    var sound := Button.new()
    sound.text = "SOUND     ON"
    sound.custom_minimum_size.y = 54
    box.add_child(sound)
    sound.pressed.connect(func(): sound.text = "SOUND     OFF" if sound.text.ends_with("ON") else "SOUND     ON")

    var music := Button.new()
    music.text = "MUSIC     ON"
    music.custom_minimum_size.y = 54
    box.add_child(music)
    music.pressed.connect(func(): music.text = "MUSIC     OFF" if music.text.ends_with("ON") else "MUSIC     ON")

    var close := Button.new()
    close.text = "CLOSE"
    close.custom_minimum_size.y = 54
    box.add_child(close)
    close.pressed.connect(_toggle_settings)
