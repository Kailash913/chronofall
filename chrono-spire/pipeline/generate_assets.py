"""Original procedural assets; no external runtime dependency. CC0-1.0."""
from pathlib import Path
import math, wave, struct, random, json
root=Path(__file__).resolve().parents[1]
rng=random.Random(81)
rate=22050
for name,duration in [('ambient',6),('reverse',.7),('forward',.65),('step',.13),('shot',.19),('impact',.3),('switch',.4),('bubble',.8)]:
    samples=[]
    for i in range(int(rate*duration)):
        t=i/rate; u=t/duration; fade=math.sin(math.pi*u)**.4
        noise=rng.uniform(-1,1)
        if name=='ambient': v=(math.sin(2*math.pi*55*t)+.35*math.sin(2*math.pi*82.5*t)+.2*math.sin(2*math.pi*110*t))*.13
        elif name=='reverse': v=(2*((t*(600-350*u))%1)-1)*fade*.22
        elif name=='forward': v=(noise*.55+math.sin(2*math.pi*(150*t+900*t*t))*.45)*fade*.3
        elif name=='step': v=noise*(1-u)**4*.3
        elif name=='shot': v=(noise*.5+math.sin(2*math.pi*(190*t-200*t*t))*.5)*(1-u)**3*.5
        elif name=='impact': v=noise*(1-u)**3*.45
        elif name=='switch': v=math.sin(2*math.pi*(440 if u<.5 else 660)*t)*fade*.25
        else: v=math.sin(2*math.pi*(180*t-70*t*t))*fade*.32
        samples.append(struct.pack('<h',int(max(-1,min(1,v))*32700)))
    p=root/'assets/audio'/f'{name}.wav'
    with wave.open(str(p),'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate); w.writeframes(b''.join(samples))
# Beveled eight-sided pillar, triangulated caps and sides.
verts=[]
for y in (-1,1):
    for x,z in [(-.7,-1),(.7,-1),(1,-.7),(1,.7),(.7,1),(-.7,1),(-1,.7),(-1,-.7)]: verts.append((x,y,z))
faces=[]
for i in range(8):
    j=(i+1)%8
    faces.extend([(i+1,j+1,j+9),(i+1,j+9,i+9)])
for i in range(1,7): faces.extend([(1,i+2,i+1),(9,i+9,i+10)])
p=root/'assets/meshes/beveled_pillar.obj'
p.write_text('\n'.join(['# Original procedural mesh CC0-1.0']+[f'v {x} {y} {z}' for x,y,z in verts]+['f '+' '.join(map(str,f)) for f in faces]))
(root/'assets/ASSET_MANIFEST.json').write_text(json.dumps({'license':'CC0-1.0','author':'Procedurally generated for Chrono-Spire','remote_attempt':{'url':'https://github.com/KenneyNL/Starter-Kits/raw/master/3D/Space%20Kit/','status':404,'used':False},'audio':list(str(p.relative_to(root)) for p in (root/'assets/audio').glob('*.wav')),'meshes':['assets/meshes/beveled_pillar.obj'],'runtime_geometry':['instanced modular walls and floors','fractured catwalk slabs','capsule character and weapon sockets','segmented enemy armor','roots and door hinges']},indent=2))
print('Generated 8 mono 16-bit WAV files and beveled pillar mesh; CC0 manifest written.')
