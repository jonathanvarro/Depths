# Treasure sources v1

Twelve unmodified outputs from built-in image_gen.imagegen: eleven
individual treasure items and one registered open chest with gold/gems.
generation-manifest.json retains exact prompts, transparency flags,
reference image roles/paths and original generated filenames.

Style references: approved rough knife and the existing native oil flask.
Chest edit target: art/source/opening-tutorial-v1/chest-open.png;
native open chest is its registration/style reference. Existing closed
and empty runtime textures are reused directly, not regenerated.

Rebuild with tools/art/build_treasure_art.py. Cropping/nearest scaling,
alpha threshold, palette reduction and chest registration are deterministic
export operations; masters remain untouched. Source/review folders have
.gdignore; the export preset excludes art/source and tools.
