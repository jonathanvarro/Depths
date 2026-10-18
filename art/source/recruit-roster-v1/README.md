# Recruit roster sources v1

Seven unmodified generated head masters and 21 animation/condition/light
atlases from built-in image_gen.imagegen. generation-manifest.json retains
exact prompts, reference paths, transparency flags and generated filenames.
Fourteen reference boards repeat an unchanged 512px master into 3x2 face
or 2x2 overlay cells; preserve them for registration.

Seven editable .ora stacks each contain 19 full-canvas layers: shared
body/jerkin, neutral head/eyes/mouth, eight facial replacements, four
conditions and two light masks. Neutral layers are initially visible;
toggle one eyes/mouth state at a time. Light masks require the controlled
strengths described in docs/recruit-roster.md.

Only top-row upper-left lighting masks are runtime exports. Bottom-row
softer studies remain source history. The exporter applies a common
184px square resize/inset, measured uniform head scale/translation and
nose/ear/chin refinement for animation, fixed
facial extraction, palette and alpha normalization. Original generated
outputs are not overwritten. Rebuild: tools/art/build_recruit_roster.py.
