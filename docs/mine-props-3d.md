# Mine supports, lanterns and miners’ shrine · #241

Owner-selected 3D prop batch, 2026-11-07. Reusable scenes are in
art/dressing/mine-3d-v1. The existing 2D designs supply the miner, pick,
timber framing, offerings and worn material direction.

Open E:/GitHub/Depths/build/local-mine-props-v1/inspector.html for the
native captures, lighting/angle comparisons and fresh/used switches.
START_REVIEW.cmd opens the interactive Godot review, including glow animation
and its exact still mode. Editable Blender masters stay in the local
masters subfolder. They retain individual pieces and named colours.

## Scenes and placement

| Scene | Mount | Geometry |
|---|---|---|
| support.tscn | Floor centre, span across local X | 352 triangles |
| support-damaged.tscn | Same registration | 459 triangles |
| lantern-standing.tscn | Floor at the lantern’s foot | 264 triangles |
| lantern-hanging.tscn | Top wall bracket, local +Z into the room | 568 triangles |
| miners-shrine.tscn | Wall/floor intersection, local +Z into the room | 1,493 fresh including flames / 1,358 used |

The frame fits a 2 m corridor beneath a 2.4 m ceiling. Its opening provides
1.6 m clear width and 1.85 m clear height beneath the corner braces.
The timber has bowed sections, chamfered edges, dark splits, rusty straps
and square nails. The damaged sibling adds a repair plank and header split.
All framing remains outside the centre passage.

Lantern bodies are approximately 24 cm wide. The standing model is about
35 cm high. The hanging model, chain and bracket extend about 54 cm below
their mounting point. Lantern panes are opaque, with a restrained emission
when lit. Source shapes have slight asymmetry and sparse rust faces.

The shrine is approximately 1.1 m wide and 1.56 m high. Its carved wooden
miner stands above a blue cloth, mineral offerings, a cup and three candles.
The niche uses irregular masonry and a timber lintel. Wall mounting should
use the actual rock face, with the root at floor level.

## Presentation API

All scenes use prop.gd. Set properties before adding them to the scene tree
or at runtime.

```gdscript
shrine.state = "empty"              # "closed" restores fresh offerings
shrine.candle_glow_enabled = false
lantern.lit = false
lantern.animate_glow = false        # exact still presentation
lantern.set_motion(false)           # compatible with Main’s effects hook
```

The shrine’s empty state removes the cloth and offerings, empties the cup,
shortens candles, adds ash and hides the flames. Root and base geometry
retain their registration. Lanterns support lit/extinguished presentation.
Glow animates only when visible, lit and enabled. Disabling animation restores
the fixed glow immediately. The scene adds no Light3D or collision.

The shared palette and world-space grain follow the existing KayKit pilot.
Opaque geometry uses one material surface per model. Lantern glass uses a
second mesh/material for state changes. Flame meshes share one instance
material. The palette is 256 × 128, with 18 colours. Grain is the existing
art/third-party/kaykit-dungeon-remastered/grain-floor1.png.

## Integration handoff

This batch supplies the new reusable scenes and the isolated review.
Live dressing and event resources still point at the existing library.
For hookup, bind the support through Dressing’s existing placement and
the shrine through the wall-mounted event resource and build_shrines.gd.
The shrine preserves the closed/empty state and candle_glow_enabled property.
Pass the effects setting through set_motion. Lantern placement should use
real mounts. Light supplies, visibility bands, event rewards and save flags
remain controller-owned.

## Sources and rebuild

Kay Lousberg’s CC0 Halloween Bits 1.0 supplies both lanterns and the fresh
and melted candles. Ten selected originals match the official pinned Git
blobs. Original bytes, licence, hashes and exact paths are retained under
art/third-party/kaykit-mine-props-v1. CREDITS.md records modifications.
Framing, masonry, carving, pick, cup, cloth and mineral geometry are authored
for Depths by tools/mine_props/build_models.py.

1. Run tools/mine_props/intake.py to restore the pinned source subset.
2. Run build_models.py in Blender with --background --factory-startup
   --disable-autoexec --python-exit-code 1, followed by -- --workspace E:/GitHub/Depths.
3. Run prepare_review.py --workspace E:/GitHub/Depths with Python/Pillow.
4. Import the isolated project in Godot 4.7.2, then run its check.gd with
   the Mobile renderer. Its local masters folder is excluded from import.
5. Run package_review.py --workspace E:/GitHub/Depths, then check_gallery.cjs
   with the workspace argument.

The review verifies metric bounds, triangle counts, palette UVs, passage
clearance, state registration, glow/still behavior and phone-safe controls.
Native captures include both light settings, three angles, each visible state,
three phone/desktop screens and a mounted corridor. Physical iPhone performance
and owner art acceptance remain review steps.

The 2026-11-07 native review passed 172 checks with clean runtime logs.
Source verification covers ten pinned originals and seven derived GLBs.
The gallery includes 52 actual native captures.
