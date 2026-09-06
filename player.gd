extends Node2D

var speed := 300.0
var health := 100.0
var max_health := 100.0
var ammo := 60
var fire_cooldown := 0.0
var aim := Vector2.RIGHT
var alive := true
var kills := 0
var radius := 18.0

func _process(delta: float) -> void:
    if not alive:
        return
    fire_cooldown = max(0.0, fire_cooldown - delta)
    queue_redraw()

func move_direction() -> Vector2:
    var d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return d.normalized() if d.length() > 0.0 else Vector2.ZERO

func try_fire(target: Vector2) -> bool:
    if not alive or ammo <= 0 or fire_cooldown > 0.0:
        return false
    aim = (target - global_position).normalized()
    ammo -= 1
    fire_cooldown = 0.12
    return true

func damage(amount: float) -> void:
    if not alive:
        return
    health -= amount
    if health <= 0.0:
        health = 0.0
        alive = false
    queue_redraw()

func heal(amount: float) -> void:
    health = min(max_health, health + amount)
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, radius, Color("#2b9cff"))
    draw_circle(Vector2.ZERO, radius - 5.0, Color("#0b1730"))
    draw_circle(Vector2(5, -5), 4.0, Color("#ffffff"))
    var gun_end := aim.normalized() * 28.0
    draw_line(Vector2.ZERO, gun_end, Color("#e7edf7"), 7.0, true)
    draw_arc(Vector2.ZERO, radius + 3.0, -PI / 2.0, -PI / 2.0 + TAU * (health / max_health), 24, Color("#58f58a"), 3.0, true)
