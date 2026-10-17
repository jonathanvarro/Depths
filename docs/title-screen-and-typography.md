# Title screen and reusable typography proposal

The owner requested a generated title screen and noted that its fonts will form persistent elements of the game (#38). This study extends the [navigation proposals](navigation-interface-design.md). **Depths remains the working name**, not a decided release title.

[Desktop title](../art/title/title-v1/title-desktop.png) · [Landscape phone](../art/title/title-v1/title-phone.png) · [Type specimen](../art/title/title-v1/title-specimen.png)

## Title composition

A lantern hangs at the edge of a rough passage descending into darkness. The composition places cave depth and warm light to the right, with a quiet dark area to the left for the title and a short menu. Broad pixel clusters connect it to the environments; restrained type and thin worn-amber rules connect it to the proposed Field kit interface. No party portrait, dense HUD, decorative skull border or invented story tagline is needed here.

The generated backdrop has **no text**. The wordmark and menu are separate Godot Labels/Buttons using actual bundled fonts. Future wording, localisation, resolution and focus states can therefore change independently of the art. This also avoids treating AI-generated lettering as a reusable typeface.

The study shows **Begin expedition / Settings / Quit** on Windows, and omits Quit in the phone composition. These are proposed labels/presentation, not working navigation. A Continue action should appear only when real resumable-save support exists; no such system is assumed. First-time opening/preparation and campaign recovery rules remain with #18/#30 and existing design decisions. The small study footer is a review label and should not ship as game chrome.

## A small type system

| Role | Proposal | Use |
| --- | --- | --- |
| Title | **Cinzel SemiBold (600)**, generous spacing at large sizes | A carved, formal identity; also suitable for a restrained future wordmark treatment |
| Major headings | **Cinzel SemiBold (600)** with normal spacing | Pack, Party, expedition result titles and short section labels |
| Action text | **Source Sans 3 SemiBold (600)** | Menu buttons, active choices, important names and numerical readouts |
| Body text | **Source Sans 3 Regular (400)** | Descriptions, dialogue, clues, costs, inventory rows and help |
| Hero map notes | Separate hand-drawn treatment as proposed in #34 | Occasional short annotations; essential labels still use readable UI type |

Cinzel's formal serif forms are a visual recommendation, not a requirement to make every label uppercase. Keep sentence case for normal controls and reading text. Do not distress small lettering, use body-length blackletter or add wide tracking to numbers. Mood comes from materials, spacing, light and the scene; names, costs and warning text should be easy to read.

The current title prototype uses 96px title / 26px menu text at 1280 × 720, and a 78px title with 26px menu text in the 1278 × 590 phone composition. The specimen uses 26–30px headings and 20–22px reading/status text. These are **layout-study sizes**, not one scale to paste into every game control. Integrate via shared theme roles and the established landscape UI scaling, then check the actual phone. Phone-study buttons are 72px tall with 100px side margins; desktop buttons are 56px tall. No physical-iPhone target-size or accessibility certification is claimed.

Use parchment text on dark panels and dark ink on paper, with amber for selection/focus. Check both treatments. The specimen includes digits and potentially confusable `Il1 / O0` characters, health/oil examples, punctuation and multiplication marks. Extend tests for all localisation strings and languages before promising coverage; the display family and body family have different character repertoires.

## Reuse and implementation boundary

[Bundled font resources, attribution and licences](../art/fonts/README.md) provide the exact files and four reusable FontVariation resources. The fonts came from the official Google Fonts distribution with accompanying SIL OFL 1.1 notices preserved. The font binaries are unmodified; filenames are simplified locally.

`art/title/title-v1/preview.tscn` is an optional Godot Control scene that renders this composition. It is deliberately **not assigned as project.godot's main scene**, and its buttons do not start games, change settings or quit. `tools/art/render_title_study.gd` renders the desktop/phone/specimen images and checks font loading, sampled glyph coverage, viewport bounds and menu target dimensions (168 checks). The PNGs are review captures; the editable text remains in the scene.

After the owner chooses the typography, adopt the role resources in one shared theme and apply it to the title, one navigation window and one room-choice panel together. Retain the existing game flow while implementing the real title/preparation screen in #18. Confirm keyboard/touch focus, localization, long labels, real phone safe areas and letter sizes before expanding the theme everywhere.

The generated source background, [exact prompt/provenance](../art/title/title-v1/generation-manifest.json), fonts and optional scene are preserved in the project. This task does not implement title-flow functionality, settle a release name, add a save system or complete a new game-wide theme.
