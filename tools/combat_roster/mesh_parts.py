"""Mesh construction in metres, using the idle pose for rigid equipment fits."""
import math
import struct
import zlib
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

EXTRA = {
    "cream": "b6a786", "linen": "877c65", "linen_dark": "544e45",
    "skin_warm": "a97857", "skin_high": "c59870", "skin_shadow": "76503e",
    "hair": "48382e", "hair_high": "71513c", "maroon": "713b37",
    "maroon_light": "995751", "maroon_dark": "462b2b", "brass": "a58752",
    "brass_dark": "685336", "brass_edge": "c3a16b", "moss": "646b50",
    "moss_light": "85886a", "pelt": "584b42", "pelt_high": "766254",
    "pelt_dark": "37312c", "red": "a46044", "fur_gray": "7e7165",
    "steel": "91948a", "steel_dark": "535954", "deep_olive": "454b3a",
    "umber": "79563b", "carapace": "745235", "carapace_light": "a17347",
    "bone": "c3ad83", "bone_dark": "827257", "sack": "9a815d",
    "wool": "5e5c52", "wool_light": "79786c",
}


def palette_png(path, palette):
    def chunk(name, data):
        return struct.pack(">I", len(data)) + name + data + struct.pack(">I", zlib.crc32(name + data))

    colours = [bytes.fromhex(colour) for colour in palette.values()]
    colours.extend([colours[0]] * (64 - len(colours)))
    rows = b"".join(
        (b"\0" + b"".join(colour * 16 for colour in colours[row:row+8])) * 16
        for row in range(56, -1, -8)
    )
    header = struct.pack(">IIBBBBB", 128, 128, 8, 2, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
                     + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))


def set_uv(mesh, palette, face_colours):
    uv = mesh.uv_layers.new(name="RosterPalette")
    indices = {colour: i for i, colour in enumerate(palette)}
    for polygon, colour in zip(mesh.polygons, face_colours, strict=True):
        i = indices[colour]
        for loop in polygon.loop_indices:
            uv.data[loop].uv = ((i % 8 + .5) / 8, (i // 8 + .5) / 8)
    for layer in list(mesh.uv_layers):
        if layer.name != uv.name:
            mesh.uv_layers.remove(layer)


def prior_colours(mesh, palette):
    old = mesh.uv_layers["DepthsPalette"]
    names = list(palette)[:32]
    return [names[math.floor(old.data[p.loop_start].uv.x * 8)
                  + 8 * math.floor(old.data[p.loop_start].uv.y * 4)] for p in mesh.polygons]


class Mesh:
    """Batch parts by surface while retaining per-part bone weights."""

    def __init__(self):
        self.vertices = []
        self.faces = []
        self.colours = []
        self.groups = {}

    def add(self, vertices, faces, colours, bone):
        start = len(self.vertices)
        self.vertices.extend(Vector(vertex) for vertex in vertices)
        self.faces.extend(tuple(start + i for i in face) for face in faces)
        self.colours.extend([colours] * len(faces) if isinstance(colours, str) else colours)
        self.groups.setdefault(bone, []).extend(range(start, len(self.vertices)))

    def loft(self, rings, bone, colour, accent=None, sides=8, axis=None, origin=(0, 0, 0), twist=0):
        """Rings are (height, half-width, half-depth, x offset, y offset)."""
        rotation = Vector((0, 0, 1)).rotation_difference(Vector(axis).normalized()) if axis else None
        vertices = []
        for layer, (height, width, depth, x, y) in enumerate(rings):
            for i in range(sides):
                theta = math.tau * (i / sides) + math.pi / sides
                irregular = 1 + twist * math.sin(i * 5.2 + layer * 3.1)
                point = Vector((x + width * irregular * math.cos(theta),
                                y + depth * irregular * math.sin(theta), height))
                vertices.append(Vector(origin) + (rotation @ point if rotation else point))
        faces = [tuple(reversed(range(sides)))]
        colours = [colour]
        for ring in range(len(rings) - 1):
            for i in range(sides):
                j = (i + 1) % sides
                a, b = ring * sides, (ring + 1) * sides
                faces.append((a+i, a+j, b+j, b+i))
                colours.append(accent if accent and i in (1, 2, 3) else colour)
        faces.append(tuple(range(len(vertices) - sides, len(vertices))))
        colours.append(accent or colour)
        self.add(vertices, faces, colours, bone)

    def segment(self, start, end, radii, bone, colour, accent=None, sides=7):
        axis = Vector(end) - Vector(start)
        self.loft([(axis.length*t, radius, radius, 0, 0) for t, radius in radii],
                  bone, colour, accent, sides, axis, start, .07)

    def stone(self, centre, size, bone, colour, accent=None, sides=8):
        x, y, z = size
        self.loft([(-z, x*.43, y*.43, 0, 0), (-z*.48, x*.9, y*.87, 0, 0),
                   (z*.15, x, y, 0, 0), (z*.72, x*.72, y*.79, 0, 0),
                   (z, x*.33, y*.41, 0, 0)],
                  bone, colour, accent, sides, origin=centre, twist=.045)

    def panel(self, outline, depth, thickness, bone, front, edge):
        """Build a front-facing plate; outline coordinates are (X, Z)."""
        size = len(outline)
        points = [(x, depth + side * thickness, z) for side in (0, 1) for x, z in outline]
        faces = [tuple(range(size)), tuple(reversed(range(size, 2*size)))]
        faces.extend((i, i + size, (i+1) % size + size, (i+1) % size) for i in range(size))
        self.add(points, faces, [front, edge] + [edge] * size, bone)

    def finish(self, name, rig, palette):
        if not self.faces:
            return None
        vertices = self.vertices.copy()
        for name_bone, indices in self.groups.items():
            pose = rig.pose.bones[name_bone]
            bind = (rig.matrix_world @ pose.matrix @ pose.bone.matrix_local.inverted()).inverted()
            for i in indices:
                vertices[i] = bind @ vertices[i]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], self.faces)
        mesh.update()
        set_uv(mesh, palette, self.colours)
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        obj.parent = rig
        for bone, indices in self.groups.items():
            group = obj.vertex_groups.new(name=bone)
            group.add(indices, 1.0, "REPLACE")
        obj.modifiers.new("Rigid skin", "ARMATURE").object = rig
        return obj
