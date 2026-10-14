from pathlib import Path
import re, json, zipfile
root=Path(__file__).resolve().parents[1]
s=(root/'scripts/main.gd').read_text()
checks={
 'camera_initialized': '_reset_camera_immediately()' in s.split('func _make_world()')[0],
 'reset_camera_lookat': 'camera.look_at(truck.position + Vector3(0.0, 1.4, 0.0))' in s,
 'viewport_width_fit': 'width_scale: float = viewport_size.x / 650.0' in s,
 'null_guard_before_fps': s.index('if truck == null or camera == null:',s.index('func _physics_process')) < s.index('fps_label.text =',s.index('func _physics_process')),
 'road_after_truck': s.index('_update_road_tiles(true)',s.index('func _make_world')) > s.index('truck = Node3D.new()',s.index('func _make_world')),
 'main_scene_exists': (root/'scenes/main.tscn').exists(),
 'android_arm64': 'architectures/arm64-v8a=true' in (root/'export_presets.cfg').read_text(),
 'project_version': 'v0.7' in (root/'project.godot').read_text(),
}
print(json.dumps(checks,indent=2)); assert all(checks.values())
