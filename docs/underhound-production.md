# First deeper horror: the Underhound

**Checkpoint 1 delivered, 2026-10-25:** [idle candidate and native/phone review](underhound-idle.md).
Owner accepted the idle (“This will work”). Matching attack/hurt are now authored
and checked in the [three-pose review](underhound-poses.md); owner acceptance of
the new poses remains open. The accepted idle stays their identity/scale reference.

2026-10-25 · Selection made by Codex at the owner's request, refs #150.

The Underhound is the first of the deeper-horror concepts selected for
production. It bridges the existing breach hound and the later impossible
bodies: a recognizable, low, long-headed predator with two opposing rib
structures and a tooth plate that slides independently of its outer muzzle.
The [concept sheet](../art/concepts/descent-horror-v1/underhound.png) establishes
the identity; it is not a finished sprite sheet.

It is a useful first production test because one body can communicate its
wrongness in three clear poses. Borrowed Pack requires several joined bodies
and unresolved targeting; Unfolding needs a staged spatial reveal; the Bell and
Sleeper still need review of their revised silhouettes. Start with a creature
whose anatomy can read at ordinary combat size, then apply what works to those
more demanding designs.

## Art brief

- **Identity anchors:** long blind wedge of a head, low four-legged stance,
  high ribbed shoulder arch. The lower/inner ribs face against the outer cage.
  Preserve a simple tail and broad clawed feet. No crown, armour or ornament.
- **Dominant impossibility:** on the attack, the internal tooth plate moves
  forward while the outer muzzle stays almost closed; the opposed ribs pull
  in different directions. Three or four broad rib masses must carry this at
  small size. Avoid individual teeth/veins competing with the silhouette.
- **Idle:** predatory crouch, jaw seam mostly shut, rib arch clearly visible.
- **Attack:** planted hind contact, shoulders forward, inner jaw displaced;
  expose the opposing ribs through the stretched hide in one readable gesture.
- **Hurt:** weight recoils sideways, foreleg folds, inner plate retracts; keep
  the same limbs, anatomy, shared scale and contact origin. No new appendages.
- **Runtime budget:** three 128×128 RGBA drawings, at most 32 visible RGB
  colours shared across poses, hard alpha, nearest sampling. Common pivot
  `(64,120)`, lowest planted contact at y=120, one scale for all poses. Start
  around the existing breach hound's 0.8 m body height; fit the complete pose
  envelope before export. This is not a larger-canvas exception.
- **Surface/light:** grouped ash-brown hide, dull ivory ribs and teeth, broad
  cool shadows with the existing warm upper-left cue. No painted floor shadow,
  background, fog, gore spray, glow, gradients or fine illustrative grain.

## Production gates

1. Establish the native128 idle against cave-dark and light backgrounds. At
   64px, the head, rib arch and four-legged weight should still read.
2. Use that same drawing as the reference for attack/hurt. Check a paused
   three-pose comparison for body drift, detached ribs and changing limbs.
3. Export with one shared palette/scale/pivot; preserve source masters and exact
   prompts, then review in the real first-person view with enemy tags and HUD
   at desktop and landscape phone sizes. Keep existing pose-aware tag bounds.
4. Accept the complete family before adding reveal frames, sounds or omens.

This selects a production subject and its scope. No new EnemyType, stats,
tactic, encounter table, floor or story role is assigned here; the existing
breach hound remains unchanged. The Underhound is not automatically placed in
the Fungal Caverns merely because that environment is being completed alongside
this decision. The new three-pose family now awaits owner review. The other nine
concepts retain their existing review status.
