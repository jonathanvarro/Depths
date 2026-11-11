# 3D combat roster (#251)

[Open the local review gallery](E:/GitHub/Depths/build/local-combat-roster-v1/inspector.html). START_REVIEW.cmd in the same folder opens the native inspector with exact 24 fps stepping, playback, equipment toggles, and lighting controls. The gallery includes paused samples, front views, and the current tactical board at three landscape screen sizes. Editable Blender masters are in the adjacent masters folder.

The [current Goblin Queen idle sprite](../art/enemies/campaign-v1/queen/idle.png) is still the live art. Her model carries over its split red skirt, uneven crown, shoulder plates and broad cleaver. The existing enraged sprite and its combat behaviour are preserved.

| Candidate | Silhouette and rig | Extra clips |
|---|---|---|
| Great rat | Broader hunched body, prominent incisors and torn-looking ears on the 21-bone rat rig | Walk, run |
| Goblin archer | Curved bow and high quiver on the common 57-bone goblin rig | Draw |
| Goblin guard | Broad worn shield, iron cap and mace on the goblin rig | Brace |
| Goblin drummer | Pale drumhead and two mallets on the goblin rig | Drum |
| Goblin trapper | Rope loops, knife and a bulging sack on the goblin rig | Snare |
| Goblin Queen | Red skirt, brass crown and iron cleaver on a larger goblin rig | Enraged |
| Broodmother | High plated abdomen, pale mandibles and folding legs on the 45-bone spider rig | Call, web, venom, walk |
| Mara | Side-swept brown hair, plain tunic and diagonal strap on the board figure rig | Walk, defend |
| Corin | Bald head, broad shoulders, quilted vest and iron sword on the board figure rig | Walk, defend |
| Sister Alwen | Linen coif, shoulder wrap and cracked staff on the board figure rig | Walk, defend, cast |
| Generic recruit | Olive cap, pack and club on the board figure rig | Walk, defend |

All eleven have idle, attack, hurt and fall. The party figures use a shared 15-bone hierarchy and original geometry with portrait-led proportions and kit. These are overhead-board models. They do not replace the 192 px portraits, establish named recruit likenesses, or depend on private Mixamo files. The fixed figure kit is separately toggleable for the caller's equipment work.

## Presentation contract

The reusable scenes are under art/enemies/combat-roster-3d-v1. Each faces local +Z and has a fixed floor origin in metres. The scene root stores the neutral height as visual_height metadata. The fitted surface bounds, sampled poses and hashes are in catalog.json. The meshes share one 128 px palette and the existing world-space cave grain. Counts range from 752 to 3,075 triangles per model, with at most four skinned surfaces. The role equipment is bone-bound and removable where separately authored.

Use play(pose), sample(pose, seconds), and set_motion(enabled) on the scene root. Still mode samples a fixed pose and holds the fall endpoint. set_equipment accepts RoleKit for goblin role equipment, Knife for the two models carrying the legacy knife, and Kit for hero hand equipment. Costume geometry such as the crown, guard cap, drum harness and quiver stays with the model. The drum body is bound to the torso.

Keep the existing EnemyType resources and visibility rules until the integration pass. The current CombatScreen assumes a Sprite child for some attacks, fades and tag placement. It will need model-aware dispatch, existing intent-to-pose mapping, and model height when converting a live encounter. Do not apply the Sprite-only camera lift to a grounded model. The party token should pass the actual active hero to the model picker. The review shows both a single leader and three figures sharing the party tile. The formation samples do not set gameplay positions. If the initial live version uses one figure, the party-card portraits can continue to identify the other companions.

## Validation

The Godot 4.7.2 Mobile review passed 2,185 checks and saved 310 captures. It compares the actual imported skin with Blender across five samples per clip. The maximum sampled bounds discrepancy was 2.1 cm. The checks cover floor and tile bounds, loop seams, held samples, still mode, equipment toggles and landscape phone controls. The game fixture passed 289 checks and saved 141 captures with the existing camera, darkness and visibility rules, an isolated encounter and the party-token comparison. Both fixtures used the #253 background desktop and confirmed unchanged foreground focus. The game fixture still prints the existing shutdown warning tracked in #249.

## Source and rebuild

- Great rat derives from br-n518's CC0 Rat, via the #252 master. The pinned source, licence and original archive are preserved on codex/rat-landmarks-3d.
- The five goblins derive from CDmir and TinyWorlds' CC0 Goblin via the baked #255 master. Broodmother derives from br-n518's CC0 Spider via the web-spinner master. Both pinned source originals are already included on the parent branch.
- The four party figures use newly authored meshes and motions. The committed Depths portrait previews serve as visual references. No private human mesh, downloaded character animation or third-party costume is used.
- See CREDITS.md beside the roster for the original source links.

1. Prepare the existing #252 rat and #255 spider/goblin review folders. The exact expected input files are build/local-rat-landmarks-v1/masters/rat-adapted.blend, its art/enemies/rat-3d-v1/rat.png, and build/local-spiders-goblin-v1/masters/{goblin,webspinner}.blend. The previous handoffs describe how to recreate them.
2. Run tools/combat_roster/build_roster.py through Blender 5.2 in background mode with --factory-startup --disable-autoexec --python-exit-code 1, passing -- --workspace E:/GitHub/Depths. It saves the eleven review masters and exports the GLBs, palette and catalog.
3. Run prepare_review.py with --workspace E:/GitHub/Depths. Import the standalone review and feature checkout headlessly. Use the private Windows desktop launcher from #253 for res://check.gd in the review folder and res://tools/combat_roster/live_check.gd in the checkout. Pass the absolute review/live folder after -- to the latter. Use native-check and live-check as the launcher output folders. Run the GPU fixtures sequentially.
4. Run package_review.py with the same workspace, then check_gallery.cjs with Playwright on NODE_PATH and the absolute review folder as its argument.

The delivery branch is codex/combat-roster-3d, stacked on codex/spiders-goblin-3d. Physical iPhone review and live combat integration are pending.
