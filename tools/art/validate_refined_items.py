"""Validate item-only visual/copy changes against their recorded Git baseline."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
CATALOGUE = ROOT / "art/items/refined-v2/catalog.json"
REVIEW = ROOT / "art/concepts/items/refined-v2"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def neutral(text):
    # Exactly the owned display_name/description values and icon texture path
    # may differ. Everything else, including all omitted/default fields,
    # resource keys, ext_resource IDs and effect/use text, must match Git.
    ident = re.search(r'^icon = ExtResource\("([^"]+)"\)', text, re.M)[1]
    text = re.sub(r'^(display_name|description) = ".*"$', r'\1 = "<visual-copy>"', text, flags=re.M)
    pattern = r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="' + re.escape(ident) + r'"\])'
    return re.sub(pattern, lambda m: m[1] + "<item-texture>" + m[2], text).replace("\r\n", "\n")


def main():
    catalogue = json.loads(CATALOGUE.read_text(encoding="utf-8"))
    items = catalogue["items"]; all_assets = items + catalogue["auxiliary"]
    actual_resources = {p.relative_to(ROOT).as_posix() for folder in ["data/items", "data/gear"] for p in (ROOT / folder).glob("*.tres")}
    assert len(items) == 32 and len(all_assets) == 34
    assert {e["resource"].replace("res://", "") for e in items} == actual_resources
    assert len({e["name"] for e in items}) == 32
    assert len({e["icon"] for e in all_assets}) == 34
    rules_checked = 0; reports = []
    for entry in items:
        path = ROOT / entry["resource"].replace("res://", "")
        text = path.read_text(encoding="utf-8")
        original = subprocess.check_output(["git", "show", catalogue["baseline_commit"] + ":" + path.relative_to(ROOT).as_posix()], cwd=ROOT, text=True)
        assert neutral(text) == neutral(original), (path, "non-visual resource content changed")
        assert re.search(r'^display_name = "(.*)"$', text, re.M)[1] == entry["name"]
        assert re.search(r'^description = "(.*)"$', text, re.M)[1] == entry["description"]
        assert entry["icon"] in text
        assert entry["description"] != entry["previous_description"]
        rules_checked += len(entry["gameplay_fields"])
    for entry in all_assets:
        source = ROOT / entry["source"].replace("res://", "")
        dest = ROOT / entry["icon"].replace("res://", "")
        assert sha(source) == entry["source_sha256"], (source, "original modified")
        assert sha(dest) == entry["export_sha256"]
        assert min(Image.open(source).size) >= 627
        assert entry["direct_source_scale"] < 1
        image = Image.open(dest).convert("RGBA"); assert image.size == (128, 128)
        bounds = image.getchannel("A").getbbox()
        assert bounds and min(bounds[:2]) >= 8 and max(bounds[2:]) <= 120, (dest, bounds)
        pixels = list(image.get_flattened_data())
        assert {p[3] for p in pixels} == {0, 255}
        visible = {p[:3] for p in pixels if p[3]}
        assert len(visible) <= 64
        reports.append({"id": entry["id"], "canvas": [128, 128], "bounds": list(bounds), "colours": len(visible), "original_preserved": True})
    for name in ["library-64-40-dark.png", "library-64-40-light.png", "before-after-64.png"]:
        path = REVIEW / name
        assert path.exists(); Image.open(path).verify()
    report = {"date": "2026-10-18", "baseline_commit": catalogue["baseline_commit"], "live_resources": len(items),
              "native_icons": len(all_assets), "all_non_visual_resource_content_unchanged": True,
              "explicit_gameplay_properties_checked": rules_checked, "runtime_rgba_bytes": len(all_assets) * 128 * 128 * 4,
              "sources_unchanged": True, "source_upscales": 0, "assets": reports, "failures": []}
    (REVIEW / "asset-validation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"ITEM_REFINEMENT: {len(items)} live resources; {rules_checked} explicit gameplay fields unchanged; {len(all_assets)} native128 icons; no source edits/upscales; {report['runtime_rgba_bytes']/1048576:.3f} MiB RGBA.")


if __name__ == "__main__":
    main()
