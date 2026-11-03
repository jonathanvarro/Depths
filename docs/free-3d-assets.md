# Free 3D assets: shortlist and licence guide

Owner direction (2026-11-03): start 3D work from existing free assets
instead of generating bespoke ones where a good free asset exists, and
**favour CC0** to avoid licence trouble later. Licences were checked on
each source's own page on 2026-11-03. Re-check before downloading:
licences can change.

## The licence words, in plain language

| Term | What it means for Depths |
|---|---|
| **CC0** ("public domain") | No conditions. Use it, change it, sell the game, put the files in this repo. Credit is optional. **The safe default.** |
| **CC-BY** | Free, but the game must credit the author (a credits line). Easy to forget, so avoid it unless an asset is special. |
| **Custom "free" licences** (e.g. Quaternius's QAL) | Free to use in a game, but with extra rules, usually *no redistributing the files themselves*. Read each one. |
| **Non-commercial (NC)** / **editorial only** | Can't be used in a game that might be sold. **Never use.** |
| **"Royalty-free"** (e.g. Mixamo) | Usable in a game, but not open: the raw files can't be shared. |

**Why "redistribute" matters here:** this GitHub repository is **public**.
Putting a model file in the repo shares it with everyone. That's fine for
CC0. For any other licence, keep the raw files local (as the Blender kit
and Mixamo clips already are) and commit only the game's own scenes and
notes.

## Shortlist

### First choice: CC0, safe to commit

**1. KayKit by Kay Lousberg** (stylised low-poly)
- **Licence:** CC0 ("Creative Commons Zero v1.0 Universal ... no
  attribution required"). The author asks you not to resell unmodified
  copies or claim them as your own; that's a request, not a CC0 condition.
  Fine for us either way.
- **Relevant packs:**
  - *Dungeon Remastered:* 200 free dungeon pieces and props, more in the
    paid "Extra" tier.
  - *Characters: Skeletons* and *Characters: Adventurers*.
  - *Character Animations*.
- **Phone fit:** excellent. Each pack shares **one gradient texture**
  (1024 square, which the author says can be shrunk to 128). Formats are
  FBX, glTF and OBJ, and the page lists Godot.
- **Style:** clean, a little toy-like. To look dark and gritty it needs the
  shared texture recoloured to the game's palette, plus the existing fog,
  light bands and wound vignette. Recolouring one image restyles a whole
  pack, which is the big advantage.
- **Rigs:** KayKit characters have their own rig. Mapping it to Mixamo or
  Godot's humanoid profile needs checking once.
- **Best for:** dungeon and cave dressing (barrels, crates, bones, torches,
  doors, rubble, chests). It's also the strongest candidate for the pilot.

**2. Kenney** (very simple low-poly)
- **Licence:** CC0 ("all game assets on the asset pages are public domain
  licensed (CC0)"). Credit is optional; just don't use the Kenney logo.
- **Relevant packs:** *Modular Cave Kit*, *Modular Dungeon Kit*, *Mini
  Dungeon* and *Graveyard Kit*.
- **Style:** the plainest of the four, and the hardest to make gritty.
- **Best for:** quick stand-ins and blocking out layouts while the real art
  is chosen.

**3. Poly Haven** (photoscanned, realistic)
- **Licence:** CC0 ("You can use our assets for any purpose ... You do not
  need to give credit ... You can redistribute them").
- **Offers:** models in categories such as nature (rocks), containers,
  lighting and industrial, plus textures and skies.
- **Style:** gritty realism, which matches the tone but clashes with
  low-poly characters if mixed carelessly. The models are detailed and
  heavy for a phone: use the smallest texture downloads and simplify
  meshes.
- **Best for:** rock and stone textures and the odd hero prop.

**4. ambientCG** (textures)
- **Licence:** CC0 1.0 ("copy, modify, distribute ... even for commercial
  purposes, all without asking permission"). No exceptions listed.
- **Offers:** rock, ground, wood, metal and similar surface textures.
- **Best for:** wall, floor and ceiling surfaces. The level builder is
  already texture-based (EnvironmentTheme), so this needs the least new
  work.

### Second choice: free but **not** CC0. Keep the files local.

**Quaternius**
- **Licence:** the site's licence page is now the **Quaternius Asset
  License (QAL) v1.0**. It allows free commercial use with no credit
  required, but you "may not ... redistribute the Assets" as files,
  "regardless of how much the Assets have been modified".
- **Mixed signals:** older pack pages (e.g. the Universal Animation
  Library page, dated March 2025) still say CC0. The QAL says assets keep
  the licence they were obtained under. To be safe, **treat any new
  Quaternius download as QAL**: usable in the game, files never committed
  to this public repo, and the version and date recorded.
- **Why it's still listed:** the free **Universal Animation Library** 1 and
  2 (120+ and 130+ humanoid clips). The Godot Asset Library listing says
  they're compatible with Mixamo rigs. They are the best free alternative
  if Mixamo ever disappears; one secondary source says Mixamo is in
  maintenance mode, which isn't confirmed by Adobe. The site also has
  *Universal Base Characters*, the *Bestiary: Dungeon Monsters* kit and
  *Modular Dungeons*.

### Avoid unless one specific item is checked

Sketchfab, itch.io, OpenGameArt and Poly Pizza mix many licences on one
site (CC0, CC-BY, non-commercial and custom). Use one of their assets only
if *that asset's own page* says CC0, and record it.

## Recommendation

1. **Surfaces:** ambientCG, then Poly Haven, for cave and stone textures.
2. **Dressing and props:** KayKit Dungeon Remastered, recoloured to the
   palette, with Kenney as quick stand-ins.
3. **Characters:** keep the current Blender/Mixamo kit (#209–#218). Hold
   KayKit characters and the Quaternius animation library in reserve.
4. **Bespoke:** only for what players remember: named companions' faces,
   bosses, the relic and signature places.

**Pilot first** (see the issue): floor 1 dressing with KayKit only,
recoloured, placed with the existing dresser and compared in the game at
desktop and phone size against what's there now.

## Record every asset

The same habit as `audio/dark-v1/CREDITS.md`. For each asset kept, note:
- source URL, pack name and version;
- licence, with a link to the licence page and the date it was checked;
- download date and file hash;
- what was changed (recolour, mesh simplification, renamed pieces).

CC0 assets and their record go in the repo, under a folder like
`art/third-party/<pack>/`. For non-CC0 assets, only the record goes in the
repo; the files stay local.

Not legal advice: this is a reading of each source's own licence page.
