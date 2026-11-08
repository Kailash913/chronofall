"""Reproducible release export; supply GODOT_ANDROID_KEYSTORE_RELEASE_* env vars."""
from pathlib import Path
import subprocess,os,hashlib,json
root=Path(__file__).resolve().parents[1]
godot=os.environ.get('GODOT','godot')
def run(args,log):
 with (root/'logs'/log).open('w') as f:
  result=subprocess.run(args,cwd=root,stdout=f,stderr=subprocess.STDOUT)
 if result.returncode:
  raise SystemExit(f'Command failed; see logs/{log}')
 text=(root/'logs'/log).read_text()
 if 'SCRIPT ERROR' in text or 'Project export' in text and 'failed' in text:
  raise SystemExit(f'Export error; see logs/{log}')
for folder in ['logs','builds/android','builds/windows']: (root/folder).mkdir(parents=True,exist_ok=True)
run([godot,'--headless','--path',str(root),'--editor','--quit'],'import.log')
run([godot,'--headless','--path',str(root),'--script','res://tests/test_mechanics.gd'],'tests.log')
run([godot,'--headless','--path',str(root),'--script','res://tests/test_touch.gd'],'touch.log')
run([godot,'--headless','--fixed-fps','60','--path',str(root),'--script','res://tests/playthrough.gd'],'playthrough.log')
run([godot,'--headless','--path',str(root),'--export-release','Android',str(root/'builds/android/ChronoSpire.apk')],'android-build.log')
run([godot,'--headless','--path',str(root),'--export-release','Windows Desktop',str(root/'builds/windows/ChronoSpire.exe')],'windows-build.log')
files=[root/'builds/android/ChronoSpire.apk',root/'builds/windows/ChronoSpire.exe']
report={str(p.relative_to(root)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files}
(root/'builds/checksums.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
