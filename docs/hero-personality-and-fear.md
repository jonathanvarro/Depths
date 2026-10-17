# Hero personalities, fear and recruit variation

Discussion recorded 2026-10-17 for #27. The owner asked to preserve these ideas for development. They are **design proposals**, not finalized rules or authorization to implement a relationship/stat system now. No numerical bonuses, penalties, thresholds or randomization ranges are settled.

## Personality structure

The owner's starting idea is lawful, neutral and lawless groups of heroes. A paladin and bandit could have powerful synergies alongside disagreements; a neutral group might cooperate more easily but miss certain advantages.

Proposed interpretation: outlook describes a hero's attitude toward authority and rules, while personal values determine their actual reactions. It is not a good/evil axis or a complete personality.

| Component | Purpose | Examples |
| --- | --- | --- |
| Outlook | Broad approach to authority and rules | Lawful, neutral, lawless |
| Value | Something the hero admires or protects | Mercy, loyalty, freedom, ambition |
| Fault | A tendency that makes cooperation difficult | Pride, greed, suspicion, recklessness |
| Boundary | A specific action they strongly oppose | Abandoning a companion, harming captives, surrendering a relic |

A lawful hero could defend a cruel institution; a lawless hero could protect vulnerable people. Neutral heroes still have convictions. Outlook should not determine courage, kindness, trustworthiness or class automatically.

For a small first version, start with **one outlook, one value and one boundary per hero**, alongside their existing motive and vulnerability. Faults are a possible later extension rather than a required fourth system.

## Cooperation, conflict and trust

Abilities provide the tactical combinations; personalities create the difficulty of keeping the group together. Do not make mixed parties automatically strongest or neutral heroes universally weaker.

| Composition | Proposed benefit | Proposed complication |
| --- | --- | --- |
| Similar outlooks | Easier agreement, dependable group actions | Shared blind spots and fewer approaches to some situations |
| Mixed outlooks | More encounter approaches and unusual tactical combinations | More difficult choices about whose principles to respect |
| Neutral-heavy | Pragmatic cooperation, negotiation, mediation and compromise | May lack particular oath-based or outlaw-specific opportunities; neutrality should still have useful options |

**Paladin/bandit example:** the paladin holds an enemy's attention while the bandit exploits the opening. Their useful combat roles are available from the start; disagreement can arise over keeping a promise, stealing supplies or accepting surrender. They could both approve of rescuing a captive for different reasons. This illustrates cooperation, not an approved class roster, combo move or damage bonus.

Propose a simple trust level **between pairs**, built through shared experience and meaningful choices. A bandit breaking rules to save the paladin could improve their relationship without changing either outlook. Trust can support cooperation despite disagreement; it need not erase a hero's boundaries.

Prefer authored objections, requests and resolvable choices over constant random arguments or lost turns. Give warning and player response before serious refusals or loss of control. Exact trust levels, change rules, consequences and persistence after deaths/recruitment remain open.

## Fear as temporary strain

The owner raised fear alongside randomized stats. Proposed fear triggers include darkness, injury, frightening enemies and a companion falling. Preparation, reassurance and reaching safety could reduce it. Courage helps a hero cope; it does not grant immunity.

| Proposed state | Readable behaviour | Possible consequence |
| --- | --- | --- |
| Steady | Normal expression and behaviour | Acts normally |
| Shaken | Visible distress and reactions | A limited reduction in effectiveness at a specific task |
| Overwhelmed | Clear alarm or a request to retreat | Needs another hero's support or a decision to withdraw |

Avoid frequent random skipped turns. Fear should create choices such as reassuring a companion, raising the lantern or withdrawing. Costs, action timing and any combat benefits remain to be designed; these examples do not add instant combat healing or a second finalized resource system.

Keep fear a candidate part of the existing strain work (#12), rather than automatically adding separate fear and stress meters. The economy research (#25) proposes **Resolve** for resisting fear and supporting companions. If that attribute is adopted, use it for the courage role rather than introducing a duplicate Courage stat. A low-Resolve hero should still be worth recruiting and protecting.

Fear's accumulation, decay, recovery at camp, floor-transition behaviour and relationship to injuries are unresolved. Do not put fear into the existing health-only timed-effect mechanism or assume changing floors clears it. Current implementation completes pending timed effects on floor changes; a future fear model must explicitly decide how it interacts with that rule.

## Modest recruit variation

Use small variation within a class/role's strengths. Every paladin should remain able to protect the party, while individual recruits might trade toughness for courage. Show relevant strengths and weaknesses before recruitment.

The minimal proposal is **one strength, one weakness and one particular fear per recruit**, rather than randomizing every number. For example, a bandit could have quick hands, poor endurance and a fear of confinement, yet remain loyal when another companion panics. This is an illustrative recruit, not a new approved character definition.

Outlook and courage remain independent: a lawful hero can be terrified and a lawless hero brave. Keep personal fears distinct from broad outlooks and class capabilities. A particular fear should have recognizable triggers, not secretly make the hero unusable on the mandatory cave route.

If numerical randomization is later adopted, choose bounded class templates and an understandable trade-off rather than allowing arbitrary rolls to create useless recruits or a universally superior option. Exact ranges, total budgets, selection method and generation timing are open. Repeatedly rerolling the same recruit or changing stats on a floor transition is not part of this proposal.

## Fit with current work and open decisions

- Current #8 implementation starts with one wounded survivor, Mara (14/20 HP), with three total party slots; it does not begin with a randomized trio. The proposed variation applies to later recruit design unless the owner separately changes the opening.
- `Companion` currently has identity, role, motive, personality, vulnerability, portrait, health and timed effects. Health is the only implemented stat. These notes do not change resources, Mara's health, saves or gameplay.
- The five attributes and numerical party examples in [the economy research](starter-cave-economy-research.md) remain proposals. This discussion adds individuality; it does not approve those stat values or replace their role assumptions with unrestricted rolls.
- Campfire recruitment and continuation after a wipe are confirmed in [the campsite design](campsite-design.md). Recruitment prices, availability and a viable replacement-party fallback remain unresolved; personality/stat variation must be considered alongside those constraints.
- Before implementation, settle what outlook changes, the smallest set of encounter reactions, trust consequences, fear thresholds/effects, recruit variation limits and what is disclosed in recruitment UI. Validate readability and choice quality with a small authored group before expanding the system.
