# Portrait families

Start with [the classified registry](../../data/portraits/catalog.json) and [paused frame inspector](../concepts/portrait-rigs-v1/inspector.html). Do not infer compatibility from the 192px canvas or a gameplay role.

| Family | Purpose | Existing assets |
| --- | --- | --- |
| Reusable · average-covered-adult-v1 | Standard NPC/minor-character kit: one shared body/collar/outfit and nine individually fitted faces. Each face owns its eyes, mouth, expression/condition and lighting components. | recruit-kit-v1 / recruit-roster-v1 |
| Unique · Mara | Individual anatomy, neckline, tunic and underlayer variants. | mara-neutral-v1 |
| Unique · Corin | Individual bald head, neck, broad body and armour. | main-heroes-v1/corin |
| Unique · Sister Alwen | Individual face, headscarf, body and clothing. | main-heroes-v1/alwen |

The existing asset/resource paths remain stable for saves and references. `rig_kind`, `rig_family` and `face_id` identify the real grouping in each PortraitSet. Standard/reusable does **not** mean interchangeable facial animation across heads. New NPCs may reuse a validated body/socket and outfit, but need their own face-matched drawings; additional body shapes require another template. Unique hero components are not stock NPC parts.

Animated portraits now use `frames-pixel-v3/`: a clean character plate without baked eyes/lips, complete neutral components that reconstruct the original exactly, and full feature replacements for blinking/speech. The earlier v2 interior masks left old lashes and lip corners visible and are superseded. Use paused stepping, enlarged crops and **Hide eye and mouth components** to inspect the actual underlying face. See [the correction handoff](../../docs/portrait-rig-families.md).
