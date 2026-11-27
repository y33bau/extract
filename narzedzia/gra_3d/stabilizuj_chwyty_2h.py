"""Blender: ciągły biegun łokcia i stały obrót dłoni na rękojeści.

Po popraw_chwyty_hadrana.py. Argumenty: folder wyników, repo.
"""
import bpy,sys,pathlib,math,json,ast
import numpy as np
from mathutils import Vector,Matrix,Quaternion
OUT,REPO=[pathlib.Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:][:2]];P='mixamorig:'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'hadran_poprawne_chwyty.blend'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');scene=bpy.context.scene
source=ast.parse((REPO/'narzedzia/gra_3d/popraw_chwyty_hadrana.py').read_text())
functions=[n for n in source.body if isinstance(n,ast.FunctionDef) and n.name in ['action','world_pose','hand','head','write_frames','sample_times']]
exec(compile(ast.Module(body=functions,type_ignores=[]),'funkcje_chwytu','exec'),globals())

def basis(direction,pole,roll=0):
 y=direction.normalized();x=y.cross(pole).normalized();z=x.cross(y).normalized()
 if roll:
  q=Quaternion(y,roll);x=q@x;z=q@z
 return Matrix((x,y,z)).transposed().to_4x4()
def pole(side):return Vector((.7 if side=='Left' else -.7,.2,-.7)).normalized()
def roll_offset(matrix,direction,p):
 b=basis(direction,p);oldx=matrix.to_3x3().col[0].normalized();newx=b.to_3x3().col[0].normalized();y=direction.normalized()
 return math.atan2(y.dot(newx.cross(oldx)),newx.dot(oldx))
def solve(world,side,wrist,handq,rolls):
 up,low,h=[P+side+s for s in ['Arm','ForeArm','Hand']]
 shoulder=world[up].translation;oldelbow=world[low].translation;oldwrist=world[h].translation
 l1=(oldelbow-shoulder).length;l2=(oldwrist-oldelbow).length;delta=wrist-shoulder;distance=max(.001,min(delta.length,l1+l2-.002));direction=delta.normalized()
 prev=rolls.get((side,'bend'),pole(side));bend=prev-direction*prev.dot(direction);bend.normalize();rolls[(side,'bend')]=bend.copy()
 along=(l1*l1-l2*l2+distance*distance)/(2*distance);height=math.sqrt(max(0,l1*l1-along*along));elbow=shoulder+direction*along+bend*height
 actual=shoulder+direction*distance
 oldhand=world[h].copy();newhand=Matrix.Translation(actual)@handq.to_matrix().to_4x4();change=newhand@oldhand.inverted()
 for child in arm.data.bones[h].children_recursive:world[child.name]=change@world[child.name]
 x=direction.cross(bend).normalized()
 for name,start,end in [(up,shoulder,elbow),(low,elbow,actual)]:
  y=(end-start).normalized();z=x.cross(y).normalized()
  world[name]=Matrix.Translation(start)@Matrix((x,y,z)).transposed().to_4x4()
 world[h]=newhand

report={}
for prefix,wn,grip in [('dwureczny_','ash_greatsword',-.15),('topor_','executioner_axe',-.16),('glewia_','warden_glaive',.43)]:
 weapon=bpy.data.objects['sprzet_'+wn]
 for a in list(bpy.data.actions):
  if not a.name.startswith(prefix) or a.name.endswith(('przewrot','smierc')):continue
  action(a);times=sample_times(a);bpy.context.scene.frame_set(int(times[0]),subframe=times[0]%1);first=world_pose();left,*_=hand('Left');right,*_=hand('Right')
  local_left=first[P+'LeftHand'].to_quaternion().inverted()@(left-first[P+'LeftHand'].translation)
  local_right=first[P+'RightHand'].to_quaternion().inverted()@(right-first[P+'RightHand'].translation)
  relative=weapon.matrix_world.to_quaternion().inverted()@first[P+'LeftHand'].to_quaternion()
  rolls={}
  for side in ['Left','Right']:
   for name,end in [('Arm','ForeArm'),('ForeArm','Hand')]:
    rolls[(side,name)]=roll_offset(first[P+side+name],first[P+side+end].translation-first[P+side+name].translation,pole(side))
  local_weapon=first[P+'RightHand'].inverted()@weapon.matrix_world
  originals=[]
  base=bpy.data.actions.get('dwureczny_'+a.name[len(prefix):]) if prefix in ['glewia_','topor_'] else a
  if a.name=='glewia_atak3':base=bpy.data.actions['dwureczny_atak1']
  if base is None:base=a
  action(base);start,end=base.frame_range
  for f in times:
   sample=start+(end-start)*(f-times[0])/max(.01,times[-1]-times[0])
   bpy.context.scene.frame_set(int(sample),subframe=sample%1);originals.append(world_pose())
  action(a)
  # Usuwamy krótkie skoki osi nadgarstka powstałe przy retargetowaniu.
  # Wygładzamy tor przed IK, aby obie dłonie podążały po tej samej ciągłej osi.
  smooth=[]
  for i in range(len(times)):
   pose={}
   for name in originals[i]:
    ids=list(range(max(0,i-6),min(len(times),i+7)))
    weights=[7-abs(j-i) for j in ids];total=sum(weights)
    origin=sum((originals[j][name].translation*w for j,w in zip(ids,weights)),Vector())/total
    q=originals[ids[0]][name].to_quaternion();acc=weights[0]
    for j,w in zip(ids[1:],weights[1:]):q=q.slerp(originals[j][name].to_quaternion(),w/(acc+w));acc+=w
    pose[name]=Matrix.Translation(origin)@q.to_matrix().to_4x4()
   # FK zachowuje długości kości: średnia pozycji światowych skracałaby ramiona.
   for b in arm.data.bones:
    if b.parent:
     offset=(b.parent.matrix_local.inverted()@b.matrix_local).translation
     pose[b.name].translation=pose[b.parent.name]@offset
   smooth.append(pose)
  frames=[]
  for frame,world in zip(times,smooth):
   wmat=world[P+'RightHand']@local_weapon
   if prefix=='glewia_':
    t=(frame-times[0])/max(.01,times[-1]-times[0]);ease=t*t*(3-2*t)
    if a.name.endswith('atak1'):axis=Vector((.08,-1,.15+.12*math.sin(math.pi*t))).normalized()
    elif a.name.endswith('atak2'):
     angle=-1+2*ease;axis=Vector((math.sin(angle),-math.cos(angle),.15)).normalized()
    elif a.name.endswith('atak3'):
     angle=.3+1.7*ease;axis=Vector((.25,-math.sin(angle),math.cos(angle))).normalized()
    else:axis=Vector((.05,-.72,.69)).normalized()
    x=axis.cross(Vector((0,0,1))).normalized();y=axis.cross(x).normalized()
    rotation=Matrix((x,y,axis)).transposed().to_quaternion()
    origin=world[P+'Hips'].translation+Vector((-.08,-.28,.35))
    wmat=Matrix.Translation(origin)@rotation.to_matrix().to_4x4()
   axis=(wmat.to_3x3()@Vector((0,0,1))).normalized();qright=wmat.to_quaternion()@local_weapon.to_quaternion().inverted();qleft=wmat.to_quaternion()@relative
   roff=qright@local_right;loff=qleft@local_left;target=wmat.translation.copy();centers=[]
   for side,off,shift in [('Right',roff,Vector()),('Left',loff,-axis*grip)]:
    shoulder=world[P+side+'Arm'].translation;elbow=world[P+side+'ForeArm'].translation;wrist=world[P+side+'Hand'].translation
    centers.append((shoulder+off+shift,(elbow-shoulder).length+(wrist-elbow).length-.009))
   for _ in range(24):
    for c,r in centers:
     delta=target-c
     if delta.length>r:target=c+delta.normalized()*r
     elif delta.length<.20:target=c+delta.normalized()*.20
   solve(world,'Right',target-roff,qright,rolls);solve(world,'Left',target+axis*grip-loff,qleft,rolls);frames.append(world)
  write_frames(a,times,frames);report[a.name]={'klucze':len(times),'biegun_lokcia':'stały, na zewnątrz i w dół','obrot_dlonii':'stały względem rękojeści'}

# Drzewce mieści się w zamkniętej dłoni; szeroka głownia pozostaje bez zwężania.
seen=set()
for name in ['sprzet_warden_glaive','odlozona_warden_glaive']:
 obj=bpy.data.objects[name]
 if obj.data.as_pointer() in seen:continue
 seen.add(obj.data.as_pointer())
 for v in obj.data.vertices:
  blend=max(0,min(1,(v.co.z-.90)/.20));factor=.22+.78*blend
  v.co.x*=factor;v.co.y*=factor
arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'hadran_chwyty_stabilne.blend'))
bpy.ops.export_scene.gltf(filepath=str(REPO/'godot/zasoby/3d/rynsztunek/hadraen_rynsztunek.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_image_format='AUTO',export_apply=False)
bpy.ops.object.select_all(action='DESELECT');obj=bpy.data.objects['sprzet_warden_glaive'];copy=obj.copy();copy.data=obj.data;scene.collection.objects.link(copy);copy.parent=None;copy.matrix_world=Matrix.Identity(4);copy.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(REPO/'godot/zasoby/3d/rynsztunek/warden_glaive.glb'),use_selection=True,export_format='GLB',export_animations=False,export_image_format='AUTO')
bpy.data.objects.remove(copy,do_unlink=True)
(OUT/'stabilizacja_2h.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
