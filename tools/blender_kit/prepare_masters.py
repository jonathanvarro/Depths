"""#210: true supplied-FBX editable masters; no garment/face authoring.

Run in Blender's factory background session. All generated assets stay local.
"""
import bpy,sys,json,hashlib,math
sys.dont_write_bytecode=True
from pathlib import Path
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from audit_sources import scene_report,points_bbox
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1'
SOURCE_UV={}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def collection(name,parent):
    c=bpy.data.collections.new(name);parent.children.link(c);return c
def move(o,c):
    for old in list(o.users_collection):old.objects.unlink(o)
    c.objects.link(o)
def digest_rig(rig):
    data=[(b.name,b.parent.name if b.parent else None,[round(x,7) for row in b.matrix_local for x in row]) for b in rig.data.bones]
    return hashlib.sha256(json.dumps(data).encode()).hexdigest()
def digest_geometry(o):
    return hashlib.sha256(json.dumps({'verts':[list(v.co) for v in o.data.vertices],'faces':[list(p.vertices) for p in o.data.polygons],'uv':[[list(x.uv) for x in l.data] for l in o.data.uv_layers],'weights':[[(o.vertex_groups[g.group].name,g.weight) for g in v.groups] for v in o.data.vertices]},sort_keys=True).encode()).hexdigest()
def shared_material(name,color):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;m.use_fake_user=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.86
    return m
def prepare(fit):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    prefs=bpy.context.preferences.filepaths
    if 'NONE' in [i.identifier for i in prefs.bl_rna.properties['file_preview_type'].enum_items]:prefs.file_preview_type='NONE'
    scene=bpy.context.scene;source=OUT/'source'/('Base '+fit.title()+' - Dying.fbx')
    bpy.ops.import_scene.fbx(filepath=str(source),use_image_search=False,automatic_bone_orientation=False)
    rig=next(o for o in scene.objects if o.type=='ARMATURE');body=next(o for o in scene.objects if o.type=='MESH')
    source_rig=digest_rig(rig);source_mesh=digest_geometry(body)
    original_rig_name=rig.name;original_body_name=body.name;original_action_name=rig.animation_data.action.name
    # Preserve source rest transforms, mesh arrays, hierarchy and weighted groups.
    # Canonical object names are only labels; bone names and Action slots stay.
    rig['source_name']=rig.name;body['source_name']=body.name;rig.name='rig.'+fit+'.v1';body.name='body.'+fit+'.v1'
    rig.data.name='skeleton.'+fit+'.v1';body.data.name='mesh.body.'+fit+'.v1'
    master=collection('KIT_'+fit+'_v1',scene.collection)
    rig_col=collection('01_RIG',master);body_col=collection('02_BODY',master)
    garments=collection('03_GARMENTS',master)
    for name in ['tunic','belt','trousers','boots']:collection('garment.'+name,garments)
    collection('04_COVERAGE_REFERENCES',master);collection('90_REVIEW',scene.collection)
    move(rig,rig_col);move(body,body_col)
    for c in list(bpy.data.collections):
        if c!=master and c.name.startswith('Collection') and not c.objects and not c.children:bpy.data.collections.remove(c)
    rig['fit_id']=fit+'-v1';body['fit_id']=fit+'-v1'
    body['coverage_convention']='cover.tunic / cover.trousers / cover.boots; empty groups only, no body removed'
    # Append empty non-bone mask groups. They do not change existing influences.
    for name in ['cover.tunic','cover.trousers','cover.boots']:body.vertex_groups.new(name=name)
    texture_repair=None
    if fit=='female':
        # The FBX references an unavailable machine-temp texture. Its original
        # packed counterpart is supplied in the owner's matching .blend.
        reference=OUT/'source/Base Female Mesh.blend'
        current_uv={layer.name:[tuple(v.uv) for v in layer.data] for layer in body.data.uv_layers}
        assert current_uv.keys()==SOURCE_UV.keys()
        assert all(len(current_uv[k])==len(SOURCE_UV[k]) and max(abs(a-b) for x,y in zip(current_uv[k],SOURCE_UV[k]) for a,b in zip(x,y))<1e-6 for k in current_uv)
        tex=OUT/'textures/source-female-body.png'
        mat=body.data.materials[0];mat.name='source.skin.female'
        image=bpy.data.images.load(str(tex),check_existing=False);image.pack()
        assert image.size[0]==1024
        for node in mat.node_tree.nodes:
            if node.type=='TEX_IMAGE':node.image=image
        texture_repair={'source_blend':reference.name,'source_image':'BodyTexturebm.png','packed_bytes_sha256':sha(tex),'both_uv_maps_match_source_blend':True,'method':'Original packed pixels relinked into existing FBX material; no repaint.'}
        image.filepath='//textures/source-female-body.png'
    else:
        body.data.materials[0].name='source.skin.male'
    for name,color in [('cloth.tunic',(.18,.16,.12)),('cloth.trousers',(.075,.08,.065)),('leather.belt',(.13,.075,.04)),('leather.boots',(.09,.055,.035))]:shared_material(name,color)
    bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=True,do_recursive=True)
    action=rig.animation_data.action;action.use_fake_user=True
    action['clip_id']='source.'+fit+'.dying';action['source_file']=source.name
    action['source_slot']=rig.animation_data.action_slot.identifier
    rig.data.pose_position='REST';scene.frame_start=round(action.frame_range[0]);scene.frame_end=round(action.frame_range[1]);scene.frame_set(scene.frame_start)
    scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1.0
    scene['kit_contract']='depths-blender-kit-v1';scene['fit_id']=fit+'-v1'
    scene['source_fbx_sha256']=sha(source);scene['source_units']='FBX import transforms preserved; 1 Blender unit = 1 metre. No aesthetic normalization.'
    scene['export_profile']='GLB; +Y up via exporter; rest skeleton; all influences (8); no applied transforms; active source Action'
    scene['mode_help']='REST is neutral modelling. Switch Armature data > Skeleton > Pose Position for the preserved dying Action; return to Rest Position before editing garments.'
    text=bpy.data.texts.new('START_HERE.txt');text.write('DEPTHS '+fit.upper()+' BASE · #210\n\nEditable true FBX base. No new face or garments.\n01_RIG: select rig.'+fit+'.v1. Armature data > Skeleton > Rest Position for fitting.\nFor animation: choose Pose Position. The source Action and OBSlot are already assigned. Scrub frames1–261 at60fps.\nDo NOT Apply Pose as Rest Pose; do not Apply object transforms or rename bones.\nMake garments in03_GARMENTS, fit_id '+fit+'-v1. Use separate objects/materials. Empty cover.* groups are mask templates only.\nUse the generic exporter/check scripts in tools/blender_kit. All supplied and derived art stays in this ignored folder.\nThe other34 clips require target-specific retargeting before garment validation.\n')
    bpy.ops.object.select_all(action='DESELECT');body.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
    # Useful neutral viewport saved with the file; no auto-running embedded code.
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                area.spaces.active.region_3d.view_distance=6.5;area.spaces.active.region_3d.view_location=Vector((0,0,1.9))
                area.spaces.active.shading.type='MATERIAL';area.spaces.active.overlay.show_extras=False
    assert digest_rig(rig)==source_rig and digest_geometry(body)==source_mesh
    path=OUT/(fit+'_base.blend');bpy.ops.wm.save_as_mainfile(filepath=str(path),check_existing=False)
    report=scene_report();report.update({'fit_id':fit+'-v1','master':path.name,'master_sha256':sha(path),'source':source.name,'source_sha256':sha(source),'source_rig_name':original_rig_name,'source_body_name':original_body_name,'source_action_name':original_action_name,'rig_sha256':source_rig,'geometry_sha256':source_mesh,'texture_repair':texture_repair,'collections':[c.name for c in bpy.data.collections]})
    return report
def main():
    global SOURCE_UV
    OUT.mkdir(parents=True,exist_ok=True)
    if any((OUT/(fit+'_base.blend')).exists() for fit in ['female','male']) and '--rebuild' not in sys.argv:
        raise RuntimeError('Masters exist. Do not overwrite downstream edits; use -- --rebuild only for an intentional fresh-source rebuild.')
    # Read the packed source directly; appending its material can attempt to
    # repack a stale path before relinking. This never saves the source .blend.
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'source/Base Female Mesh.blend'),load_ui=False,use_scripts=False)
    image=bpy.data.images['BodyTexturebm.png'];assert image.packed_file
    SOURCE_UV={layer.name:[tuple(v.uv) for v in layer.data] for layer in bpy.data.objects['FemaleMesh'].data.uv_layers}
    texture=OUT/'textures/source-female-body.png';texture.parent.mkdir(exist_ok=True)
    texture.write_bytes(bytes(image.packed_file.data))
    # A source/version manifest contains only hashes and metadata, not model data.
    sources=[{'file':p.relative_to(OUT).as_posix(),'sha256':sha(p),'bytes':p.stat().st_size} for p in sorted((OUT/'source').rglob('*')) if p.is_file()]
    reports=[prepare(fit) for fit in ['female','male']]
    manifest={'schema':'depths-blender-kit-v1','blender':bpy.app.version_string,'local_only':True,'sources':sources,'fits':reports,'export':{'format':'GLB','units':'metres; no source dimension normalization','axis':'Blender +Z up -> glTF/Godot +Y up','preserve_source_object_transforms':True,'max_influences':8,'rest_position_armature':True},'coverage':{'prefix':'cover.','method':'retain original body; duplicate and mask only a derived export; no deleting source faces','current_state':'empty groups; no active coverage mask'},'missing_or_pending':['All cross-source idle/walk/sit clips require target-specific retargeting and visual review before use for garment acceptance.','No garment fit or physical-iPhone performance acceptance is claimed.']}
    (OUT/'kit-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print('KIT_MASTERS_SAVED',[(r['fit_id'],r['master']) for r in reports],flush=True)
if __name__=='__main__':main()
