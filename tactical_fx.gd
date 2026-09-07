extends Node3D

var smoke_timer := 0.0
var dust_timer := 0.0

func _process(delta: float) -> void:
    smoke_timer -= delta
    dust_timer -= delta

func impact(pos: Vector3, strength := 1.0) -> void:
    var light := OmniLight3D.new()
    light.position = pos + Vector3.UP * 0.25
    light.light_color = Color("#ff9d4d")
    light.light_energy = 5.0 * strength
    light.omni_range = 4.0 * strength
    add_child(light)
    get_tree().create_timer(0.08).timeout.connect(func(): if is_instance_valid(light): light.queue_free())

func smoke(pos: Vector3) -> void:
    if smoke_timer > 0.0:
        return
    smoke_timer = 0.15
    for i in 5:
        var puff := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.35 + i * 0.07
        mesh.height = mesh.radius * 2.0
        puff.mesh = mesh
        puff.position = pos + Vector3(randf_range(-0.8,0.8), 0.35 + i * 0.25, randf_range(-0.8,0.8))
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.32,0.34,0.34,0.42)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.roughness = 1.0
        puff.material_override = mat
        add_child(puff)
        var tw := create_tween()
        tw.tween_property(puff, "scale", Vector3.ONE * 2.4, 1.8)
        tw.parallel().tween_property(puff, "position:y", puff.position.y + 1.8, 1.8)
        tw.tween_callback(puff.queue_free)

func dust(pos: Vector3) -> void:
    if dust_timer > 0.0:
        return
    dust_timer = 0.1
    var ring := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.15
    mesh.bottom_radius = 1.1
    mesh.height = 0.08
    ring.mesh = mesh
    ring.position = pos + Vector3.UP * 0.05
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.38,0.32,0.24,0.35)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ring.material_override = mat
    add_child(ring)
    var tw := create_tween()
    tw.tween_property(ring, "scale", Vector3.ONE * 2.2, 0.45)
    tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.45)
    tw.tween_callback(ring.queue_free)
