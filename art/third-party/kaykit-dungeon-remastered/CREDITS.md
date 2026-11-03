# KayKit Dungeon Remastered: asset record

Pilot for #224 (owner, 2026-11-03). See `docs/free-3d-assets.md`.

- **Author:** Kay Lousberg, www.kaylousberg.com. Credit isn't required, but
  is welcome.
- **Pack:** KayKit Dungeon Remastered 1.0, the free version.
- **Licence:** CC0 1.0 Universal (public domain). See `LICENSE.txt`,
  copied unchanged from the pack.
- **Licence checked on 2026-11-03:**
  - the pack's itch.io page, https://kaylousberg.itch.io/kaykit-dungeon-remastered
    ("Creative Commons Zero v1.0 Universal ... no attribution required");
  - the `LICENSE.txt` inside the download;
  - the Godot Asset Library listing, https://godotengine.org/asset-library/asset/2126 (CC0).
- **Downloaded 2026-11-03** from KayKit's GitHub organisation (the files
  the Godot Asset Library links to):
  https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0/archive/b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07.zip
  - Archive SHA-256: `e96a65ce4040b6b630f04470a60fd523d621c124cfbad062809cf7b94ccf714b` (6,357,418 bytes).
  - It contained models and textures only, no code.

## What's here, and what changed

Ten of the pack's 200 models, copied unchanged from `Assets/gltf/`. Only
the file names lose their `.gltf` infix (`barrel_large.gltf.glb` becomes
`barrel_large.glb`).

| File | SHA-256 |
|---|---|
| barrel_large.glb | 9fae6a79056241baf253fe9272dc7a7ddb174e1caf153eb5013c58a596722148 |
| barrel_small.glb | f46d0c421e46080aff079286ce9459a22da25e1b4f3489a04243f17617175212 |
| barrel_small_stack.glb | c23dc73a11c5a57ed33cb8a9df99f2b2793517341c5d62c6e50b0150652e8e99 |
| bottle_A_brown.glb | 14180809d494fdd48fd3771e02c36a076e8e729b5efb3bea18e1e157d1c11874 |
| bottle_B_green.glb | dd509e40346972ca15dd77c89ebf50f582346acf7587f2a40bae48c6704ca8af |
| box_large.glb | 6dacda267f04769f8ebbb7e991885785054923ea3d5eb19e833768a911d5b661 |
| box_small.glb | 3052015d7cd670c170742317fd9c728e5643221450857abbae9eefe6dbc66092 |
| crates_stacked.glb | 43182b077ead9b033804300ef453b7402bdc979f00cfce2d7f0c91dcf6bb5d3c |
| keg.glb | cc620e27439ab8dbbf93b1c4bd94d1d634798757c0314b2c9f12bb445afd0f51 |
| rubble_half.glb | 7514ccbda643c13d5a782579e4f01ee6402eec5519590d3f048d396cdaedec24 |

- **`texture-floor1.png`:** made by us. It's the pack's shared
  `dungeon_texture.png` (1024 square), shrunk to 256 square, muted, and
  snapped to 32 colours sampled from the live floor 1 art (cave-v1 walls,
  floor and dressing). `palette-floor1.png` shows those 32 colours.
  `grain-floor1.png` is made by us from floor 1's own wall texture (its
  light and dark only), laid over the pieces as a grit layer.
  Rebuild with `python tools/art/build_kaykit_pilot.py <dungeon_texture.png>`.
- **In the game:** each model's own embedded texture is discarded on
  import, and every piece uses the recoloured texture instead
  (`scripts/kaykit_pilot.gd`). Pieces are scaled to 0.45 (rubble to 0.3).
  The model files themselves are unedited.
