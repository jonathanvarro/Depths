# Spider family and goblin base — Depths #255 / #251

CC0 originals and declarations: `art/third-party/oga-creatures-v1`.

- Spider family derives from br-n518's Spider. Source topology gains six tiny
  thorax-skinned eye islands (48 triangles); derived total is 270 per spider.
  The original 45-bone labels/hierarchy and source idle/walk/bite are retained.
  Legs are thickened conservatively; web-spinner abdomen is fuller/paler,
  venom abdomen narrower/longer with ochre/dark warning masses. Hurt, rolled
  curled fall, web and venom poses are authored on that same rig.
- Goblin derives from CDmir/TinyWorlds' CC0 Goblin. Body/eyes are reduced for
  phone use; jewellery/necklace are removed. Authored ragged tunic, knife and
  closed wooden buckler use the original 57-bone rig. Idle/slash/hurt are authored;
  fall derives from the source Die at half duration. Evaluated motion is baked
  for export; an editable constrained fitting master is retained separately.
- Fixed outer floor origins, +Z fronts and constant metric scales. Internal
  floor corrections keep all visible geometry off the floor; the goblin fall
  is registered inside its 2m tile. Original source files are never altered.
- One shared authored 32-colour 256×128 point palette and existing project cave
  grain (`art/third-party/kaykit-dungeon-remastered/grain-floor1.png`). No baked
  lights, emission, particles or collision; no new texture download.

Runtime API and review limits: `docs/spiders-and-goblin-3d.md`.
No EnemyType, combat rules, loot, lore or named portrait is changed.
