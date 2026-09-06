extends Node2D

var speed := 120.0
var health := 45.0
var fire_timer := 0.0
var target: Node2D
var alive := true
var radius := 15.0

func setup(player: Node2D) -> void:
    target = player

func _process(delta: float) -> void:
    if not alive or not is_instance_valid(target) or not target.alive:
        return
    fire_timer = max(0.0, fire_timer - delta)
    var to_player := target.global_position - global_position
    var distance := to_player.length()
    if distance > 230.0:
        global_position += to_player.normalized() * speed * delta
    elif distance > 110.0:
        var side := Vector2(-to_player.y, to_player.x).normalized()
        global_position += (side * sin(Time.get_ticks_msec() * 0.002 + global_position.x) * 0.35) * speed * delta
    queue_redraw()

func can_fire() -> bool:
    if not alive or fire_timer > 0.0 or not is_instance_valid(target):
        return false
    if global_position.distance_to(target.global_position) > 420.0:
        return false
    fire_timer = 0.8 + randf() * 0.8
    return true

func damage(amount: float) -> void:
    if not alive:
        return
    health -= amount
    if health <= 0.0:
        health = 0.0
        alive = false
        queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, radius, Color("#ff5b61"))
    draw_circle(Vector2.ZERO, radius - 5.0, Color("#32151c"))
    draw_circle(Vector2(4, -4), 3.0, Color("#ffffff"))
    if is_instance_valid(target):
        draw_line(Vector2.ZERO, (target.global_position - global_position).normalized() * 23.0, Color("#ffcc66"), 5.0, true)
    draw_arc(Vector2.ZERO, radius + 3.0, -PI / 2.0, -PI / 2.0 + TAU * (health / 45.0), 20, Color("#ff8b8f"), 2.0, true)
