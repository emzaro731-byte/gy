extends Node2D

var velocity := Vector2.ZERO
var damage := 20.0
var owner_is_player := true
var life := 1.6

func setup(start: Vector2, direction: Vector2, player_owned: bool, amount: float = 20.0) -> void:
    global_position = start
    velocity = direction.normalized() * 720.0
    owner_is_player = player_owned
    damage = amount

func _process(delta: float) -> void:
    global_position += velocity * delta
    life -= delta
    queue_redraw()
    if life <= 0.0:
        queue_free()

func _draw() -> void:
    draw_circle(Vector2.ZERO, 4.0, Color("#ffe27a"))
    draw_line(-velocity.normalized() * 7.0, Vector2.ZERO, Color("#ffffff"), 2.0, true)
