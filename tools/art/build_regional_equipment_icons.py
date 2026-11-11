"""Build the first two regional icon bindings and a review of all 22 proposals."""
from pathlib import Path
import hashlib
import html
import json
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image
from build_field_kit_art import fitted

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"art/items/regional-equipment-v1"
SOURCE=ROOT/"art/source/regional-equipment-v1"
REVIEW=ROOT/"art/concepts/regional-equipment-v1"
EARLY=ROOT/"art/concepts/early-equipment-v1"
DECISIONS={
    "surveyors-shortsword":"The existing sword belongs to the founder. Keep the proposed ordinary shortsword separate.",
    "quarry-hammer":"Adopted for the actual Miner's sledge in the tool rack.",
    "shaft-spear":"The live Ash-shaft spear already has this narrow profile.",
    "miners-sling":"No corresponding live sling base.",
    "hazel-walking-staff":"No corresponding live walking-staff base.",
    "waxed-work-jerkin":"The live Patched leather jerkin already has this silhouette.",
    "quilted-work-coat":"Hold. The live description specifies sleeveless quilting.",
    "riveted-mining-coat":"No corresponding live plate-reinforced mine coat.",
    "pit-shield":"The existing Iron-rimmed buckler now has a dedicated round shield.",
    "survey-cape":"Hold. A short hooded cape differs from the live Oilcloth cloak.",
    "prospectors-satchel":"The live Leather satchel already uses this bag.",
    "notched-falchion":"The live Goblin cleaver uses this picture.",
    "gatebreaker-mace":"Keep the heavier concept. The actual Light mace receives its own narrower variant.",
    "garrison-spear":"The live Boar spear already has the related crossbar adaptation.",
    "sentry-shortbow":"No corresponding live weapon base.",
    "cinderwood-baton":"No corresponding live weapon base.",
    "raiders-leather-vest":"No exact asymmetric vest base. The studded variant is already used separately.",
    "riveted-guard-coat":"Hold. The live Studded jerkin has a dedicated sleeveless icon.",
    "garrison-scale-coat":"Hold. The live scale shirt has a shorter dedicated icon.",
    "gate-guards-shield":"Hold. The live goblin shield is round and has a dedicated icon.",
    "raiders-mantle":"The live Shadow-dyed cape uses this picture.",
    "quartermasters-pack":"The existing Miner's frame pack is already pictured and remains a Cave & Mine base.",
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def encode(path, data):
    path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")


def validate_icon(icon, size):
    assert icon.size==(size,size)
    pixels=np.asarray(icon)
    alpha=pixels[:,:,3]
    assert set(np.unique(alpha))=={0,255}
    assert not pixels[alpha==0,:3].any()
    assert len(np.unique(pixels[alpha>0,:3],axis=0))<=64
    left,top,right,bottom=icon.getchannel("A").getbbox()
    assert min(left,top,size-right,size-bottom)>=size//16


def main():
    original=json.loads((EARLY/"catalog.json").read_text(encoding="utf-8"))["items"]
    generated=json.loads((SOURCE/"generation.json").read_text(encoding="utf-8"))["assets"][0]
    assert digest(ROOT/generated["reference"])==generated["reference_sha256"]
    candidates={entry["id"]:entry for entry in original}
    hammer=candidates["quarry-hammer"]
    items=[
        {"id":"miners_sledge","name":"Miner’s sledge","region":"Cave & Mine",
         "source":hammer["source"],"source_sha256":hammer["source_sha256"],
         "old":"art/items/refined-v2/wooden-club.png","binding":"data/gear/miners_sledge.tres"},
        {"id":"light_mace","name":"Light mace","region":"Goblin Territory",
         "source":(SOURCE/generated["file"]).relative_to(ROOT).as_posix(),"source_sha256":generated["sha256"],
         "old":"art/items/story-slice-v1/companion-mace.png","binding":"data/equipment/bases.json"},
    ]
    (OUT/"compact64").mkdir(parents=True,exist_ok=True)
    REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/".gdignore").touch()
    for entry in items:
        source=ROOT/entry["source"]
        assert digest(source)==entry["source_sha256"]
        with Image.open(source) as image:
            raw=image.convert("RGBA")
        assert raw.getchannel("A").getextrema()[0]==0
        for size in (128,64):
            image,_=fitted(raw,size,64)
            validate_icon(image,size)
            path=OUT/(entry["id"]+".png") if size==128 else OUT/"compact64"/(entry["id"]+".png")
            image.save(path)
            entry["export" if size==128 else "compact"]="res://"+path.relative_to(ROOT).as_posix()
        assert entry["export"] in (ROOT/entry["binding"]).read_text(encoding="utf-8")
    assert set(DECISIONS)==set(candidates)
    for item in original:
        path=EARLY/item["candidate_icon"]
        assert digest(path)==item["icon_sha256"]
    encode(OUT/"catalog.json",{"items":items,"candidate_audit":DECISIONS})
    cards=[]
    for item in items:
        old="../../../"+item["old"]
        new="../../../"+item["export"][6:]
        compact="../../../"+item["compact"][6:]
        cards.append(f'<article><h2>{item["name"]}</h2><p>{item["region"]}</p>'
                     f'<figure><img src="{old}" width="64" height="64" alt="Previous icon"><figcaption>Previous</figcaption></figure>'
                     f'<figure><img src="{new}" width="64" height="64" alt="Updated icon"><figcaption>Updated</figcaption></figure>'
                     f'<figure><img src="{compact}" width="40" height="40" alt="Updated at 40 pixels"><figcaption>40 px</figcaption></figure></article>')
    rows=[]
    for item in original:
        name=html.escape(item["name"])
        icon="../early-equipment-v1/"+item["candidate_icon"]
        rows.append(f'<tr><td><img src="{icon}" width="40" height="40" alt=""></td><th scope="row">{name}</th>'
                    f'<td>{html.escape(DECISIONS[item["id"]])}</td></tr>')
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · Regional equipment</title>
<style>
:root{background:#151a18;color:#e2d7bf;font:16px system-ui}body{margin:auto;max-width:980px;padding:18px}h1,h2{font-family:Georgia,serif}
main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,290px),1fr));gap:12px}article,table{background:#232a25;border:1px solid #59533d}article{padding:10px 14px}
figure{display:inline-grid;justify-items:center;vertical-align:bottom;margin:8px}img{object-fit:contain;image-rendering:pixelated}figcaption,p,td{color:#c9bfaa}
table{width:100%;border-collapse:collapse}th,td{padding:7px 9px;border-top:1px solid #3e4538;text-align:left}a{color:#dabb84}
</style>
<h1>Regional equipment</h1><main>'''+''.join(cards)+'''</main>
<h2>Original proposals and current items</h2><table aria-label="Regional art review">'''+''.join(rows)+'''</table>
<p><a href="../early-equipment-v1/inspector.html">Original size and background controls</a> ·
<a href="../../../docs/regional-equipment-icons.md">Handoff and sources</a></p></html>'''
    (REVIEW/"inspector.html").write_text(page,encoding="utf-8")
    print("Two icon bindings, four output PNGs, and all 22 candidate hashes verified.")


if __name__=="__main__":
    main()
