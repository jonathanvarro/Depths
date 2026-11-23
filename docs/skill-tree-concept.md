# Skills and gothic menu studies (#268 / #269)

Owner direction, 2026-11-21: use the supplied Valor Mortis screens as
structural references. Small, shared class improvements belong above the
named character's larger special traits. Menus should feel more distinctive
and gothic; their outside edges stay straight and their inward corners bevel.

**Owner review, 2026-11-21:** Reliquary brass is approved ("works great").
The skill paths should use the landscape width, with no fixed description
column. Hover/tap descriptions should follow the backpack inventory pattern.
This revision implements that presentation in the concept inspector.

## Selectable skill-screen concept

Open `art/concepts/interface/skill-tree-v1/inspector.html`. It uses the
existing Cinzel/Source Sans typefaces, muted green-black surfaces, parchment
grain, brass accents, approved portraits and existing glyphs.

- **Above:** six compact class-training seals. Four small rank marks suggest
  modest improvements. Health and accuracy sit alongside class-appropriate
  options; the Mage has Spell reserve. They now run horizontally across the
  full available width. Connecting lines are visual groupings, not approved
  prerequisite chains.
- **Below:** three larger personal medallions. Known traits retain a bright
  rim; later story traits retain a dim symbol and lock. The connecting line
  expresses a personal path, not automatic unlock logic.
- **Compare Corin and Branna:** their upper Melee panel is identical for this
  comparison. Corin's proposed identity develops his existing Grudge into
  retaliation and personal endurance. Branna's proposed identity grows from
  rescue work into protection and recovery. Mara and Alwen also have examples.
- **Inspection:** initially hidden on every screen size; it reserves no
  layout space. Mouse hover or keyboard focus previews a card beside the
  source; click/tap pins it. Moving from the source into the card keeps it
  readable. Unpinned previews disappear after leaving; Close, outside click
  or Escape dismisses a pinned card. Escape/Close restores source focus.
  The selected node stays reachable. Long descriptions scroll within the
  card while its heading, unlock information and Close remain accessible.
  Locked traits can be inspected. Hero selection stays on the left.
- **Landscape:** class training and personal paths each span the width to
  the right of the portrait rail. The two sections remain visible together
  on phone shapes; compact layouts omit the explanatory footer.

This is an independent visual proposal. Current `Progression` rules remain:
expedition levels reset, while learned skills persist. The screen explicitly
labels the level as belonging to this expedition and skills as enduring.
Corin's Grudge, Mara's Keen eyes and Alwen's Field medic text reuse existing
traits. **All new ranks, bonuses, critical mechanics, Branna traits, additional
personal slots and story conditions are proposals, not approved balance or
implemented progression.** There is no spend button or invented currency.
No save, class, quest, trait resource or live screen is changed.

## Three button treatments

Open `art/concepts/interface/gothic-buttons-v1/inspector.html`.

1. **Worn iron:** restrained double frame, small rivets and smoke-dark metal.
2. **Reliquary brass — owner selected:** tarnished inlay and a small
   pointed-arch accent. `selection.json` records the approval and the three
   placement rules. Its frame is reflected in the revised skill heading.
3. **Carved slate:** cool stone, shallow engraving and a few chipped corners.

Each has left/centre/right variants. The left has a flat left edge and
beveled right corners; the centre bevels both ends; the right mirrors the
left. Hover, keyboard focus, pressed selection and unavailable states are
reviewable. The right-hand button can be disabled using the sheet's control.
Keep the 44px minimum hit area when adapting these shapes for Godot.

Nine original scalable frame studies live in its `assets` folder, generated
by `tools/art/build_gothic_button_concepts.py`. Labels remain real text,
separate from frames. These are reusable design sources, not drop-in Godot
StyleBoxes. Reliquary brass is the approved visual direction; live Godot menu
adaptation is separate. CSS stretches the frame for comparison;
production should preserve corner widths through a polygon or sliced frame.
The owner's reference screenshots are not redistributed in this delivery.

## Review

Headless Chrome checked all images/fonts, hero switching, equal shared-class
panels, different personal panels, Mage spell reserve inspection, touch-size
controls, Escape, button selection and unavailable states. The revision also
checks initial card hiding, hover preview/leave, moving into a card, pinning,
outside dismissal, keyboard focus, emulated touch, a long-text scrolling
stress case and simulated 47px side / 21px bottom safe margins. All nine
nodes at each of four sizes retain reachable sources and bounded cards.
Both skill sections fit at 1440×900, 1278×590, 844×390 and 667×375 without
page overflow. All skill hit areas are at least 86px in these samples.
The button sheet scrolls vertically on a
phone because it compares three treatments; each individual button remains
at least 58px high. See `validation.json` and the `captures` directories beside
the inspectors. These are browser concept captures, not running-game footage
or physical-iPhone validation. Existing live kit and menus remain unchanged.
