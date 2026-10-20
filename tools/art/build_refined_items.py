"""Re-export every live item from original art; preserve every gameplay field.

No image generation or creative paint operation occurs here. Cropping, rotation
of the already-authored torch and direct-source reduction register existing art.
The catalogue records the exact source, old binding, copy and unchanged rules.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import argparse
import hashlib
import json
import re
import subprocess
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art/items/refined-v2"
REVIEW = ROOT / "art/concepts/items/refined-v2"
SIZE, CONTENT, COLOURS = 128, 112, 64

# Resource filenames remain the stable game/save identifiers. Copy describes
# what the art actually shows, rather than inventing rarity, factions or powers.
COPY = {
    "amber_pendant": ("Amber tear pendant", "Honey-coloured amber hangs in a dark silver claw setting. A short loop of chain is all that remains."),
    "amethyst": ("Rough amethyst", "Violet points still rooted in pale stone. The broken base is gritty with the old seam."),
    "copper_ore": ("Copper ore", "Green seams crust a dark, freshly broken lump. The merchant buys it for the copper beneath."),
    "dressing": ("Linen dressing", "Clean linen wound tight and tied with cord. Binds one injury until camp, removing its penalties without healing it."),
    "emerald": ("Step-cut emerald", "A deep green stone cut into broad, descending steps. One corner is chipped; the heart is clear."),
    "fine_cloth": ("Blue broadcloth", "Dense blue cloth folded under crossed pale ties. The outer fold is dusty; the cloth within is sound."),
    "garnet": ("Cut garnet", "A squat, wine-red gem with a broad face and uneven facets. Its edges are dark enough to look black."),
    "gold_nuggets": ("Gold nuggets", "Heavy yellow knots with quartz still caught in their creases. They have never passed through a mint."),
    "gold_signet_ring": ("Worn gold signet", "A thick gold band with a deep-cut branching seal. The rim is rubbed smooth where a thumb worried it."),
    "military_medal": ("Faded campaign medal", "A sunburst medal hangs from a frayed red ribbon. Raised rays surround a centre worn nearly flat."),
    "oil_flask": ("Leather oil flask", "A squat, stitched flask with a narrow metal pourer. Refills the lantern; unused oil stays in the flask."),
    "old_coin_purse": ("Old coin purse", "A puckered leather purse, its cord polished by handling. Old-minted coins knock dully together inside."),
    "pearl_necklace": ("Pearl necklace", "Uneven cream pearls strung in a loose oval. A little gilt clasp holds more securely than the thread."),
    "ration": ("Trail ration", "Hard bread, dried meat and cheese in a tied cloth. Feeds the party: each hero regains 4 health over 20 time, completed by rest or a floor change."),
    "restorative_draught": ("Restorative draught", "Dark herbal liquor in a round, cloth-bound bottle. The most hurt hero regains 10 health over 20 time, completed by rest or a floor change."),
    "silver_goblet": ("Dented silver goblet", "A wide-lipped silver cup with a buckled bowl and narrow foot. Tarnish has settled deep in its chased border."),
    "silver_ingot": ("Stamped silver ingot", "A squat cast bar with sloping sides and a small punched mark. Its rough underside still holds casting grit."),
    "silver_locket": ("Silver sprig locket", "An oval silver case worked with a small leaf sprig. The hinge is black with age and the lid holds fast."),
    "silver_trinket": ("Silver leaf brooch", "A long, veined silver leaf with a bent pin beneath. A dark crease marks where the stem was straightened."),
    "small_reliquary": ("Gilt reliquary", "A small iron-bound casket beneath worn gilding. Its pitched lid and stubborn clasp guard a relic you cannot see."),
    "spice_pouch": ("Sealed spice pouch", "A red-brown packet cinched tight under an unbroken seal. Pepper and a sweet, dry scent escape through the cloth."),
    "torch": ("Pitch-wrapped torch", "Pitch-dark cloth grips a rough wooden stave. Light it to see; throw the burning torch in a fight to drive one enemy away, losing the torch."),
    "broken_knife": ("Broken knife", "A jagged stump of iron above a two-rivet wooden grip. The missing point makes a poor weapon worse."),
    "broken_short_sword": ("Broken short sword", "A broad break ends the blade just above its plain guard. The leather grip still fits a fighting hand."),
    "cracked_staff": ("Split walking staff", "A nurse's worn staff, split with the grain above its cloth grip. Light in the hand; unreliable under a hard blow."),
    "iron_sword": ("Companion's iron sword", "A straight, carefully kept blade above a plain iron crossguard. Familiar leather fills the palm; this one was made to last."),
    "leather_jerkin": ("Patched leather jerkin", "Thick hide, front ties and crooked repairs. Reduces each blow by 2, to a minimum of 1; initiative -2."),
    "padded_coat": ("Quilted coat", "Sleeveless quilting hangs in narrow, hand-stitched channels. Reduces each blow by 1, to a minimum of 1."),
    "plain_knife": ("Riveted knife", "Two dark rivets secure a wooden grip beneath a short, rust-freckled blade. Light and easy to place, with little weight behind it."),
    "simple_spear": ("Ash-shaft spear", "A small iron leaf bound to a long ash shaft. Reaches from the back row and can strike enemies behind the front."),
    "woodcutters_axe": ("Woodcutter's axe", "A pitted iron wedge on a curved, darkened haft. A heavy working tool: hard-hitting, but difficult to land cleanly."),
    "wooden_club": ("Knotted oak club", "A swollen knot forms the head; a dark wrap marks the grip. Plain oak, balanced well enough for repeated blows."),
}

TREASURE = {
    "amber_pendant": "amber-pendant", "amethyst": "amethyst", "emerald": "emerald",
    "garnet": "garnet", "gold_signet_ring": "gold-signet-ring", "old_coin_purse": "coin-purse",
    "silver_goblet": "silver-goblet", "silver_trinket": "silver-brooch",
}
EXTRA = {
    "fine_cloth": "fine-cloth", "gold_nuggets": "gold-nuggets", "military_medal": "military-medal",
    "pearl_necklace": "pearl-necklace", "silver_ingot": "silver-ingot", "silver_locket": "silver-locket",
    "small_reliquary": "small-reliquary", "spice_pouch": "spice-pouch",
}
STARTER = {
    "dressing": "clean-dressing", "oil_flask": "oil-flask", "ration": "party-ration",
    "restorative_draught": "restorative-draught", "iron_sword": "iron-sword", "padded_coat": "padded-coat",
    "plain_knife": "plain-knife", "simple_spear": "simple-spear", "woodcutters_axe": "woodcutters-axe",
    "wooden_club": "wooden-club",
}
DESIGN = {
    "amber_pendant": "Teardrop amber and short loop; warm translucent centre distinguishes it from the opaque red/green gems.",
    "amethyst": "Upright multi-point violet cluster, pale rocky foot; the only uncut crystal cluster.",
    "copper_ore": "Low irregular rock with oxidised green/copper veins, distinct from brilliant gold knots.",
    "dressing": "Pale rolled linen and loose square end, clean treatment material rather than treasure cloth.",
    "emerald": "Rectangular emerald with broad stair-step facets; distinct from squat irregular garnet.",
    "fine_cloth": "Deep blue folded rectangle under crossed pale ties; cool colour separates it from red spice parcel.",
    "garnet": "Low irregular red gem with black-red edge and large face; no glow or magic.",
    "gold_nuggets": "Several irregular yellow knots, no minted circular outline or stamped face.",
    "gold_signet_ring": "Heavy open band and prominent round seal; angular branching engraving informs the reusable seal glyph.",
    "military_medal": "Red triangular ribbon over a round sunburst medal; this radial mark remains distinct from the branching seal.",
    "oil_flask": "Opaque stitched leather kidney shape and metal spout; no confusion with glass draught.",
    "old_coin_purse": "Upright gathered leather pouch and hanging cord, distinct from the flat sealed spice parcel.",
    "pearl_necklace": "Open oval of unequal cream beads, readable negative centre; no gem pendant.",
    "ration": "Cream tied cloth, broad loaf, meat and cheese; a compact food bundle.",
    "restorative_draught": "Round amber-red bottle with cork and pale neck wrap; unique glass silhouette among live supplies.",
    "silver_goblet": "Wide cup, narrow foot and shallow dent; a tall silver vessel rather than a jewellery outline.",
    "silver_ingot": "Low trapezoidal cast bar and small punched mark; not a fabricated royal seal.",
    "silver_locket": "Closed oval with tiny suspension ring and leaf sprig; no claim it can be opened/equipped.",
    "silver_trinket": "Long diagonal leaf, pronounced vein and pin; distinct from the compact oval locket.",
    "small_reliquary": "Pitched-lid iron-bound gilded casket; miniature closed container, sold as one valuable.",
    "spice_pouch": "Red-brown wrapped rectangle, tied neck and seal; opposite palette/shape to coin purse.",
    "torch": "Long rough stave and thick black head, full silhouette registered diagonally; body remains unlit icon.",
    "broken_knife": "Short jagged stump and two-rivet wooden handle; intact knife retains a visibly complete point.",
    "broken_short_sword": "Plain crossguard and abruptly truncated broad blade; recognisably a sword despite break.",
    "cracked_staff": "Long slim wood, central cloth grip and longitudinal split; club has a visibly swollen striking head.",
    "iron_sword": "Long straight blade, full guard and cleaner iron; quality is conveyed by construction rather than jewellery.",
    "leather_jerkin": "Large flat patched hide panels and front ties; no quilted channels of the padded coat.",
    "padded_coat": "Sleeveless rounded garment with dense parallel quilting and small front ties.",
    "plain_knife": "Wide short iron point, rusty freckles and two-rivet grip; rough useful starter craftsmanship.",
    "simple_spear": "Very long slim shaft and small leaf point; entire shaft kept inside padding for reach identity.",
    "woodcutters_axe": "Curved haft and broad single wedge head; asymmetry distinguishes it from linear weapons.",
    "wooden_club": "Broad knotted head, tapering shaft and wrapped grip; organic asymmetry with no invented spikes.",
}


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8", newline="\n")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path):
    return path.relative_to(ROOT).as_posix()


def properties(text):
    """Exported values excluding only the three deliberately revised visual fields."""
    body = text.split("[resource]", 1)[1]
    return {m[1]: m[2] for m in re.finditer(r"^([a-z_]+) = (.+)$", body, re.M)
            if m[1] not in ("display_name", "description", "icon")}


def icon_binding(text):
    ident = re.search(r'^icon = ExtResource\("([^"]+)"\)', text, re.M)[1]
    path = re.search(r'\[ext_resource type="Texture2D" path="([^"]+)" id="' + re.escape(ident) + r'"\]', text)[1]
    return ident, path


def source_spec(ident):
    if ident in TREASURE:
        return ROOT / "art/source/treasure-v1" / (TREASURE[ident] + ".png"), None, 0
    if ident in EXTRA:
        return ROOT / "art/source/treasure-extra-v1" / (EXTRA[ident] + ".png"), None, 0
    if ident in STARTER:
        return ROOT / "art/items/starter-v1" / (STARTER[ident] + ".png"), None, 0
    source, crop, rotation = {
        "broken_knife": ("opening-tutorial-v1/broken-knife", None, 0),
        "broken_short_sword": ("campaign-v1/broken-short-sword", None, 0),
        "cracked_staff": ("campaign-v1/cracked-staff", None, 0),
        "copper_ore": ("inventory-64-v1/copper-ore", None, 0),
        "leather_jerkin": ("backlog96-v1/leather-armour", [0, 0, 627, 627], 0),
        "torch": ("torch-v1/torch-generated", None, -28),
        "lantern": ("inventory-64-v1/lantern", None, 0),
        "lantern-unlit": ("inventory-64-v1/lantern-unlit", None, 0),
    }[ident]
    return ROOT / "art/source" / (source + ".png"), crop, rotation


def fitted(source, crop, rotation):
    raw = Image.open(source).convert("RGBA")
    if crop:
        raw = raw.crop(crop)
    mask = raw.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    bounds = mask.getbbox()
    assert bounds
    art = raw.crop(bounds)
    if rotation:
        art = art.rotate(rotation, resample=Image.Resampling.BICUBIC, expand=True)
    # Direct-source reduction, never enlargement of the old 64px icon. Lanczos
    # conserves narrow spear shafts and engraved jewellery during reduction.
    ratio = min(CONTENT / art.width, CONTENT / art.height)
    assert ratio < 1, (source, art.size)
    reduced = art.resize((round(art.width * ratio), round(art.height * ratio)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE))
    canvas.alpha_composite(reduced, ((SIZE - reduced.width) // 2, (SIZE - reduced.height) // 2))
    alpha = canvas.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    samples = [p[:3] for p in canvas.get_flattened_data() if p[3] >= 128]
    strip = Image.new("RGB", (len(samples), 1)); strip.putdata(samples)
    pal = strip.quantize(colors=COLOURS, dither=Image.Dither.NONE)
    canvas = canvas.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGBA")
    canvas.putalpha(alpha)
    return canvas, bounds, ratio


def font(size):
    return ImageFont.truetype(str(next((ROOT / "art/fonts/source-sans-3").glob("*.ttf"))), size)


def contact_sheets(entries):
    for name, colour, ink in [("dark", "#1b2420", "#e6dac1"), ("light", "#d6cbb4", "#262b27")]:
        board = Image.new("RGBA", (1008, ((len(entries) + 5) // 6) * 154 + 40), colour)
        draw = ImageDraw.Draw(board)
        draw.text((16, 8), "Live item library · direct-source 128 px exports shown at 64 px and 40 px", font=font(18), fill=ink)
        for index, entry in enumerate(entries):
            x, y = (index % 6) * 168, (index // 6) * 154 + 38
            image = Image.open(ROOT / entry["icon"].replace("res://", "")).convert("RGBA")
            board.alpha_composite(image.resize((64, 64), Image.Resampling.LANCZOS), (x + 16, y + 8))
            board.alpha_composite(image.resize((40, 40), Image.Resampling.LANCZOS), (x + 104, y + 20))
            words = entry["name"].split(); lines = [""]
            for word in words:
                if len(lines[-1] + " " + word) > 22:
                    lines.append(word)
                else:
                    lines[-1] = (lines[-1] + " " + word).strip()
            for row, line in enumerate(lines):
                draw.text((x + 84, y + 82 + row * 17), line, font=font(15), fill=ink, anchor="mt")
        board.convert("RGB").save(REVIEW / ("library-64-40-" + name + ".png"))
    # A labelled direct before/after export comparison, without applying
    # invented sharpening/contrast, supports judging loss of tiny details.
    board = Image.new("RGBA", (1008, ((len(entries) + 5) // 6) * 138 + 40), "#1b2420")
    draw = ImageDraw.Draw(board)
    draw.text((16, 8), "Previous 64 px export / refined source export at 64 px", font=font(18), fill="#e6dac1")
    for index, entry in enumerate(entries):
        x, y = (index % 6) * 168, (index // 6) * 138 + 38
        old = Image.open(ROOT / entry["previous_icon"].replace("res://", "")).convert("RGBA")
        new = Image.open(ROOT / entry["icon"].replace("res://", "")).convert("RGBA")
        board.alpha_composite(old.resize((64, 64), Image.Resampling.NEAREST), (x + 12, y + 8))
        board.alpha_composite(new.resize((64, 64), Image.Resampling.LANCZOS), (x + 90, y + 8))
        draw.text((x + 84, y + 84), entry["id"].replace("_", " "), font=font(12), fill="#e6dac1", anchor="mt")
    board.convert("RGB").save(REVIEW / "before-after-64.png")


def main():
    parser = argparse.ArgumentParser(); parser.add_argument("--wire", action="store_true"); args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True); REVIEW.mkdir(parents=True, exist_ok=True)
    write(REVIEW / ".gdignore", "")
    files = sorted([*(ROOT / "data/items").glob("*.tres"), *(ROOT / "data/gear").glob("*.tres")])
    assert len(files) == len(COPY) == 32
    old_catalogue_path = OUT / "catalog.json"
    prior = json.loads(old_catalogue_path.read_text()) if old_catalogue_path.exists() else {}
    previous = {e["id"]: e for e in prior.get("items", [])}
    baseline_commit = prior.get("baseline_commit") or subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    entries = []
    for path in files:
        ident = path.stem; name, description = COPY[ident]
        text = path.read_text(encoding="utf-8"); key, old_icon = icon_binding(text)
        baseline = previous.get(ident)
        original = subprocess.check_output(["git", "show", baseline_commit + ":" + relative(path)], cwd=ROOT, text=True)
        assert properties(original) == properties(text), (path, "rules differ from original resource")
        if baseline:
            rules = baseline["gameplay_fields"]
            assert rules == properties(text), (path, "gameplay fields changed since baseline")
        else:
            rules = properties(text)
        source, crop, rotation = source_spec(ident)
        image, bounds, ratio = fitted(source, crop, rotation)
        dest = OUT / (ident.replace("_", "-") + ".png"); image.save(dest)
        icon = "res://" + relative(dest)
        entry = {"id": ident, "resource": "res://" + relative(path), "name": name, "description": description,
                 "icon": icon, "previous_icon": baseline["previous_icon"] if baseline else old_icon,
                 "previous_name": re.search(r'^display_name = "(.*)"$', original, re.M)[1],
                 "previous_description": re.search(r'^description = "(.*)"$', original, re.M)[1],
                 "original_resource_sha256": hashlib.sha256(original.encode("utf-8")).hexdigest(),
                 "source": "res://" + relative(source), "source_sha256": sha(source),
                 "source_canvas": list(Image.open(source).size), "source_cell": crop,
                 "source_alpha_bounds": list(bounds), "source_rotation_degrees": rotation,
                 "direct_source_scale": ratio, "design": DESIGN[ident], "gameplay_fields": rules,
                 "export_sha256": sha(dest)}
        entries.append(entry)
        if args.wire:
            text = re.sub(r'^display_name = ".*"$', "display_name = " + json.dumps(name, ensure_ascii=False), text, flags=re.M)
            text = re.sub(r'^description = ".*"$', "description = " + json.dumps(description, ensure_ascii=False), text, flags=re.M)
            pattern = r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="' + re.escape(key) + r'"\])'
            text, count = re.subn(pattern, lambda match: match[1] + icon + match[2], text)
            assert count == 1 and properties(text) == rules
            write(path, text)
    auxiliary = []
    for ident in ["lantern", "lantern-unlit"]:
        source, crop, rotation = source_spec(ident); image, bounds, ratio = fitted(source, crop, rotation)
        dest = OUT / (ident + ".png"); image.save(dest)
        auxiliary.append({"id": ident, "icon": "res://" + relative(dest), "source": "res://" + relative(source),
                          "source_canvas": list(Image.open(source).size), "source_sha256": sha(source), "export_sha256": sha(dest),
                          "direct_source_scale": ratio, "source_alpha_bounds": list(bounds)})
    catalogue = {"version": 2, "date": "2026-10-18", "baseline_commit": baseline_commit, "canvas": [128, 128], "content_box": [112, 112],
                 "padding_minimum": 8, "colour_limit_per_icon": COLOURS, "alpha": "binary cutout",
                 "processing": "Source alpha crop, torch registration rotation only, direct Lanczos reduction, 64-colour quantisation without dither. No upscaling or paint edits.",
                 "items": entries, "auxiliary": auxiliary}
    write(old_catalogue_path, json.dumps(catalogue, indent=2, ensure_ascii=False) + "\n")
    contact_sheets(entries)
    print("32 item resources and 2 lantern exports prepared; " + ("all 32 live bindings/copy updated." if args.wire else "no live resources changed."))


if __name__ == "__main__":
    main()
