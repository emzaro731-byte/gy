extends Node2D

var speed := 135.0
var health := 70.0
var max_health := 70.0
var fire_timer := 0.0
var target: Node2D
var alive := true
var radius := 18.0
var strafe_phase := 0.0
var hit_flash := 0.0
var body_t := 0.0

func setup(player: Node2D) -> void:
    target = player
    strafe_phase = randf() * TAU

func _process(delta: float) -> void:
    if not alive or not is_instance_valid(target) or not target.alive:
        return
    fire_timer = max(0.0, fire_timer - delta)
    hit_flash = max(0.0, hit_flash - delta)
    body_t += delta
    var to_player := target.global_position - global_position
    var distance := to_player.length()
    if distance > 260.0:
        global_position += to_player.normalized() * speed * delta
    elif distance > 120.0:
        var side := Vector2(-to_player.y, to_player.x).normalized()
        var strafe := sin(body_t * 2.7 + strafe_phase)
        global_position += (to_player.normalized() * 0.22 + side * strafe * 0.8) * speed * delta
    else:
        var side := Vector2(-to_player.y, to_player.x).normalized()
        global_position += (side * sin(body_t * 3.2 + strafe_phase) - to_player.normalized() * 0.12) * speed * delta
    queue_redraw()

func can_fire() -> bool:
    if not alive or fire_timer > 0.0 or not is_instance_valid(target):
        return false
    if global_position.distance_to(target.global_position) > 460.0:
        return false
    fire_timer = 0.65 + randf() * 0.65
    return true

func damage(amount: float) -> void:
    if not alive:
        return
    health = max(0.0, health - amount)
    hit_flash = 0.12
    if health <= 0.0:
        alive = false
    queue_redraw()

func _draw() -> void:
    var flash := Color("#ffffff") if hit_flash > 0.0 else Color("#55616a")
    # Robot shadow and legs
    draw_ellipse(Vector2(0, 22), Vector2(23, 8), Color(0, 0, 0, 0.35))
    draw_rect(Rect2(-14, 10, 10, 20), Color("#20282e"), true)
    draw_rect(Rect2(4, 10, 10, 20), Color("#20282e"), true)
    draw_rect(Rect2(-17, 25, 15, 6), Color("#11171b"), true)
    draw_rect(Rect2(2, 25, 15, 6), Color("#11171b"), true)
    # Torso armor
    draw_polygon(PackedVector2Array([Vector2(-22,-15),Vector2(22,-15),Vector2(18,13),Vector2(-18,13)]), PackedColorArray([flash]))
    draw_rect(Rect2(-15,-8,30,15), Color("#171e24"), true)
    draw_line(Vector2(-17,-13), Vector2(-17,10), Color("#9aa6ad"), 3.0)
    draw_line(Vector2(17,-13), Vector2(17,10), Color("#9aa6ad"), 3.0)
    draw_rect(Rect2(-7,7,14,5), Color("#c49a45"), true)
    # Shoulder joints and arms
    draw_circle(Vector2(-24,-8), 6, Color("#090d10"))
    draw_circle(Vector2(24,-8), 6, Color("#090d10"))
    draw_rect(Rect2(-31,-2,9,22), Color("#3b464d"), true)
    draw_rect(Rect2(22,-2,9,22), Color("#3b464d"), true)
    # Head / helmet
    draw_rect(Rect2(-15,-33,30,21), Color("#10161b"), true)
    draw_rect(Rect2(-11,-27,22,6), Color("#76eaff"), true)
    draw_line(Vector2(-13,-32), Vector2(-17,-20), Color("#9aa6ad"), 3.0)
    draw_line(Vector2(13,-32), Vector2(17,-20), Color("#9aa6ad"), 3.0)
    draw_line(Vector2(0,-35), Vector2(0,-39), Color("#c49a45"), 2.0)
    draw_circle(Vector2(0,-41), 2.5, Color("#ff5252"))
    # Rifle
    var aim_dir := (target.global_position - global_position).normalized() if is_instance_valid(target) else Vector2.RIGHT
    draw_line(Vector2(9,2), aim_dir * 38.0, Color("#151b20"), 7.0, true)
    draw_line(Vector2(12,1), aim_dir * 38.0, Color("#b4bec5"), 2.0, true)
    draw_circle(aim_dir * 40.0, 3.0, Color("#ff5b61"))
    # Health bar
    draw_rect(Rect2(-25,-49,50,5), Color(0.03,0.03,0.03,0.85), true)
    draw_rect(Rect2(-24,-48,48 * (health / max_health),3), Color("#54e88b"), true)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in 32:
        var a := TAU * float(i) / 32.0
        points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
    draw_colored_polygon(points, color)
