"""Deterministic SVG button-frame studies for #269; no runtime bindings."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'art/concepts/interface/gothic-buttons-v1/assets'

def contour(side, inset=0):
    lo, hi, top, bottom = inset, 600-inset, inset, 132-inset
    bevel = 23-inset*.18
    left, right = side != 'left', side != 'right'
    pts = [(lo+bevel if left else lo, top), (hi-bevel if right else hi, top)]
    if right: pts += [(hi, top+bevel), (hi, bottom-bevel)]
    pts += [(hi-bevel if right else hi, bottom), (lo+bevel if left else lo, bottom)]
    if left: pts += [(lo, bottom-bevel), (lo, top+bevel)]
    return ' '.join(f'{x:.1f},{y:.1f}' for x,y in pts)

def frame(material, side):
    palettes = {
        'iron': ('#282b27','#151b17','#938672','#514c3f'),
        'brass': ('#332d21','#161d16','#b39a66','#6b5838'),
        'slate': ('#2a302e','#131b19','#8c9385','#4d5850'),
    }
    upper, lower, edge, inset = palettes[material]
    parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="600" height="132" viewBox="0 0 600 132"><defs><linearGradient id="face" x2="0" y2="1"><stop stop-color="{upper}"/><stop offset="1" stop-color="{lower}"/></linearGradient><clipPath id="inside"><polygon points="{contour(side,3)}"/></clipPath></defs>',
           f'<polygon points="{contour(side,1)}" fill="url(#face)" stroke="{edge}" stroke-width="2"/>',
           f'<polygon points="{contour(side,7)}" fill="none" stroke="#080e0a" stroke-width="3"/>',
           f'<polygon points="{contour(side,11)}" fill="none" stroke="{inset}" stroke-width="1.1"/>',
           '<g clip-path="url(#inside)">']
    # Fixed irregular scratches and short chips, kept away from the text.
    scratches=[(34,19,62,18),(102,9,123,10),(210,17,228,16),(381,8,401,9),(469,18,477,18),(542,115,570,114),(23,108,43,109),(312,119,326,118)]
    for x,y,x2,y2 in scratches:
        parts.append(f'<path d="M{x} {y} {x2} {y2}" fill="none" stroke="{edge}" stroke-opacity=".30" stroke-width="1.2"/>')
    if material == 'iron':
        for x,y in [(19 if side=='left' else 35,25),(565 if side!='right' else 581,105)]:
            parts.append(f'<circle cx="{x}" cy="{y}" r="2.2" fill="#777360" stroke="#0b120d" stroke-width="1.2"/>')
        parts.append('<path d="M145 4 160 5 M420 127 440 125 M11 45 11 62" fill="none" stroke="#a19377" stroke-opacity=".35"/>')
    elif material == 'brass':
        parts += [f'<path d="M266 11 285 11 300 3 315 11 334 11 M266 121 285 121 300 129 315 121 334 121" fill="none" stroke="{edge}" stroke-width="1.2"/>',
                  '<path d="M30 51 37 65 30 80 M570 51 563 65 570 80" fill="none" stroke="#8f7950" stroke-width="1.3"/>',
                  '<path d="M68 22 81 22 M454 109 463 110 M530 11 549 12" fill="none" stroke="#50634c" stroke-width="3" stroke-opacity=".65"/>']
    else:
        parts += ['<path d="M22 9 37 24 34 32 47 39 M551 125 539 111 543 105 528 95 M391 2 385 14" fill="none" stroke="#080f0e" stroke-width="2"/>',
                  '<path d="M21 11 35 25 32 33 M549 125 537 111" fill="none" stroke="#91978a" stroke-width=".7" stroke-opacity=".4"/>',
                  '<path d="M58 17 175 18 M418 115 532 114" fill="none" stroke="#929680" stroke-opacity=".18"/>']
    parts.append('</g></svg>')
    return ''.join(parts)

def main():
    DEST.mkdir(parents=True,exist_ok=True)
    for material in ['iron','brass','slate']:
        for side in ['left','centre','right']:
            (DEST/f'{material}-{side}.svg').write_text(frame(material,side),encoding='utf-8')
    print('Wrote nine authored SVG button frame studies.')

if __name__=='__main__': main()
