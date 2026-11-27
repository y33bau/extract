"""Blender: modele Meshy -> skala w metrach, PBR, szkielet Hadrana i osobne GLB.

Uruchomienie: blender -b --factory-startup --python ten_plik -- katalog_assetow repo
Źródła i rejestr kosztów pozostają w katalogu autora, poza repo.
"""
import bpy, sys, pathlib, math, json, importlib.util
import numpy as np
from mathutils import Vector, Matrix, Quaternion
from mathutils.kdtree import KDTree

ROOT, REPO = map(pathlib.Path, sys.argv[sys.argv.index('--')+1:][:2])
OUT = REPO/'godot/zasoby/3d/rynsztunek'
OUT.mkdir(parents=True,exist_ok=True)
PARAM = {
 'rusty_sword':(1.04,.12,True,'bron_miecz'),
 'steel_falchion':(1.06,.13,True,'bron_miecz'),
 'warden_glaive':(2.40,.34,False,'bron_glewia'),
 'ash_greatsword':(1.72,.17,True,'bron_dwureczny'),
 'executioner_axe':(1.32,.22,False,'bron_topor'),
 'wood_buckler':(.54,.50,False,'bron_tarcza'),
 'iron_kite':(.84,.50,False,'bron_tarcza'),
 'ash_aegis':(1.02,.50,False,'bron_tarcza'),
 'hunter_bow':(1.28,.50,False,'luk'),
 'yew_longbow':(1.68,.50,False,'luk'),
 'shadow_bow':(1.42,.50,False,'luk'),
}
ARMORS = ['leather_jerkin','chainmail_hauberk','ash_plate']
REPORT = {'modele':{},'animacje':{},'chwyty':{}}

def clear(): bpy.ops.wm.read_factory_settings(use_empty=True)
def imported(path):
 old=set(bpy.data.objects)
 if str(path).endswith('.fbx'): bpy.ops.import_scene.fbx(filepath=str(path))
 else: bpy.ops.import_scene.gltf(filepath=str(path))
 return list(set(bpy.data.objects)-old)
def join_mesh(objects,name):
 meshes=[o for o in objects if o.type=='MESH']
 bpy.ops.object.select_all(action='DESELECT')
 for o in meshes: o.select_set(True)
 bpy.context.view_layer.objects.active=meshes[0]
 bpy.ops.object.join(); o=bpy.context.object;o.name=name
 mw=o.matrix_world.copy();o.parent=None;o.matrix_world=mw
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 return o
def optimize(o,name,limit=4500):
 if len(o.data.polygons)>limit:
  m=o.modifiers.new('siatka_do_gry','DECIMATE');m.ratio=limit/len(o.data.polygons)
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
 for mat in o.data.materials:
  if not mat:continue
  mat.name=name+'_'+mat.name
  if mat.use_nodes:
   for node in mat.node_tree.nodes:
    if node.type=='TEX_IMAGE' and node.image:
     im=node.image
     size=1024 if im.colorspace_settings.name=='sRGB' else 512
     if max(im.size)>size:im.scale(size,size)
     im.pack()
def export(path,objects,animations=False):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
  export_animations=animations,export_animation_mode='ACTIONS',export_force_sampling=True,
  export_image_format='AUTO',export_yup=True,export_apply=False)
def normalize(name):
 clear(); o=join_mesh(imported(ROOT/'meshy'/name/'model.glb'),name)
 xyz=np.array([v.co[:] for v in o.data.vertices]);center=xyz.mean(axis=0)
 _,_,axes=np.linalg.svd(xyz-center,full_matrices=False)
 z=axes[0]; y=axes[-1]
 if z[2]<0:z=-z
 if y[1]<0:y=-y
 if PARAM[name][2]:z=-z
 x=np.cross(y,z);x/=np.linalg.norm(x);y=np.cross(z,x)
 pts=(xyz-center)@np.array([x,y,z]).T
 length,grip,_,_=PARAM[name];lo=pts.min(axis=0);hi=pts.max(axis=0)
 scale=length/(hi[2]-lo[2]);pts*=scale
 pts[:,0]-=(lo[0]+hi[0])*scale/2;pts[:,1]-=(lo[1]+hi[1])*scale/2
 pts[:,2]-=(lo[2]+grip*(hi[2]-lo[2]))*scale
 widths={'rusty_sword':.22,'steel_falchion':.24,'warden_glaive':.24,'ash_greatsword':.30,'executioner_axe':.46}
 if name in widths:
  pts[:,0]*=widths[name]/(pts[:,0].max()-pts[:,0].min())
  if name=='warden_glaive':
   before=pts[:,2].copy();z0=before.min();z1=before.max();split=.35
   pts[:,2]=np.where(before<split,z0+(before-z0)/(split-z0)*(1.05-z0),1.05+(before-split)/(z1-split)*(z1-1.05))
  thickness=.035 if name in ['warden_glaive','executioner_axe'] else .025
  factor=min(1,thickness/(pts[:,1].max()-pts[:,1].min()))
  blade=pts[:,2]>(1.05 if name=='warden_glaive' else .15)
  pts[blade,1]*=factor
 for v,p in zip(o.data.vertices,pts):v.co=p
 optimize(o,name)
 REPORT['modele'][name]={'dlugosc_m':length,'poligony':len(o.data.polygons),'pivot':'chwyt','os_ostrza':'Blender +Z / glTF +Y'}
 export(OUT/(name+'.glb'),[o])

def parent_like(o,t):
 o.parent=t.parent;o.parent_type=t.parent_type;o.parent_bone=t.parent_bone
 o.matrix_parent_inverse=t.matrix_parent_inverse.copy();o.matrix_basis=t.matrix_basis.copy()
def material(name,color,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1)
 bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=.65
 return m
def cylinder(name,r,depth,z,mat):
 bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=depth,location=(0,0,z))
 o=bpy.context.object;o.name=name;o.data.materials.append(mat)
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 return o
def procedural():
 clear(); leather=material('skora_kolczanu',(.16,.075,.035));iron=material('stal_grotu',(.3,.31,.32),.85)
 feather=material('lotki_popielate',(.32,.29,.24));wood=material('drewno_strzaly',(.22,.12,.055))
 c=[cylinder('trzon',.0045,.72,.36,wood),cylinder('grot',.012,.065,.75,iron)]
 for angle in [0,math.tau/3,math.tau*2/3]:
  bpy.ops.mesh.primitive_cube_add(size=1,location=(.014*math.cos(angle),.014*math.sin(angle),.08));o=bpy.context.object;o.scale=(.028,.002,.085);o.rotation_euler.z=angle;o.data.materials.append(feather);c.append(o)
 arrow=join_mesh(c,'iron_arrow');export(OUT/'iron_arrow.glb',[arrow])
 c=[cylinder('kolczan',.085,.56,.28,leather)]
 for z in [.04,.50]:c.append(cylinder('okucie',.088,.045,z,iron))
 for i in range(7):
  a=arrow.copy();a.data=arrow.data.copy();bpy.context.collection.objects.link(a);a.location=(.045*math.cos(i*math.tau/7),.045*math.sin(i*math.tau/7),.24+(i%3)*.025);c.append(a)
 q=join_mesh(c,'quiver');export(OUT/'quiver.glb',[q])
 bpy.data.objects.remove(arrow,do_unlink=True)

def bind_nearest(o,body,arm):
 kd=KDTree(len(body.data.vertices))
 for i,v in enumerate(body.data.vertices):kd.insert(body.matrix_world@v.co,i)
 kd.balance();groups={g.index:g.name for g in body.vertex_groups}
 for g in body.vertex_groups:o.vertex_groups.new(name=g.name)
 for v in o.data.vertices:
  p=o.matrix_world@v.co
  # Kaftan leży nad wypukłą zbroją bazową. Najbliższy wierzchołek mógłby
  # należeć do dłoni lub naramiennika; ciągłe pola wag eliminują rozdarcia.
  levels=[('Hips',1.02),('Spine',1.17),('Spine1',1.30),('Spine2',1.45)]
  z=max(1.02,min(1.45,p.z));weights={}
  for (a,za),(b,zb) in zip(levels,levels[1:]):
   if za<=z<=zb:
    t=(z-za)/(zb-za);weights={'mixamorig:'+a:1-t,'mixamorig:'+b:t};break
  if 'chainmail' in o.name:
   sleeve=max(0,min(1,(abs(p.x)-.25)/.13))
   weights={k:w*(1-sleeve) for k,w in weights.items()}
   side='Left' if p.x>0 else 'Right';fore=max(0,min(1,(abs(p.x)-.39)/.10))
   weights['mixamorig:'+side+'Arm']=sleeve*(1-fore);weights['mixamorig:'+side+'ForeArm']=sleeve*fore
  total=sum(weights.values())
  for n,w in weights.items():o.vertex_groups[n].add([v.index],w/total,'REPLACE')
 mod=o.modifiers.new('szkielet_Hadrana','ARMATURE');mod.object=arm
 mw=o.matrix_world.copy();o.parent=arm;o.matrix_world=mw

def armor(name,body,arm):
 source=ROOT/'meshy'/name/'model.glb'
 if name=='chainmail_hauberk' and (ROOT/'meshy/chainmail_hauberk_v2/model.glb').exists():source=ROOT/'meshy/chainmail_hauberk_v2/model.glb'
 o=join_mesh(imported(source),'pancerz_'+name)
 xyz=np.array([v.co[:] for v in o.data.vertices]);lo=xyz.min(0);hi=xyz.max(0)
 # Szerokość obejmuje rękawy kolczugi. Pozostałe kaftany mieszczą się pod naramiennikami.
 dims=np.array((.98,.48,.65)) if name=='chainmail_hauberk' else np.array((.64,.48,.63 if name=='leather_jerkin' else .59))
 xyz=(xyz-(lo+hi)/2)/(hi-lo)*dims+np.array((0,-.015,1.25))
 for v,p in zip(o.data.vertices,xyz):v.co=p
 optimize(o,name,6500);bind_nearest(o,body,arm)
 REPORT['modele'][name]={'poligony':len(o.data.polygons),'szkielet':'oryginalny mixamorig Hadrana','wagi':'ciągłe pola kręgosłupa i rękawów, bez przeskoków między ręką i korpusem'}
 return o

def bone_world(arm,name):return arm.matrix_world@arm.pose.bones['mixamorig:'+name].matrix
def reset_pose(arm):
 for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 bpy.context.view_layer.update()

def retarget(arm):
 # Używamy sprawdzonego przenoszenia ruchu z projektu; nazwy SMPLH mapowane na Mixamo.
 spec=importlib.util.spec_from_file_location('potok',REPO/'narzedzia/gra_3d/potok.py');P=importlib.util.module_from_spec(spec)
 old=sys.argv;sys.argv=['potok','--','{}'];spec.loader.exec_module(P);sys.argv=old
 mapping={'Pelvis':'Hips','Spine1':'Spine','Spine2':'Spine1','Spine3':'Spine2','Neck':'Neck','Head':'Head'}
 for s,w in [('L','Left'),('R','Right')]:
  for a,b in [('Hip','UpLeg'),('Knee','Leg'),('Ankle','Foot'),('Foot','ToeBase'),('Collar','Shoulder'),('Shoulder','Arm'),('Elbow','ForeArm'),('Wrist','Hand')]:mapping[s+'_'+a]=w+b
  for finger in ['Thumb','Index','Middle','Ring','Pinky']:
   for i in range(1,4):mapping[s+'_'+finger+str(i)]=w+'Hand'+finger+str(i)
 for idx,name in enumerate(['glewia_pchniecie','glewia_ciecie','glewia_ciezki'],1):
  # Punktem odniesienia jest prawdziwa poza obrony Hadrana. SMPLH i Mixamo
  # mają różne orientacje kości w bind pose, dlatego przenosimy delty ruchu.
  guard=bpy.data.actions['dwureczny_blok'];arm.animation_data.action=guard
  arm.animation_data.action_slot=guard.slots[0];bpy.context.scene.frame_set(1)
  base={b.name:arm.matrix_world@arm.pose.bones[b.name].matrix for b in arm.data.bones}
  objs=imported(ROOT/'meshy'/name/'motion.fbx');src=next(o for o in objs if o.type=='ARMATURE')
  for b in src.data.bones:
   if b.name in mapping:b.name='mixamorig:'+mapping[b.name]
  sa=src.animation_data.action;f0,f1=sa.frame_range
  poses=[];bpy.context.scene.frame_set(int(f0));first_source={b.name:src.matrix_world@src.pose.bones[b.name].matrix for b in src.data.bones}
  for i in range(60):
   f=f0+(f1-f0)*i/59;bpy.context.scene.frame_set(int(f),subframe=f-int(f));world={}
   for bone in arm.data.bones:
    n=bone.name;rot=base[n].to_quaternion()
    if n in first_source and any(k in n for k in ['Spine','Shoulder','Arm','ForeArm','Hand','Neck','Head']):
     delta=(src.matrix_world@src.pose.bones[n].matrix).to_quaternion()@first_source[n].to_quaternion().inverted()
     if 'Spine' in n or 'Neck' in n or 'Head' in n:
      axis,angle=delta.to_axis_angle();delta=Quaternion(axis,max(-.40,min(.40,angle)))
     rot=delta@rot
    pos=base[n].translation if bone.parent is None else (world[bone.parent.name]@(base[bone.parent.name].inverted()@base[n])).translation
    world[n]=Matrix.Translation(pos)@rot.to_matrix().to_4x4()
   poses.append(world)
  # SMPLH ma biodra w spoczynku poniżej zera. Skala z wysokości bioder
  # (właściwa dla Mixamo) dałaby ujemną wysokość. Zachowujemy ruch w miejscu.
  hips='mixamorig:Hips';head='mixamorig:Head'
  src_hip=src.matrix_world@src.data.bones[hips].head_local
  dst_hip=arm.matrix_world@arm.data.bones[hips].head_local
  legacy_scale=dst_hip.z/src_hip.z
  factor=((arm.matrix_world@arm.data.bones[head].head_local)-dst_hip).length/((src.matrix_world@src.data.bones[head].head_local)-src_hip).length
  first=poses[0][hips].translation.copy()
  # Nogi i biodra pozostają w bazowej postawie bojowej, ruch dotyczy góry ciała.
  action=bpy.data.actions.new('glewia_atak'+str(idx));action.use_fake_user=True;arm.animation_data_create();arm.animation_data.action=action
  for i,pose in enumerate(poses):
   P.ustaw_poze(arm,pose)
   for pb in arm.pose.bones:
    pb.keyframe_insert('rotation_quaternion',frame=i+1)
    if pb.parent is None:pb.keyframe_insert('location',frame=i+1)
  REPORT['animacje'][action.name]={'zrodlo':name,'klatki':60,'fps':30}
  for o in objs:bpy.data.objects.remove(o,do_unlink=True)
  bpy.data.actions.remove(sa)
 arm.animation_data.action=None;reset_pose(arm)
 # Oryginalne ciało zostaje dla stanu bez pancerza. Druga skóra nie dubluje
 # napierśnika pod wymiennymi kaftanami i zachowuje oryginalne wagi.
 import bmesh
 body=bpy.data.objects['cialo']
 trimmed=body.copy();trimmed.data=body.data.copy();bpy.context.collection.objects.link(trimmed);trimmed.name='cialo_pod_pancerzem'
 bm=bmesh.new();bm.from_mesh(trimmed.data)
 faces=[f for f in bm.faces if abs((trimmed.matrix_world@f.calc_center_median()).x)<.30 and 1.03<(trimmed.matrix_world@f.calc_center_median()).z<1.50]
 bmesh.ops.delete(bm,geom=faces,context='FACES');bm.to_mesh(trimmed.data);bm.free()

def build_hero():
 clear();imported(REPO/'godot/zasoby/3d/postacie/hadraen.glb')
 arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');body=bpy.data.objects['cialo']
 arm.animation_data.action=None;reset_pose(arm)
 templates={n:bpy.data.objects[n] for n in ['bron_miecz','bron_glewia','bron_dwureczny','bron_topor','bron_tarcza']}
 for name,(_,_,_,template) in PARAM.items():
  o=join_mesh(imported(OUT/(name+'.glb')),'sprzet_'+name)
  if template=='luk':
   # Wspólny chwyt łuków: dłoń lewa; łęczysko pionowo w pozie celowania.
   t=templates['bron_miecz'];parent_like(o,t);o.parent_bone='mixamorig:LeftHand'
  else:parent_like(o,templates[template])
  o.hide_render=True
 for name in ARMORS:armor(name,body,arm)
 for n in ['iron_arrow','quiver']:
  o=join_mesh(imported(OUT/(n+'.glb')),'sprzet_'+n)
  parent_like(o,templates['bron_miecz'])
  if n=='quiver':
   # Przestrzeń kości kręgosłupa, skórzany kołczan za prawym barkiem.
   o.parent_bone='mixamorig:Spine2';o.matrix_parent_inverse=Matrix.Identity(4);o.matrix_basis=Matrix.Translation((.17,-.16,-.30))@Matrix.Rotation(math.radians(-18),4,'Y')
  o.hide_render=True
 retarget(arm)
 for o in bpy.data.objects:
  if o.type=='MESH':
   for m in o.data.materials:
    if m and m.use_nodes:
     for n in m.node_tree.nodes:
      if n.type=='TEX_IMAGE' and n.image and max(n.image.size)>1024:n.image.scale(1024,1024);n.image.pack()
 # Dodatkowe pozy i kontrola chwytów zostają dopieczone w osobnym przebiegu.
 bpy.context.scene.render.fps=30
 for o in bpy.data.objects:
  if o.type=='MESH':o.hide_render=False
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'hadran_rynsztunek.blend'))
 export(OUT/'hadraen_rynsztunek.glb',[o for o in bpy.context.scene.objects if o.type in ['MESH','ARMATURE','EMPTY']],True)

if __name__=='__main__':
 for n in PARAM:
  if '--force' in sys.argv or not (OUT/(n+'.glb')).exists():normalize(n)
 procedural();build_hero()
 (ROOT/'kontrola_blender.json').write_text(json.dumps(REPORT,indent=2,ensure_ascii=False),encoding='utf-8')
