# Six wall masters · #126

Six separate opaque images generated with built-in ImageGen, one per wall family. Originals are retained byte-for-byte as `*-master.png`. [generation.json](generation.json) contains each exact prompt, generated source path and SHA256 hash. These source images are excluded from Godot import/export.

Runtime 128px textures and Godot materials are in [descent-walls-v1](../../textures/descent-walls-v1/README.md). The deterministic export performs BOX downsampling, a small wrapping edge-apron correction and 32-colour quantization without dithering. It never overwrites these masters or any prior material library. [Art direction, previews and limitations](../../../docs/descent-wall-library.md).
