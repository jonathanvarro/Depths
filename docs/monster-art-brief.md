# New monsters: art brief

Owner request, 2026-10-21. The late floors need more kinds of foe, and the breach needs its monsters.

- **The breach family:** the owner confirmed it is what came up through the breach after the gas.
- **Hollow miners:** the gassed shift, risen. The owner likes them.
- **Order:** the four priority monsters first, but the whole set is requested here.

Plan and behaviour: #140. Research and numbers: [stats, monsters and XP research](stats-monsters-xp-research.md) (#97).

## The contract (as `art/enemies/campaign-v1`)

- **Canvas:** 128 × 128 RGBA, transparent, untrimmed, with a bottom-centre pivot at (64,120). The Broodmother is a mini-boss and may use a larger canvas (suggested 160 or 192). That is a deliberate exception: say which.
- **Style:** at most 32 colours per monster, shared across its poses. Three shades per material, warm light from the upper left, and large crisp pixel clusters. No dithering, gradients, antialiasing, text or ground shadow. Follow [the enemy art direction](enemy-art-direction.md).
- **Scale:** one scale for the whole pose set. A raised limb must not shrink the body. Small creatures keep their small world size in the scene.
- **Files:** one folder per monster with each pose as a PNG, a `frames.tres` SpriteFrames and a `scene.tscn`, registered in `catalog.json` like the existing campaign enemies.
- **Poses:** each monster's poses are listed below. Every one needs at least **idle, attack and hurt**; the extra poses are what its fight behaviour shows on screen.

## Priority batch (do these first)

| Monster | Floors | Look | Poses |
|---|---|---|---|
| **Cave bat** | 1–2 | Leathery, ragged wings, pale ears; small. | idle (hanging, wings wrapped) · **swoop** (wings wide, diving; reads as "in the air") · **landed** (on the ground, wings sprawled, exposed) · hurt |
| **Goblin brute** | 3–4 | A head taller and twice as broad as a goblin, crude iron maul, scraps of the same goblin kit and palette. | idle · **wind-up** (maul raised high, obvious) · attack (the blow) · **recover** (slumped, maul dragging, open) · hurt |
| **Gas-bloat** (breach) | 3+ | A drifting, veined sac of trapped gas, sickly yellow-green, trailing thin tendrils. It floats: no feet on the contact line, but keep the same pivot. | idle (drifting) · **swell** (bloated, straining: about to burst) · attack (a puff) · hurt · **burst** (it tears open; 2–3 frames if possible) |
| **Hollow miner** (breach) | 3+ | One of the town's gassed shift, risen: grey skin, sunken eyes, miner's leather cap with a dead lamp, a pick in hand. Tragic and unsettling more than gory. | idle (slack, swaying) · **grab** (reaching, both hands) · attack (pick swing) · hurt |

## The rest of the set

| Monster | Floors | Look | Poses |
|---|---|---|---|
| **Rock beetle** | 2 | A heavy, plated beetle the colour of the mine's rock. | idle · **curled** (a stone-like ball, clearly protected) · attack (unfolded bite) · hurt |
| **Venom spider** | 2–3 | The cave spider's shape with a warning colour (sickly green-black, bright fangs), so it reads as the more dangerous kin. | idle · attack · hurt |
| **Broodmother** (mini-boss) | optional 2–3 | A bloated, scarred matriarch spider with an egg-sac. Larger canvas. | idle · **call** (raised, sac pulsing) · attack · hurt · **enraged** (hurt and aggressive, below half health) |
| **Goblin trapper** | 2–3 | Lean goblin, coils of cord and a bag of hooks, a small throwing knife. | idle · **set snare** (crouched, laying cord) · attack (throw) · hurt |
| **Gate captain** (mini-boss) | optional 3–4 | A goblin officer in mismatched scavenged plate, a horn on a cord, a heavy cleaver. | idle · **rally** (horn raised) · wind-up · attack · hurt |
| **Lamp-eater** (breach) | 3+ | A pale moth-thing as big as a dog, dusty wings, a proboscis drawn to light. | idle (fluttering) · **drain** (proboscis on the light, wings mantled) · hurt |
| **Breach hound** (breach) | 3+ | Lean, hairless, too many teeth. Hunts in pairs, so make it readable when two stand side by side. | idle (low, stalking) · attack (lunge) · hurt |

## Effects and icons

These follow the existing `combat_fx` and `backlog96` styles.

| Need | Detail |
|---|---|
| **Gas cloud** | A 3–4 frame burst that drifts over the party when a gas-bloat bursts. Also a lingering haze frame. |
| **Intent icons** (backlog96 intent set, 32px) | swoop, curl, wind-up (if not covered by the existing heavy-blow icon), swell/burst, grab, drain light, set snare, rally, call brood |
| **Card status icons** (backlog96 status set) | grabbed (can't act), snared (slowed), gassed |
| **Light drained** | a small icon that pops from the lantern when a lamp-eater drinks |

## Not needed (Claude handles these in code)

- **Elite foes** (a "Hardened goblin" and so on): an outline or rim and a coloured nameplate in code. No new sprites.
- **Hatchlings:** the Broodmother's hatchlings reuse the small-spider art.
- **The hollow miner's dropped pick:** uses the pick icon from #138.
- **Behaviour, numbers, intro lines and encounter tables.**
