# Treasure illustrations / world props v1

Twelve new 128px RGBA illustrations, bottom contact at (64,120); actual
closed/empty chest textures are borrowed from tutorial-chest-v1 unchanged.
Four pickup scenes (coins-small, coins-heap, coin-purse, coin-sack) are
lit upright billboards with floor-centre roots and no collision/loot logic.

chest.tscn reuses the tutorial chest script: set_state(closed/open/empty).
Only open depicts the new treasure contents. These are three static
drawings, not an opening animation. Game state remains authoritative.

See docs/treasure-art.md and art/items/treasure-v1/catalog.json.
