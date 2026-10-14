from pathlib import Path
import configparser
root=Path(__file__).resolve().parents[1]
files=['project.godot','scenes/main.tscn','scripts/main.gd','export_presets.cfg','.github/workflows/android-debug.yml']
for file in files: assert (root/file).is_file(),file
s=(root/'scripts/main.gd').read_text()
for token in ['func _reset_camera_immediately()', 'if camera_inside:', 'func _toggle_camera()', '_reset_camera_immediately()']:
    assert token in s,token
assert 'HT2 Android Prototype v0.' in (root/'project.godot').read_text()
assert 'arm64-v8a=true' in (root/'export_presets.cfg').read_text()
print('PASS: 8 static project checks; Godot and Android build remain unverified')
