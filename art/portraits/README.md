# Portrait families

Start with [the classified registry](../../data/portraits/catalog.json) and [paused frame inspector](../concepts/portrait-rigs-v1/inspector.html). Do not infer compatibility from the 192px canvas or a gameplay role.

| Family | Purpose | Existing assets |
| --- | --- | --- |
| Reusable · average-covered-adult-v1 | Standard NPC/minor-character kit: one shared body/collar/outfit and nine individually fitted faces. Each face owns its eyes, mouth, expression/condition and lighting components. | recruit-kit-v1 / recruit-roster-v1 |
| Unique · Mara | Individual anatomy, neckline, tunic and underlayer variants. | mara-neutral-v1 |
| Unique · Corin | Individual bald head, neck, broad body and armour. | main-heroes-v1/corin |
| Unique · Sister Alwen | Individual face, headscarf, body and clothing. | main-heroes-v1/alwen |
| Unique · Fixer A/B/C | Three concept-faithful recruit busts with their own red coats, tilted face registration and animation. Ordinary recruit roles; art rigs are individual. | fixer-v1; [handoff](../../docs/fixer-portraits.md) |

The existing asset/resource paths remain stable for saves and references. `rig_kind`, `rig_family` and `face_id` identify the real grouping in each PortraitSet. Standard/reusable does **not** mean interchangeable facial animation across heads. New NPCs may reuse a validated body/socket and outfit, but need their own face-matched drawings; additional body shapes require another template. Unique hero components are not stock NPC parts.

Animated portraits retain `frames-pixel-v3/` clean plates/neutral components and use `frames-pixel-v4/` animation (#124): original lip tissue around smaller shaded openings, softly pursed mouths and curved skin-toned lids that retain the lower iris halfway through a blink. Corin's profile, beard texture and tooth gap are preserved. Recruits honestly declare two talking shapes; the three unique heroes have three. Neutral, matte registration, timing and card filtering are unchanged. Use paused stepping, enlarged crops and **Hide eye and mouth components** to inspect the actual face. See [the current handoff](../../docs/portrait-rig-families.md).
