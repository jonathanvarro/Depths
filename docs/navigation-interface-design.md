# Navigation and menu direction — first study

The owner asked to brainstorm the general navigation interface so it can establish the flavour of later menus and windows (#37). These are **two proposals for review**, not an approved interface theme or changes to the Godot UI. The interactive study was supplied in the owner's design chat; [review captures and provenance](../art/concepts/interface/navigation-v1/README.md) preserve the comparison for other assistants.

**Follow-up (2026-10-17):** The owner selected **Field kit** in the interactive comparison and chose Pack as the next design. See [Pack screen refinement](pack-screen-design.md) (#39) for the editable Godot preview using the accepted title/font pairing. The original alternatives below remain a record of the comparison; the live Pack has not yet adopted the new design.

**Current refinement (#61/#62):** The owner liked the [image-slot Pack and tabbed hero window](pack-and-hero-window-design.md), then requested a [simpler exploration HUD](exploration-hud-design.md): icon-only backpack just right of portraits, Settings gear and a compact visible lantern/torch meter. These explicit updates supersede the labelled Pack/Menu and no-fuel-readout suggestions below; accessible names and hover/focus labels remain required.

## Two coherent directions

| Direction | Exploration | Windows | Trade-off |
| --- | --- | --- | --- |
| **Field kit — recommended starting point** | Mostly open cave view; portrait cards low left, movement low right, folded map and small Pack/Menu actions high right | Dark charcoal/leather-like surfaces with thin worn-metal edges; parchment reserved for maps and documents | Keeps the dungeon present and the bright paper meaningful; needs restraint so frames do not become decorative armour |
| **Field journal** | A persistent tabbed header gathers Map, Pack, Party and Menu | A broad paper-led book with a binding edge, ink rules and item lists | Strong continuity with the hero-drawn map; more navigation remains visible and bright paper dominates longer menu visits |

The alternatives differ in layout and navigation, not just colour. A useful eventual blend is Field kit's quiet exploration layout, with Field journal's material language used selectively inside documents and records. Do not mix both sets of navigation controls onto one screen.

## Shared material and type rules

- **Practical, carried objects:** dark worn leather/cloth, restrained iron edging, rough paper. One thin frame and small corner wear; keep the centre of panels quiet. Avoid elaborate stone monuments, skull borders, oversized rivets and continuous animated flames.
- **Colour roles:** charcoal/black-brown surfaces, parchment text, muted brown structure; amber for the current choice/focus. Use red for danger/health loss, not every selected tab. Pair states with text/shapes as well as colour. Paper uses dark ink, rather than the same light text as dark panels.
- **Type:** modest serif headings can suggest an old record; clear regular-weight body type and action labels do the practical work. Handwriting belongs to short map notes. Avoid blackletter, all-caps body copy and low-contrast distressed lettering. Prototype browser sizes are not final phone typography; begin actual Godot integration with the existing readable UI scale and test on target phones.
- **Icons:** small recognizable pictograms beside words; avoid unexplained icon-only navigation. Prototype line icons are stand-ins for a later coordinated art pass. Item pictures and portraits provide much of the visual character already.
- **Light:** keep UI contrast dependable when the cave is dark. Character lighting follows [the separate portrait-lighting requirement](portrait-lighting.md); the study reuses the current baked-lit Mara as a placeholder and does not complete #36.

## Exploration layout

Keep the central first-person view largely clear. The three existing party slots remain at the bottom left and the four movement controls remain at the bottom right: forward/back plus turn left/right, without strafing. Use a clearer grouped arrangement before inventing gestures or extra movement modes. The current player's portrait is the natural proposed entry to that hero's information; empty slots do not imply recruitment is available inside the cave.

Keep the small map in a stable upper corner and let tapping it open the full sheet. Pack and Menu remain direct, visibly labelled actions. Inventory inspection should not require opening a general menu first. Supplies remain in Pack, as already decided, rather than adding a new permanent oil/food dashboard. Current-location text can be small and quiet; persistent title chrome is a proposal to test against phone space, not a required large logo in play.

In combat, retain the party cards and replace movement with the available action panel. Event/transition decisions also temporarily take control from movement. One active interaction surface at a time; a modal must not leave move controls clickable underneath it.

## A common window family

| Window | Reusable structure |
| --- | --- |
| Pack | Title/Back, supply list with image/name/count, one selected-item detail region, explicit applicable action or reason it is unavailable |
| Map | Broad parchment surface, reliable hand-drawn routes, floor title/legend and one clear return control; follow [the map design](hand-drawn-map-design.md) |
| Hero review | Identity/portrait, health/condition, then useful character information; detailed equipment tabs wait for that system |
| Room choice / passage prompt | Clear heading, concise clue/question, a short stack of actions; show known time/resource costs with the relevant action |
| Camp service | Provider or activity identity, focused service choices and a consistent Back to clearing; preserve [the spatial campsite navigation](campsite-design.md) |
| Expedition results | A readable record of what happened and explicit next actions appropriate to the actual outcome; share frames/type with other windows without inventing new persistence rules |

Use one selected detail region rather than rows of small floating popovers. For phone widths that cannot hold list and detail side by side, make item detail a readable second pane/step with an obvious return. The in-chat narrow review stacks them to remain inspectable; that vertical fallback is not a commitment to portrait-orientation gameplay.

## Navigation behaviour

Use **Map / Pack / Party / Menu** as the small vocabulary in this study. Party review is a proposed new entry; the current game cards are informational. These are top-level destinations, not a requirement to implement a journal, quest log, equipment screen, save/load or new campaign systems.

Top-level windows return to exploration. A nested window returns one level first: Controls -> Menu -> exploration, or use-item prompt -> Pack -> exploration. Escape follows the same hierarchy as the visible Back control; it must never consume an item or accept a consequential choice. Return focus to the control that opened the window, retaining item selection. A tab switch between sibling windows should not build a long browser-like Back history.

Opening and browsing remain free of time/resource costs. Show actual effects and costs on actions that spend them. The prototype's generic item confirmation illustrates an action window; adding confirmation to every ordinary item use is not decided. Avoid extra taps for routine actions unless accidental use is a real problem. A committed outcome or combat defeat must not be dismissed into an invalid exploration state by a generic Back handler.

Mouse hover, keyboard focus and touch press should share the same selected/active language. Use native focus order and visible focus marks; no hover-only information, hidden long-press controls or swipe-only Back. Keep touch targets at least 44pt and clear of safe areas in the actual iPhone layout, with adequate separation. Full-screen presentation should recompose before shrinking labels. Optional transitions should be brief and respect reduced motion.

## Smallest next implementation

After the owner chooses a direction, theme one exploration HUD, one Pack and one room-choice panel together. Share panel, heading, button, focus/disabled and spacing definitions in a Godot Theme/reusable scenes; keep textures separate from actual labels and hit areas. Validate those components before styling every menu.

Review in Windows and a landscape phone: three occupied portraits, long item names, depleted/unusable items, sparse/large maps, nested Back and focus return, decisions with several choices, a committed result and a combat transition. Do not spend the next pass adding unrequested dashboard panels or treating this prototype as a game implementation.

## Review status

Both directions support local exploration-control feedback, Pack selection and a sample action window, map, Mara review, Menu/Controls, Back and Escape. Checked at 1024, 736, 568 and 320px review widths, with no script errors or horizontal overflow in the visited states; focus return and variant switching passed. The 320/568 views are responsive conversation previews, not supported game orientations. Product captures are 992 × 640 inside a 1024px browser viewport, not physical iPhone checks or the shipped Godot interface. Reused counts and character text are illustrative presentation content, not new balance or lore decisions.
