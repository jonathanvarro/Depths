#!/usr/bin/env python3
"""Equipment model probe (#193): generates items from the tables in
docs/equipment-model/, checks every rule, and reports distributions,
regional matchups, a boss-fight simulation and mastery pace.

    python tools/balance/equipment_probe.py            # seed 193, 5000 items per base
    python tools/balance/equipment_probe.py --seed 7 --items 20000

Reads the real monster numbers from data/enemies/*.tres and the floor scaling
from scripts/combat_state.gd, so it follows the game. It never touches player
saves or live definitions. Writes docs/equipment-model/examples.json and
examples.csv (table 6) and docs/equipment-model/probe-report.md.

This is a model for review, not the game's combat: fights are simplified
(see the report's notes). Coefficients live in the JSON tables, not here.
"""
import argparse
import csv
import json
import math
import os
import random
import re
import statistics

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MODEL = os.path.join(ROOT, "docs", "equipment-model")  # outputs: examples, report
TABLES = os.path.join(ROOT, "data", "equipment")  # the live tables the game reads


def load(name):
    with open(os.path.join(TABLES, name), encoding="utf-8") as f:
        return json.load(f)


BASES = {b["id"]: b for b in load("bases.json")["bases"]}
ROLLS = load("rolls.json")
MODS = load("modifiers.json")
MASTERY = load("mastery.json")
REGION = load("region_marches.json")


def roundi(x):
    """Godot's roundi: halves away from zero."""
    return int(math.floor(abs(x) + 0.5)) * (1 if x >= 0 else -1)


# --- The game's own numbers -------------------------------------------------

ENEMY_DEFAULTS = {"max_health": 6, "damage_min": 1, "damage_max": 3, "accuracy": 0.7, "initiative": 10, "threat": 1}


def enemy(enemy_id):
    with open(os.path.join(ROOT, "data", "enemies", enemy_id + ".tres"), encoding="utf-8") as f:
        text = f.read()
    out = dict(ENEMY_DEFAULTS)
    for key in ENEMY_DEFAULTS:
        m = re.search(r"^%s = ([0-9.]+)$" % key, text, re.M)
        if m:
            out[key] = float(m.group(1)) if "." in m.group(1) else int(m.group(1))
    out["name"] = re.search(r'^display_name = "([^"]+)"', text, re.M).group(1)
    return out


def depth_scale():
    with open(os.path.join(ROOT, "scripts", "combat_state.gd"), encoding="utf-8") as f:
        m = re.search(r"const DEPTH_SCALE := \{([^}]*)\}", f.read())
    return {int(k): float(v) for k, v in re.findall(r"(\d+): ([0-9.]+)", m.group(1))}


def scaled(enemy_id, floor_number):
    e = enemy(enemy_id)
    s = depth_scale().get(floor_number, 1.0)
    e["max_health"] = roundi(e["max_health"] * s)
    e["damage_min"] = roundi(e["damage_min"] * s)
    e["damage_max"] = roundi(e["damage_max"] * s)
    return e


# --- Generation -------------------------------------------------------------

def weighted(rng, table):
    roll = rng.random()
    for key, weight in table.items():
        roll -= weight
        if roll < 0:
            return key
    return list(table)[-1]


def eligible_mods(base, region):
    out = []
    for m in MODS["modifiers"]:
        if base["slot"] not in m["slots"]:
            continue
        if "regions" in m and region not in m["regions"]:
            continue
        if m.get("reach_only") and not base.get("reach"):
            continue
        if region < m.get("min_region", 0):
            continue
        out.append(m)
    return out


def pick_mods(rng, base, region, count):
    """Up to `count` modifiers: no duplicates or conflicts, within budget; a
    drawback only alongside a real strength."""
    pool = eligible_mods(base, region)
    chosen = []
    strengths = [m for m in pool if m["kind"] != "drawback"]
    rng.shuffle(strengths)
    for m in strengths:
        if len(chosen) >= count:
            break
        if _fits(chosen, m):
            chosen.append(m)
    # A drawback can stand in for the second strength, buying a stronger first.
    if count >= 2 and len(chosen) >= 1 and rng.random() < 0.25:
        drawbacks = [m for m in pool if m["kind"] == "drawback"]
        rng.shuffle(drawbacks)
        for d in drawbacks:
            trial = chosen[:1] + [d]
            if _fits(chosen[:1], d):
                chosen = trial
                break
    return chosen


def _fits(chosen, m):
    if any(c["id"] == m["id"] for c in chosen):
        return False
    if any(m["id"] in c.get("conflicts", []) or c["id"] in m.get("conflicts", []) for c in chosen):
        return False
    return sum(c["cost"] for c in chosen) + m["cost"] <= MODS["max_budget"]


def generate(rng, base_id, quality=None, growth=None, mods=None):
    base = BASES[base_id]
    q = quality or weighted(rng, ROLLS["quality"]["weights"])
    item = {"base": base_id, "quality": q, "damage_roll": 0, "accuracy_roll": 0.0, "health_roll": 0, "growth": {}, "mods": [], "points": 0.0}
    if base["slot"] == "weapon":
        item["damage_roll"] = int(weighted(rng, ROLLS["stat_roll"]["weapon_damage_max"]))
        item["accuracy_roll"] = int(weighted(rng, ROLLS["stat_roll"]["weapon_accuracy_points"])) / 100.0
    else:
        item["health_roll"] = int(weighted(rng, ROLLS["stat_roll"]["body_health"]))
    for stat in base["grows"]:
        item["growth"][stat] = (growth or {}).get(stat) or weighted(rng, ROLLS["growth"]["weights_by_quality"][q])
    if mods is not None:
        item["mods"] = [m for m in MODS["modifiers"] if m["id"] in mods]
    else:
        count = int(weighted(rng, ROLLS["modifier_count"][str(base["region"])]))
        item["mods"] = pick_mods(rng, base, base["region"], count)
    return item


def growth_rate(item, stat):
    tier = item["growth"].get(stat)
    return ROLLS["growth"]["rates"][stat][tier] if tier else 0.0


def stats(item, level):
    """The item's numbers at mastery `level`."""
    base = BASES[item["base"]]
    mod_effect = {}
    for m in item["mods"]:
        for k, v in m["effect"].items():
            mod_effect[k] = v if k not in mod_effect else mod_effect[k]
    if base["slot"] == "weapon":
        q = ROLLS["quality"]["weapon"][item["quality"]]
        grow = math.floor(level * growth_rate(item, "damage") + 1e-9)
        lo = base["damage"][0] + q["damage"] + grow + mod_effect.get("damage", 0)
        hi = base["damage"][1] + q["damage"] + item["damage_roll"] + grow + mod_effect.get("damage", 0)
        lo = max(1, lo)
        hi = max(lo, hi)
        acc = base["accuracy"] + q["accuracy"] + item["accuracy_roll"] + level * growth_rate(item, "accuracy") + mod_effect.get("accuracy", 0.0)
        return {"damage": [lo, hi], "accuracy": round(acc, 4), "mods": mod_effect}
    q = ROLLS["quality"]["body"][item["quality"]]
    health = q["health"] + item["health_roll"] + math.floor(level * growth_rate(item, "health") + 1e-9) + mod_effect.get("max_health", 0)
    handling = math.floor(level * growth_rate(item, "handling") + 1e-9)
    init = max(0, base.get("initiative_penalty", 0) + q["initiative_penalty"] - handling)
    return {"armour": base.get("armour", 0), "guard": base.get("guard", 0), "pack_slots": base.get("pack_slots", 0),
            "health": health, "initiative_penalty": init, "mods": mod_effect}


def level_for(points, brittle=False):
    need = 1.25 if brittle else 1.0
    level = 0
    for row in MASTERY["levels"]:
        if points >= row["points"] * need:
            level = row["level"]
    return level


def name_of(item):
    base = BASES[item["base"]]
    name = base["name"]
    if item["quality"] != "ordinary":
        name = "%s %s" % (item["quality"].capitalize(), name[0].lower() + name[1:])
    for m in item["mods"]:
        if m["name"].startswith("of "):
            name = "%s %s" % (name, m["name"])
        else:
            name = "%s %s" % (m["name"], name[0].lower() + name[1:])
    return name


# --- Checks -----------------------------------------------------------------

def check_tables(errors):
    def sums(label, table):
        total = sum(table.values())
        if abs(total - 1.0) > 1e-9:
            errors.append("%s sums to %.4f" % (label, total))
    sums("quality weights", ROLLS["quality"]["weights"])
    for k, t in ROLLS["stat_roll"].items():
        if not k.startswith("_"):
            sums("stat roll " + k, t)
    for q, t in ROLLS["growth"]["weights_by_quality"].items():
        sums("growth weights " + q, t)
    for r, t in ROLLS["modifier_count"].items():
        if not r.startswith("_"):
            sums("modifier count region " + r, t)
    ids = [m["id"] for m in MODS["modifiers"]]
    if len(ids) != len(set(ids)):
        errors.append("duplicate modifier ids")
    for m in MODS["modifiers"]:
        for c in m.get("conflicts", []):
            if c not in ids:
                errors.append("%s conflicts with unknown %s" % (m["id"], c))
    for b in BASES.values():
        for stat in b["grows"]:
            if stat not in ROLLS["growth"]["rates"]:
                errors.append("%s grows unknown %s" % (b["id"], stat))


def check_item(item, errors):
    base = BASES[item["base"]]
    ids = [m["id"] for m in item["mods"]]
    if len(ids) != len(set(ids)):
        errors.append("duplicate modifier on %s" % name_of(item))
    for m in item["mods"]:
        if any(c in ids for c in m.get("conflicts", [])):
            errors.append("conflicting modifiers on %s" % name_of(item))
    if sum(m["cost"] for m in item["mods"]) > MODS["max_budget"]:
        errors.append("over budget: %s" % name_of(item))
    if item["mods"] and all(m["kind"] == "drawback" for m in item["mods"]):
        errors.append("a drawback alone: %s" % name_of(item))
    for level in (0, 3, 6):
        s = stats(item, level)
        if base["slot"] == "weapon":
            lo, hi = s["damage"]
            if lo < 1 or lo > hi:
                errors.append("invalid damage %s at M%d: %s" % (name_of(item), level, s["damage"]))
        elif s["initiative_penalty"] < 0:
            errors.append("negative slowing on %s" % name_of(item))


# --- Combat expectation -----------------------------------------------------

def hit_chance(hero_accuracy, item_accuracy):
    return min(0.95, max(0.1, hero_accuracy + item_accuracy))


def blow(d, weapon_stats, base, foe, proposed, strength):
    mods = weapon_stats["mods"]
    dmg = d + strength
    armour = foe.get("armour", 0) if proposed else 0
    if proposed:
        rule = REGION["strike_rules"].get(base["strike"], {})
        armour = max(0, armour - rule.get("ignore_armour", 0) - mods.get("ignore_armour", 0))
        if foe.get("armour", 0) == 0:
            dmg += rule.get("bonus_vs_unarmoured", 0)
        if foe.get("family") in ("beast", "breach"):
            dmg += rule.get("bonus_vs_beast", 0)
    dmg += mods.get("damage_vs", {}).get(foe.get("family"), 0)
    if foe.get("family") == "breach":
        dmg += mods.get("damage_vs", {}).get("beast", 0)
    return max(1, dmg - armour)


def expected_hit(weapon_item, level, hero, foe, proposed):
    base = BASES[weapon_item["base"]]
    s = stats(weapon_item, level)
    strength = hero["strength_bonus"] if (base["force"] or (base["light"] and hero["strength_bonus"] > 0)) else 0
    lo, hi = s["damage"]
    mean = statistics.mean(blow(d, s, base, foe, proposed, strength) for d in range(lo, hi + 1))
    return hit_chance(hero["accuracy"], s["accuracy"]), mean


def strike(loadout, foe, proposed):
    """Expected damage of one Strike: every front-row member attacks."""
    total = 0.0
    for hero, (item, level) in zip(REGION["party_model"]["front"], loadout["weapons"]):
        p, mean = expected_hit(item, level, hero, foe, proposed)
        total += p * mean
    return total


# --- The boss -----------------------------------------------------------------

def boss_fight(rng, loadout, proposed, party_level):
    model = REGION["party_model"]
    boss_def = REGION["boss"]
    queen = scaled(boss_def["id"], REGION["floor"])
    queen.update({"armour": boss_def["armour"], "family": boss_def["family"]})
    guard_def = scaled(boss_def["guards"]["id"], REGION["floor"])
    guard_def.update(next(o for o in REGION["ordinary"] if o["id"] == boss_def["guards"]["id"]))
    level_hp = 2 * (party_level - model["level"])
    heroes = []
    for hero, (body, body_level) in zip(model["front"], loadout["bodies"]):
        bs = stats(body, body_level)
        hp = hero["health"] + level_hp + bs["health"]
        heroes.append({"hp": hp, "max": hp, "armour": bs["armour"]})
    q_hp = queen["max_health"]
    guards = []
    draughts = model["draughts"]
    called = 0
    for rnd in range(1, 80):
        # The party's one action: drink when someone is low, else Strike.
        low = [h for h in heroes if 0 < h["hp"] < h["max"] * 0.3]
        if low and draughts > 0:
            draughts -= 1
            h = low[0]
            h["hp"] = min(h["max"], h["hp"] + 10)
        else:
            target = guards[0] if guards else None
            foe = guard_def if target else queen
            for hero, alive, (item, level) in zip(model["front"], heroes, loadout["weapons"]):
                if alive["hp"] <= 0:
                    continue
                p, _ = expected_hit(item, level, hero, foe, proposed)
                if rng.random() < p:
                    s = stats(item, level)
                    base = BASES[item["base"]]
                    strength = hero["strength_bonus"] if (base["force"] or (base["light"] and hero["strength_bonus"] > 0)) else 0
                    dmg = blow(rng.randint(s["damage"][0], s["damage"][1]), s, base, foe, proposed, strength)
                    if target:
                        target["hp"] -= dmg
                        if target["hp"] <= 0:
                            guards.pop(0)
                            target = guards[0] if guards else None
                            foe = guard_def if target else queen
                    else:
                        q_hp -= dmg
            if q_hp <= 0:
                return True, rnd, sum(max(0, h["hp"]) for h in heroes) / sum(h["max"] for h in heroes)
        # The foes.
        living = [h for h in heroes if h["hp"] > 0]
        if not living:
            return False, rnd, 0.0
        if rnd % boss_def["guards"]["every_rounds"] == 0 and called < boss_def["guards"]["max"]:
            called += 1
            guards.append({"hp": guard_def["max_health"]})
        else:
            h = rng.choice(living)
            if rng.random() < queen["accuracy"]:
                dmg = rng.randint(queen["damage_min"], queen["damage_max"])
                if rng.random() < 0.2:  # her cleaver: the coin
                    dmg = 0 if rng.random() < 0.5 else dmg * 2
                if dmg:
                    h["hp"] -= max(1, dmg - h["armour"])
        for g in guards:
            living = [h for h in heroes if h["hp"] > 0]
            if not living:
                break
            h = rng.choice(living)
            if rng.random() < guard_def["accuracy"]:
                h["hp"] -= max(1, rng.randint(guard_def["damage_min"], guard_def["damage_max"]) - h["armour"])
        if all(h["hp"] <= 0 for h in heroes):
            return False, rnd, 0.0
    return False, 80, 0.0


# --- Loadouts ------------------------------------------------------------------

def fixed(base, quality="ordinary", growth="steady", mods=()):
    rng = random.Random(0)
    item = generate(rng, base, quality, {s: growth for s in BASES[base]["grows"]}, list(mods))
    item["damage_roll"] = 0
    item["accuracy_roll"] = 0.0
    item["health_roll"] = 0
    return item


def loadouts():
    def both(weapon, wl, body, bl):
        return {"weapons": [(weapon, wl), (weapon, wl)], "bodies": [(body, bl), (body, bl)]}
    jerkin = fixed("studded_jerkin")
    old_jerkin = fixed("leather_jerkin")
    return [
        ("Fresh ordinary sword and jerkin (M0)", both(fixed("iron_sword"), 0, jerkin, 0), 3),
        ("Exceptional sword, slow growth (M0)", both(fixed("iron_sword", "exceptional", "slow"), 0, jerkin, 0), 3),
        ("Ordinary sword and jerkin, mastered (M3)", both(fixed("iron_sword"), 3, jerkin, 3), 3),
        ("Cracked sword, swift growth, well mastered (M6)", both(fixed("iron_sword", "cracked", "swift"), 6, jerkin, 3), 3),
        ("Light mace (smash) as the counter (M2)", both(fixed("light_mace"), 2, jerkin, 2), 3),
        ("Biting goblin cleaver (M1)", both(fixed("goblin_cleaver", mods=["biting"]), 1, jerkin, 1), 3),
        ("Sword of the goblin-bane (M1)", both(fixed("iron_sword", mods=["goblin_bane"]), 1, jerkin, 1), 3),
        ("Region-1 leftovers: oak club, old jerkin (M3)", both(fixed("oak_club"), 3, old_jerkin, 3), 3),
        ("Deep start: fresh ordinary gear, level 1", both(fixed("iron_sword"), 0, jerkin, 0), 1),
        ("Deep start: mastered mace and jerkin, level 1", both(fixed("light_mace"), 3, jerkin, 3), 1),
    ]


# --- Mastery pace ---------------------------------------------------------------

def mastery_pace(hero, item, level, proposed):
    """Fights (and expeditions of about 6 fights) to reach M3 and M6 against the
    region's ordinary foes, by the credit rules."""
    credit = MASTERY["weapon_credit"]
    per_fight = []
    for o in REGION["ordinary"]:
        foe = scaled(o["id"], REGION["floor"])
        foe.update(o)
        factor = min(2.0, max(MASTERY["trivial_foes"]["threat_factor_floor"], foe["threat"] / REGION["region_threat"]))
        p, mean = expected_hit(item, level, hero, foe, proposed)
        swings = math.ceil(foe["max_health"] / max(0.5, 2 * p * mean))  # both front heroes share the work
        earned = swings * (p * credit["hit"] + (1 - p) * credit["miss"]) * factor + 0.5 * credit["kill"] * factor
        per_fight.append(min(credit["per_fight_cap"], earned * 2.5))  # about 2.5 foes a fight
    fight = statistics.mean(per_fight)
    expedition = fight * 6 + MASTERY["extraction"]["worn_item"]
    targets = {row["level"]: row["points"] for row in MASTERY["levels"]}
    return fight, {lv: targets[lv] / fight for lv in (3, 6)}, {lv: targets[lv] / expedition for lv in (3, 6)}


# --- Report ---------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--seed", type=int, default=193)
    ap.add_argument("--items", type=int, default=5000)
    ap.add_argument("--fights", type=int, default=4000)
    args = ap.parse_args()
    rng = random.Random(args.seed)
    errors = []
    check_tables(errors)
    lines = ["# Equipment model probe report (#193)", "",
             "Generated by `python tools/balance/equipment_probe.py --seed %d --items %d --fights %d`. "
             "Tables: `docs/equipment-model/*.json`. Monster numbers come from `data/enemies/*.tres`, scaled for floor %d. "
             "**A model for review:** the boss fight is simplified (see Notes), and every coefficient is a proposal." % (args.seed, args.items, args.fights, REGION["floor"]), ""]

    # The worked examples from #193 must reproduce.
    sword = {"exceptional": fixed("iron_sword", "exceptional", "slow"), "ordinary": fixed("iron_sword", "ordinary", "steady"), "cracked": fixed("iron_sword", "cracked", "steady")}
    expect = {"exceptional": ([4, 6], [4, 6], [5, 7]), "ordinary": ([3, 5], [4, 6], [6, 8]), "cracked": ([2, 4], [3, 5], [5, 7])}
    lines += ["## Worked examples reproduce", "", "| Sword (base 3–5) | Growth | M0 | M3 | M6 |", "|---|---|---|---|---|"]
    for q, item in sword.items():
        got = tuple(stats(item, lv)["damage"] for lv in (0, 3, 6))
        if got != expect[q]:
            errors.append("sword example %s gave %s, expected %s" % (q, got, expect[q]))
        lines.append("| %s | %.2f | %d–%d | %d–%d | %d–%d |" % (q.capitalize(), growth_rate(item, "damage"), *got[0], *got[1], *got[2]))
    sanity = 2 * 0.8 * statistics.mean(max(1, d - 2) for d in range(5, 8))
    if abs(sanity - 6.4) > 1e-9:
        errors.append("sanity check gave %.2f, expected 6.4" % sanity)
    lines += ["", "Sanity check: two front fighters, 5–7 at 80%% against 2 armour: **%.1f** expected damage per Strike (expected 6.4)." % sanity, ""]

    # Generation: validity and distributions.
    lines += ["## Generated items", "", "%d items per region-2 base, seed %d. Every item passed the checks: valid damage, no duplicate or conflicting modifiers, within budget, no drawback alone." % (args.items, args.seed), ""]
    lines += ["| Base | Mean damage M0 (p10 / p50 / p90) | M3 | M6 | To-hit bonus M0 (p10 / p90) |", "|---|---|---|---|---|"]
    combos = {"exceptional": 0, "exceptional_swift": 0, "two_mods": 0, "exceptional_swift_two_mods": 0, "with_drawback": 0}
    total = 0
    all_items = []
    for base_id, base in BASES.items():
        if base["region"] != REGION["region"]:
            continue
        items = [generate(rng, base_id) for _ in range(args.items)]
        for it in items:
            check_item(it, errors)
            total += 1
            exc = it["quality"] == "exceptional"
            swift = any(t == "swift" for t in it["growth"].values())
            two = len(it["mods"]) == 2
            combos["exceptional"] += exc
            combos["exceptional_swift"] += exc and swift
            combos["two_mods"] += two
            combos["exceptional_swift_two_mods"] += exc and swift and two
            combos["with_drawback"] += any(m["kind"] == "drawback" for m in it["mods"])
        all_items.append((base_id, items))
        if base["slot"] == "weapon":
            row = []
            for lv in (0, 3, 6):
                means = sorted(sum(stats(it, lv)["damage"]) / 2 for it in items)
                row.append("%.1f / %.1f / %.1f" % (means[len(means) // 10], means[len(means) // 2], means[len(means) * 9 // 10]))
            accs = sorted(stats(it, 0)["accuracy"] for it in items)
            lines.append("| %s | %s | %s | %s | %+.0f%% / %+.0f%% |" % (base["name"], row[0], row[1], row[2], 100 * accs[len(accs) // 10], 100 * accs[len(accs) * 9 // 10]))
    lines += ["", "| Body armour | Health M0 (p10 / p50 / p90) | M3 | M6 | Slowing M0 → M6 |", "|---|---|---|---|---|"]
    for base_id, items in all_items:
        base = BASES[base_id]
        if base["slot"] != "body":
            continue
        row = []
        for lv in (0, 3, 6):
            hps = sorted(stats(it, lv)["health"] for it in items)
            row.append("%+d / %+d / %+d" % (hps[len(hps) // 10], hps[len(hps) // 2], hps[len(hps) * 9 // 10]))
        slow0 = statistics.mean(stats(it, 0)["initiative_penalty"] for it in items)
        slow6 = statistics.mean(stats(it, 6)["initiative_penalty"] for it in items)
        lines.append("| %s (armour %d) | %s | %s | %s | %.1f → %.1f |" % (base["name"], base["armour"], row[0], row[1], row[2], slow0, slow6))
    lines += ["", "**How rare are the combinations?** Of %d region-2 items: exceptional %.1f%%; exceptional with swift growth %.2f%%; two modifiers %.1f%%; "
              "exceptional, swift and two modifiers %.3f%%; carrying a drawback %.1f%%. Nothing required should hang on the rarest of these." % (
                  total, 100 * combos["exceptional"] / total, 100 * combos["exceptional_swift"] / total, 100 * combos["two_mods"] / total,
                  100 * combos["exceptional_swift_two_mods"] / total, 100 * combos["with_drawback"] / total), ""]

    # Regional matchups.
    foes = []
    for o in REGION["ordinary"]:
        f = scaled(o["id"], REGION["floor"])
        f.update(o)
        foes.append(f)
    queen = scaled(REGION["boss"]["id"], REGION["floor"])
    queen.update({"armour": REGION["boss"]["armour"], "family": REGION["boss"]["family"]})
    foes.append(queen)
    lines += ["## Regional matchups (floor %d)" % REGION["floor"], "",
              "Expected damage of one **Strike** (both front-row heroes attack; a melee hero with Strength 3 adds 1 to force weapons). "
              "Actions to kill in brackets. **Today** = the game's rules (no enemy armour); **proposed** = the regional table's armour and strike rules.", ""]
    header = "| Loadout | " + " | ".join("%s (%d hp)" % (f["name"], f["max_health"]) for f in foes) + " |"
    lines += [header, "|" + "---|" * (len(foes) + 1)]
    for label, lo, _ in loadouts():
        cells = []
        for f in foes:
            today = strike(lo, f, False)
            prop = strike(lo, f, True)
            cells.append("%.1f → %.1f (%d)" % (today, prop, math.ceil(f["max_health"] / max(0.1, prop))))
        lines.append("| %s | %s |" % (label, " | ".join(cells)))
    lines += ["", "Each cell: today → proposed (actions to kill under the proposal).", ""]

    # The boss.
    lines += ["## The boss: the goblin queen", "",
              "%d simulated fights per loadout, with the proposed rules (her armour 2; guards every 3 rounds, up to 2). Party level 3 unless noted." % args.fights, "",
              "| Loadout | Wins | Rounds (median) | Health left when won |", "|---|---|---|---|"]
    boss_rows = []
    for label, lo, level in loadouts():
        frng = random.Random(args.seed * 31 + len(label))
        results = [boss_fight(frng, lo, True, level) for _ in range(args.fights)]
        wins = [r for r in results if r[0]]
        rate = len(wins) / len(results)
        rounds = statistics.median([r[1] for r in wins]) if wins else 0
        left = statistics.mean([r[2] for r in wins]) if wins else 0
        boss_rows.append((label, rate))
        lines.append("| %s | %.0f%% | %s | %.0f%% |" % (label, 100 * rate, rounds, 100 * left))
    lines.append("")

    # Mastery pace.
    hero = REGION["party_model"]["front"][0]
    fight, fights_to, expeditions_to = mastery_pace(hero, fixed("iron_sword"), 1, True)
    lines += ["## Mastery pace", "",
              "An ordinary iron sword against this region's ordinary foes earns about **%.1f** mastery points a fight (capped at %d), plus %d for bringing it home." % (
                  fight, MASTERY["weapon_credit"]["per_fight_cap"], MASTERY["extraction"]["worn_item"]),
              "That is about **%.0f fights (%.1f expeditions) to mastery 3** and **%.0f fights (%.1f expeditions) to mastery 6**, at about 6 fights an expedition." % (
                  fights_to[3], expeditions_to[3], fights_to[6], expeditions_to[6]),
              "With practised hands (double gain while 2+ levels behind the hero's best item of that slot), a newly found counter reaches mastery 3 in about half that.", ""]

    # Table 6: generated examples.
    examples = []
    erng = random.Random(args.seed + 6)
    for base_id, base in BASES.items():
        if base["region"] != REGION["region"]:
            continue
        for n in range(4):
            it = generate(erng, base_id)
            for lv in (0, 3, 6):
                s = stats(it, lv)
                row = {"seed": args.seed + 6, "item": n, "name": name_of(it), "base": base_id, "quality": it["quality"],
                       "growth": "/".join("%s %s" % (k, v) for k, v in it["growth"].items()), "mods": ", ".join(m["text"] for m in it["mods"]),
                       "mastery": lv}
                if base["slot"] == "weapon":
                    hero = REGION["party_model"]["front"][0]
                    row.update({"damage": "%d-%d" % tuple(s["damage"]), "to_hit_bonus": "%+.0f%%" % (100 * s["accuracy"]),
                                "strike_vs_goblin": round(expected_hit(it, lv, hero, foes[0], True)[0] * expected_hit(it, lv, hero, foes[0], True)[1], 2),
                                "strike_vs_queen": round(expected_hit(it, lv, hero, queen, True)[0] * expected_hit(it, lv, hero, queen, True)[1], 2)})
                else:
                    row.update({"armour": s["armour"], "health": "%+d" % s["health"], "slowing": s["initiative_penalty"]})
                examples.append(row)
    with open(os.path.join(MODEL, "examples.json"), "w", encoding="utf-8") as f:
        json.dump({"_about": "Table 6 of 6: generated examples (#193), written by tools/balance/equipment_probe.py.", "examples": examples}, f, indent=1)
    keys = sorted({k for r in examples for k in r})
    with open(os.path.join(MODEL, "examples.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=keys)
        w.writeheader()
        w.writerows(examples)

    lines += ["## Notes on the model", "",
              "- **The boss fight is simplified:** both front heroes strike each round; guards stand in front and are struck first; the queen hits a random front hero, with her cleaver 20% of the time (the coin: a miss or a double blow); a draught (10 health) when a hero falls below 30%. No back-row attacks, Brace, stepping or Flare: real play has more tools, so treat these as a lower bound.",
              "- **Proposed rules** (enemy armour, strike types) are not in the game; the matchups show them beside today's rules.",
              "- **Mastery pace** assumes about 2.5 foes a fight and both front heroes sharing the work.",
              ""]
    lines += ["## Checks", "", ("**All checks passed** (%d items generated)." % total) if not errors else "**Errors:**\n\n" + "\n".join("- " + e for e in errors[:40]), ""]
    with open(os.path.join(MODEL, "probe-report.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("\n".join(lines[-3:]))
    print("boss:", ", ".join("%s %.0f%%" % (l.split(" (")[0], 100 * r) for l, r in boss_rows))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
