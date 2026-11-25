# Field kit: fitted pack, equipment diagram and pause menu (#290)

The owner's 2026-11-24 request is implemented on
`codex/field-kit-silhouette-menu`. Review before merging; physical iPhone
and owner visual acceptance remain outstanding.

## Live presentation

- The pack has a short folded flap, secured straps and twelve registered
  compartments. The entire painting is aspect-fitted, including its buckles
  and outer edges. `KitBag.fitted_art` opts in; trade keeps its existing art
  and pocket registration.
- The selected hero's four existing slots sit around a neutral etched body
  diagram: weapon by the hand, armour at the chest, back by the shoulder,
  trinket beside the waist. No new equipment slots or gameplay rules.
  Art is centred inside square targets, including rarity frames.
- Portraits have an inset clear of the reliquary brass bevel. The hero's
  name, role, health and condition sit below the header.
- A worn physical book spine immediately right of the pack opens the existing
  quest journal. Mouse and touch use the same action and larger invisible
  target around the narrow book. Gear and X have explicitly centred icons.
- Below 640 window pixels of usable workspace width, a Gear/Pack switch
  beside the portrait rail shares the main pane between them. This keeps
  the complete bag and touch targets usable on the smallest phones. The
  selected hero persists when switching. Equipment/Status tabs remain.
- Sizing uses `Viewport.get_screen_transform()`, including project stretch
  and the text-size preference. Header, portraits, tabs, slots, book,
  pagination and pause actions have at least 44 window-pixel targets in the
  checked matrix. Small captions and summary have readable minimum sizes.

## Menu and input

The header gear and Escape open `PauseMenu`: Continue, Options, Save & exit.
An item brief consumes the first Escape to dismiss inspection. Existing
nested screens retain their own Back/Escape behavior. X and I/B still close
the pack, subject to the tutorial's existing guided-drop rule.

The tree really pauses. PauseMenu and Settings alone process while paused;
Options opens the same Settings screen on the layer above the menu. Its
Escape returns to the paused menu, then Continue/Escape restores the prior
screen, selection, focus and pause state. Input ordering explicitly defers
to visible Options, since node input order differs from CanvasLayer order.
Save & exit restores pause state and calls the existing `Main.save_and_exit`:
no new serialization, save restrictions or exit rules. Camp's direct actions
are unchanged.

Inventory counts/capacity/pages, recipient selection, hover/tap briefs,
damage header, curses, founder weapon, mastery, drag/drop, costs and tutorial
authority remain in their existing controllers. The diagram's empty canvas
forwards medicine drops to the selected hero too.

## Art provenance

`art/ui/field-kit-v3` contains the new pack and book PNGs and the original
vector body diagram. Both PNGs were produced with the built-in imagegen
tool, using the existing project bag solely as a material/style reference.
Generated source PNGs are preserved unchanged. Exact prompts, source output
names, dimensions, SHA-256 hashes and registration are in
`generation-manifest.json`. No external model, font or third-party pack added.
All chrome continues to use the shared reliquary brass theme.

The generated book includes faint low-alpha padding; a normalized
AtlasTexture region uses the solid subject bounds (325,51,235,1689 on the
887×1774 original) so the complete spine/bookmark remains visible. The PNG
is untouched. Bag pocket registration is normalized to the 1448×1086 source:
first origin (0.124,0.164), cell extent (0.195,0.228), four columns × three rows.

## Verification and local review

Local gallery: `build/local-field-kit-v3/inspector.html` in the owner's main
working copy. Captures are actual Godot 4.7.2 Mobile renders on a private
Windows desktop. No preview was opened on the owner's active desktop.
Checks use isolated APPDATA and a private test save; no owner saves changed.

- `tools/field_kit_v3_check.gd`: 510 checks, zero failures. Real Main at
  1280×720, 1278×590, 844×390 and 667×375; Normal/Larger; simulated phone
  margins. Full pack fit, portraits, icon centring, target bounds, paged and
  over-capacity bags, mouse/touch book, Escape/gear, true pause, interactive
  Options, return navigation and actual Save & exit to title.
- `tools/check_pack_context.gd`: 553 checks, zero failures. Real mouse/touch
  gestures, recipient medicine, gear equip/return, curses, founder weapon,
  contextual briefs, long descriptions and phone layouts. Touch assertions
  now measure window pixels rather than logical UI units.
- `tools/pack_brief_check.gd`: 176 checks, zero failures. Equipped/carried
  damage header, comparisons, no duplicate picture, bounded art and cards.
- `tools/pack_drag_check.gd`: eleven policy checks, zero failures, headless.
  The fixture now frees Main before quitting for a clean shutdown.
- `tools/opening_playthrough.gd phone <output> 11`: completed with zero
  failures, including the forced broken-knife drop, relight, chest flow,
  spider encounter, commander quest and arrival at camp.
- Headless editor import and `git diff --check` pass.

Example GPU command (run from the delivery checkout with isolated APPDATA):

```powershell
python tools/testing/background_godot.py --godot <Godot-console.exe> --project . --output <private-log-dir> --timeout 90 -- --resolution 1280x720 --script res://tools/field_kit_v3_check.gd -- <capture-dir>
```
