extends Node3D

# Original Hard Truck 2 physics is NOT implemented here.
# This is a synthetic test vehicle for Android graphics/input validation.
var speed: float = 0.0
var heading: float = 0.0
var steering: float = 0.0
var throttle: float = 0.0
var braking: float = 0.0
var left_pressed: bool = false
var right_pressed: bool = false
var truck: Node3D
var camera: Camera3D
var speed_label: Label
var camera_inside: bool = false
var steering_buttons: Array[Button] = []
var input_buttons: Dictionary = {}
var ui_root: Control
var distance_m: float = 0.0
var frame_count: int = 0
var elapsed_seconds: float = 0.0
var fps_label: Label
var pause_label: Label
var road_tiles: Array[Node3D] = []
const TILE_LENGTH: float = 100.0
const TILE_COUNT: int = 9
var last_tile_index: int = -999999
var last_tile_lane: int = -999999
const ROAD_WIDTH: float = 12.0

func _ready() -> void:
    _make_world()
    _make_ui()
    _configure_keyboard()
    get_viewport().size_changed.connect(_layout_controls)
    get_tree().application_focus_out.connect(_release_controls)
    _layout_controls()
    _reset_camera_immediately()

func _make_world() -> void:
    var env := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color(0.54, 0.75, 0.92)
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color(0.8, 0.84, 0.92)
    env.environment = settings
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, -30, 0)
    add_child(sun)
    _make_road_tiles()
    truck = Node3D.new()
    add_child(truck)
    _box(Vector3(0, 1.15, 0.3), Vector3(2.4, 1.6, 5.0), Color(0.15, 0.30, 0.75), truck)
    _box(Vector3(0, 2.15, -1.25), Vector3(2.3, 1.5, 1.9), Color(0.83, 0.18, 0.12), truck)
    for z in [-1.3, 1.8]:
        for x in [-1.25, 1.25]:
            _box(Vector3(x, 0.52, z), Vector3(0.45, 0.95, 0.9), Color(0.08, 0.08, 0.09), truck)
    _update_road_tiles(true)
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 68
    add_child(camera)

# Reuse nine lightweight road tiles instead of creating an enormous map.
# This is a synthetic test road, NOT reconstructed HT2 map data.
func _make_road_tiles() -> void:
    for i in range(TILE_COUNT):
        var tile := Node3D.new()
        tile.name = "RoadTile_%d" % i
        add_child(tile)
        _box(Vector3(0, -0.16, 0), Vector3(120, 0.3, TILE_LENGTH), Color(0.19, 0.40, 0.20), tile)
        _box(Vector3(0, 0.01, 0), Vector3(12, 0.04, TILE_LENGTH), Color(0.17, 0.17, 0.19), tile)
        for mark in range(-4, 5):
            _box(Vector3(0, 0.045, float(mark) * 10.0), Vector3(0.17, 0.01, 4.0), Color(0.95, 0.88, 0.63), tile)
        road_tiles.append(tile)

func _update_road_tiles(force: bool = false) -> void:
    if truck == null:
        return
    var center_index := roundi(truck.position.z / TILE_LENGTH)
    # Move the synthetic strip in X as well as Z so it remains visible
    # during steering tests. This is NOT a reconstructed road network.
    var lane_index := roundi(truck.position.x / ROAD_WIDTH)
    if not force and center_index == last_tile_index and lane_index == last_tile_lane:
        return
    last_tile_index = center_index
    last_tile_lane = lane_index
    var half_count: int = int(TILE_COUNT / 2)
    for i in range(TILE_COUNT):
        road_tiles[i].position.z = float(center_index + i - half_count) * TILE_LENGTH
        road_tiles[i].position.x = float(lane_index) * ROAD_WIDTH

func _box(pos: Vector3, dims: Vector3, tint: Color, parent: Node3D) -> void:
    var mesh := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = dims
    mesh.mesh = cube
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mesh.material_override = mat
    mesh.position = pos
    parent.add_child(mesh)

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var hud := Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(hud)
    ui_root = hud
    speed_label = Label.new()
    speed_label.position = Vector2(25, 18)
    speed_label.add_theme_font_size_override("font_size", 24)
    speed_label.text = "HT2 ANDROID TECH DEMO | 0 km/h"
    hud.add_child(speed_label)
    var controls := [
        ["◀", "left", Vector2(0.04, 0.77)],
        ["▶", "right", Vector2(0.18, 0.77)],
        ["BRAKE", "brake", Vector2(0.69, 0.77)],
        ["GAS", "gas", Vector2(0.84, 0.77)]
    ]
    for item in controls:
        var button := Button.new()
        button.text = item[0]
        button.anchor_left = item[2].x
        button.anchor_right = item[2].x
        button.anchor_top = item[2].y
        button.anchor_bottom = item[2].y
        button.offset_right = 130
        button.offset_bottom = 105
        button.custom_minimum_size = Vector2(130, 105)
        button.mouse_filter = Control.MOUSE_FILTER_STOP
        button.add_theme_font_size_override("font_size", 26)
        button.button_down.connect(_control_changed.bind(item[1], true))
        button.button_up.connect(_control_changed.bind(item[1], false))
        hud.add_child(button)
        steering_buttons.append(button)
        input_buttons[item[1]] = button
    var camera_button := Button.new()
    camera_button.text = "CAMERA"
    camera_button.anchor_left = 0.79
    camera_button.anchor_right = 0.79
    camera_button.anchor_top = 0.04
    camera_button.anchor_bottom = 0.04
    camera_button.offset_right = 160
    camera_button.offset_bottom = 65
    camera_button.pressed.connect(_toggle_camera)
    hud.add_child(camera_button)
    var reset_button := Button.new()
    reset_button.text = "RESET"
    reset_button.anchor_left = 0.64
    reset_button.anchor_right = 0.64
    reset_button.anchor_top = 0.04
    reset_button.anchor_bottom = 0.04
    reset_button.offset_right = 150
    reset_button.offset_bottom = 65
    reset_button.pressed.connect(_reset_truck)
    hud.add_child(reset_button)
    input_buttons["camera"] = camera_button
    input_buttons["reset"] = reset_button
    fps_label = Label.new()
    fps_label.add_theme_font_size_override("font_size", 17)
    hud.add_child(fps_label)
    pause_label = Label.new()
    pause_label.text = "TEST BUILD | placeholder physics"
    pause_label.add_theme_font_size_override("font_size", 17)
    hud.add_child(pause_label)

func _layout_controls() -> void:
    if ui_root == null:
        return
    var viewport_size := get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return
    # Fit four bottom buttons on the narrower of the two foldable displays.
    var height_scale: float = viewport_size.y / 720.0
    var width_scale: float = viewport_size.x / 650.0
    var scale_factor: float = clampf(minf(height_scale, width_scale), 0.38, 1.4)
    var button_width: float = 132.0 * scale_factor
    var button_height: float = 96.0 * scale_factor
    var margin: float = 24.0 * scale_factor
    var gap: float = 12.0 * scale_factor
    var positions := {
        "left": Vector2(margin, viewport_size.y - margin - button_height),
        "right": Vector2(margin + button_width + gap, viewport_size.y - margin - button_height),
        "brake": Vector2(viewport_size.x - margin - 2.0 * button_width - gap, viewport_size.y - margin - button_height),
        "gas": Vector2(viewport_size.x - margin - button_width, viewport_size.y - margin - button_height),
        "reset": Vector2(viewport_size.x - margin - 2.0 * button_width - gap, margin),
        "camera": Vector2(viewport_size.x - margin - button_width, margin)
    }
    for key in positions:
        var button: Button = input_buttons[key]
        button.set_anchors_preset(Control.PRESET_TOP_LEFT)
        button.position = positions[key]
        button.size = Vector2(button_width, button_height if key in ["left", "right", "brake", "gas"] else 64.0 * scale_factor)
        button.custom_minimum_size = Vector2.ZERO
    speed_label.position = Vector2(margin, margin)
    speed_label.add_theme_font_size_override("font_size", roundi(23.0 * scale_factor))
    fps_label.position = Vector2(margin, margin + 44.0 * scale_factor)
    fps_label.add_theme_font_size_override("font_size", roundi(17.0 * scale_factor))
    pause_label.position = Vector2(margin, margin + 72.0 * scale_factor)
    pause_label.add_theme_font_size_override("font_size", roundi(17.0 * scale_factor))

func _release_controls() -> void:
    left_pressed = false
    right_pressed = false
    throttle = 0.0
    braking = 0.0
    for key in ["left", "right", "brake", "gas"]:
        var button: Button = input_buttons.get(key)
        if button != null:
            button.set_pressed_no_signal(false)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED:
        _release_controls()

func _configure_keyboard() -> void:
    var bindings := {"accelerate": KEY_W, "brake": KEY_S, "turn_left": KEY_A, "turn_right": KEY_D}
    for action in bindings:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var event := InputEventKey.new()
        event.physical_keycode = bindings[action]
        InputMap.action_add_event(action, event)

func _toggle_camera() -> void:
    camera_inside = not camera_inside
    _reset_camera_immediately()

func _reset_truck() -> void:
    speed = 0.0
    heading = 0.0
    truck.position = Vector3.ZERO
    truck.rotation = Vector3.ZERO
    distance_m = 0.0
    _update_road_tiles(true)
    _reset_camera_immediately()
    _release_controls()

func _reset_camera_immediately() -> void:
    if camera == null or truck == null:
        return
    if camera_inside:
        camera.position = truck.position + Vector3(-sin(heading), 2.7, -cos(heading))
        camera.look_at(camera.position + Vector3(-sin(heading) * 12.0, -0.6, -cos(heading) * 12.0))
    else:
        camera.position = truck.position + Vector3(sin(heading) * 12.0, 7.0, cos(heading) * 12.0)
        camera.look_at(truck.position + Vector3(0.0, 1.4, 0.0))

func _control_changed(name: String, pressed: bool) -> void:
    match name:
        "left": left_pressed = pressed
        "right": right_pressed = pressed
        "gas": throttle = 1.0 if pressed else 0.0
        "brake": braking = 1.0 if pressed else 0.0

func _physics_process(delta: float) -> void:
    if truck == null or camera == null:
        return
    elapsed_seconds += delta
    frame_count += 1
    if elapsed_seconds >= 0.5:
        fps_label.text = "FPS %d | %.1f, %.1f" % [Engine.get_frames_per_second(), truck.position.x, truck.position.z]
        elapsed_seconds = 0.0
        frame_count = 0
    var gas_input: float = maxf(throttle, Input.get_action_strength("accelerate"))
    var brake_input: float = maxf(braking, Input.get_action_strength("brake"))
    var steer_input: float = (1.0 if right_pressed else 0.0) - (1.0 if left_pressed else 0.0) + Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
    steer_input = clampf(steer_input, -1.0, 1.0)
    var acceleration: float = gas_input * 7.0 - brake_input * 14.0
    if gas_input < 0.01 and brake_input < 0.01:
        acceleration = -1.2
    speed = clampf(speed + acceleration * delta, 0.0, 30.0)
    heading += steer_input * speed * 0.017 * delta
    truck.rotation.y = heading
    truck.position += Vector3(-sin(heading), 0, -cos(heading)) * speed * delta
    distance_m += speed * delta
    _update_road_tiles()
    if camera_inside:
        camera.position = truck.position + Vector3(-sin(heading) * 1.0, 2.7, -cos(heading) * 1.0)
        camera.look_at(camera.position + Vector3(-sin(heading) * 12.0, -0.6, -cos(heading) * 12.0))
    else:
        camera.position = camera.position.lerp(truck.position + Vector3(sin(heading) * 12.0, 7.0, cos(heading) * 12.0), minf(delta * 4.0, 1.0))
        camera.look_at(truck.position + Vector3(0, 1.4, 0))
    speed_label.text = "HT2 TEST | %d km/h | %.2f km" % [roundi(speed * 3.6), distance_m / 1000.0]
