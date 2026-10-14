from pathlib import Path
import re, sys, zipfile
root = Path(__file__).resolve().parents[1]
project = (root / "project.godot").read_text(encoding="utf-8")
scene = (root / "scenes/main.tscn").read_text(encoding="utf-8")
script = (root / "scripts/main.gd").read_text(encoding="utf-8")
preset = (root / "export_presets.cfg").read_text(encoding="utf-8")
checks = {
    "scene file": (root / "scenes/main.tscn").exists(),
    "main scene linked": 'run/main_scene="res://scenes/main.tscn"' in project,
    "script linked": 'res://scripts/main.gd' in scene,
    "Android preset": 'platform="Android"' in preset,
    "ARM64 selected": 'architectures/arm64-v8a=true' in preset,
    "no internet permission": 'package/permissions/internet=false' in preset,
    "road init after truck": script.index('truck = Node3D.new()') < script.index('    _update_road_tiles(true)\n    camera = Camera3D.new()'),
    "input release": 'func _release_controls()' in script,
    "fps diagnostic": 'Engine.get_frames_per_second()' in script,
}
for label, ok in checks.items(): print(("PASS" if ok else "FAIL") + " " + label)
sys.exit(0 if all(checks.values()) else 1)
