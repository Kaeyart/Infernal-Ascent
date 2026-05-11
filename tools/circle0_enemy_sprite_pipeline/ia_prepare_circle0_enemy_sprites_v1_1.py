from PIL import Image, ImageDraw, ImageFont
import numpy as np
import cv2
from pathlib import Path
import json, csv, zipfile, shutil, os, re

SOURCE_MAP = {
    'ash_wretch': Path('/mnt/data/ChatGPT Image May 10, 2026, 02_18_28 AM (1)-Photoroom.png'),
    'gate_warden': Path('/mnt/data/ChatGPT Image May 10, 2026, 02_18_28 AM (2)-Photoroom.png'),
    'cinder_scribe': Path('/mnt/data/ChatGPT Image May 10, 2026, 02_18_28 AM (3)-Photoroom.png'),
    'bell_hound': Path('/mnt/data/ChatGPT Image May 10, 2026, 02_18_29 AM (4)-Photoroom.png'),
    'vestibule_bailiff': Path('/mnt/data/ChatGPT Image May 10, 2026, 02_18_29 AM (5)-Photoroom.png'),
}
DIRECTIONS = ['down','left','right','up']
CANVAS = 320
ANCHOR_Y = 302
PAD = 7
ALPHA_THRESH = 18
OUT = Path('/mnt/data/circle0_enemy_sprites_v1_1_work')
if OUT.exists(): shutil.rmtree(OUT)
root = OUT/'art/actors/enemies/circle0'
(root/'source').mkdir(parents=True, exist_ok=True)
(root/'contact_sheets').mkdir(parents=True, exist_ok=True)
(root/'manifest').mkdir(parents=True, exist_ok=True)
(ROOT_TOOLS:=OUT/'tools/circle0_enemy_sprite_pipeline').mkdir(parents=True, exist_ok=True)
manifest=[]

def clean_alpha(im):
    im = im.convert('RGBA')
    arr = np.array(im)
    a = arr[...,3]
    arr[...,3] = np.where(a > ALPHA_THRESH, a, 0).astype(np.uint8)
    # remove leftover color in fully transparent pixels
    arr[arr[...,3] == 0, :3] = 0
    return Image.fromarray(arr, 'RGBA')

def components(im):
    arr=np.array(im)
    mask=(arr[...,3] > ALPHA_THRESH).astype('uint8')
    n, labels, stats, cents = cv2.connectedComponentsWithStats(mask, 8)
    comps=[]
    for i in range(1,n):
        x,y,w,h,area=stats[i]
        if area > 200:
            comps.append({'bbox':(int(x),int(y),int(x+w),int(y+h)), 'area':int(area), 'center':(float(cents[i][0]), float(cents[i][1]))})
    return comps

def cluster_rows(comps):
    comps=sorted(comps,key=lambda c:c['center'][1])
    rows=[]
    for c in comps:
        placed=False
        for row in rows:
            avg=sum(x['center'][1] for x in row)/len(row)
            if abs(c['center'][1]-avg) < 90:
                row.append(c); placed=True; break
        if not placed:
            rows.append([c])
    rows=sorted(rows,key=lambda r:sum(c['center'][1] for c in r)/len(r))
    # If too many/too few rows, fallback to sorting into 4 chunks by y.
    if len(rows) != 4 or any(len(r)!=4 for r in rows):
        comps=sorted(comps,key=lambda c:c['center'][1])[:16]
        rows=[comps[i*4:(i+1)*4] for i in range(4)]
    rows=[sorted(row,key=lambda c:c['center'][0]) for row in rows]
    return rows

def stable_frame(im, bbox):
    x1,y1,x2,y2=bbox
    x1=max(0,x1-PAD); y1=max(0,y1-PAD); x2=min(im.width,x2+PAD); y2=min(im.height,y2+PAD)
    crop=im.crop((x1,y1,x2,y2))
    # final exact alpha cleaning on crop
    crop=clean_alpha(crop)
    w,h=crop.size
    max_w=CANVAS-18; max_h=CANVAS-18
    scale=min(1.0, max_w/max(1,w), max_h/max(1,h))
    if scale < 1.0:
        crop=crop.resize((max(1,int(w*scale)), max(1,int(h*scale))), Image.Resampling.LANCZOS)
        crop=clean_alpha(crop)
        w,h=crop.size
    canvas=Image.new('RGBA',(CANVAS,CANVAS),(0,0,0,0))
    px=int((CANVAS-w)/2)
    py=int(ANCHOR_Y-h)
    py=max(0,min(CANVAS-h,py))
    canvas.alpha_composite(crop,(px,py))
    return canvas

def make_contact(role):
    files=[]
    for d in DIRECTIONS:
        files += sorted((root/role).glob(f'{role}_{d}_*.png'))
    cell=190; label_h=24; margin=16
    sheet=Image.new('RGBA',(cell*4+margin*2,(cell+label_h)*4+margin*2),(18,18,18,255))
    draw=ImageDraw.Draw(sheet)
    try: font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
    except: font=None
    idx=0
    for r,d in enumerate(DIRECTIONS):
        for c in range(4):
            f=files[idx]; idx+=1
            im=Image.open(f).convert('RGBA')
            thumb=im.copy(); thumb.thumbnail((cell-24,cell-34), Image.Resampling.LANCZOS)
            x=margin+c*cell+(cell-thumb.width)//2
            y=margin+r*(cell+label_h)+(cell-thumb.height)//2
            sheet.alpha_composite(thumb,(x,y))
            draw.text((margin+c*cell+5, margin+r*(cell+label_h)+cell-8), f'{d}_{c+1:02d}', fill=(220,210,190), font=font)
    sheet.save(root/'contact_sheets'/f'{role}_contact_sheet_v1_1_stabilized.png')

for role,src in SOURCE_MAP.items():
    im=clean_alpha(Image.open(src))
    shutil.copy(src, root/'source'/f'{role}_source_sheet_photoroom.png')
    comps=components(im)
    if len(comps) < 16:
        raise RuntimeError(f'{role}: found only {len(comps)} components')
    comps=sorted(comps, key=lambda c:c['area'], reverse=True)[:16]
    rows=cluster_rows(comps)
    role_dir=root/role; role_dir.mkdir(parents=True, exist_ok=True)
    for row_i,row in enumerate(rows):
        direction=DIRECTIONS[row_i]
        for col_i,c in enumerate(row):
            frame=stable_frame(im,c['bbox'])
            out_name=f'{role}_{direction}_{col_i+1:02d}.png'
            out_path=role_dir/out_name
            frame.save(out_path)
            manifest.append({'role':role,'direction':direction,'frame':col_i+1,'path':str(out_path.relative_to(OUT)),'source_bbox':c['bbox'],'component_center':c['center'],'component_area':c['area']})
    make_contact(role)

# full contact sheet from role contacts
role_contacts=[root/'contact_sheets'/f'{role}_contact_sheet_v1_1_stabilized.png' for role in SOURCE_MAP]
imgs=[Image.open(p).convert('RGBA') for p in role_contacts]
w=max(i.width for i in imgs); h=sum(i.height for i in imgs)+40*len(imgs)
full=Image.new('RGBA',(w,h),(10,10,10,255))
draw=ImageDraw.Draw(full)
try: font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',18)
except: font=None
y=0
for role,img in zip(SOURCE_MAP,imgs):
    draw.text((12,y+8),role,fill=(245,210,150),font=font)
    full.alpha_composite(img,(0,y+32)); y+=img.height+40
full.save(root/'contact_sheets'/'ALL_CIRCLE0_ENEMY_FRAMES_CONTACT_SHEET_V1_1_STABILIZED.png')

with open(root/'manifest'/'circle0_enemy_sprites_manifest_v1_1_stabilized.json','w') as f:
    json.dump(manifest,f,indent=2)
with open(root/'manifest'/'circle0_enemy_sprites_manifest_v1_1_stabilized.csv','w',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=['role','direction','frame','path','source_bbox','component_center','component_area'])
    writer.writeheader(); writer.writerows(manifest)

# Copy this script into tools for rerun.
shutil.copy(__file__, ROOT_TOOLS/'ia_prepare_circle0_enemy_sprites_v1_1.py')
print('done', len(manifest), 'frames')
