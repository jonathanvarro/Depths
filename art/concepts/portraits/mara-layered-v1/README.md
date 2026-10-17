# Mara — layered wardrobe prototype

Canvas: 192 × 192. Open `mara-layered-192.ora` in an OpenRaster-compatible editor such as Krita or GIMP. Toggle **Outfit - brown tunic** to compare the plain underlayer with the tunic. Individual full-canvas transparent PNG layers are also supplied for other editors and eventual game use. `preview.png` is the combined result.

## Actual layers, bottom to top

1. `background.png` — solid dark background.
2. `base.png` — transparent character cutout; body, face, hair, and plain underlayer are combined.
3. `tunic.png` — independently toggleable brown tunic.
4. `eyes-neutral.png` — neutral eye/brow replacement patch including nearby skin.
5. `mouth-neutral.png` — neutral mouth replacement patch including nearby skin.

Every layer is 192 × 192 with origin (0,0); never trim individual layers or resize them separately. The neutral facial patches reproduce the base features and do not animate yet. Replacement expression patches need to cover the old features completely.

## Important limits

This is a working wardrobe test, not a fully separated production master. Back/front hair, bare head/body, and original underlayer still need separation and hidden-area reconstruction. The tunic hides the existing underlayer; it does not replace a separately removable clothing layer. Hair-over-collar and hood layering need that further preparation. A generated edit slightly changed the base rendering; retain the earlier v2 image as the identity reference. Alpha edges and pixel clusters need manual cleanup before final use. No blinking or speech frames are claimed or included.

## Generation and export

Used the built-in image-generation tool with `mara-base-192-v2.png` as the reference for both edits. Prompt set:

- Base: remove only the near-black background to real alpha; preserve Mara's identity, entire pose and framing, slight turn to image right, brown hair, plain sleeveless underlayer, upper-left lighting, and gritty crisp pixel style. No additions, cropping, labels, or painted checkerboard.
- Outfit: isolate only a worn muted-brown medieval short-sleeved tunic, full square canvas aligned to the reference shoulders, low rounded neckline, upper portion empty and transparent. Match perspective, upper-left lighting, and gritty pixel style. No human parts, hair, mannequin, hood, equipment, or background.

Generated images were reduced with nearest-neighbor sampling to 192 × 192. The build script exports neutral facial selection patches and packages the PNGs as OpenRaster; it is a local provenance helper and references the original generated-image paths. The ORA and supplied PNGs are self-contained and do not need the script or those source paths to open.

## Next art pass

The owner subsequently required [separate character and lighting layers](../../../../docs/portrait-lighting.md). This prototype has warm highlights/shadows baked into its character, garment and facial patches. A future source-art pass must reauthor neutral layers plus registered lighting masks, including the animated expression set now in `art/portraits/mara-animation-v1`; adding an overlay alone does not remove the baked illumination. These originals are preserved.

Separate back hair, face/neck/body, front hair, and underlayer; reconstruct covered pixels. Then author one blink and a small mouth-open replacement by editing pixels on this registered master, checking that the face does not drift between frames. Test a high collar before attempting a hood.
