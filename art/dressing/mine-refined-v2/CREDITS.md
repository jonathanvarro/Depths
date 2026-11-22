# Refined mine props · #278

Kay Lousberg's **KayKit Halloween Bits 1.0** (CC0 1.0) supplies the retained
lantern and candle cores. Exact original files, licence, pinned Git blobs and
SHA-256 verification remain in `art/third-party/kaykit-mine-props-v1`.
No new external files were downloaded for this pass.

`tools/mine_polish/build_models.py` builds on the project's earlier authored
mine helpers, preserving source lantern/candle registration and adding beveled
edges, cage bars, a carrying bail, vents, brackets, nail heads, hand-hewn timber,
joinery, repaired supports, a more legible carved miner, chipped masonry,
worked rock, mineral seams, rail shoes and fasteners. The older library is
retained unchanged. Physical UVs and vertex material colours replace the flat
palette-point UVs; original UVs/materials remain in the original sources.

All new surface detail is authored procedural shader code under
`art/materials/worked-props-v2`: directional grain/end grain, corrosion,
hammering, stone pores and cloth weave. There are no new generated images or
external texture licences. Editable component masters stay local under
`build/local-mine-polish-v2/masters`.
