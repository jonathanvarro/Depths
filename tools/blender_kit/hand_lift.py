"""#218: lift hands that sink into the trousers, as a corrected copy of a clip.

For every frame, hand/forearm points (body and tunic sleeve) are tested
against the evaluated trousers. Where they sit inside, the hand is moved out
along the trouser surface normal, plus a small margin. The lift is smoothed
over time so the hand rises gently before contact rather than snapping. Each
arm is then re-posed with a two-bone solve (shoulder -> elbow -> hand) that
keeps the elbow on its original side and the hand's world orientation, so
fingers keep their pose. Frames that need no lift keep the source keys.

The source Action is never changed: the result is a copy named
`<action>.handlift`, and both stay in the file.
"""
import math

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

MARGIN = .003          # source units of clearance above the cloth
WINDOW = 8             # frames either side used to ease in/out
SIGMA = 4.0
SIDES = ['Left', 'Right']


def arm_points(obj):
    """Vertex index -> side for vertices mostly weighted to a hand/forearm."""
    names = {g.index: g.name for g in obj.vertex_groups}
    result = {}
    for v in obj.data.vertices:
        if not v.groups:
            continue
        name = names.get(max(v.groups, key=lambda g: g.weight).group, '')
        if 'Hand' in name or 'ForeArm' in name:
            result[v.index] = 'Left' if 'Left' in name else 'Right'
    return result


def world_mesh(obj):
    deps = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(deps)
    mesh = ev.to_mesh()
    points = [ev.matrix_world @ v.co for v in mesh.vertices]
    polygons = [tuple(p.vertices) for p in mesh.polygons]
    ev.to_mesh_clear()
    return points, polygons


def penetration(arms, trousers):
    """Per side: (depth, outward normal) of the deepest point inside the cloth."""
    tree = BVHTree.FromPolygons(*world_mesh(trousers))
    worst = {s: (0.0, Vector((0, 0, 1))) for s in SIDES}
    for obj, ids in arms:
        points, _ = world_mesh(obj)
        for i, side in ids.items():
            loc, normal, _, dist = tree.find_nearest(points[i])
            if loc is None or dist > .08:
                continue
            depth = -(points[i] - loc).dot(normal)
            # Inside only when the point lies behind the nearest face; near
            # edges a far point's projection can wrongly look negative.
            if depth > .7 * dist and depth > worst[side][0]:
                worst[side] = (depth, normal.normalized())
    return worst


def assign(rig, action):
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]


def frame(f):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()


def measure(rig, action, arms, trousers):
    assign(rig, action)
    first, last = map(round, action.frame_range)
    raw = {}
    for f in range(first, last + 1):
        frame(f)
        raw[f] = penetration(arms, trousers)
    return first, last, raw


def smooth(raw, first, last):
    """Lift vectors per side: dilate over the window, then Gaussian ease."""
    lifts = {}
    for side in SIDES:
        need = {f: raw[f][side][1] * (raw[f][side][0] + MARGIN) if raw[f][side][0] > 0 else Vector()
                for f in raw}
        dilated = {}
        for f in need:
            window = [need[k] for k in range(max(first, f - WINDOW), min(last, f + WINDOW) + 1)]
            dilated[f] = max(window, key=lambda v: v.length)
        eased = {}
        for f in need:
            total, weight = Vector(), 0.0
            for k in range(-WINDOW, WINDOW + 1):
                # Clamp at clip ends so a lift present at the end stays full there.
                g = math.exp(-k * k / (2 * SIGMA * SIGMA))
                total += dilated[min(last, max(first, f + k))] * g
                weight += g
            eased[f] = total / weight
        lifts[side] = eased
    return lifts


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
    r1 = (e - s).rotation_difference(new_e - s).to_matrix().to_4x4()
    about = lambda p, r: Matrix.Translation(p) @ r @ Matrix.Translation(-p)
    new_arm = about(s, r1) @ arm_m
    fore_1 = about(s, r1) @ fore_m
    r2 = (r1.to_3x3() @ (h - e)).rotation_difference(t - new_e).to_matrix().to_4x4()
    new_fore = about(new_e, r2) @ fore_1
    new_hand = Matrix.Translation(t) @ hand_m.to_3x3().normalized().to_4x4()
    inverse = world.inverted()
    for bone, matrix in zip(bones, (new_arm, new_fore, new_hand)):
        bone.matrix = inverse @ matrix
        bpy.context.view_layer.update()


def lift_action(rig, action, arms, trousers, passes=2):
    """Return (corrected action, report). The source action is untouched."""
    source_name = action.name
    corrected = None
    first, last, before = measure(rig, action, arms, trousers)
    total = {s: {f: Vector() for f in before} for s in SIDES}
    raw = before
    for _ in range(passes):
        lifts = smooth(raw, first, last)
        for side in SIDES:
            for f in total[side]:
                total[side][f] += lifts[side][f]
        # Re-pose from the untouched source each pass with the summed lift.
        rebuilt = action.copy()
        assign(rig, rebuilt)
        previous = {}
        for f in range(first, last + 1):
            if all(total[s][f].length < 1e-6 for s in SIDES):
                continue
            frame(f)
            for side in SIDES:
                if total[side][f].length >= 1e-6:
                    solve_arm(rig, side, total[side][f])
            for side in SIDES:
                for n in ('Arm', 'ForeArm', 'Hand'):
                    bone = rig.pose.bones[f'mixamorig:{side}{n}']
                    q = bone.rotation_quaternion.copy()
                    key = bone.name
                    if key in previous and q.dot(previous[key]) < 0:
                        q.negate()
                        bone.rotation_quaternion = q
                    previous[key] = q
                    for prop in ('location', 'rotation_quaternion', 'scale'):
                        bone.keyframe_insert(prop, frame=f, group=bone.name)
        for layer in rebuilt.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        for point in curve.keyframe_points:
                            point.interpolation = 'LINEAR'
        _, _, raw = measure(rig, rebuilt, arms, trousers)
        if corrected:
            bpy.data.actions.remove(corrected)
        corrected = rebuilt
        corrected.name = source_name + '.handlift'
        corrected.use_fake_user = True
    after = raw
    lift_size = {s: max(v.length for v in total[s].values()) for s in SIDES}
    step = {s: max((total[s][f + 1] - total[s][f]).length for f in range(first, last)) for s in SIDES}
    report = {
        'source_action': source_name, 'corrected_action': corrected.name,
        'slot': corrected.slots[0].identifier, 'frames': [first, last],
        'margin_source_units': MARGIN, 'ease_window_frames': WINDOW,
        'max_depth_before': {s: max(before[f][s][0] for f in before) for s in SIDES},
        'frames_inside_before': sum(1 for f in before if any(before[f][s][0] > 0 for s in SIDES)),
        'max_depth_after': {s: max(after[f][s][0] for f in after) for s in SIDES},
        'frames_inside_after': sum(1 for f in after if any(after[f][s][0] > 0 for s in SIDES)),
        'max_lift_source_units': lift_size,
        'max_lift_change_per_frame': step,
        'frames_changed': sum(1 for f in before if any(total[s][f].length >= 1e-6 for s in SIDES)),
        'source_curves_modified': False,
    }
    assign(rig, action)
    return corrected, report, total
