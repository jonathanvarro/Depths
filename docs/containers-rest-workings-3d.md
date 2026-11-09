# Containers, rest sites and old workings · #242

Owner-selected batches built in order on 2026-11-08. New production scenes
are in art/props/expedition-3d-v1. The local review is
E:/GitHub/Depths/build/local-expedition-props-v1/inspector.html.
START_REVIEW.cmd opens the native review with state selection and lid motion.
Editable Blender masters retain separate pieces in the local masters folder.

## Scenes

| Scene | Fresh / closed triangles | Open triangles | Empty / used triangles |
|---|---|---|---|
| chest.tscn | 728 | 996 | 728 |
| strongbox.tscn | 520 | 788 | 628 |
| abandoned-pack.tscn | 356 | — | 380 |
| dry-alcove.tscn | 472 | — | 472 |
| cold-camp.tscn | 900 | — | 960 |
| old-workings.tscn | 704 | — | 636 |
| rails.tscn | 604 | — | — |
| rails-broken.tscn | 564 | — | — |

The wooden chest is approximately 95 cm wide, 80 cm deep and 72 cm high
when closed. It retains the CC0 source’s arched lid and original hinge.
The separate strongbox is approximately 64 × 48 × 36 cm, with a flat,
dented lid, riveted iron straps and a broken lock visible after emptying.
Both use the same 102-degree opening angle. Their decorative cloth bundle
and coins are visible in the open state. Actual drops remain authoritative
in the game. The art does not enumerate inventory contents.

The patched canvas pack has worn leather straps and a tied blanket. Its
searched state folds the flap behind the mouth, removes the blanket and
leaves a loose strap. The body retains its shared floor registration.

The dry alcove has a roughly 66 cm wide, 147 cm long bedroll, rolled blanket
end and old ash. Resting leaves a flatter, more rumpled covering. The cold
campsite adds an extinguished fire ring, charred sticks, a cup and a small
bag. Its used state spreads the ash and disturbs the bedding. Both are cold
scenery without flame, emission or world light.

Old workings combine short pit props, a rock outcrop, ore trough, old pick
and loose rubble. The picked-clean state removes the ore and leaves scrape
marks. It occupies approximately 1.2 × 0.85 m. Place it as an event prop or
against an actual wall, with clearance chosen by the caller.

Rails are two-metre sections along local Z. They have split sleepers,
square spikes, rusted feet and worn iron heads. The broken sibling shares
registration and includes a missing sleeper section and a bent raised end.
It is a separate decor variant. It does not create a movement hazard.

## State and motion API

Every scene uses prop.gd and a floor origin. Front faces local +Z.

```gdscript
chest.state = "open"                 # lid open, decorative contents visible
chest.set_state(&"empty")            # lid open, contents hidden
pack.set_searched(true)              # equivalent to state = "empty"
prop.set_motion(false)               # finish the current lid transition immediately
prop.animate_motion = false          # fixed presentation
```

Containers support closed/open/empty. Packs, rest spots and workings use
closed/empty. Rails are static. Before _ready, state assignment restores the
final pose immediately. At runtime, enabled lid transitions take 0.32 seconds.
Repeated state assignments are idempotent. A new target cancels the previous
tween and starts from the current angle. Disabling motion finishes the latest
state immediately. The lid keeps its hinge while the prop’s root stays fixed.

The twenty-four-colour palette extends the preceding mine props’ palette
without changing its original colour indices. Opaque geometry uses one
surface per component and the same world-space cave grain. The generated
palette is 256 × 128. No collision, lights, interaction handlers, rewards or
saved flags are added by these scenes.

## Source and integration handoff

Kay Lousberg’s CC0 Dungeon Remastered 1.0 supplies the wooden chest, separate
lid and floor bed. Three preserved originals, including the licence, match
their pinned official Git blobs under art/third-party/kaykit-containers-rest-v1.
CREDITS.md records recolouring, mild warping, rescaling and hinge preservation.
The strongbox, pack, blankets, fire remains, workings, rails and small contents
are authored geometry using the established mine prop mesh helpers.

Live event and dressing bindings still use the earlier library. For hookup,
use the existing container closed/open/empty states, pack searched state and
Main’s empty-prop handling. Replace the relevant builder references together
with event scene references so regeneration preserves the new bindings.
Reset any sprite-specific scale/billboard assumptions and use metre units.
Pass the effects preference through set_motion. Loot, resting, trap outcomes,
pathfinding, event persistence and inventory rules stay controller-owned.

## Rebuild and validation

1. Run tools/mine_props/intake.py --source art/third-party/kaykit-containers-rest-v1.
2. Run tools/containers_3d/build_models.py in Blender with --background
   --factory-startup --disable-autoexec --python-exit-code 1, followed by
   -- --workspace E:/GitHub/Depths.
3. Run prepare_review.py --workspace E:/GitHub/Depths with Python/Pillow.
4. Import the isolated project with Godot 4.7.2 and run check.gd using the
   Mobile renderer. Local Blender masters are excluded from import.
5. Run package_review.py --workspace E:/GitHub/Depths and check_gallery.cjs
   with the workspace argument.

The native review checks all sixteen GLBs’ bounds, UVs and triangle counts,
state registration, decorative contents, interrupted lid motion, immediate
still mode and phone-safe controls. Its 102 captures include both light
settings, three angles, every supported art state, three phone/desktop screens
and one comparison per batch. These are native Windows renders at phone
dimensions. Physical iPhone performance and owner visual acceptance remain
review steps.

The 2026-11-08 review passed 574 native checks with clean runtime logs,
verification of three originals and sixteen derived GLBs, and 24 browser
checks. Rebuilding the preceding mine prop set after exposing its mesh helpers
reproduced its existing models and catalog unchanged.
