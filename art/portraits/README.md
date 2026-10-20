# Portrait families

Start with [the classified registry](../../data/portraits/catalog.json) and [paused frame inspector](../concepts/portrait-rigs-v1/inspector.html). Do not infer compatibility from the 192px canvas or a gameplay role.

| Family | Purpose | Existing assets |
| --- | --- | --- |
| Reusable · average-covered-adult-v1 | Standard NPC/minor-character kit: one shared body/collar/outfit and nine individually fitted faces. Each face owns its eyes, mouth, expression/condition and lighting components. | recruit-kit-v1 / recruit-roster-v1 |
| Unique · Mara | Individual anatomy, neckline, tunic and underlayer variants. | mara-neutral-v1 |
| Unique · Corin | Individual bald head, neck, broad body and armour. | main-heroes-v1/corin |
| Unique · Sister Alwen | Individual face, headscarf, body and clothing. | main-heroes-v1/alwen |

The existing asset/resource paths remain stable for saves and references. `rig_kind`, `rig_family` and `face_id` identify the real grouping in each PortraitSet. Standard/reusable does **not** mean interchangeable facial animation across heads. New NPCs may reuse a validated body/socket and outfit, but need their own face-matched drawings; additional body shapes require another template. Unique hero components are not stock NPC parts.

The active blink/talk drawings now use precise fitted pixel repairs in each face's `frames-pixel-v2/` folder. They preserve the resting face outside small lid/lip masks, replacing the former broad patch changes. Canvas dimensions, resource ownership and playback alone still cannot establish visual fit: use paused stepping, the unchanged reference, enlarged crops and changed-pixel overlay. See [the correction handoff](../../docs/portrait-rig-families.md).
