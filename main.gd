extends Node2D

const PLAYER_SCRIPT = preload("res://player.gd")
const BOT_SCRIPT = preload("res://bot.gd")
const BULLET_SCRIPT = preload("res://bullet.gd")

const WORLD_SIZE := Vector2(3000, 2200)
const WORLD_CENTER := WORLD_SIZE * 0.5
const BOT_COUNT := 18

var player: Node2D
var bots: Array[Node2D] = []
var bullets: Array[Node2D] = []
var loot: Array[Dictionary] = []
var safe_radius := 900.0
var zone_time := 0.0
var match_time := 0.0
var game_over := false
var win := false
var virtual_move := Vector2.ZERO
var hud: CanvasLayer
var status_label: Label
var stats_label: Label
var zone_label: Label
var fire_button: Button
var restart_button: Button

func _ready() -> void:
    randomize()
    _create_player()
    _create_bots()
    _create_loot()
    _create_hud()
    queue_redraw()

func _create_player() -> void:
    player = Node2D.new()
    player.set_script(PLAYER_SCRIPT)
    player.position = WORLD_CENTER
    add_child(player)
    var camera := Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 7.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(WORLD_SIZE.x)
    camera.limit_bottom = int(WORLD_SIZE.y)
    player.add_child(camera)

func _create_bots() -> void:
    for i in BOT_COUNT:
        var bot := Node2D.new()
        bot.set_script(BOT_SCRIPT)
        var angle := randf() * TAU
        var distance := randf_range(350.0, 850.0)
        bot.position = WORLD_CENTER + Vector2(cos(angle), sin(angle)) * distance
        bot.setup(player)
        add_child(bot)
        bots.append(bot)

func _create_loot() -> void:
    for i in 24:
        var kind := "medkit" if i % 3 == 0 else "ammo"
        loot.append({"position": Vector2(randf_range(180.0, WORLD_SIZE.x - 180.0), randf_range(180.0, WORLD_SIZE.y - 180.0)), "kind": kind, "taken": false})

func _create_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)

    var panel := ColorRect.new()
    panel.position = Vector2(18, 18)
    panel.size = Vector2(355, 112)
    panel.color = Color(0.02, 0.05, 0.10, 0.82)
    hud.add_child(panel)

    stats_label = Label.new()
    stats_label.position = Vector2(34, 28)
    stats_label.add_theme_font_size_override("font_size", 22)
    hud.add_child(stats_label)

    zone_label = Label.new()
    zone_label.position = Vector2(34, 66)
    zone_label.add_theme_font_size_override("font_size", 18)
    hud.add_child(zone_label)

    status_label = Label.new()
    status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    status_label.position = Vector2(-300, 25)
    status_label.size = Vector2(600, 60)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 30)
    hud.add_child(status_label)

    _add_mobile_controls()

func _add_mobile_controls() -> void:
    var left := _make_control_button("◀", Vector2(32, 560), Vector2(70, 70))
    var right := _make_control_button("▶", Vector2(178, 560), Vector2(70, 70))
    var up := _make_control_button("▲", Vector2(105, 488), Vector2(70, 70))
    var down := _make_control_button("▼", Vector2(105, 632), Vector2(70, 70))
    left.button_down.connect(func(): virtual_move.x = -1.0)
    left.button_up.connect(func(): if virtual_move.x < 0: virtual_move.x = 0.0)
    right.button_down.connect(func(): virtual_move.x = 1.0)
    right.button_up.connect(func(): if virtual_move.x > 0: virtual_move.x = 0.0)
    up.button_down.connect(func(): virtual_move.y = -1.0)
    up.button_up.connect(func(): if virtual_move.y < 0: virtual_move.y = 0.0)
    down.button_down.connect(func(): virtual_move.y = 1.0)
    down.button_up.connect(func(): if virtual_move.y > 0: virtual_move.y = 0.0)

    fire_button = _make_control_button("FIRE", Vector2(1090, 555), Vector2(150, 110))
    fire_button.add_theme_font_size_override("font_size", 26)
    fire_button.button_down.connect(_mobile_fire)

    var hint := Label.new()
    hint.text = "WASD / ARROWS + MOUSE  •  Mobile: buttons + FIRE"
    hint.position = Vector2(20, 680)
    hint.add_theme_font_size_override("font_size", 15)
    hud.add_child(hint)

func _make_control_button(text: String, pos: Vector2, size: Vector2) -> Button:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = size
    b.modulate = Color(1, 1, 1, 0.82)
    b.add_theme_font_size_override("font_size", 28)
    hud.add_child(b)
    return b

func _mobile_fire() -> void:
    if game_over or not player.alive:
        return
    var target := _nearest_bot_position()
    if target != Vector2.INF:
        _fire_player(target)

func _nearest_bot_position() -> Vector2:
    var best := Vector2.INF
    var best_dist := INF
    for bot in bots:
        if is_instance_valid(bot) and bot.alive:
            var d := player.global_position.distance_squared_to(bot.global_position)
            if d < best_dist:
                best_dist = d
                best = bot.global_position
    return best

func _process(delta: float) -> void:
    if game_over:
        queue_redraw()
        return

    match_time += delta
    zone_time += delta
    safe_radius = max(170.0, 900.0 - zone_time * 2.0)

    if player.alive:
        var d := player.move_direction()
        if virtual_move.length() > 0.0:
            d = virtual_move.normalized()
        player.global_position += d * player.speed * delta
        player.global_position.x = clamp(player.global_position.x, 40.0, WORLD_SIZE.x - 40.0)
        player.global_position.y = clamp(player.global_position.y, 40.0, WORLD_SIZE.y - 40.0)

        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _fire_player(get_global_mouse_position())

        if player.global_position.distance_to(WORLD_CENTER) > safe_radius:
            player.damage(12.0 * delta)

        _collect_loot()

    for bot in bots:
        if not is_instance_valid(bot) or not bot.alive:
            continue
        if bot.global_position.distance_to(WORLD_CENTER) > safe_radius:
            bot.damage(10.0 * delta)
        if bot.can_fire():
            _fire_bot(bot)

    _update_bullets()
    _cleanup_dead_bots()
    _update_hud()

    if not player.alive:
        game_over = true
        win = false
    elif _living_bots() == 0:
        game_over = true
        win = true

    queue_redraw()

func _fire_player(target: Vector2) -> void:
    if not player.try_fire(target):
        return
    var bullet := Node2D.new()
    bullet.set_script(BULLET_SCRIPT)
    add_child(bullet)
    bullet.setup(player.global_position + player.aim.normalized() * 26.0, player.aim, true, 25.0)
    bullets.append(bullet)

func _fire_bot(bot: Node2D) -> void:
    var direction := (player.global_position - bot.global_position).normalized()
    var bullet := Node2D.new()
    bullet.set_script(BULLET_SCRIPT)
    add_child(bullet)
    bullet.setup(bot.global_position + direction * 23.0, direction, false, 9.0)
    bullets.append(bullet)

func _update_bullets() -> void:
    for bullet in bullets.duplicate():
        if not is_instance_valid(bullet):
            bullets.erase(bullet)
            continue
        if bullet.owner_is_player:
            for bot in bots:
                if is_instance_valid(bot) and bot.alive and bullet.global_position.distance_to(bot.global_position) < 23.0:
                    bot.damage(bullet.damage)
                    bullet.queue_free()
                    break
        else:
            if player.alive and bullet.global_position.distance_to(player.global_position) < 24.0:
                player.damage(bullet.damage)
                bullet.queue_free()

func _collect_loot() -> void:
    for item in loot:
        if item.taken:
            continue
        if player.global_position.distance_to(item.position) < 38.0:
            item.taken = true
            if item.kind == "medkit":
                player.heal(30.0)
            else:
                player.ammo += 25

func _cleanup_dead_bots() -> void:
    for bot in bots:
        if is_instance_valid(bot) and not bot.alive and not bot.get_meta("counted", false):
            bot.set_meta("counted", true)
            player.kills += 1

func _living_bots() -> int:
    var count := 0
    for bot in bots:
        if is_instance_valid(bot) and bot.alive:
            count += 1
    return count

func _update_hud() -> void:
    stats_label.text = "HP %d/%d     Ammo %d     Kills %d" % [int(player.health), int(player.max_health), player.ammo, player.kills]
    zone_label.text = "Players: %d     Safe zone: %dm" % [_living_bots() + (1 if player.alive else 0), int(safe_radius)]
    if not game_over:
        status_label.text = "BATTLE ROYALE"
    else:
        status_label.text = "VICTORY!" if win else "ELIMINATED"
        if restart_button == null:
            restart_button = Button.new()
            restart_button.text = "PLAY AGAIN"
            restart_button.position = Vector2(500, 120)
            restart_button.size = Vector2(280, 70)
            restart_button.add_theme_font_size_override("font_size", 24)
            restart_button.pressed.connect(_restart)
            hud.add_child(restart_button)

func _restart() -> void:
    get_tree().reload_current_scene()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#10251c"))
    var grid := 100
    for x in range(0, int(WORLD_SIZE.x) + 1, grid):
        draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), Color(0.12, 0.25, 0.18, 0.45), 1.0)
    for y in range(0, int(WORLD_SIZE.y) + 1, grid):
        draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), Color(0.12, 0.25, 0.18, 0.45), 1.0)

    draw_circle(WORLD_CENTER, 900.0, Color(0.2, 0.55, 0.95, 0.05))
    draw_circle(WORLD_CENTER, safe_radius, Color(0.15, 0.75, 1.0, 0.035))
    draw_arc(WORLD_CENTER, safe_radius, 0, TAU, 120, Color(0.35, 0.85, 1.0, 0.85), 5.0, true)

    for item in loot:
        if item.taken:
            continue
        var c := Color("#62d8ff") if item.kind == "ammo" else Color("#64f28b")
        draw_circle(item.position, 12.0, c)
        draw_circle(item.position, 5.0, Color("#10251c"))

    draw_circle(WORLD_CENTER, 10.0, Color("#ffffff"))
