# Elves and dark sound library

Delivered 2026-10-22 for #131, #96 and #99; sound work also contributes to #54.

[Elf inspector](../art/concepts/elves-v1/inspector.html) ·
[Listening gallery](../art/concepts/sound-v1/inspector.html) ·
[59.33-second sound reel](../art/concepts/sound-v1/audition.wav) ·
[Sound credits](../audio/dark-v1/CREDITS.md)

## Elf artwork

Two ordinary elf portraits complete the pair requested after the dark elves:
fair skin, blonde hair, green eyes, long swept ears, pronounced upswept brows,
silver layered mithril, green cloak and gold circlet. The man's narrow chin and
the woman's fuller lips/lashes retain the [concept brief](elves-concept.md).
Edric supplies the established painted treatment; dark elves supply framing
and the separate-rig contract. Neither reference's facial features are reused.

| Asset | Entry point |
|---|---|
| Portrait catalogue | `art/portraits/elves-v1/catalog.json` |
| Unique male PortraitSet | `data/portraits/elves-v1/elf-man.tres` |
| Unique female PortraitSet | `data/portraits/elves-v1/elf-woman.tres` |
| Swordswoman combat scene | `art/enemies/elves-v1/swordswoman/scene.tscn` |
| Combat registration | `art/enemies/elves-v1/swordswoman/registration.json` |
| Original masters, exact prompts and reference roles | `art/source/elves-v1/generation.json` |

Each portrait has its own face/family ID. It stays separate from the reusable
human/recruit catalogue and the dark elf catalogue. No hero, NPC name, class,
dialogue, recruit eligibility, hostility, enemy numbers or encounter is assigned.
Claude can bind these ready resources when the story needs them.

Every layer is an untrimmed 192×192 canvas. Clean character plus neutral eyes
and neutral mouth reconstruct the resting composition byte-for-byte. Half and
closed lids replace the complete eye footprint; the closed frame contains no
iris. Three talk shapes replace the complete lip footprint; the round mouth
starts from the clean plate and removes the old corners. These use the existing
#124 native drawing methods, with their exact helper hashes retained. Earlier
dark elf/human artwork and exporters remain intact. There are no new condition
overlays. Shadow and highlight are separate authored masks; these are a practical
lighting contribution, not a physical relighting model or a new fuel controller.

The swordswoman has idle, attack and hurt poses with one gently curved sabre.
All three use a common 112px reduced square inside a 128×128 export, one shared
≤32-colour palette, binary transparency and floor pivot **(64,120)**. Vertical
registration plants the boots without independently scaling body parts. The
scene proposes 1.95m presentation height, shaded nearest filtering and a
Y-billboard; it adds no collision, light or behaviour. No blade or body part
touches the crop boundary.

Five built-in ImageGen outputs are kept byte-for-byte, with exact prompts,
source hashes and original output locations. Native masks, contours, clean
plates and iris/opening drawings are retained for repair. `build_elves.py`
rebuilds the exports; `build_elves_sound_review.py` rebuilds both review pages.
The portrait/runtime library occupies about **3.281 MiB RGBA** before engine
overhead, including fallback compositions.

## Sound library

`audio/dark-v1/catalog.json` lists **30 mono 44.1kHz PCM16 WAV assets**, with
input archive members, processing lineage, output hashes, durations and levels.
The set combines verified CC0 recordings with original sound-design layers.
These are edited game effects, not new recording sessions or AI audio output.
Wet web/venom layers include synthesis; the drum body is built from muffled
material impacts. The queen uses transformed balloon-friction audio, with no
actor voice cloning. Source pages, downloads, licences and hashes are preserved
in `art/source/audio-dark-v1`; [CREDITS.md](../audio/dark-v1/CREDITS.md) links
every primary source and explains the original Vorbis/MP3-derived provenance.

| Group | Delivered assets |
|---|---|
| Combat | 3 dense hits, wood/metal blocks, 2 misses, web spit, venom |
| Items | 2 coin contacts, purchase, timed coin flip, heavy chest, torch ignition/burnout |
| Feedback | Stumble, hollow-floor fall, soft UI click, short recorded heartbeat |
| Fortress | Gate break, queen screech, muffled drum hit, distant drum loop, outskirts mix |
| Camp/light | Fire, wind, distant murmur, combined camp bed, held-torch crackle loop |

The aim is dense, damped material contact with subdued metal and quieter UI.
All one-shots have faded zero endpoints, no loop flag and ≥6dB peak headroom.
Loops have joined endpoints and explicit native forward-loop imports. The
camp murmur is lowered/filtered and very quiet in the combined bed; intelligible
dialogue is not intended. Actual device listening remains necessary before
calling the mix owner-approved. The complete decoded library is approximately
**13.317 MiB PCM**, excluding overhead; only referenced streams load at runtime.

`tools/audio/fetch_dark_foley_sources.py` preserves the exact downloads and
licence evidence. `build_dark_sound_library.py` deterministically rebuilds
offline with NumPy/soundfile; dependencies may live in ignored `build/audio-deps`.
No source download, original audition or placeholder is overwritten. Source
archives stay in `art/source`, which the existing Windows export excludes.

## Live sound connections

`Sounds.play()` retains existing call sites and now uses the finished library.
Hits, misses and coins vary through a private presentation RNG, so sound cannot
advance game/event dice. Finished one-shot players free themselves. Explicit
loops belong to their screen and stop when it closes.

- Combat adds misses, web/venom feedback, drummer beats and the queen's screech;
  existing hit/block calls pick up the new recordings. Metal block is also ready
  as an explicit key; existing generic block behaviour is preserved.
- Camp starts/stops its combined fire/wind/murmur bed with visibility. Successful
  purchases/sales get cues, and camp/event buttons have a quiet click.
- Existing chest, gold, heartbeat and torch-light hooks use the new streams.
  Torch burnout and stumble/fall feedback are connected.
- The coin uses a single flick and contact exactly **2.368s** later, matching the
  existing nine-spin tween. The sound supplies no outcome hint; odds/timing are
  unchanged.
- Floor 3 receives the distant-drums/cave mix until the queen is defeated.
  Gate breaking has its own timber/iron cue. Cave ambience stops at camp and
  restarts on re-entry even when the theme has not changed. Streams explicitly
  stop before swapping, and the native check allows mixer release before freeing.

One-shots, heartbeat and camp ambience follow **Effects** settings. The existing
Main ambient player stays on **Music**, along with current music behaviour.
Separate camp stems and the held-torch loop are ready but not stacked onto the
live combined bed. Current music, softened footsteps, movement timing, combat
rules, stats and save format are unchanged. #54 remains open for the broader
movement/door/ambience recordings and music work; #96 remains open for later
merchant progression if the story ever needs it.

## Verification and review limits

- **189** elf source/export/import/preservation checks: exact resting
  reconstruction, complete replacement masks, closed iris removal, shared combat
  scale/palette/pivot and preserved existing artwork.
- **49** actual Godot portrait/playback/lighting/combat checks and nine captures
  at native192, card96, desktop and phone landscape sizes.
- **340** sound source/licence/PCM/level/timing/import/preservation checks,
  including deterministic offline rebuild of all sounds and the reel.
- **169** native Godot audio checks: decoding, loop flags, Effects routing,
  playback/freeing, independent RNG, real CampScreen visibility, detached Main
  ambience selection/re-entry and actual CoinFlip stream binding.
- **62** elf and **82** listening-gallery browser checks: every eye/mouth
  combination, clean plates, pause/step/play, poses, all30 actual WAV playbacks,
  stop/repeat/reel/filter controls and layouts down to 390px.

Reports and captures are alongside each inspector. The asset fixtures never
enter Main's scene lifecycle or touch saves; browser audio tests are muted.
Godot 4.7.2 final asset import/render/audio logs are clean. The existing full
coin and fortress playthroughs also pass **11/25 checks**, using disposable
project-local saves and muted audio. Both legacy playthrough harnesses report
one CanvasItem RID and two ObjectDB instances at shutdown; the focused asset
fixtures report none. These warnings are recorded rather than treated as a
clean legacy shutdown. Actual iPhone performance and listening, owner visual/mix
review and eventual elf story assignment remain.
