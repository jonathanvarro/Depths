# Expedition props

Eight reusable scenes provide chests, a strongbox, an abandoned pack,
two cold rest sites, old workings and intact/broken rails.

Containers accept closed/open/empty. Packs, resting sites and workings
accept closed/empty. Rails are static. set_state, set_searched and set_motion
are available on the root. Set state before adding a scene to restore its
final pose directly. Runtime lid motion is optional.

Every prop has a floor origin. Faces look along local +Z. Rails run along
local Z in two-metre sections. Shared palette and cave grain are assigned
at runtime. These scenes add no collision or gameplay outcomes.

Handoff and rebuild steps are in docs/containers-rest-workings-3d.md.
Review at E:/GitHub/Depths/build/local-expedition-props-v1/inspector.html.
