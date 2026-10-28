"""Archive the complete editable project without local build caches."""
from pathlib import Path
import zipfile
root=Path(__file__).resolve().parents[1]
output=Path('/Users/xavier/Codex/2026-10-27/realtime-voice-chat/outputs/FrenchB1-source.zip')
output.parent.mkdir(parents=True,exist_ok=True)
files=[]
for path in root.rglob('*'):
    relative=path.relative_to(root)
    if any(p in {'.build','.git','__pycache__','.DS_Store'} for p in relative.parts) or path.suffix=='.pyc':continue
    if path.is_file():files.append(path)
with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
    for path in sorted(files):archive.write(path,Path('FrenchB1')/path.relative_to(root))
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
print(f'{output}: {len(files)} files, {output.stat().st_size:,} bytes')
