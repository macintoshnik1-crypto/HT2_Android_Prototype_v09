# Hard Truck 2 Android — technical prototype v0.9

**Not the original game and not yet a tested APK.** This is a minimal synthetic 3D driving test in Godot 4.4.1. The original HT2 map, truck meshes, physics and missions have not been ported.

## New in v0.9

- An automated **engine-level smoke test** (`tests/smoke_test.gd`) creates the scene, checks road/camera/truck, presses throttle, switches camera, and resets the truck.
- CI workflow now runs static checks, Godot import/compilation, gameplay smoke test, and Android ARM64 debug export.
- CI verifies the exported APK is non-empty and passes ZIP integrity checks.

## Build via GitHub Actions

1. Create a **private** GitHub repository and upload the contents of this directory (including `.github`).
2. In Actions, run **Android debug APK** via **Run workflow**.
3. Inspect the log. If all stages pass, download `ht2-android-debug-apk` from that workflow run.
4. Install the APK on your Pixel 10 Pro Fold. Android may ask for permission to install from that source.

The workflow uses the third-party `barichello/godot-ci:4.4.1` container image, which is expected to provide the Godot editor, Android export templates and SDK. Its exact contents and the workflow have **not** been tested in this environment. A workflow run may expose incompatibilities requiring fixes.

## Local engine test

```bash
python3 tools/preflight.py
python3 tools/check_v08.py
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/smoke_test.gd
```

Look for `SMOKE_TEST_PASS` and a successful process exit code.

## Important limitations

The simulated road follows the player and does not represent a real map. The physics are synthetic. No original copyrighted assets are included. The Android debug signing key is generated in CI and may change between builds, so uninstalling the previous test app may be necessary before installing a later one.
