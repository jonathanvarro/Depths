# Portrait families

Start with [the classified registry](../../data/portraits/catalog.json) and [paused frame inspector](../concepts/portrait-rigs-v1/inspector.html). Do not infer compatibility from the 192px canvas or a gameplay role.

| Family | Purpose | Existing assets |
| --- | --- | --- |
| Reusable · average-covered-adult-v1 | Standard NPC/minor-character kit: one shared body/collar/outfit and nine individually fitted faces. Each face owns its eyes, mouth, expression/condition and lighting components. | recruit-kit-v1 / recruit-roster-v1 |
| Unique · Mara | Individual anatomy, neckline, tunic and underlayer variants. | mara-neutral-v1 |
| Unique · Corin | Individual bald head, neck, broad body and armour. | main-heroes-v1/corin |
| Unique · Sister Alwen | Individual face, headscarf, body and clothing. | main-heroes-v1/alwen |

The existing asset/resource paths remain stable for saves and references. `rig_kind`, `rig_family` and `face_id` identify the real grouping in each PortraitSet. Standard/reusable does **not** mean interchangeable facial animation across heads. New NPCs may reuse a validated body/socket and outfit, but need their own face-matched drawings; additional body shapes require another template. Unique hero components are not stock NPC parts.

Current visual problem: broad rectangular facial patches can change surrounding skin/brow/nose detail. Canvas dimensions, resource ownership and playback checks cannot establish visual fit. Use paused stepping, the unchanged reference, enlarged crops and changed-pixel overlay before approving frames. See [the correction handoff](../../docs/portrait-rig-families.md).
