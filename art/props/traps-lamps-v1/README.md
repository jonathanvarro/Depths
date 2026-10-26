# Traps and dead lamps

#158 / #159 · Native128, hard alpha, <=32 colours per state pair.

`snare.tscn`, `dart.tscn`, `bell.tscn`, `lamp.tscn` implement the existing
`closed` / `empty` state contract. Story builders and all four live events are
connected. Each pair keeps one full-canvas transform and one shared palette.

Snare/dart are horizontal floor sprites. Bell and rack are upright. The trap
mount script uses Main's optional `mount_in_cell()` hook for within-cell offsets
and separate knee-height dart ports against actual walls. The rack emits no light.

- [Handoff and checks](../../../docs/traps-and-dead-lamps.md)
- [Native and actual room review](../../concepts/traps-lamps-v1/inspector.html)
- [Exact built-in ImageGen prompts and masters](../../source/traps-lamps-v1/generation.json)

Rebuild with `tools/art/build_traps_lamps.py`; import before running story builders.
Physical iPhone testing remains open. Existing rules and saves are unchanged.
