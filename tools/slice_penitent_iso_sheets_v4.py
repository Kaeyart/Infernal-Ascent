#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import json, shutil

ROOT = Path.cwd()
ASSET = ROOT/'art/iso/player/penitent_v1'
FRAMES = ASSET/'frames'
STRIPS = ASSET/'direction_strips'
SRC = ROOT/'art_source/penitent_knight_v2'
PREV = ROOT/'preview/penitent_knight_v4'
for p in [ASSET, FRAMES, STRIPS, SRC, PREV]: p.mkdir(parents=True, exist_ok=True)

sources={
    'idle': {'path':SRC/'idle_source_photoroom.png','cols':4,'rows':4,'out':'penitent_idle_iso_4x4.png','compat':'penitent_idle_4x1.png','fps':7,'scale_ref':'all'},
    'walk': {'path':SRC/'walk_source_photoroom.png','cols':6,'rows':4,'out':'penitent_walk_iso_6x4.png','compat':'penitent_walk_4x1.png','fps':10,'scale_ref':'all'},
    'dash': {'path':SRC/'dash_source_photoroom.png','cols':4,'rows':4,'out':'penitent_dash_iso_4x4.png','compat':'penitent_dash_2x1.png','fps':16,'scale_ref':'all'},
    'hit': {'path':SRC/'hit_source_photoroom.png','cols':3,'rows':4,'out':'penitent_hit_iso_3x4.png','compat':'penitent_hit_2x1.png','fps':12,'scale_ref':'first'},
    'death': {'path':SRC/'death_source_photoroom.png','cols':6,'rows':4,'out':'penitent_death_iso_6x4.png','compat':None,'fps':8,'scale_ref':'first'},
    'respawn': {'path':SRC/'respawn_source_photoroom.png','cols':6,'rows':4,'out':'penitent_respawn_iso_6x4.png','compat':None,'fps':8,'scale_ref':'last'},
    'light_attack': {'path':SRC/'light_attack_source_photoroom.png','cols':5,'rows':4,'out':'penitent_light_attack_iso_5x4.png','compat':'penitent_attack_4x1.png','fps':12,'scale_ref':'ends'},
    'heavy_attack': {'path':SRC/'heavy_attack_source_photoroom.png','cols':6,'rows':4,'out':'penitent_heavy_attack_iso_6x4.png','compat':None,'fps':10,'scale_ref':'ends'},
}
DIRECTIONS=['se','sw','nw','ne']
FRAME_W=320; FRAME_H=320; BASELINE_Y=286; CENTER_X=160
ALPHA_THRESHOLD=20; CROP_PAD=8; TARGET_STANDING_HEIGHT=226; CANVAS_MARGIN=14

def body_mask_from_rgba(arr):
    r=arr[:,:,0].astype(np.int16); g=arr[:,:,1].astype(np.int16); b=arr[:,:,2].astype(np.int16); a=arr[:,:,3]
    opaque=a>ALPHA_THRESHOLD
    bright_slash=(r>165) & (g>150) & (b>120)
    cyan_smear=(g>90) & (b>80) & (r<95)
    return opaque & (~bright_slash) & (~cyan_smear)

def alpha_mask_from_image(im): return np.array(im.getchannel('A')) > ALPHA_THRESHOLD

def segments_from_projection(proj, min_val, min_len=4):
    active=proj>min_val; segs=[]; start=None
    for i,v in enumerate(active):
        if v and start is None: start=i
        elif not v and start is not None:
            if i-start>=min_len: segs.append([start,i])
            start=None
    if start is not None and len(active)-start>=min_len: segs.append([start,len(active)])
    return segs

def normalize_segments(segs, expected, length, min_size=12):
    segs=[s for s in segs if s[1]-s[0] >= min_size]
    while len(segs)>expected:
        gaps=[(segs[i+1][0]-segs[i][1], i) for i in range(len(segs)-1)]
        gaps.sort(); _,idx=gaps[0]
        segs[idx]=[segs[idx][0], segs[idx+1][1]]; del segs[idx+1]
    if len(segs)==expected: return [(int(a),int(b)) for a,b in segs]
    if segs: lo=min(s[0] for s in segs); hi=max(s[1] for s in segs)
    else: lo=0; hi=length
    edges=[round(lo+(hi-lo)*i/expected) for i in range(expected+1)]
    return [(int(edges[i]), int(edges[i+1])) for i in range(expected)]

def detect_rows(mask, rows):
    yproj=mask.sum(axis=1); min_val=max(8, int(mask.shape[1]*0.004))
    return normalize_segments(segments_from_projection(yproj,min_val,5), rows, mask.shape[0], max(10,mask.shape[0]//80))

def detect_cols(row_mask, cols):
    xproj=row_mask.sum(axis=0); min_val=max(5, int(row_mask.shape[0]*0.012))
    return normalize_segments(segments_from_projection(xproj,min_val,5), cols, row_mask.shape[1], max(8,row_mask.shape[1]//160))

def bbox_from_mask(mask):
    ys,xs=np.where(mask)
    if len(xs)==0: return None
    return (int(xs.min()), int(ys.min()), int(xs.max()+1), int(ys.max()+1))

def clean_alpha(im):
    im=im.convert('RGBA'); arr=np.array(im); arr[arr[:,:,3] <= ALPHA_THRESHOLD, 3]=0
    return Image.fromarray(arr,'RGBA')

class FrameData:
    def __init__(self,anim,r,c,crop,anchor_bbox):
        self.anim=anim; self.r=r; self.c=c; self.crop=crop; self.anchor_bbox=anchor_bbox; self.placed=None

def collect_frames(anim, meta):
    im=clean_alpha(Image.open(meta['path']).convert('RGBA'))
    W,H=im.size; mask=alpha_mask_from_image(im); rows=detect_rows(mask, meta['rows']); frames=[]
    for r,(y0,y1) in enumerate(rows):
        cols=detect_cols(mask[y0:y1,:], meta['cols'])
        for c,(x0,x1) in enumerate(cols):
            bb=bbox_from_mask(mask[y0:y1,x0:x1])
            if bb is None:
                tx0,ty0,tx1,ty1=x0,y0,x1,y1
            else:
                bx0,by0,bx1,by1=bb
                tx0=max(0,x0+bx0-CROP_PAD); ty0=max(0,y0+by0-CROP_PAD); tx1=min(W,x0+bx1+CROP_PAD); ty1=min(H,y0+by1+CROP_PAD)
            crop=clean_alpha(im.crop((tx0,ty0,tx1,ty1)))
            arr=np.array(crop); content=bbox_from_mask(arr[:,:,3] > ALPHA_THRESHOLD) or (0,0,crop.width,crop.height)
            anchor=bbox_from_mask(body_mask_from_rgba(arr)) or content
            frames.append(FrameData(anim,r,c,crop,anchor))
    return frames

def choose_scale(frames, meta):
    refs=[]
    for f in frames:
        include = meta['scale_ref']=='all' or (meta['scale_ref']=='first' and f.c==0) or (meta['scale_ref']=='last' and f.c==meta['cols']-1) or (meta['scale_ref']=='ends' and (f.c==0 or f.c==meta['cols']-1))
        if include: refs.append(f.anchor_bbox[3]-f.anchor_bbox[1])
    if not refs: refs=[f.anchor_bbox[3]-f.anchor_bbox[1] for f in frames]
    scale=TARGET_STANDING_HEIGHT/max(float(np.median(refs)),1.0)
    max_w=max(f.crop.width for f in frames); max_h=max(f.crop.height for f in frames)
    return min(scale,(FRAME_W-2*CANVAS_MARGIN)/max_w,(FRAME_H-CANVAS_MARGIN-8)/max_h,1.18)

def place_frame(f,scale):
    sw=max(1,int(round(f.crop.width*scale))); sh=max(1,int(round(f.crop.height*scale)))
    scaled=f.crop.resize((sw,sh), Image.Resampling.LANCZOS)
    ax0,ay0,ax1,ay1=f.anchor_bbox; anchor_cx=((ax0+ax1)/2)*scale; anchor_bottom=ay1*scale
    px=int(round(CENTER_X-anchor_cx)); py=int(round(BASELINE_Y-anchor_bottom))
    px=max(0,min(px,FRAME_W-sw)); py=max(0,min(py,FRAME_H-sh))
    canvas=Image.new('RGBA',(FRAME_W,FRAME_H),(0,0,0,0)); canvas.alpha_composite(scaled,(px,py)); f.placed=canvas
    return canvas

def save_sheet(anim,meta,frames,scale):
    sheet=Image.new('RGBA',(meta['cols']*FRAME_W, meta['rows']*FRAME_H),(0,0,0,0))
    for f in frames:
        if f.placed is None: place_frame(f,scale)
        sheet.alpha_composite(f.placed,(f.c*FRAME_W,f.r*FRAME_H))
        out_dir=FRAMES/anim/DIRECTIONS[f.r]; out_dir.mkdir(parents=True,exist_ok=True)
        f.placed.save(out_dir/f'{anim}_{DIRECTIONS[f.r]}_{f.c:02d}.png')
    sheet.save(ASSET/meta['out'])
    for r,dname in enumerate(DIRECTIONS):
        sheet.crop((0,r*FRAME_H,meta['cols']*FRAME_W,(r+1)*FRAME_H)).save(STRIPS/f'penitent_{anim}_{dname}_{meta["cols"]}x1.png')
    if meta.get('compat'):
        comp_cols=2 if meta['compat'].endswith('2x1.png') else min(meta['cols'],4)
        sheet.crop((0,0,comp_cols*FRAME_W,FRAME_H)).save(ASSET/meta['compat'])
    for r,dname in enumerate(DIRECTIONS):
        imgs=[frames[r*meta['cols']+c].placed for c in range(meta['cols'])]
        imgs[0].save(PREV/f'{anim}_{dname}.gif',save_all=True,append_images=imgs[1:],duration=max(45,int(1000/meta['fps'])),loop=0,disposal=2)

manifest=[]
for anim,meta in sources.items():
    if not Path(meta['path']).exists(): raise SystemExit(f'Missing source: {meta["path"]}')
    frames=collect_frames(anim,meta); scale=choose_scale(frames,meta); save_sheet(anim,meta,frames,scale)
    manifest.append({'anim':anim,'sheet':meta['out'],'cols':meta['cols'],'rows':meta['rows'],'frame_size':[FRAME_W,FRAME_H],'fps':meta['fps'],'scale':round(scale,4)})
(ASSET/'ANIMATION_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Done. Wrote V4 Penitent Knight sprite sheets to', ASSET)
