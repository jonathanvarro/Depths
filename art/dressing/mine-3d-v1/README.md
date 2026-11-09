# Mine props

Use support.tscn or support-damaged.tscn across a 2 m corridor.
lantern-standing.tscn anchors at the floor. lantern-hanging.tscn anchors
at the top of its wall bracket, facing local +Z into the room.
miners-shrine.tscn anchors at the wall/floor intersection.

Shrine state is closed or empty. Lanterns use lit. animate_glow and
set_motion(false) control the optional glow motion. All scenes assign
their shared palette and the existing cave grain at runtime.

Sources, dimensions, state behavior, rebuild steps and review are recorded
in docs/mine-props-3d.md. The local gallery is
E:/GitHub/Depths/build/local-mine-props-v1/inspector.html.
