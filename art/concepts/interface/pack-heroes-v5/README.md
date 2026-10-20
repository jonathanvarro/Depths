# Quieter combined Field kit · #112 / #109

Open `combined-kit.html` in a browser from a full checkout. Equipment/Status stays left, shared inventory right. Click/touch pins item details; hover/focus inspects; explicit actions demonstrate equip/replacement/unequip and stack decrements. Escape closes details first. Portraits select the recipient; arrow keys switch the tabs.

This is an isolated design review, not the live Godot inventory. The three starting hero options are together for comparison only. Inventory, oil, condition and loadouts are fixtures, not starting grants or balance decisions. Use does not simulate actual healing/time; twelve compartments are not a capacity rule. Real targeting/permissions/trait bonuses, larger inventories and persistence need model binding during integration.

Build: `tools/art/build_refined_kit_study.py`. Editable `layout.html`, `base.css`, `refined.css` and `interaction.js`; current resource data is recorded in `item-data.json`/`manifest.json`. Approved v3 bag/roll and original prompts are retained. Existing native control/seal assets are reused. No new generated raster art.

`tools/art/check_refined_kit_study.cjs` checks desktop, two phone shapes and compact landscape, including overflow paging after unequipping all heroes; 129 checks/12 captures. See [handoff](../../../../docs/visual-refinement.md).
