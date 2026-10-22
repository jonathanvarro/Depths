# Gas and light-drain cues · #141

Original native pixel FX: four-frame 128px gas burst, separate 256×64 faint haze,
and six-frame 40×48 light-drained pop. [Catalogue](catalog.json) ·
[handoff](../../../docs/new-monster-art.md).

SpriteFrames use `once`, not a looping animation. Both sequences finish fully
clear. Normal alpha/nearest, no bright additive flash or light node. Controllers
own triggers, placement, duration and settings; these assets apply no game effect.
