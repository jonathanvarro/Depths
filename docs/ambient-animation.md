# Ambient animation: art request

*2026-10-20 · Owner request: ambient animations such as fog, eyes in the darkness, or swirling darkness. Related: wall, ceiling and floor dressing (#128, [brief](wall-ceiling-dressing.md)), landmarks (#117), party condition (#64), the art backlog (#96).*

Everything here is **atmosphere**: no new rules. Most of it reacts to two things the game already tracks:
- **The party's light:** Bright, Steady, Dim or Out.
- **Nerves (strain):** Steady, Uneasy, Shaken or Panicking.

As the light fails and nerves fray, the cave should feel like it's closing in. When light returns, it backs off. This is the "show, don't tell" direction (#105): the player sees the danger rather than reading about it.

## The effects

| # | Effect | What it looks like | When it appears |
|---|---|---|---|
| A1 | **Floor fog** | A low, slow-drifting mist hugging the floor, thicker in rooms than corridors. | Always faint. Denser on deeper floors and in later wet or drowned areas. |
| A2 | **Eyes in the darkness** | A pair of eyes glinting at the far end of a corridor, beyond your light. They blink and then they're gone. 3 kinds: small red (rat-like), a cluster (spider-like), and pale and wide-set (unknown). | Only when the light is **Dim or Out**, or nerves are **Shaken or worse**. Never inside your light radius; they vanish if your light would reach them. |
| A3 | **Swirling darkness** | Inky tendrils curling in from the screen's edges, slowly writhing. | Grows as the light fails and nerves fray: none at Steady with good light, a hint at Dim or Uneasy, strong when the light is Out or the party is Panicking. It recedes when light returns. |
| A4 | **Dust motes** | Tiny specks drifting slowly in the light near the party. | When the light is Steady or Bright. The cosy contrast to A3. |
| A5 | **Water drips** | A single drop falling from the ceiling, with a small splash and ring on the floor or a puddle. | Here and there, under stalactites and on puddles (#128). |
| A6 | **Torch smoke and embers** | A thin smoke wisp and a few sparks rising from a lit goblin wall torch. | With the lit goblin wall torch (#128 item 9). |
| A7 | **Fungus glow pulse** | A slow brighten-and-fade on glowing fungus patches. | With the glowing fungus (#128, second batch). |
| A8 | **A passing shadow** (rare) | Something dark crossing a far corridor end, glimpsed for an instant. | Very rarely, and only when the light is Dim or Out. |

## Format

- **Style:** pixel art matching the cave props, with nearest-neighbour filtering. Smooth gradients in fog and darkness should be dithered or stepped to fit the pixel look.
- **Frames:** sprite sheets (transparent PNG) at **6–10 fps**, looping seamlessly. Give the frame size and count in the sheet's README or catalogue, as with the existing props.
  - **Eyes (A2):** about 8–12 frames per kind (fade in, hold, blink, fade out). Small, roughly 16–32 px wide at in-world scale; they're meant to be barely seen.
  - **Drips (A5) and smoke (A6):** short loops of 6–10 frames.
- **Fog (A1):** a **tileable** strip, about 256×64, that the game scrolls slowly, plus 2–3 soft patch shapes for rooms. The edges must wrap without seams.
- **Swirling darkness (A3):** a **full-frame screen overlay** at 640×360 (the game scales it up), black with transparency. Provide **3 intensity levels** (hint, medium, strong) of an 8–12-frame loop, or one strong loop the game can fade in. Keep the centre of the screen clear: it should press in from the edges, not cover what's ahead.
- **Blending:** say which pieces add light (embers, the fungus glow, the eyes' glint) and which are plain transparency (fog, darkness).
- **Phone cost:** small textures, few layers. Each effect should cost about one sprite or one overlay, not hundreds of particles.

## How the game will use them (Claude, once art lands)

- **Fog, drips, smoke and glow** are placed with the dressing (#128), using the same stable per-floor rules.
- **Eyes and the passing shadow** are spawned beyond the edge of the party's light, at the far end of a straight corridor, and only under the light and nerve conditions above. One at a time, a few at most per minute.
- **Swirling darkness** joins the existing bleeding-vignette shader layer. Its strength follows light and nerves, and it eases in and out over a few seconds, never popping.
- **Settings:** the screen-flash setting already turns down the bleeding flash. The swirling darkness will follow it too, for players sensitive to motion at the screen edges.

## Decided: the eyes are pure atmosphere (owner, 2026-10-20)

Eyes in the darkness appear at random in the dark and **never hint at real enemies**. Fights stay ambushes (#46), and no pattern in the eyes says whether a room is safe.

### The question as it was asked

The decided rule is that enemies ambush: they aren't visible before a fight (#46). Two options:

1. **Pure atmosphere (suggested):** eyes appear at random in the dark, unrelated to where real enemies are. They're a feeling, not a warning. Because they never mean anything, they can't spoil an ambush, and they can't teach a player "no eyes means safe".
2. **A fair warning:** eyes appear more often near a room that holds a fight. That's a real clue for careful players, but it softens the ambush rule and makes darkness tactically useful.
