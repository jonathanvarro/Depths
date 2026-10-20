# Wall material review · #126

[Native/64px overview](wall-families.png) · [4×4 repeat](repeat-4x4.png) · [export validation](export-validation.json) · [Godot report](godot-validation.json)

Each family has `*-neutral.png`, `*-lantern.png` and `*-phone-lantern.png` actual Godot captures. All use the same `LevelBuilder` room, existing cave floor/ceiling and shared light settings; only the wall material changes. Phone images are 1278×590 desktop simulations. The live game/themes remain unchanged.

Native 128px/32-colour exports, exact sources/prompts and all material paths are described in [the handoff](../../../docs/descent-wall-library.md). Neutral repeated tiles establish surface identity; the Godot captures expose current box UV scale and do not imply matched new floor/ceiling artwork or a shipped new floor.
