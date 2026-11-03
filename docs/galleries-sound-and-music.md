# Water, warnings and a deeper-cave score (#167 / #54)

2026-11-01. Listening gallery:
`art/concepts/galleries-audio-v1/inspector.html`. Individual controls, complete
audition and wheel-to-drain sequence are available. No autoplay. Final subjective
mix/character review on headphones and physical phone speakers remains open.

Delivered: four matching distant wanderer warnings (scrape, shuffle, stones,
chitter), three weighted wading steps, a four-second iron wheel groan,8.8-second
receding water rush,24-second Galleries water/air/drip loop and72-second original
music candidate **Below the Sluice**. This is a focused deeper-cave music addition;
the existing approved title/cave/combat/fortress/camp tracks are retained.

Sources, licences, hashes and exact processing are retained in
`art/source/audio-galleries-v1/sources.json`, `audio/galleries-v1/CREDITS.md` and
`catalog.json`. The new water source is rubberduck's CC0 pack; the rest reuses
the already-credited Kenney/wind/balloon-friction sources. Sound designs are
hybrids, not represented as fresh field recordings. Music is original offline
additive/modal synthesis, not an instrumental performance or an audio-service
output. Its composition and seed are retained in the builder.

## Live presentation hooks

- `Sounds` provides distinct warning keys and three private-RNG wade variants.
  The shown warning and played sound match. Presentation randomness never
  advances gameplay dice; normal dry steps are suppressed during wet steps.
- `EventScreen` plays the wheel only when resolution newly sets `drained`.
  `Main._drain_galleries()` plays the receding rush when the result is continued.
  Reading quickly can overlap the wheel's tail; no artificial wait/time cost was
  added. The preview sequence demonstrates a normal paced transition.
- `Galleries.theme_from()` assigns the water ambience, routed to Effects on
  the deeper floors. It stays a single Main-owned player, stopped at camp and
  restarted/replaced through the existing place transitions. Dry Galleries retain
  distant water/air; this art pass does not change flood flags or rules.
- `Music.track_for("galleries")` returns the new score on floors5/6; combat/camp
  keep their existing music and normal place-crossfade behavior. Effects/Music
  settings remain independent. No player state/save format changed.

The runtime format is mono44.1kHz PCM16, generous headroom, faded effect endpoints
and joined loop endpoints. Music uses the established QOA import compression;
effects are uncompressed.11 runtime files total 10.40MiB PCM before engine
overhead/compression. Rebuild with `tools/audio/build_galleries_audio.py`, import
once, rebuild to set explicit import flags, then refresh imports.

Checks:44 offline format/level checks, five verified source hashes/licences,35
endpoint/format/distinctness checks,126 preserved earlier files and39 real-controller/event/native
stream checks. The isolated Main fixture disables its live startup, UI and save
lifecycle, uses copied resources and no player files, exercises the actual wet/
dry/opening paths, message/sample matching, theme/music transitions, drain/sluice
choice, finished-player cleanup and settings mutes. The focused native audio fixture exits cleanly. The headless fixture still
reports retained-resource warnings; its assertions pass. Separately the existing
full-Main mastery test reports zero failed assertions then crashes on Windows
(exit-1073741819 /0xC0000005), reproduced on unchanged2328f0b as well.
AGENTS.md therefore blocks commit/push until that process failure is resolved
([#204](https://github.com/jonathanvarro/Depths/issues/204)). The restricted editor import also reports its known preference
safe-save warning. These are recorded limits, not a clean full-game soak claim.

#167's optional dedicated floor4 gate stair and remaining visual hookup/review
remain separate. Broader #54 soundtrack/footstep selection remains open.
