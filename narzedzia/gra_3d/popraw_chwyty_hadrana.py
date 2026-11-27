"""Blender: anatomiczne mocowania i kontrola miecza względem tarczy, po chwyty_hadrana.py.

Argumenty po --: folder źródłowych assetów, repo, folder wyników kontroli.
"""
import bpy,sys,pathlib,math,json
import numpy as np
from mathutils import Vector,Matrix,Quaternion
from mathutils.bvhtree import BVHTree

SOURCE,REPO,OUT=[pathlib.Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:][:3]];OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'hadran_rynsztunek_gotowy.blend'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');scene=bpy.context.scene;P='mixamorig:'
weapons=['rusty_sword','steel_falchion','warden_glaive','ash_greatsword','executioner_axe']
shields=['wood_buckler','iron_kite','ash_aegis']
report={'mocowania':{},'kolizje':{}}

def action(a):
 arm.animation_data.action=a
 if a.slots:arm.animation_data.action_slot=a.slots[0]
def head(side,name):return (arm.matrix_world@arm.pose.bones[P+side+name].matrix).translation
def hand(side):
 wrist=head(side,'Hand');middle=head(side,'HandMiddle1');index=head(side,'HandIndex1');pinky=head(side,'HandPinky1')
 z=(index-pinky).normalized();long=(middle-wrist).normalized();x=z.cross(long).normalized();y=z.cross(x).normalized()
 center=(index+pinky)/2-long*.035
 return center,x,y,z
def matrix(origin,x,y,z):return Matrix.Translation(origin)@Matrix((x,y,z)).transposed().to_4x4()
def attach(obj,bone,world):
 obj.parent=arm;obj.parent_type='BONE';obj.parent_bone=P+bone;obj.matrix_parent_inverse=Matrix.Identity(4);obj.matrix_world=world;bpy.context.view_layer.update()

# Oś ostrza wychodzi od strony kciuka, a rękojeść przechodzi przez zamkniętą dłoń.
action(bpy.data.actions['miecz_postoj']);scene.frame_set(1)
center,x,y,z=hand('Right')
for n in weapons:
 obj=bpy.data.objects['sprzet_'+n]
 xx,yy=x,y
 if n=='executioner_axe' and np.mean([v.co.x for v in obj.data.vertices if v.co.z>.5])<0:xx,yy=-x,-y
 attach(obj,'RightHand',matrix(center,xx,yy,z))
 report['mocowania'][n]={'kosc':'RightHand','os_ostrza':'od małego palca do kciuka','pivot':'środek chwytu'}

# Przód każdego modelu ustala geometria (umbo/deska). Przed tarczą nie ma dłoni.
FRONT={'wood_buckler':-1,'iron_kite':-1,'ash_aegis':-1}
center,normal,_,up=hand('Left')
for n in shields:
 obj=bpy.data.objects['sprzet_'+n];sign=FRONT[n]
 yy=normal*sign;xx=yy.cross(up).normalized();zz=xx.cross(yy).normalized()
 origin=center+normal*.080-up*(.11 if n!='wood_buckler' else 0)
 attach(obj,'LeftHand',matrix(origin,xx,yy,zz))
 report['mocowania'][n]={'kosc':'LeftHand','strona_przednia_y':sign,'dystans_przed_dlonia_m':.080}

# Meshy dodało na tylnej stronie puklerza bryłę przypominającą pięść. Tarcza
# nie może zawierać własnej dłoni: zastępujemy tę bryłę rzeczywistym uchwytem.
import bmesh
report['mocowania']['warden_glaive']['korekta_modelu']='Głownia po dodatniej osi; postawa i klipy kierują ją w górę lub ku celowi.'
wood=bpy.data.objects['sprzet_wood_buckler'];bm=bmesh.new();bm.from_mesh(wood.data)
junk=[f for f in bm.faces if f.calc_center_median().y>.008 and (f.calc_center_median().x**2+f.calc_center_median().z**2)<.10**2]
bmesh.ops.delete(bm,geom=junk,context='FACES');bm.to_mesh(wood.data);bm.free()

# Zapis podglądowy przed korektą animacji. Mocowanie jest stałe względem kości.
def world_pose():return {b.name:arm.matrix_world@arm.pose.bones[b.name].matrix for b in arm.data.bones}
def apply_pose(world):
 inv=arm.matrix_world.inverted()
 for b in arm.data.bones:
  target=inv@world[b.name]
  base=b.matrix_local.inverted()@target if b.parent is None else b.matrix_local.inverted()@b.parent.matrix_local@(inv@world[b.parent.name]).inverted()@target
  loc,q,_=base.decompose();pb=arm.pose.bones[b.name];pb.rotation_mode='QUATERNION';pb.rotation_quaternion=q;pb.location=loc if b.parent is None else Vector();pb.scale=(1,1,1)
 bpy.context.view_layer.update()
def branch(world,name,pivot,q):
 m=Matrix.Translation(pivot)@q.to_matrix().to_4x4()@Matrix.Translation(-pivot)
 for b in [arm.data.bones[name],*arm.data.bones[name].children_recursive]:world[b.name]=m@world[b.name]
def reach(world,side,target):
 upper,lower,handbone=[P+side+s for s in ['Arm','ForeArm','Hand']]
 old=world[handbone].to_quaternion()
 shoulder=world[upper].translation;elbow=world[lower].translation;wrist=world[handbone].translation
 l1=(elbow-shoulder).length;l2=(wrist-elbow).length;delta=target-shoulder;dist=max(.001,min(delta.length,l1+l2-.003));direction=delta.normalized()
 bend=(elbow-shoulder)-direction*(elbow-shoulder).dot(direction)
 if bend.length<.001:bend=Vector((0,0,-1))-direction*direction.z*-1
 bend.normalize();along=(l1*l1-l2*l2+dist*dist)/(2*dist);height=math.sqrt(max(0,l1*l1-along*along));goal=shoulder+direction*along+bend*height
 branch(world,upper,shoulder,(elbow-shoulder).rotation_difference(goal-shoulder))
 elbow=world[lower].translation;wrist=world[handbone].translation
 branch(world,lower,elbow,(wrist-elbow).rotation_difference(target-elbow))
 branch(world,handbone,world[handbone].translation,old@world[handbone].to_quaternion().inverted())
def keyframe(frame):
 for pb in arm.pose.bones:
  pb.keyframe_insert('rotation_quaternion',frame=frame)
  if pb.parent is None:pb.keyframe_insert('location',frame=frame)

def sample_times(a):
 lo,hi=map(float,a.frame_range)
 return sorted(set([lo,hi]+[i/2 for i in range(math.ceil(lo*2),math.floor(hi*2)+1)]))

def write_frames(a,times,worlds):
 # Zastępujemy również dawne klucze ułamkowe (np. 0.8, 1.6 klatki), które
 # inaczej zostawały między poprawionymi pozami i odrywały dłoń przy eksporcie.
 bag=a.layers[0].strips[0].channelbag(a.slots[0])
 for fc in list(bag.fcurves):bag.fcurves.remove(fc)
 inv=arm.matrix_world.inverted();previous={};channels={}
 for world in worlds:
  for b in arm.data.bones:
   target=inv@world[b.name]
   base=b.matrix_local.inverted()@target if b.parent is None else b.matrix_local.inverted()@b.parent.matrix_local@(inv@world[b.parent.name]).inverted()@target
   loc,q,_=base.decompose()
   if b.name in previous and previous[b.name].dot(q)<0:q.negate()
   previous[b.name]=q.copy();path='pose.bones["'+b.name+'"]'
   for i,v in enumerate(q):channels.setdefault((path+'.rotation_quaternion',i),[]).append(float(v))
   if b.parent is None:
    for i,v in enumerate(loc):channels.setdefault((path+'.location',i),[]).append(float(v))
 for (path,i),values in channels.items():
  fc=bag.fcurves.new(path,index=i);fc.keyframe_points.add(len(times));fc.keyframe_points.foreach_set('co',[v for t,value in zip(times,values) for v in (t,value)])
  for key in fc.keyframe_points:key.interpolation='LINEAR'
  fc.update()

cache={}
for n in shields:
 o=bpy.data.objects['sprzet_'+n];verts=[v.co.copy() for v in o.data.vertices];faces=[tuple(p.vertices) for p in o.data.polygons]
 cache[n]=(BVHTree.FromPolygons(verts,faces,epsilon=.018),np.array([v[:] for v in verts]))
blade_cache={}
for n in weapons:
 o=bpy.data.objects['sprzet_'+n];blade_cache[n]=(np.array([v.co[:] for v in o.data.vertices]),[tuple(p.vertices) for p in o.data.polygons])
def collision(wn,sn):
 w=bpy.data.objects['sprzet_'+wn];s=bpy.data.objects['sprzet_'+sn]
 m=np.array(s.matrix_world.inverted()@w.matrix_world);verts,faces=blade_cache[wn];points=verts@m[:3,:3].T+m[:3,3]
 tree,sv=cache[sn]
 if np.any(points.max(0)<sv.min(0)-.040) or np.any(points.min(0)>sv.max(0)+.040):return False
 blade=BVHTree.FromPolygons([Vector(p) for p in points],faces,epsilon=.018)
 return bool(tree.overlap(blade))

def collisions():return [(w,s) for w in weapons[:2] for s in shields if collision(w,s)]

if '--preview' not in sys.argv:
 # Korygujemy samą lewą rękę, bez przesuwania broni poza chwyt i bez zmiany czasu ciosu.
 for a in list(bpy.data.actions):
  if not a.name.startswith('miecz_'):continue
  action(a);lo,hi=map(int,a.frame_range);bases=[];before=0
  times=sample_times(a)
  for f in times:
   scene.frame_set(int(f),subframe=f-int(f));bases.append(world_pose());before+=bool(collisions())
  frames=bases;after=before;chosen=None
  if before:
   # Jedna korekta dla całego klipu, a nie skoki ręki w pojedynczych klatkach.
   candidates=[(yaw,dx,dy,dz) for yaw in [0,-.25,-.5,.25,.5,-.8,.8,-1.2,1.2] for dx,dy,dz in [(.18,.12,0),(.30,.18,-.05),(.40,.25,-.15),(.25,-.08,.10),(.05,.20,-.25),(.0,-.25,.15),(.3,-.25,.2),(.0,.35,.20),(.35,.0,-.3)]]
   for yaw,dx,dy,dz in candidates:
    trial=[];bad=0
    for base in bases:
     pose={k:v.copy() for k,v in base.items()}
     if yaw:branch(pose,P+'RightArm',pose[P+'RightArm'].translation,Quaternion(Vector((0,0,1)),yaw))
     reach(pose,'Left',base[P+'LeftHand'].translation+Vector((dx,dy,dz)));apply_pose(pose)
     bad+=bool(collisions());trial.append(pose)
     if bad>=after:break
    if len(trial)==len(bases) and bad<after:frames=trial;after=bad;chosen=[yaw,dx,dy,dz]
    if after==0:break
   if after:
    # Przewrót: broń prowadzona z boku ciała; bark i nadgarstek obracają się razem z chwytem.
    for axis in [Vector((1,0,0)),Vector((0,1,0)),Vector((0,0,1))]:
     for angle in [-.35,.35,-.7,.7,-1.0,1.0]:
      trial=[];bad=0
      for base in bases:
       pose={k:v.copy() for k,v in base.items()}
       branch(pose,P+'RightArm',pose[P+'RightArm'].translation,Quaternion(axis,angle))
       reach(pose,'Left',base[P+'LeftHand'].translation+Vector((.30,.15,-.05)));apply_pose(pose)
       bad+=bool(collisions());trial.append(pose)
       if bad>=after:break
      if len(trial)==len(bases) and bad<after:frames=trial;after=bad;chosen=[list(axis),angle]
      if after==0:break
     if after==0:break
   if after:
    best=frames
    for local_axis in [Vector((1,0,0)),Vector((0,1,0)),Vector((0,0,1))]:
     for angle in [-.15,.15,-.30,.30,-.45,.45]:
      trial=[];bad=0
      for base in best:
       pose={k:v.copy() for k,v in base.items()};axis=pose[P+'RightHand'].to_quaternion()@local_axis
       branch(pose,P+'RightHand',pose[P+'RightHand'].translation,Quaternion(axis,angle));apply_pose(pose)
       bad+=bool(collisions());trial.append(pose)
       if bad>=after:break
      if len(trial)==len(best) and bad<after:frames=trial;after=bad;chosen={'bark':chosen,'nadgarstek':[list(local_axis),angle]}
      if after==0:break
     if after==0:break
  write_frames(a,times,frames)
  report['kolizje'][a.name]={'klatki':len(frames),'przed':before,'po':after,'korekta_klipu':chosen}
  print('KOLIZJE',a.name,before,after,flush=True)

 # Oś nowych broni 2H też jest anatomiczna. Przenosimy drugi chwyt na rękojeść/drzewce.
 report['dwie_rece']={}
 for prefix,wn,grip in [('dwureczny_','ash_greatsword',-.15),('topor_','executioner_axe',-.16),('glewia_','warden_glaive',.43)]:
  weapon=bpy.data.objects['sprzet_'+wn]
  for a in list(bpy.data.actions):
   if not a.name.startswith(prefix):continue
   if a.name.endswith(('przewrot','smierc')):
    report['dwie_rece'][a.name]={'chwyt':'lewa ręka zwalnia chwyt podczas przewrotu lub upadku'};continue
   action(a);lo,hi=map(int,a.frame_range);frames=[];errors=[]
   times=sample_times(a)
   for f in times:
    scene.frame_set(int(f),subframe=f-int(f));pose=world_pose();palm,_,_,_=hand('Left')
    if prefix=='glewia_':
     t=(f-lo)/max(1,hi-lo)
     if a.name.endswith('atak1'):desired=Vector((.08,-1,.15+.12*math.sin(math.pi*t))).normalized()
     elif a.name.endswith('atak2'):
      angle=-1+2*t*t*(3-2*t);desired=Vector((math.sin(angle),-math.cos(angle),.15)).normalized()
     elif a.name.endswith('atak3'):
      angle=.3+1.7*t*t*(3-2*t);desired=Vector((.25,-math.sin(angle),math.cos(angle))).normalized()
     else:desired=Vector((.05,-.72,.69)).normalized()
     axis=(weapon.matrix_world.to_3x3()@Vector((0,0,1))).normalized()
     branch(pose,P+'RightHand',pose[P+'RightHand'].translation,axis.rotation_difference(desired));apply_pose(pose)
    axis=(weapon.matrix_world.to_3x3()@Vector((0,0,1))).normalized()
    palm,normal,_,thumb=hand('Left');branch(pose,P+'LeftHand',pose[P+'LeftHand'].translation,thumb.rotation_difference(axis));apply_pose(pose)
    # Wspólny obszar dosięgania obu ramion. Żadna dłoń nie pozostaje obok drzewca.
    right,_,_,_=hand('Right');left,_,_,_=hand('Left')
    roff=right-pose[P+'RightHand'].translation;loff=left-pose[P+'LeftHand'].translation
    centers=[]
    for side,off,shift in [('Right',roff,Vector()),('Left',loff,-axis*grip)]:
     shoulder=pose[P+side+'Arm'].translation;elbow=pose[P+side+'ForeArm'].translation;wrist=pose[P+side+'Hand'].translation
     centers.append((shoulder+off+shift,(elbow-shoulder).length+(wrist-elbow).length-.009))
    target_right=right.copy()
    for _ in range(16):
     for c,r in centers:
      delta=target_right-c
      if delta.length>r:target_right=c+delta.normalized()*r
    reach(pose,'Right',target_right-roff);apply_pose(pose)
    target=weapon.matrix_world@Vector((0,0,grip));reach(pose,'Left',target-loff);apply_pose(pose)
    actual,_,_,_=hand('Left');errors.append((actual-target).length);frames.append(pose)
   write_frames(a,times,frames)
   report['dwie_rece'][a.name]={'max_blad_chwytu_m':max(errors)}

 # Liniowe krzywe nie robią dodatkowego wychylenia pomiędzy skontrolowanymi pozami.
 for a in bpy.data.actions:
  for layer in a.layers:
   for strip in layer.strips:
    for slot in a.slots:
     bag=strip.channelbag(slot)
     if bag:
      for fc in bag.fcurves:
       for key in fc.keyframe_points:key.interpolation='LINEAR'
 report['kontrola_gesta']={}
 for a in list(bpy.data.actions):
  if not a.name.startswith('miecz_'):continue
  action(a);lo,hi=a.frame_range;bad=[]
  for half in range(int(lo*2),int(hi*2)+1):
   scene.frame_set(half//2,subframe=(half%2)*.5)
   pairs=collisions()
   if pairs:bad.append({'klatka':half/2,'pary':pairs})
  report['kontrola_gesta'][a.name]={'probki':int((hi-lo)*2)+1,'kolizje':bad}
  print('GESTA',a.name,len(bad),flush=True)

arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()

# Na plecach przód tarczy też musi być skierowany na zewnątrz.
for n in shields:
 obj=bpy.data.objects['odlozona_'+n]
 attach(obj,'Spine2',Matrix.Translation((-.10,.34,1.27))@Matrix.Rotation(0 if FRONT[n]>0 else math.pi,4,'Z'))
for n in ['warden_glaive','executioner_axe']:
 attach(bpy.data.objects['odlozona_'+n],'Spine2',Matrix.Translation((-.23,.29,.95))@Matrix.Rotation(.35,4,'Y'))

# Rzeczywisty tylny uchwyt: poprzeczka w pięści i dwa wsporniki przy desce.
gripmat=bpy.data.materials.new('zelazo_uchwytu_tarczy');gripmat.diffuse_color=(.09,.07,.05,1);gripmat.use_nodes=True
bs=gripmat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.09,.07,.05,1);bs.inputs['Metallic'].default_value=.7;bs.inputs['Roughness'].default_value=.65
for n in shields:
 sign=FRONT[n];z=.11 if n!='wood_buckler' else 0
 for prefix in ['sprzet_','odlozona_']:
  parent=bpy.data.objects[prefix+n]
  for label,pos,scale in [('chwyt',(0,-sign*.08,z),(.026,.028,.12)),('wspornik_gora',(0,-sign*.04,z+.065),(.024,.09,.018)),('wspornik_dol',(0,-sign*.04,z-.065),(.024,.09,.018))]:
   bpy.ops.mesh.primitive_cube_add(size=1);o=bpy.context.object;o.name='uchwyt_'+prefix+n+'_'+label;o.parent=parent;o.matrix_parent_inverse=Matrix.Identity(4);o.location=pos;o.scale=scale;o.data.materials.append(gripmat)
  if n=='wood_buckler':
   bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.10,depth=.008);o=bpy.context.object;o.name='uchwyt_'+prefix+n+'_podklad';o.parent=parent;o.matrix_parent_inverse=Matrix.Identity(4);o.location=(0,.010,0);o.rotation_euler.x=math.pi/2;o.data.materials.append(gripmat)
# Gęstość 60 Hz zachowuje kontrolowany kontakt dłoni także pomiędzy dawnymi klatkami 30 Hz.
# Podwojenie osi czasu i FPS razem zachowuje dotychczasowe długości wszystkich klipów.
for a in bpy.data.actions:
 for layer in a.layers:
  for strip in layer.strips:
   for slot in a.slots:
    bag=strip.channelbag(slot)
    if bag:
     for fc in bag.fcurves:
      for key in fc.keyframe_points:
       key.co.x*=2;key.handle_left.x*=2;key.handle_right.x*=2
scene.render.fps=60
report['eksport_fps']=60
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'hadran_poprawne_chwyty.blend'))
(OUT/'kontrola_chwytow.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
if '--preview' not in sys.argv:
 bpy.ops.export_scene.gltf(filepath=str(REPO/'godot/zasoby/3d/rynsztunek/hadraen_rynsztunek.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_image_format='AUTO',export_apply=False)
 for n in shields+['warden_glaive']:
  src=bpy.data.objects['sprzet_'+n];copy=src.copy();copy.data=src.data;scene.collection.objects.link(copy);copy.parent=None;copy.matrix_world=Matrix.Identity(4);copies=[copy]
  for child in src.children:
   o=child.copy();o.data=child.data;scene.collection.objects.link(o);o.parent=copy;o.matrix_parent_inverse=Matrix.Identity(4);o.matrix_basis=child.matrix_basis.copy();copies.append(o)
  bpy.ops.object.select_all(action='DESELECT')
  for o in copies:o.select_set(True)
  bpy.ops.export_scene.gltf(filepath=str(REPO/'godot/zasoby/3d/rynsztunek'/(n+'.glb')),use_selection=True,export_format='GLB',export_animations=False,export_image_format='AUTO',export_apply=False)
  for o in reversed(copies):bpy.data.objects.remove(o,do_unlink=True)
