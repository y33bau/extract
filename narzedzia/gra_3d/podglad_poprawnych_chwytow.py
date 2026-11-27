"""Zbliżenia mocowań i kolejnych faz animacji z czterech stron."""
import bpy,sys,pathlib,math
from mathutils import Vector
blend,out=[pathlib.Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:][:2]];out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(blend));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=20
scene.world=bpy.data.worlds.new('kontrola');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.2,.2,.23,1)
bpy.ops.object.camera_add(location=(-3,-6,2.7));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=2.65;scene.camera=cam
for loc,power,size in [((2,-4,5),600,4),((-3,-1,2),350,3),((1,3,3),500,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object;l.data.energy=power;l.data.size=size;l.rotation_euler=(Vector((0,0,1))-l.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=700;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.film_transparent=True
def shot(name,weapon,shield,action,frame=1,camera=(-3,-6,2.7)):
 show=['cialo_pod_pancerzem','pancerz_leather_jerkin','sprzet_'+weapon]
 if shield:show.append('sprzet_'+shield)
 for o in bpy.data.objects:
  if o.type=='MESH':o.hide_render=o.name not in show and not (o.parent and o.parent.name in show)
 a=bpy.data.actions[action];arm.animation_data.action=a;arm.animation_data.action_slot=a.slots[0];scene.frame_set(frame)
 cam.location=camera;cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
for s in ['wood_buckler','iron_kite','ash_aegis']:shot(s,'rusty_sword',s,'miecz_postoj')
shot('tarcza_od_wewnatrz','rusty_sword','wood_buckler','miecz_blok',1,(3,5,2.7))
for a in ['miecz_atak1','miecz_atak2','miecz_atak3']:
 for fraction in [.25,.5,.75]:
  hi=bpy.data.actions[a].frame_range[1];shot(a+'_'+str(fraction),'steel_falchion','ash_aegis',a,round(hi*fraction))
for w,a in [('ash_greatsword','dwureczny_postoj'),('executioner_axe','topor_postoj'),('warden_glaive','glewia_postoj')]:shot(w,w,None,a)
