# Field sound and deeper-cave music delivery · #217 / #167 / #54

2026-11-03. Listening hub: `art/concepts/field-audio-v1/inspector.html`.
The field pack is now live through the floor themes and gameplay hooks. The
November 11 regression rechecked passage, step and ambience assets, creature
reactions, prayer cues, traps, Pack actions and the Effects bus. Listening and
mix judgement remain open under #217 and #54.

## Delivered files

`audio/field-v1` contains 46 new mono effects/ambience assets and a per-file
catalogue/credits. Each entry records source archive members, original synthesis,
processing, seed lineage, hash, duration, measured peak/RMS, intended bus and hook.

| Role | Files | Intended hookup |
|---|---|---|
| Soft gritty stone footsteps | `step-stone-1` … `4` | Theme footstep array; keep presentation RNG independent of game dice |
| Four 40s beds | `ambience-cave`, `fungal`, `stone`, `fortress` | Theme/place-owned loop on Effects; do not layer with the old placeholder bed |
| Contact/passages | `wall-bump`, `passage-web`, `passage-roots`, `passage-stone-door` | Theme bump/open sounds, using the actual passage material |
| Prayers | `prayer-cast`, `mend`, `light`, `bind`, `watch`, `miscast` | Successful cast or miscast presentation; one cue per resolution, replacing borrowed block |
| Six creature families | `rat`, `spider`, `goblin`, `beetle`, `bat`, `deep` × `hurt` / `death` | One reaction from the relevant presentation family; avoid double-playing hurt and death |
| Map warnings | `map-noticed`, `map-heavy-blow` | Actual notice/marked-tile warning; preserve gameplay warning timing |
| Traps | `trap-dart`, `snare`, `alarm-bell`, `tripwire` | Triggered trap states, not merely opening their inspection |
| Brews | `brew-drink`, `brew-shatter` | Drink / thrown-flask impact; no knowledge/identification hint |
| Progress | `level-up`, `stairs-up`, `stairs-down` | Actual advancement / accepted floor travel, not prompt opening |
| Pack | `pack-eat`, `bandage`, `oil`, `tome` | Successful item interaction, once; preserve costs/time/effects |
| Smith | `smith-temper` | Successful hammer/anvil temper; preserve price and outcome rules |

Names in the table abbreviate shared prefixes; `catalog.json` supplies exact
complete resource paths and suggested hooks. The stone steps can serve floors
1–4 initially; extra material families are optional later work, not new rules.

The same delivery preserves the previously prepared `audio/galleries-v1`:
four wanderer warnings, three wades, sluice wheel, receding drain, 24s Galleries
ambience and **Below the Sluice**, the existing original 72s score candidate.
Its original recipe, source archive/evidence, catalogue and credits are included.
No new soundtrack was substituted for the approved title/cave/fortress/combat/camp
tracks. The score's musical character still needs owner listening review.

## Character, provenance and levels

Field audio is CC0-derived material editing plus original offline sound design,
not an audio-generation service or newly recorded performances. Prayers use
quiet breath-like noise and low modal resonance, without spoken words. Monster
reactions use recorded balloon friction and material layers; they are explicitly
designed creature sounds rather than real animal or actor recordings. No voice
is cloned. The score uses the original additive/modal composition, seed 16754.
Field synthesis seed is 21703.

The exact Kenney, Bashar3A, qubodup and rubberduck source/evidence credits are
in `audio/field-v1/CREDITS.md`; the older library records remain. One historical
captured queen-source licence page had been LF-normalized in the Git blob even
though its recorded hash referred to mixed original line endings. This branch
restores the exact already-retained capture bytes from the main local copy.
Existing `.gitattributes` already marks those evidence files `-text -diff`, so
future checkouts preserve the recorded identity; the same rule now covers the
retained Galleries water-pack licence capture. The page's text/licence is not
changed and no new licence grant is inferred.

All delivered runtime sources are mono44.1kHz PCM16 WAV. Effects import without
compression/normalization/trimming; music uses existing QOA compression policy.
Loops have explicit forward-loop flags; one-shots have faded zero endpoints.
The combined 57 assets total about28.60MiB decoded PCM before engine compression
and overhead; only the active ambience/score should be owned/played per place.
Four 40s beds are separate candidates, not four simultaneous layers.

Footsteps have peak ceiling about-17dBFS and RMS target about-32dBFS. They are
deliberately soft; no automatic import normalization is allowed. Other effects
retain at least6dB headroom. All field effects/ambience target Effects; the score
targets Music. Existing global/user volumes remain unchanged. Match final levels
in context with the approved combat/camp music, on headphones and physical phone
speakers; objective signal checks cannot approve tone or mix by themselves.

## Checks and reproduction

755 offline source/licence/hash/format/headroom/DC/endpoint/import/distinctness
and deterministic-rebuild checks pass. All46 field WAVs are byte-identical on
rebuild and the11 retained Galleries WAVs are unchanged. The126 earlier audio
assets/metadata tracked by the preserved snapshot remain unchanged.

An isolated Godot4.7.2 Mobile asset project imports all57 files. Its516 checks
pass: native decoding/durations/formats, explicit loop behavior, real playback,
end-seek one-shot completion versus continuing loop, explicit stops, and independent
Music/Effects mute/volume values. Master is muted throughout the fixture. It
never loads Main, game RNG or player settings/save files. This proves assets and
bus routing in the fixture, not unimplemented live-game hooks or phone performance.

149 browser checks pass for all57 individual entries, decoded metadata, actual
muted playback, category filters, one-player-at-a-time behavior, full score length,
loop controls, source/handoff links and desktop/landscape-phone layouts. Browser
audition checks do not establish physical-device speaker or headphone quality.

Rebuild: `tools/audio/build_field_audio.py`; optional `--deps <folder>` adds an
existing NumPy/soundfile dependency directory. Prepare/import the isolated engine
fixture with `prepare_audio_asset_check.py`, run it again with
`--configure-imports`, reimport, then run `--script check.gd`. The import helper
copies explicit `.import` files back to the runtime asset folders. Finish with
`validate_field_audio.py --rebuild` and `package_field_audio.py`.

The compact26.69s sampler and individual full assets are on the listening page.
It has no autoplay, filters by role and pauses other players when one starts.
The older Galleries listening page and wheel/drain sequence remain available.
The branch contains assets and tools only; no shared `main.gd`, `sounds.gd`,
`music.gd`, themes or model files are edited. Claude can connect the catalogued
keys while preserving current gameplay and his concurrent changes.
