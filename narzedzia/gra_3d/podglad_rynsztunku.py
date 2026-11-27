"""Blender: porównawcze podglądy nowego wyposażenia na Hadranie."""
import bpy,sys,pathlib,math
from mathutils import Vector
root=pathlib.Path(sys.argv[sys.argv.index('--')+1]);out=root/'podglady';out.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(root/'hadran_rynsztunek_gotowy.blend'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=24
scene.world=bpy.data.worlds.new('swiat');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.15,.15,.18,1)
bpy.ops.object.camera_add(location=(3,-6,2.8));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.5;scene.camera=cam
for loc,power,size in [((2,-4,5),600,4),((-3,-1,2),300,3),((1,3,3),500,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object;l.data.energy=power;l.data.shape='DISK';l.data.size=size;l.rotation_euler=(Vector((0,0,1))-l.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=700;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=True;scene.view_settings.view_transform='AgX'
def render(name,armor,show,action='miecz_postoj',frame=1):
 for o in bpy.data.objects:
  if o.type!='MESH':continue
  o.hide_render=o.name!='cialo_pod_pancerzem' and o.name!='pancerz_'+armor and o.name not in show
 a=bpy.data.actions.get(action);arm.animation_data.action=a
 if a.slots:arm.animation_data.action_slot=a.slots[0]
 scene.frame_set(frame);scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
for n in ['leather_jerkin','chainmail_hauberk','ash_plate']:
 render(n,n,['sprzet_rusty_sword','sprzet_wood_buckler','pochwa_rusty_sword'])
render('luk','leather_jerkin',['sprzet_hunter_bow','sprzet_iron_arrow','sprzet_quiver','odlozona_rusty_sword','pochwa_rusty_sword','odlozona_wood_buckler'],'luk_celowanie')
for f in [1,20,40,59]:render('glewia_%02d'%f,'chainmail_hauberk',['sprzet_warden_glaive','odlozona_iron_kite'],'glewia_atak1',f)
