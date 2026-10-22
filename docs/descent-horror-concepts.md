# Descent into the grotesque — concept drafts

2026-10-22 · #150, #151, #152 · Built-in ImageGen concept exploration.

[Review gallery](../art/concepts/descent-horror-v1/inspector.html) ·
[Ten-concept comparison](../art/concepts/descent-horror-v1/comparison.png) ·
[Exact prompts, references and source hashes](../art/source/descent-horror-v1/generation.json) ·
[Art direction](enemy-art-direction.md)

Ten draft concept sheets follow the owner's direction: dark and gritty
throughout, increasingly grotesque and disconnected from reality toward the
final objective. The existing breach hound supplies the first family anchors.
The Underhound then supplies the painting/material/layout reference, while
later bodies become less recognizable. Warm foreground light and cold rock
shadows connect the sheets; the Sleeper shifts to a colder distant presence.

Each sheet includes a main painting, an alternate/revealing view, an omen or
context inset and a small painted shape-study strip. The gallery can magnify
each region, filter the three batches and compare all ten. Its viewport crops
are review aids; full original sheets are always one click away.

## Drafts and review focus

| Request | Draft | What the sheet explores | What still needs judgement |
|---|---|---|---|
| #150 | [Underhound](../art/concepts/descent-horror-v1/underhound.png) | Opposing rib structures and a sliding inner tooth plate on a familiar predator | How strongly ribs should press through/show beneath the hide; the body should stay recognizable |
| #150 | [Borrowed Pack](../art/concepts/descent-horror-v1/borrowed-pack.png) | Three bodies under one hide; a head retreats into the common skin | Simplification of overlapping legs and flesh bridges at production size |
| #150 | [Marrow Shepherd](../art/concepts/descent-horror-v1/marrow-shepherd.png) | A narrow tending body, branching bone cradles and a forming animal in an abdominal pod | Nursery gesture and the amount of bodily exposure; no life-cycle lore is fixed |
| #151 | [Drowned Bell](../art/concepts/descent-horror-v1/drowned-bell.png) | Hanging organic bell, inner clapper-like organs and contraction/expansion | Droplet direction and deep/delayed sound require later motion/audio |
| #151 | [Unfolding](../art/concepts/descent-horror-v1/unfolding.png) | A tightly curled animal and an extended form whose length could not fit there | Reveal staging and a presentation that preserves its impossible length |
| #151 | [Choir of One](../art/concepts/descent-horror-v1/choir-of-one.png) | Closed black blade becomes an organic rib-like fan; repeated passage shapes imply resonance | Multiple voice distances and repeated footsteps remain sound directions |
| #151 | [Weight](../art/concepts/descent-horror-v1/weight.png) | An ivory teardrop, precise lower seams, deep interior and suspended material | How bodily the form feels; orbit/uphill movement are implied by a still |
| #152 | [Open Door](../art/concepts/descent-horror-v1/open-door.png) | An organic frame contains an incompatible view of the same mine chamber; false reflection omen | Fixed interior view while the frame turns needs a prototype; it is not an assumed usable exit |
| #152 | [Hollow Interval](../art/concepts/descent-horror-v1/hollow-interval.png) | The hound becomes flat absence against a visible room; grit outlines an empty jaw | It can read as a black shadow in a still. The foreground post stays visible; room/dust interruption needs a later proof |
| #152 | [Sleeper Beyond](../art/concepts/descent-horror-v1/sleeper-beyond.png) | Tiny party/mining cues, vertical dark water and one enormous curled finger | Architecture-first recognition needs occlusion and reveal pacing; full body/identity remain unknown |

The first [Sleeper candidate](../art/concepts/descent-horror-v1/sleeper-beyond-first.png)
read as a worm-like talon. One targeted built-in edit replaced that shape with
a blunt finger and broad nail across its views. Both originals and exact prompts
are retained. The current sheet is a clearer finger proposal; neither version
is an owner selection or a confirmed final encounter.

## Selection ledger

**All ten owner selections are pending.** Working names remain working names.
Review the family relationship, escalating wrongness, physical materials and
main silhouettes before choosing a production direction. Then decide which
beings need a fight, a room event, a distant encounter or only an omen. The
Sleeper's complete body, relation to the relic and final story role remain open.

The request checkboxes for owner selection stay open. No production follow-up
should treat delivery of these drafts as approval of every proposed creature.

## Possible later presentation

These are implementation options for review, not work performed in this batch:

- **Wrong animals:** a few deliberate body/jaw/pod states at one common scale.
  The Pack may be one grouped organism; its targeting/body count is unresolved.
- **Impossible bodies:** a small state set with independently placed droplets,
  ripples, hanging material or orbiting objects. The Unfolding needs a staged
  ledge reveal; it should not shrink merely to fit an attack pose into a square.
- **Open Door:** a separately held interior image with changing outer frame.
- **Hollow Interval:** a room/background mask with sparse edge particles; first
  prove that it reads as absence rather than a flat black animal.
- **Sleeper:** an environmental backdrop and separate water layer with one
  restrained joint change. A complete model or combat sprite set is unnecessary
  for judging this reveal.

Current runtime resolution, palette, alpha, pivot and animation budgets remain
the production baseline. Detailed concept painting does not establish a larger
runtime budget. No enemy definitions, combat rules, stats, encounters, shaders,
sound, animation rigs, floors or lore were added. Existing delivered assets and
Claude's story work remain intact.

## Files and checks

- `art/concepts/descent-horror-v1/`: ten current sheets plus the first Sleeper
  candidate, catalogue, offline gallery, responsive captures and reports.
- `art/source/descent-horror-v1/`: eleven unaltered generated masters, exact
  prompts, reference roles/hashes and original built-in output locations.
- `tools/art/record_horror_concepts.py`: byte-for-byte copies and manifest.
- `tools/art/build_horror_concept_review.py`: catalogue and review page.
- `tools/art/validate_horror_concepts.py`: source/copy/reference integrity,
  dimensions, complete request coverage and review-region checks.
- `tools/art/check_horror_concept_review.cjs`: real browser image decoding,
  all five views of every sheet, batch navigation and responsive layout.

All source sheets are **1536×1024**, with scenery. Both source and review folders
have `.gdignore`; nothing is imported as game art. Source integrity and coverage
pass **118 checks**, including exact copies and reference hashes. The browser check passes
**76 checks** at desktop, 844px landscape and 390px widths. Captures are review
pages, not Godot or physical-phone views. Shape studies are drawn proposals;
they are not final native128 silhouettes, aligned animation frames or proof of
performance. No live-game test is needed for this concept-only delivery.
