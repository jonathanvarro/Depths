# Enemy art direction

The owner likes the cave environments and creature designs, but wants enemies less detailed than the first generated set: consistent future renders and lower production requirements. This establishes that direction. The numeric limits below are a **proposed working standard**, demonstrated by one goblin study, for review before rebuilding the library (#32).

## Descent into the grotesque — owner direction, 2026-10-22

The art stays **dark and gritty throughout**. As the party approaches the final
floor and objective, monsters become **increasingly grotesque and disconnected
from reality**. Familiar bodies gradually stop obeying anatomy, volume,
perspective and scale. Grotesque physicality continues into the most abstract
designs: stretched skin, compressed flesh, exposed internal structures or an
uncomfortable suggestion of something living inside apparently inert forms.
Increasing abstraction should retain that disturbing, material presence.

The existing breach hounds are the visual bridge. Their low predatory stance,
stretched jaw and rib shapes can echo through later designs, so the player
recognizes something familiar becoming harder to comprehend. Different families
can follow different paths; every animal and goblin need not transform.

The following are relative stages of the descent, not fixed floor assignments:

| Stage | Visual progression | Useful examples from the requested concepts |
| --- | --- | --- |
| Upper mine | Recognizable, worn, hungry animals and physically plausible foes establish the ordinary world | Existing rats, bats and goblins |
| Beyond the breach | Recognizable animals with an unmistakable anatomical wrongness; flesh looks strained by the structure beneath | Underhound's opposed rib cages and sliding teeth; Borrowed Pack's continuous hide |
| Deeper layers | Bodies cannot contain their own anatomy; folds, cavities and connections violate expected volume or movement | Marrow Shepherd's forming creatures; Unfolding's compressed/extended forms; Weight's interior depth |
| Near the final objective | The outline, space or apparent environment becomes the creature; scale and presence become difficult to reconcile | Open Door's incompatible view; Hollow Interval's missing body; Sleeper Beyond's architectural shape revealed as part of a body |

These examples come from the open concept requests
[#150](https://github.com/jonathanvarro/Depths/issues/150),
[#151](https://github.com/jonathanvarro/Depths/issues/151) and
[#152](https://github.com/jonathanvarro/Depths/issues/152). Their working names
and designs remain proposals. This direction does not decide the relic's
identity, a common origin for the creatures, a final boss or the floor count.

### Making the progression visible in 2D

- **Lead with one dominant impossibility.** A second rib cage, one hide shared
  by several bodies, or an opening that contains too much depth gives the eye
  something specific to understand. Supporting details should reinforce it.
- **Use large contours and negative space.** Wrong joint placement, a strained
  flesh bridge, a cavity or an impossible fold must survive a small silhouette
  study. Surface grime and extra teeth alone cannot carry the progression.
- **Show the revealing state.** Pair a compressed body with its extended form,
  or an apparently ordinary jaw with the teeth displaced. Preserve identity
  anchors between states so the change reads as deliberate anatomy. A concept
  sheet needs only the alternate view that explains its defining wrongness.
- **Use context for absence and scale.** A creature-shaped hole needs the room
  behind it; an enormous body part needs small mining or human cues. A contextual
  composition or separate background/body layer can explain what a standalone
  transparent sprite cannot. Keep any production method a later proposal.
- **Keep the materials grounded.** Broad masses of dirty ivory, bruised flesh,
  wet stone and tarnished metal can share the mine's shadows. Use selective
  diseased colour and restrained lighting. Later creatures should still feel
  tangible even when their geometry is impossible.

Review the stages beside each other, first as silhouettes and then at phone
display size against a room. The progression should be visible without a name,
description or sound track. Sound, omens and limited motion can reinforce it.
Keep actionable poses, targeting and warnings clear as fictional anatomy gets
less comprehensible. The player's controls and HUD remain dependable.

Detailed paintings are allowed for #150–#152's **concept exploration**. Existing
runtime canvas, palette, transparency, pose-registration and small animation
budgets below continue to apply when selected concepts enter production.
Greater horror comes from the design and reveal; it does not require higher
texture resolution, dense surface detail, long animation cycles or escalating
gore. Exact graphic detail remains open. Existing delivered art is preserved;
any revisions should be chosen after concept review.

Prompt addition for the new concepts:

> Dark, gritty Depths creature concept at [relative descent stage]. Keep
> [recognizable family anchors], with [one dominant physical impossibility].
> Make the grotesque structure readable through silhouette, material weight
> and [one revealing state or environmental cue]. Show its relation to the
> more grounded and more abstract stages. Keep small-view readability and
> broad shadow masses; supporting detail must serve the central idea.

## Shared visual rules

**Production follow-up (#33):** the owner requested the remaining enemies in this direction after the goblin study. The complete [cave-simple-v1 set](../art/enemies/cave-simple-v1/README.md) now applies the 128px, shared 32-colour maximum and three-pose contract to rat, spider and goblin, and is connected through EnemyType.scene. Treat those as this family's working limits; exceptional future enemies can be reviewed separately.

Enemies belong with the simple, shadow-heavy environments. Keep the detailed expression work for party portraits. Convey menace through posture, silhouette and a few recognizable features. Avoid making every surface equally interesting.

| Element | Proposed production rule |
| --- | --- |
| Canvas | Ordinary enemies: 128 × 128 RGBA, transparent background, no trimming. Larger enemies need a deliberate exception, not an automatic resolution increase |
| Pixel treatment | Crisp clusters on the native grid; nearest filtering at display sizes. No antialiasing, dithering, gradients, noise or painterly texture |
| Colour | At most 32 visible RGB colours per enemy, shared across all its poses. Aim for 3 shades per material; the goblin study uses at most 24 colours |
| Lighting | One warm light from upper left; broad cool/dark shadow masses. No painted floor shadow, glow or background lighting baked around the silhouette |
| Shapes | Silhouette first; 2–3 identity anchors per creature. Large shapes remain readable against the cave at native size |
| Surface detail | One or two useful wear marks per major object. Group fur into masses, cloth into 2–3 folds, wood into a few planks. No individual hairs, weave, grain, pores or scattered scratches |
| Outline | Restrained dark contour where it separates forms. Avoid heavy uniform cartoon borders and cute proportions |
| Initial coverage | One idle, one attack and one hurt drawing. These are poses, not an invitation to generate long animation cycles |

Keep the same body proportions, equipment and palette between poses. Attack and hurt must read from the large body gesture rather than a changed facial expression alone. Avoid extra weapons, trophies or ornament when making variants; each new detail adds continuity work.

## Creature identity

| Creature | Preserve | Simplify |
| --- | --- | --- |
| Rat | Low body, pointed snout, round ears, long tail | Fur becomes 2–3 broad masses; a few whisker/eye marks only |
| Spider | Two body masses, eight leg silhouettes, low spread | Broad joint shapes; no hair rendering or decorative shell texture |
| Goblin | Pointed ears, lean crouch, crude knife and round buckler | Simple triangular face, ragged tunic with a few folds, broad shield planks |

These rules define visual identity, not stats, encounter composition or new enemy types.

## Canvas and pose registration

Use a bottom-centre pivot `(64,120)` on the 128px canvas, with eight pixels of bottom padding including the pivot row. Place the lowest planted foot/contact pixel at y=120; keep the visual centre around x=64. Let tails and weapons extend asymmetrically. The pivot is the scene origin, not a requirement for symmetrical anatomy.

Establish **one scale for the complete pose set** before export. Never fit each pose independently to its bounding box: a raised arm must not shrink the body. Keep the idle body height and planted-foot position consistent in attack/hurt, and leave enough space for the widest pose. An airborne pose may leave the contact line but retains the same origin. Small and large creatures use different world heights in their scene; filling a similar texture area does not make a rat goblin-sized.

The existing exploratory set is 256px with pivot `(128,240)`. The proposed coordinates halve that contract. Preserve its originals and scenes until a complete replacement set is reviewed. The single simpler goblin is a study, not a partial replacement of the runtime pose set.

## Reference and export process

1. Establish one idle drawing against this guide. Review native size against both cave-dark and light backgrounds. Check the silhouette and identity anchors before approving detail.
2. Use that accepted drawing as the identity/style reference for attack and hurt. Keep the shared canvas, lighting, scale and palette explicit in every prompt.
3. Inspect anatomy, equipment, alpha edges and pose readability. A generated request for a pixel size does not guarantee a native-grid deliverable.
4. Export to the exact canvas, align the common pivot, and map all poses to the same palette without dithering. Inspect again; quantization alone cannot repair an overly detailed drawing.
5. Verify dimensions, transparency, palette count and registration, then inspect in the first-person scene on desktop and landscape phone. Approve a complete three-pose family before expanding production.

Prompt template:

> Depths enemy sprite: [creature and 2–3 identity anchors], [idle/attack/hurt gesture]. Use the approved reference for identity, proportions, equipment, palette and pixel scale. Front-facing, full body, transparent square canvas, designed for 128 × 128 native pixels. Bottom-centre pivot (64,120), same scale across poses. Large crisp pixel clusters, broad shadows, warm upper-left light, three shades per material, at most 32 shared colours. Sparse deliberate wear only. No hair strands, pores, cloth weave, wood grain, noise, dithering, gradients, antialiasing, painterly detail, background, ground shadow, text or UI. Keep all limbs/equipment inside the canvas.

Generation still needs visual review and exact export checks; this template is guidance, not a guarantee of pixel alignment or palette compliance.

## Study and practical limits

[Same-size comparison](../art/enemies/style-study-v1/comparison.png): the detailed concept and simpler goblin are both shown on 128px canvases, enlarged with nearest filtering. The simpler redraw was made with the built-in image editor, then normalized, registered and limited to at most 24 visible colours. [Original and exact prompt](../art/source/enemy-style-v1/generation-manifest.json), [export checks](../art/enemies/style-study-v1/validation.json), [rebuild script](../tools/art/build_enemy_style_study.py). The detailed side is reduced solely for a fair comparison; it is not a new production asset. Review facial pixel placement and edge cleanup before treating the study as final.

128px contains one quarter as many pixels as 256px, so equivalent uncompressed RGBA texture data uses one quarter the space. Fewer texture marks and poses also reduce art cleanup and continuity work. Flat colours at the same resolution do not automatically reduce draw calls or GPU cost, and these are not measured iPhone performance results. Texture import settings, scene count and animation scope still matter. No promise of faster image generation is implied.

The nine more detailed [cave enemy poses](../art/enemies/cave-v1/preview.png) remain preserved as exploratory references. The [simplified family handoff](../art/enemies/cave-simple-v1/README.md) supersedes their combat paths; the [earlier expedition handoff](../art/expedition-v1/README.md) preserves the original pass's resource contract.
