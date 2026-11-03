"""Blender counterpart of actor.gd; import alongside tools/blender_kit.

set_outfit('female', 'jacket', {'tunic','trousers','boot.left','boot.right'})
uses the existing logical upper slot without displaying two upper garments.
"""
import bpy
from wardrobe_visibility import set_pieces,PIECES


def set_outfit(fit,outfit,pieces=PIECES):
    if outfit not in ['jacket','tunic']:raise ValueError('Unknown outfit')
    keep=set_pieces(fit,pieces)
    for obj in bpy.context.scene.objects:
        if obj.get('piece') and obj.get('fit_id')==fit+'-v1':
            visible=obj.get('piece') in pieces and obj.get('outfit','both') in ['both',outfit]
            obj.hide_set(not visible);obj.hide_render=not visible
    bpy.context.view_layer.update()
    return keep
