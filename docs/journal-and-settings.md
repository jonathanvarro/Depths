# Quest log and Settings · Field kit cleanup

2026-10-26 · #165 / #51 · [Actual Godot previews](../art/concepts/interface/journal-settings-v1/inspector.html)

Both live menus now use the shared charcoal/brass Field kit frame, Cinzel
headings and Source Sans text. The journal reuses the existing rough map paper;
all four reused image/SVG inputs are unchanged and pinned in the review catalogue.
There is no new raster art or generated character artwork.

## Quest log

Open quests precede completed ones in a scrollable list. Selecting an entry
shows its actual stage, floor, giver and next step on paper. The view keeps the
last inspected quest while it remains valid, and refreshes progress on reopening.
The empty journal has no stale selection. Unknown hidden quests remain absent:
`Quests.in_log()` is still the sole source of entries, and browsing writes no
quest state. `Quests.next_step()` remains authoritative; no objectives are added.

Below 650 UI pixels of body width, the list and detail become separate views.
Select a quest to read it; All quests or the first Escape returns to the list.
A further Escape closes. Wider views retain both columns, and Escape closes
directly. Long lists and details scroll independently. Text does not impose
the old fixed 600px minimum width.

## Settings

Sound and Display use two columns where they fit. Narrow layouts put both
sections into one scroll area, avoiding nested touch scrolling. Volume sliders
keep their percentage readouts; toggle buttons explicitly say On/Off. The
Normal/Large/Larger choices remain the same settings values and continue to
resize the real interface immediately. Controls stay alive during scale changes,
and focus survives reflow between columns. Fullscreen remains desktop-only.

Music credits are available in the fixed header and retain the existing full
attribution/licences. Back or Escape returns from credits to Settings; another
Escape closes. The redundant automatic-save sentence is removed, while every
change still uses `Settings.set_value()` and its existing immediate save/apply.
No preferences, audio routing, defaults or save formats are changed.

## Shared behavior and callers

`scripts/field_menu.gd` supplies the bounded frame, persistent heading/Close,
safe-area API, keyboard focus cycle and focus return. It responds to canvas
resize and late minimum-size changes, including the title's Larger-text case.
Tab/Shift-Tab stay inside the modal; Tab still navigates even though Main also
uses it for the map. Pack/map shortcuts cannot operate the underlying screen.
Close and other controls have accessible names, and minimum touch targets are
44px or larger in UI coordinates.

`closed` remains both menus' signal. Quest `open(camp)` and Settings `open()`
remain their public entry points. Main now supplies the journal's safe-area
insets as well as Settings'. The title hosts Settings in its own CanvasLayer,
clear of the underlying title layout. Title, Pack header and camp gear presses
focus their opener explicitly so touch-opened menus return keyboard focus to
the correct control. Changes outside the two menus are limited to these hooks.

## Verification

- **479 isolated Godot checks**, clean renderer exit: desktop 1280×720,
  landscape 1278×590, SE-shaped 1334×750 and compact 844×390, Normal/Larger text;
  simulated GUI mouse/touch/key input, every setting reachable through focus,
  focus cycling, nested Escape, empty/discovered/completed quests, updated flags,
  scrolling, immediate audio application, persisted/reloaded settings and reflow.
- **65 actual caller checks:** title, Pack journal/gear and camp gear;
  safe areas, correct opener focus and underlying shortcut suppression.
- **45 existing story assertions and 26 batch/settings assertions** pass with
  `fails=0`. Runs used project-local saves and restored test preferences.
- **36 captures / 45 browser checks:** review images decode, quick choices work,
  and the review page fits desktop, landscape and narrow browser widths.

The isolated fixture backs up/restores `user://test_settings.cfg`; it never
changes the player's normal settings or game save. Main validation uses a
private save under ignored `build/menu-polish-review`. Physical iPhone usability
remains #66; simulated input and screenshots do not complete that task.

The Main fixture still reports one CanvasItem RID/two ObjectDB instances at
shutdown. Legacy story/batch runners also report their cleanup/resource warnings;
functional assertions pass, and this UI task does not claim to fix teardown.

Tools: `tools/art/check_journal_settings.gd`,
`tools/art/check_journal_settings_main.gd`,
`tools/art/build_journal_settings_review.py` and
`tools/art/check_journal_settings_review.cjs`. Reports/captures live alongside
the gallery. This completes the requested two-menu pass; #51 remains open for
the broader interface review and other screens.
