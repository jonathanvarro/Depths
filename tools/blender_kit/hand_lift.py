"""#218: keep a hand out of the thigh, as a corrected copy of a clip.

An animator-style correction over a frame window: during the window the hand
is moved out from the thigh (away from the thigh bone's axis, toward where the
hand already is) by `amount`, easing in and out with a raised cosine. Each
frame the arm is re-posed with a two-bone solve (shoulder -> elbow -> hand)
that keeps the elbow on its original side and the hand's world orientation,
so the fingers keep their pose. Frames outside the window keep the source keys.

The window comes from looking at the motion (renders), not an automatic
inside test: whole-mesh inside tests proved unreliable here because the
trousers are open at the waist and cuffs and hands hang close to the hips.

The source Action is never changed: the result is a copy named
`<action>.handlift`, and both stay in the file.
"""
import math

import bpy
from mathutils import Matrix, Vector


def frame(f):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()


def assign(rig, action):
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]


def weight(f, start, full_from, full_to, end):
    """0 outside [start, end], 1 inside [full_from, full_to], cosine ease between."""
    if f <= start or f >= end:
        return 0.0
    if f < full_from:
        return .5 - .5 * math.cos(math.pi * (f - start) / (full_from - start))
    if f > full_to:
        return .5 - .5 * math.cos(math.pi * (end - f) / (end - full_to))
    return 1.0


def outward(rig, side, thigh):
    """Unit vector out of the thigh toward its outer top: the body's own
    side plus up, made perpendicular to the thigh bone (world). A direction
    "from the thigh axis toward the hand" was tried first; it swings
    unpredictably when the hand is buried near the axis and pushed the hand
    down between the knees."""
    world = rig.matrix_world
    leg = rig.pose.bones[f'mixamorig:{side}{thigh}']
    axis = (world @ leg.tail - world @ leg.head).normalized()
    hips = rig.pose.bones['mixamorig:Hips']
    # The body's left/right and up from the hips, so it follows her turning.
    basis = (world @ hips.matrix).to_3x3().normalized()
    lateral = basis @ Vector((1, 0, 0)) * (1 if side == 'Left' else -1)
    up = basis @ Vector((0, 1, 0))
    wanted = lateral + up
    wanted -= axis * wanted.dot(axis)
    return wanted.normalized()


def solve_arm(rig, side, lift):
    """Move the hand by `lift` (world), keeping elbow side and hand rotation."""
    bones = [rig.pose.bones[f'mixamorig:{side}{n}'] for n in ('Arm', 'ForeArm', 'Hand')]
    world = rig.matrix_world
    arm_m, fore_m, hand_m = (world @ b.matrix for b in bones)
    s, e, h = arm_m.translation, fore_m.translation, hand_m.translation
    t = h + lift
    a, b = (e - s).length, (h - e).length
    d = min(max((t - s).length, abs(a - b) + 1e-6), a + b - 1e-6)
    u = (t - s).normalized()
    w = (e - s) - u * (e - s).dot(u)
    if w.length < 1e-8:
        return
    w.normalize()
    x = (a * a - b * b + d * d) / (2 * d)
    new_e = s + u * x + w * math.sqrt(max(a * a - x * x, 0))
    t = s + u * d
    about = lambda p, r: Matrix.Translation(p) @ r @ Matrix.Translation(-p)
    r1 = (e - s).rotation_difference(new_e - s).to_matrix().to_4x4()
    new_arm = about(s, r1) @ arm_m
    fore_1 = about(s, r1) @ fore_m
    r2 = (r1.to_3x3() @ (h - e)).rotation_difference(t - new_e).to_matrix().to_4x4()
    new_fore = about(new_e, r2) @ fore_1
    # Keep the hand's world rotation and the rig's scale; only move it.
    new_hand = Matrix.Translation(t) @ hand_m.to_3x3().to_4x4()
    inverse = world.inverted()
    for bone, matrix in zip(bones, (new_arm, new_fore, new_hand)):
        bone.matrix = inverse @ matrix
        bpy.context.view_layer.update()


def lift_window(rig, action, side, window, amount, thigh='UpLeg'):
    """Return (corrected action, report). `window` is (start, full_from,
    full_to, end) in source frames. The source action is untouched."""
    corrected = action.copy()
    corrected.name = action.name + '.handlift'
    corrected.use_fake_user = True
    first, last = map(round, action.frame_range)
    frames = [f for f in range(first, last + 1) if weight(f, *window) > 0]
    # "Out of the thigh" can swing quickly as the hand passes the thigh axis,
    # so the direction is averaged over nearby frames before it is applied.
    assign(rig, action)
    directions = {}
    for f in frames:
        frame(f)
        directions[f] = outward(rig, side, thigh)
    lifts = {}
    for f in frames:
        total = sum((directions[g] * math.exp(-(g - f) ** 2 / 128) for g in frames if abs(g - f) <= 20),
                    start=directions[f] * 0)
        lifts[f] = total.normalized() * amount * weight(f, *window)
    assign(rig, corrected)
    previous = {}
    changed = []
    names = [f'mixamorig:{side}{n}' for n in ('Arm', 'ForeArm', 'Hand')]
    for f in frames:
        frame(f)
        solve_arm(rig, side, lifts[f])
        for name in names:
            bone = rig.pose.bones[name]
            q = bone.rotation_quaternion.copy()
            if name in previous and q.dot(previous[name]) < 0:
                q.negate()
                bone.rotation_quaternion = q
            previous[name] = q
            for prop in ('location', 'rotation_quaternion', 'scale'):
                bone.keyframe_insert(prop, frame=f, group=name)
        changed.append(f)
    for layer in corrected.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for point in curve.keyframe_points:
                        point.interpolation = 'LINEAR'
    assign(rig, action)
    report = {'source_action': action.name, 'corrected_action': corrected.name,
              'slot': corrected.slots[0].identifier, 'side': side, 'thigh_bone': thigh,
              'window_frames': list(window), 'lift_source_units': amount,
              'frames_changed': [changed[0], changed[-1]] if changed else [],
              'source_curves_modified': False}
    return corrected, report
