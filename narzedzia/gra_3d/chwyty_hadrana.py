"""Blender: chwyt obu rąk, pozy łuku oraz pochwy i noszenie broni.

Uruchamiać po rynsztunek_hadrana.py z tymi samymi dwoma argumentami.
"""
import bpy,sys,pathlib,math,json,importlib.util
from mathutils import Vector,Matrix,Quaternion
ROOT,REPO=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);OUT=REPO/'godot/zasoby/3d/rynsztunek'
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'hadran_rynsztunek.blend'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');scene=bpy.context.scene
PFX='mixamorig:'
report={'chwyt_glewii':{},'luk':{},'pochwy':[]}

def set_action(a):
 arm.animation_data.action=a
 if a.slots:arm.animation_data.action_slot=a.slots[0]
def world_pose():return {b.name:arm.matrix_world@arm.pose.bones[b.name].matrix for b in arm.data.bones}
def apply_pose(world):
 inv=arm.matrix_world.inverted()
 for b in arm.data.bones:
  pb=arm.pose.bones[b.name];target=inv@world[b.name]
  if b.parent:base=b.matrix_local.inverted()@b.parent.matrix_local@(inv@world[b.parent.name]).inverted()@target
  else:base=b.matrix_local.inverted()@target
  loc,rot,_=base.decompose();pb.rotation_mode='QUATERNION';pb.rotation_quaternion=rot
  pb.location=loc if b.parent is None else Vector();pb.scale=(1,1,1)
 bpy.context.view_layer.update()
def rotate_branch(world,name,pivot,q):
 transform=Matrix.Translation(pivot)@q.to_matrix().to_4x4()@Matrix.Translation(-pivot)
 for b in [arm.data.bones[name],*arm.data.bones[name].children_recursive]:world[b.name]=transform@world[b.name]
def reach(world,side,target,hand_rotation=None):
 upper,lower,hand=[PFX+side+s for s in ['Arm','ForeArm','Hand']]
 shoulder=world[upper].translation;elbow=world[lower].translation;wrist=world[hand].translation
 l1=(elbow-shoulder).length;l2=(wrist-elbow).length;delta=target-shoulder;dist=min(delta.length,l1+l2-.002);d=delta.normalized()
 bend=(elbow-shoulder)-d*(elbow-shoulder).dot(d)
 if bend.length<.001:bend=Vector((0,0,-1))-d*d.dot(Vector((0,0,-1)))
 bend.normalize();along=(l1*l1-l2*l2+dist*dist)/(2*dist);height=math.sqrt(max(0,l1*l1-along*along))
 goal_elbow=shoulder+d*along+bend*height
 rotate_branch(world,upper,shoulder,(elbow-shoulder).rotation_difference(goal_elbow-shoulder))
 elbow=world[lower].translation;wrist=world[hand].translation
 rotate_branch(world,lower,elbow,(wrist-elbow).rotation_difference(target-elbow))
 if hand_rotation is not None:
  q=hand_rotation@world[hand].to_quaternion().inverted();rotate_branch(world,hand,world[hand].translation,q)
 return (world[hand].translation-target).length
def keyframe(frame):
 for pb in arm.pose.bones:
  pb.keyframe_insert('rotation_quaternion',frame=frame)
  if pb.parent is None:pb.keyframe_insert('location',frame=frame)

# Glewia otrzymuje własne ruchy i szeroki chwyt również w chodzie i obronie.
for a in list(bpy.data.actions):
 if a.name.startswith('dwureczny_') and not a.name.split('_',1)[1].startswith('atak'):
  copy=a.copy();copy.name=a.name.replace('dwureczny_','glewia_');copy.use_fake_user=True
for a in list(bpy.data.actions):
 if not a.name.startswith('glewia_'):continue
 set_action(a);lo,hi=map(int,a.frame_range);frames=[];errors=[]
 for f in range(lo,hi+1):
  scene.frame_set(f);world=world_pose();weapon=bpy.data.objects['sprzet_warden_glaive']
  # Nadgarstek prawej dłoni orientuje drzewce między obiema dłońmi.
  # Dłonie pozostają w naturalnym zasięgu animacji, bez rozciągania ramion.
  h=PFX+'LeftHand';palm=world[h].translation+(world[h].to_quaternion()@Vector((0,1,0)))*.04
  for _ in range(3):
   origin=weapon.matrix_world.translation;axis=(weapon.matrix_world.to_3x3()@Vector((0,0,1))).normalized()
   desired=(palm-origin).normalized();q=axis.rotation_difference(desired)
   rotate_branch(world,PFX+'RightHand',world[PFX+'RightHand'].translation,q);apply_pose(world)
  origin=weapon.matrix_world.translation;axis=(weapon.matrix_world.to_3x3()@Vector((0,0,1))).normalized()
  distance=(palm-origin).dot(axis);target=origin+axis*distance-(world[h].to_quaternion()@Vector((0,1,0)))*.04
  errors.append(reach(world,'Left',target));frames.append(world)
 for f,w in zip(range(lo,hi+1),frames):apply_pose(w);keyframe(f)
 report['chwyt_glewii'][a.name]={'max_blad_nadgarstka_m':max(errors),'klatki':len(frames)}

# Pozy łuku na istniejącym szkielecie, bez zmiany momentu ani kosztu strzału w regułach gry.
base=bpy.data.actions.get('miecz_postoj');set_action(base);scene.frame_set(1);guard=world_pose()
for name,draw in [('luk_celowanie',True),('luk_strzal',False)]:
 action=bpy.data.actions.new(name);action.use_fake_user=True;set_action(action)
 errors=[]
 for f in range(1,19):
  w={k:v.copy() for k,v in guard.items()}
  # Lewa dłoń trzyma łuk, prawa wraca do policzka i wypuszcza cięciwę.
  release=0 if draw else max(0,min(1,(f-4)/4))
  left=Vector((.10,-.50,1.42));right=Vector((-.10,-.12-.20*release,1.46-.03*release))
  errors.append(reach(w,'Left',left));errors.append(reach(w,'Right',right));apply_pose(w);keyframe(f)
 report['luk'][name]={'klatki':18,'max_blad_m':max(errors)}

# Ustawiamy modele w pozie naciągnięcia. Ich lokalny transform zachowuje potem kontakt z kością.
set_action(bpy.data.actions['luk_celowanie']);scene.frame_set(1)
def attach_world(o,bone,matrix):
 o.parent=arm;o.parent_type='BONE';o.parent_bone=PFX+bone;o.matrix_parent_inverse=Matrix.Identity(4)
 o.matrix_world=matrix;bpy.context.view_layer.update()
for name in ['hunter_bow','yew_longbow','shadow_bow']:
 o=bpy.data.objects['sprzet_'+name];attach_world(o,'LeftHand',Matrix.Translation((.10,-.54,1.44))@Matrix.Rotation(math.pi/2,4,'Z'))
 # Morf odciąga istniejącą cięciwę wraz ze sprężystym ugięciem łęczyska.
 if not o.data.shape_keys:
  o.shape_key_add(name='Basis');key=o.shape_key_add(name='naciagniecie')
  pts=[v.co for v in o.data.vertices];zmax=max(abs(v.z) for v in pts)
  mid=[v.x for v in pts if abs(v.z)<zmax*.12];edge=max(mid);handle=min(mid)
  for i,p in enumerate(pts):
   string=max(0,min(1,(p.x-(handle+edge)/2)/max(.008,(edge-handle)/2)))
   fall=max(0,1-abs(p.z)/zmax)
   key.data[i].co.x+=.34*string*fall+.025*(1-string)*fall
arrow=bpy.data.objects['sprzet_iron_arrow'];direction=Vector((.20,-.42,-.02)).normalized();attach_world(arrow,'RightHand',Matrix.Translation((-.10,-.12,1.46))@direction.to_track_quat('Z','Y').to_matrix().to_4x4())

# Wróć do spoczynkowego szkieletu, żeby mocowania na plecach nie odziedziczyły pozy łucznika.
arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
q=bpy.data.objects['sprzet_quiver'];attach_world(q,'Spine2',Matrix.Translation((.23,.20,1.00))@Matrix.Rotation(math.radians(-18),4,'Y'))
vest=bpy.data.objects['pancerz_leather_jerkin']
if q.data.materials and vest.data.materials:q.data.materials[0]=vest.data.materials[0]

leather=bpy.data.materials.new('skora_pochwy');leather.use_nodes=True
bs=leather.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.07,.035,.018,1);bs.inputs['Roughness'].default_value=.8
def scabbard(source,name,start):
 # Obwiednia prawdziwego ostrza: pochwa nie przecina kordelasa ani szerokiej głowni.
 verts=[];faces=[];points=[v.co for v in source.data.vertices];top=max(v.z for v in points)
 for i in range(17):
  z=start+(top-start)*i/16;near=[v for v in points if abs(v.z-z)<(top-start)/14]
  if not near:near=points
  x0=min(v.x for v in near)-.009;x1=max(v.x for v in near)+.009
  thickness=max(.012,max(abs(v.y) for v in near)+.007)
  for j in range(8):
   a=j*math.tau/8;verts.append(((x0+x1)/2+(x1-x0)/2*math.cos(a),thickness*math.sin(a),z))
 for i in range(16):
  for j in range(8):a=i*8+j;b=i*8+(j+1)%8;faces.append((a,b,b+8,a+8))
 faces.append(tuple(range(128,136)))
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);scene.collection.objects.link(o);o.data.materials.append(leather)
 return o
for name in ['rusty_sword','steel_falchion','warden_glaive','ash_greatsword','executioner_axe']:
 src=bpy.data.objects['sprzet_'+name];stowed=src.copy();stowed.data=src.data;bpy.context.collection.objects.link(stowed);stowed.name='odlozona_'+name
 if name in ['rusty_sword','steel_falchion']:
  mat=Matrix.Translation((-.30,.06,.96))@Matrix.Rotation(math.pi+.12,4,'Y')
 else:mat=Matrix.Translation((-.23,.22,1.48))@Matrix.Rotation(math.pi-.35,4,'Y')
 attach_world(stowed,'Hips' if name in ['rusty_sword','steel_falchion'] else 'Spine2',mat)
 if name in ['rusty_sword','steel_falchion','ash_greatsword']:
  sheath=scabbard(src,'pochwa_'+name,.10 if name!='ash_greatsword' else .20);attach_world(sheath,'Hips' if name!='ash_greatsword' else 'Spine2',mat);report['pochwy'].append(name)
for name in ['wood_buckler','iron_kite','ash_aegis','hunter_bow','yew_longbow','shadow_bow']:
 src=bpy.data.objects['sprzet_'+name];o=src.copy();o.data=src.data;bpy.context.collection.objects.link(o);o.name='odlozona_'+name
 mat=Matrix.Translation((-.10,.27,1.27))@Matrix.Rotation(math.pi,4,'Z')
 if name.endswith('bow'):mat=Matrix.Translation((-.20,.24,1.2))@Matrix.Rotation(.30,4,'Y')
 attach_world(o,'Spine2',mat)

# Eksport: zachowujemy każdą animację, kości oraz skórę pancerzy. Dodatkowy blend zostaje u autora.
scene.render.fps=30
for o in scene.objects:
 o.hide_set(False);o.hide_render=False
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'hadran_rynsztunek_gotowy.blend'))
(ROOT/'kontrola_chwytow.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
bpy.ops.export_scene.gltf(filepath=str(OUT/'hadraen_rynsztunek.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_image_format='AUTO',export_apply=False)
for name in ['leather_jerkin','chainmail_hauberk','ash_plate']:
 bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.data.objects['pancerz_'+name].select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),use_selection=True,export_format='GLB',export_animations=False,export_image_format='AUTO',export_apply=False)
