extends Node2D

var speed := 300.0
var health := 100.0
var max_health := 100.0
var ammo := 60
var fire_cooldown := 0.0
var aim := Vector2.RIGHT
var alive := true
var kills := 0
var radius := 20.0
var walk_t := 0.0

func _process(delta: float) -> void:
    if not alive:
        return
    fire_cooldown = max(0.0, fire_cooldown - delta)
    walk_t += delta
    queue_redraw()

func move_direction() -> Vector2:
    var d := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): d.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): d.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): d.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): d.y += 1.0
    return d.normalized() if d.length() > 0.0 else Vector2.ZERO

func try_fire(target: Vector2) -> bool:
    if not alive or ammo <= 0 or fire_cooldown > 0.0:
        return false
    aim = (target - global_position).normalized()
    ammo -= 1
    fire_cooldown = 0.10
    return true

func damage(amount: float) -> void:
    if not alive: return
    health = max(0.0, health - amount)
    if health <= 0.0: alive = false
    queue_redraw()

func heal(amount: float) -> void:
    health = min(max_health, health + amount)
    queue_redraw()

func _draw() -> void:
    # Premium armored player soldier silhouette
    var bob := sin(walk_t * 10.0) * 1.5
    draw_ellipse(Vector2(0, 25), Vector2(25, 8), Color(0,0,0,0.35))
    draw_rect(Rect2(-14, 8+bob, 10, 22), Color("#24303a"), true)
    draw_rect(Rect2(4, 8-bob, 10, 22), Color("#24303a"), true)
    draw_rect(Rect2(-18, 25, 15, 6), Color("#10161c"), true)
    draw_rect(Rect2(3, 25, 15, 6), Color("#10161c"), true)
    draw_polygon(PackedVector2Array([Vector2(-23,-14),Vector2(23,-14),Vector2(18,14),Vector2(-18,14)]), PackedColorArray([Color("#2d6f9e")]))
    draw_rect(Rect2(-14,-7,28,14), Color("#0b1730"), true)
    draw_line(Vector2(-17,-12), Vector2(-17,10), Color("#78a7c5"), 3.0)
    draw_line(Vector2(17,-12), Vector2(17,10), Color("#78a7c5"), 3.0)
    draw_circle(Vector2(-24,-5), 6, Color("#18232c"))
    draw_circle(Vector2(24,-5), 6, Color("#18232c"))
    draw_rect(Rect2(-30,0,9,19), Color("#31566f"), true)
    draw_rect(Rect2(21,0,9,19), Color("#31566f"), true)
    draw_rect(Rect2(-15,-34,30,22), Color("#101820"), true)
    draw_rect(Rect2(-11,-28,22,6), Color("#69eaff"), true)
    draw_circle(Vector2(0,-38), 3, Color("#59dfff"))
    var gun_end := aim.normalized() * 39.0
    draw_line(Vector2(10,1), gun_end, Color("#11171d"), 8.0, true)
    draw_line(Vector2(11,0), gun_end, Color("#d7e1e8"), 2.0, true)
    draw_circle(gun_end, 3.0, Color("#ffcf66"))
    draw_rect(Rect2(-27,-49,54,5), Color(0.03,0.03,0.03,0.9), true)
    draw_rect(Rect2(-26,-48,52 * (health/max_health),3), Color("#58f58a"), true)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in 32:
        var a := TAU * float(i) / 32.0
        points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
    draw_colored_polygon(points, color)
