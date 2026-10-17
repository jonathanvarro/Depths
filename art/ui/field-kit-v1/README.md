# Field kit style proposal

`style.gd` creates an opt-in Godot Theme using the existing licensed fonts in `art/fonts`. It provides PageTitle, ItemTitle, SecondaryText, Emphasis, ItemRow and PrimaryAction roles, plus base Button states. See [Pack design](../../../docs/pack-screen-design.md) for sizes and interaction guidance.

The Pack preview uses this factory. It is not installed globally; adopting it for live screens is a separate implementation task. Keep body text readable, give bright action buttons a distinct focus border, and reserve paper textures for maps/documents.
