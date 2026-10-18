class_name PortraitSet
extends Resource
## The layers that make up one character's portrait (see DESIGN.md,
## "Portrait system").
##
## Every texture is a full 192 x 192 canvas with the same origin, so layers
## line up without offsets. Never trim or resize a layer on its own.
## Reuse comes from sharing files: characters on the same body template point
## at the same `body` and `clothing` images and differ in `head`, hair, eyes
## and mouth.
##
## Animation swaps whole drawings rather than deforming the face:
## blink_frames replace `eyes` briefly, talk_frames replace `mouth`. Leave
## them empty and blinking/talking simply doesn't happen.

## Layers are drawn in this order, bottom to top.
@export var background: Texture2D
## Hair (or hood) pieces that go behind the body.
@export var back: Array[Texture2D] = []
## Reusable upper-body template (one of the planned six builds).
@export var body: Texture2D
## The character's own head/face.
@export var head: Texture2D
@export var eyes: Texture2D
@export var mouth: Texture2D
@export var clothing: Array[Texture2D] = []
## Front hair, accessories, anything over clothing.
@export var front: Array[Texture2D] = []
## Optional overlays switched on by condition, keyed by name
## (e.g. "blood", "dirt", "bandage", "scar", "pallor").
@export var conditions: Dictionary[String, Texture2D] = {}

@export_group("Lighting")
## Optional neutral black/white passes, registered to this exact outfit.
## PortraitView tints these; neither background nor card UI is illuminated.
@export var light_shadow: Texture2D
@export var light_highlight: Texture2D

@export_group("Animation")
## Eyes closing, in order (e.g. half-closed, closed). Played forward then back.
@export var blink_frames: Array[Texture2D] = []
## Mouth shapes cycled while speaking.
@export var talk_frames: Array[Texture2D] = []
