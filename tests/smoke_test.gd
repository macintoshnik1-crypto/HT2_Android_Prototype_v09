extends SceneTree

# Runs inside Godot 4.4.1: godot --headless --path . --script res://tests/smoke_test.gd
# Fails with non-zero exit status on assertions. No Android device is required.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    if scene == null:
        push_error("Cannot load main scene")
        quit(1)
        return
    var root: Node = scene.instantiate()
    get_root().add_child(root)
    await process_frame
    await process_frame
    var truck: Node3D = root.get("truck") as Node3D
    var camera: Camera3D = root.get("camera") as Camera3D
    var tiles: Array = root.get("road_tiles")
    if truck == null or camera == null or tiles.size() != 9:
        push_error("World initialization failed")
        quit(2)
        return
    var start_pos: Vector3 = truck.position
    root.call("_control_changed", "gas", true)
    for i in range(45):
        await physics_frame
    root.call("_control_changed", "gas", false)
    if truck.position.distance_to(start_pos) <= 0.01:
        push_error("Truck did not move after throttle")
        quit(3)
        return
    root.call("_toggle_camera")
    if not root.get("camera_inside"):
        push_error("Camera toggle failed")
        quit(4)
        return
    root.call("_reset_truck")
    if truck.position.length() > 0.001 or root.get("speed") != 0.0 or root.get("distance_m") != 0.0:
        push_error("Reset failed")
        quit(5)
        return
    print("SMOKE_TEST_PASS: world, throttle, camera, reset")
    quit(0)
