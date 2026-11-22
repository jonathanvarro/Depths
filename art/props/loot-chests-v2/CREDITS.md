# Common, silver and embellished gold chests · #279

The chest shell, separate lid and original hinge derive from Kay Lousberg's
**KayKit Dungeon Remastered 1.0**, CC0 1.0 Universal. The exact original
`chest.glb`, licence and pinned official-blob/SHA-256 records are preserved at
`art/third-party/kaykit-containers-rest-v1`. No new external file was downloaded.

`tools/mine_polish/build_models.py` fits each shell to metric scale, changes lid
profiles, adds mild wear/bevels, and authors separate fittings: a common repair
board, silver corner guards/central rib, gold scrollwork, a lid seal and lozenge,
pull rings, locks, feet and decorative contents. Lid ornament is projected onto
the actual source lid surface. Physical UVs and vertex colours support the new
shared procedural materials. Original files and the earlier derived chest
remain unchanged. Editable masters stay local in
`build/local-mine-polish-v2/masters`.

The scene code supplies lid motion and visual state only. Actual loot,
rarity assignment and save state remain owned by the game controllers.
