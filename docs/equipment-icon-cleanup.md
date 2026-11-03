# Seven equipment bases (#196)

2026-11-01. Review `art/concepts/equipment-live-v1/inspector.html`; phone-size
dark/parchment comparisons are in `library.png`. Twelve real Pack/loot/merchant
captures include desktop, iPhone15 landscape and SE-shaped windows, Normal and
Larger text, simulated safe areas. Physical iPhone inspection remains separate.

| Stable base ID | Picture / source choice |
|---|---|
| boar_spear | New crossbar variant of the handworked garrison spear |
| goblin_cleaver | Retained broad chipped notched falchion |
| studded_jerkin | New studded variant of the raider's asymmetric leather vest |
| goblin_scale | New waist-length scale shirt: uneven rows, repaired gap, low corner |
| buckler | Retained round timber-and-iron shield master |
| goblin_shield | New patched hide-on-wood round shield, irregular edge plates |
| shadow_cape | Retained short dark raider's mantle |

Four built-in ImageGen calls; exact prompts, immutable generated masters,
reference/output hashes and reuse reasons are in
`art/source/equipment-live-v1/generation.json`. Original outputs were copied into
the project; previous designs remain intact. This completes the seven borrowed
base pictures, not a blanket repaint or final shape approval of all22 candidates
from #194/#195.

Exports: aligned128 and directly source-reduced64, hard alpha, zero hidden RGB,
64 visible colours and8/4px padding. The source may be much larger, but runtime
detail stays within the established inventory budget. Shared original icons and
template resources are unchanged. Rebuild with
`tools/art/build_equipment_live_icons.py`; it asserts the entire bases table is
identical after excluding the seven new icon fields and two obsolete placeholder
sentences.

Optional `bases.json.icon` is presentation-only. `GearModel.refresh_art()` applies
that picture and current base description to new items and already-generated
items passed through the normal restore conversion (`ensure_instance`). Existing
rolls, IDs, quality, mastery, growth, modifiers, tempering and RNG state survive
unchanged. The shared legacy templates keep their original pictures.

Checks:57 export/data invariants,108 headless and120 Mobile-renderer checks,
including all seven bases at five qualities, actual serialized-old-icon restore,
unchanged full nonvisual item data/RNG, and12 captures. Existing gear-model
checks also exit cleanly. The mastery run reports `fails=0` but then
crashes with Windows access violation `0xC0000005` (exit-1073741819), both here
and on an unchanged2328f0b baseline copied into ignored build storage.
Commit/push is paused under AGENTS.md pending that failed process check, tracked
in [#204](https://github.com/jonathanvarro/Depths/issues/204). The unrelated older `gear_check` wording assertion
mentioned in NOTES was not part of this delivery.
