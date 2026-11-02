"""Reversible garment/body preview coverage; no gameplay or source-face edits."""
import bpy
PIECES=('tunic','belt','trousers','boot.left','boot.right')
def set_pieces(fit,visible):
    visible=set(visible)
    if not visible.issubset(PIECES):raise ValueError('Unknown preview garment')
    body=bpy.data.objects['body.'+fit+'.v1']
    for o in bpy.context.scene.objects:
        piece=o.get('piece')
        if piece and o.get('fit_id')==fit+'-v1':o.hide_set(piece not in visible);o.hide_render=piece not in visible
    covered=set()
    for piece in visible-{'belt'}:
        name='cover.'+('boots.'+piece.split('.')[1] if piece.startswith('boot.') else piece)
        group=body.vertex_groups[name]
        covered.update(v.index for v in body.data.vertices if any(g.group==group.index and g.weight>.5 for g in v.groups))
    keep=set(range(len(body.data.vertices)))-covered
    group=body.vertex_groups['coverage.keep'];group.remove(list(range(len(body.data.vertices))))
    if keep:group.add(sorted(keep),1,'REPLACE')
    mask=body.modifiers['Reversible visible-garment coverage'];mask.show_viewport=mask.show_render=bool(covered)
    body['visible_pieces']=','.join(sorted(visible));bpy.context.view_layer.update()
    return keep
