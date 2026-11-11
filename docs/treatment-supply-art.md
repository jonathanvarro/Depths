# Treatment supplies and fortress follow-up

[Local review](E:/GitHub/Depths/build/local-fortress-treatment-v1/polish.html) shows the pickup on a cave floor, the two icon sizes, the journal silhouette and the archer's ready, drawn and release frames.

- [Treatment bundle scene](../art/props/treatment-supplies-v1/scene.tscn) is a linen roll with two faded red ties and a closed olive packet. It has one material surface, 484 triangles and a floor-centre origin facing +Z. Its approximate bounds are 0.41 m wide, 0.16 m high and 0.34 m deep. Place or remove the scene from the encounter controller when the pickup is available or collected.
- [Pack icon at 128 × 128](../art/items/treatment-supplies-v1/bundle-128.png) and [compact icon at 64 × 64](../art/items/treatment-supplies-v1/bundle-64.png) use the same model as the pickup and the field kit's alpha and palette export. Use either icon once the nurse's quest assigns an item ID. The closed packet leaves the treatment ingredients open.
- [Goblin King bestiary silhouette](../art/ui/expedition-v1/thumbnails/goblin_king.png) follows the existing 64 × 64 journal format and resolves through the King’s enemy ID. The archer's draw and release are described in [the fortress art guide](fortress-goblins-3d.md).

The editable Blender models are in the local review's `masters` folder. To rebuild, run `tools/fortress_goblins/build.py` and `build_treatment_bundle.py` in background Blender, passing the local review directory as `--review-output` to both scripts. The fortress exporter also takes the workspace path as `--workspace`. Prepare the isolated project with `prepare_review.py` using the same paths, import headlessly and run `res://check_polish.gd` through the private-desktop launcher. `export_polish_icons.py --review-output PATH` builds the journal and item PNGs from those renders.

The focused Mobile check passed the imported string tension, release, interruption and still-mode checks. The full fortress regression also passed 691 checks. The treatment icon and pickup await quest integration.
