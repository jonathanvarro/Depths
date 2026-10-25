# Authored combat fog · #129

2026-10-25. A dark, low bank of mist replaces the generated battle-stage fog.
It rises over 0.6 seconds, settles around the enemies' feet, and recedes over
0.5 seconds when combat ends. Ten held surge states come from the authored
bank's alpha silhouette. The backdrop drifts at eight visual updates per second;
two weighted offset samples make the horizontal wrap continuous.

The near-black stage stays behind enemies and below the HUD. Its quad now fits
the full viewport and follows viewport resizing, avoiding cropped fog or exposed
side strips. Existing combat timing, positioning and enemy depth priority remain.
With screen flashes disabled, the stage uses a plain fade and a static bank.
Hidden stages stop processing. This effect never affects carried light, nerves,
turns, enemy behaviour or any other game rule.

- [Phone combat](../art/concepts/combat-fog-v1/combat-1278.png)
- [Desktop mid-transition](../art/concepts/combat-fog-v1/surge-1280-6.png)
- [Still mode](../art/concepts/combat-fog-v1/still-1278.png)
- [Runtime sizes and timing](../art/effects/combat-fog-v1/catalog.json)
- [Exact built-in ImageGen prompt and original source](../art/source/combat-fog-v1/generation.json)

The original transparent generated PNG is retained unaltered. Godot's deterministic
exporter reduces it to a 640×214 bank with a restrained colour ramp and stepped
alpha, then derives a 4×3 matte atlas containing ten 320×180 states. The two game
textures use about 3.16 MiB of RGBA memory before engine overhead, one quad and
one material. Source/review folders have `.gdignore`; runtime textures import
losslessly and use explicit nearest sampling in the shader. No particles.

Rebuild: run `tools/art/export_combat_fog.gd` with Godot 4.7.2, import the project,
then run `tools/art/check_combat_fog.gd` in the real renderer. The isolated fixture
loads actual combat controls, portraits and enemies without Main or save files.
Its report and twelve captures cover entry, exit, settled/still presentation and
desktop/landscape-phone framing. Physical iPhone performance remains unmeasured.
