# Fixer source archive

Current: three unaltered built-in ImageGen masters, `prompts.json`,
`generation.json`, fitted native mattes/recipes and three editable `.ora` stacks.
`references/` contains the exact two concepts supplied by the owner on
2026-10-27. Current artwork follows their red coats and ochre waistcoats.

`superseded/` retains the first plain-template masters, their exact prompts and
generation record, an archival copy of the first export recipe and its sampled
accessory patch. These are history, not inputs to the current exporter. Do not
run the archived exporter from this folder. The earlier comparison is retained
under `art/concepts/fixer-v1/superseded/`.

Rebuild current assets with `tools/art/build_fixer_portraits.py` from the project
root. See `docs/fixer-portraits.md` for layer registration and verification.
`preserved-inputs.json` pins the 498 pre-existing portrait images/resources used
for the no-overwrite audit; it does not assign their anatomy to the new rigs.
