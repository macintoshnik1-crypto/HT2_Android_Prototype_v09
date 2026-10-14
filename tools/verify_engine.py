#!/usr/bin/env python3
"""Check Godot project import and GDScript parsing using an installed Godot executable."""
import argparse, pathlib, shutil, subprocess, sys
p=argparse.ArgumentParser(); p.add_argument('--godot',default='godot'); args=p.parse_args()
exe=shutil.which(args.godot)
if not exe:
    print('UNVERIFIED: Godot executable not found. Install Godot 4.x and rerun.'); sys.exit(2)
root=pathlib.Path(__file__).resolve().parents[1]
for cmd in ([exe,'--headless','--path',str(root),'--editor','--import','--quit'],
            [exe,'--headless','--path',str(root),'--quit-after','3']):
    print('RUN:', ' '.join(cmd),flush=True)
    result=subprocess.run(cmd,capture_output=True,text=True,timeout=120)
    print(result.stdout[-4000:]); print(result.stderr[-4000:])
    if result.returncode: sys.exit(result.returncode)
print('Godot headless import and scene smoke test completed.')
