# New monster families · #141

Eleven scenes/SpriteFrames families and 46 registered drawings. Ordinary canvases
128×128, pivot 64,120; Broodmother deliberately 192×192, pivot 96,180. At most 32
shared colours per creature, one scale across all poses, shaded nearest sprites.
[Catalogue](catalog.json) · [paused review](../../concepts/monsters-v1/inspector.html) ·
[full handoff](../../../docs/new-monster-art.md).

Every family supports idle/attack/hurt plus its requested state poses. Bat attack
aliases swoop; lamp-eater attack aliases drain; gas-bloat burst plays two drawings.
`pose_bounds.gd` keeps existing tags above raised poses. `bat_mount.gd` adds
presentation-only hanging/swoop/landed heights. No timers, collision, light or rules.
The four implemented enemy definitions and their builder are connected; special
states and seven future enemies remain for Claude's combat integration.
