# Tutorial chest states (#70)

Use `scene.tscn` with `set_state(&"closed")`, `set_state(&"open")`, `set_state(&"empty")`, or instance the correspondingly named scene. Three transparent, registered 128×128 drawings with one shared 32-colour maximum. Root belongs at floor centre; the lit sprite handles camera-facing orientation. No collision, light or inventory logic is included.

See [the complete handoff](../../../docs/opening-tutorial-art.md) for the pivot, world scale, state meanings, existing `Main._add_chest` mapping, source prompts and validation. [State overview](../../concepts/opening-tutorial-v1/chest-dark.png).
