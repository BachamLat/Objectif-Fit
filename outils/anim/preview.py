"""Prévisualisation des animations (même cinématique que lib/ui/exercise_anim.dart)."""
import json, math, sys
from PIL import Image, ImageDraw, ImageFont

L_UA, L_FA, L_TH, L_SH, L_FOOT = 12.0, 11.0, 15.0, 15.0, 4.5

def pt(b, L, a):
    r = math.radians(a)
    return (b[0] + L * math.cos(r), b[1] - L * math.sin(r))

def ang(f, t):
    return math.degrees(math.atan2(-(t[1] - f[1]), t[0] - f[0]))

def ik(root, target, l1, l2, bend):
    dx, dy = target[0] - root[0], target[1] - root[1]
    d = max(0.01, min(math.hypot(dx, dy), l1 + l2 - 0.05))
    base = ang(root, target)
    c = max(-1.0, min(1.0, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)))
    a1 = base + bend * math.degrees(math.acos(c))
    mid = pt(root, l1, a1)
    end_t = pt(root, d, base)
    a2 = ang(mid, end_t)
    return mid, pt(mid, l2, a2), a1, a2

def lerp_v(a, b, t):
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return a + (b - a) * t
    if isinstance(a, list) and isinstance(b, list):
        return [x + (y - x) * t for x, y in zip(a, b)]
    if isinstance(a, dict) and isinstance(b, dict) and a.get("j") == b.get("j"):
        return {"j": a["j"], "d": lerp_v(a.get("d", [0, 0]), b.get("d", [0, 0]), t)}
    return a if t < 0.5 else b

def pose_at(ex, t):
    A = ex["a"]
    B = dict(A); B.update(ex.get("b", {}))
    if ex.get("loop"):
        return dict(A)
    return {k: lerp_v(A[k], B[k], t) for k in A}

def resolve(spec, J):
    if isinstance(spec, str):
        return J[spec]
    if isinstance(spec, dict):
        b = J[spec["j"]]; d = spec.get("d", [0, 0])
        return (b[0] + d[0], b[1] + d[1])
    return (spec[0], spec[1])

def solve(ex, t):
    P = pose_at(ex, t)
    J = {}
    hip = tuple(P["hip"]); J["hip"] = hip
    tor = P["torso"]
    J["neck"] = pt(hip, 22, tor); J["shoulder"] = pt(hip, 19.5, tor); J["head"] = pt(hip, 28, tor)
    sh = J["shoulder"]
    theta = t * 360.0
    # bras proche
    if ex.get("loop") and "handCrank" in ex:
        hc = ex["handCrank"]; ph = hc.get("phase", 0)
        def hpt(th):
            r = math.radians(th)
            return (hc["c"][0] + hc["r"][0] * math.cos(r), hc["c"][1] - hc["r"][1] * math.sin(r))
        el, hd, _, _ = ik(sh, hpt(theta + ph), L_UA, L_FA, P.get("eb", -1))
        el2, hd2, _, _ = ik(sh, hpt(theta + ph + 180), L_UA, L_FA, P.get("eb", -1))
    else:
        if "handAt" in P:
            el, hd, _, _ = ik(sh, resolve(P["handAt"], J), L_UA, L_FA, P.get("eb", -1))
        elif "uaR" in P:
            el = pt(sh, L_UA, tor + P["uaR"]); hd = pt(el, L_FA, tor + P["faR"])
        else:
            el = pt(sh, L_UA, P["ua"]); hd = pt(el, L_FA, P["fa"])
        if "handAt2" in P:
            el2, hd2, _, _ = ik(sh, resolve(P["handAt2"], J), L_UA, L_FA, P.get("eb", -1))
        elif "ua2" in P:
            el2 = pt(sh, L_UA, P["ua2"]); hd2 = pt(el2, L_FA, P["fa2"])
        else:
            el2, hd2 = el, hd
    J["elbow"], J["hand"], J["elbow2"], J["hand2"] = el, hd, el2, hd2
    # jambes
    def leg(target_key, th_key, sh_key, fallback=None):
        if target_key in P:
            kn, an, _, sa = ik(hip, resolve(P[target_key], J), L_TH, L_SH, P.get("kb", 1))
            return kn, an, sa
        if th_key in P:
            kn = pt(hip, L_TH, P[th_key]); an = pt(kn, L_SH, P[sh_key]); return kn, an, P[sh_key]
        return fallback
    if ex.get("loop") and "crank" in ex:
        cr = ex["crank"]
        def cpt(th):
            r = math.radians(th)
            return (cr["c"][0] + cr["r"][0] * math.cos(r), cr["c"][1] - cr["r"][1] * math.sin(r))
        kn, an, _, sa = ik(hip, cpt(theta), L_TH, L_SH, P.get("kb", 1))
        kn2, an2, _, sa2 = ik(hip, cpt(theta + 180), L_TH, L_SH, P.get("kb", 1))
    else:
        kn, an, sa = leg("footAt", "th", "sh")
        r2 = leg("footAt2", "th2", "sh2", (kn, an, sa))
        kn2, an2, sa2 = r2
    J["knee"], J["foot"], J["knee2"], J["foot2"] = kn, an, kn2, an2
    ft = P.get("ft", sa + 90); ft2 = P.get("ft2", sa2 + 90)
    J["toe"] = pt(an, L_FOOT, ft); J["toe2"] = pt(an2, L_FOOT, ft2)
    return J

COL = {"frame": (154, 163, 178), "metal": (80, 89, 102), "pad": (46, 52, 64), "stack": (195, 201, 211),
       "cable": (120, 128, 142), "floor": (201, 207, 216)}
FIG = (36, 70, 212); FIG2 = (150, 168, 235)
S = 4  # échelle

def draw_items(d, items, J):
    for it in items:
        c = COL.get(it.get("c", "frame"), (0, 0, 0))
        if it["t"] in ("line", "pad"):
            pts = [resolve(p, J) for p in it["p"]]
            w = it.get("w", 2) * S
            col = COL["pad"] if it["t"] == "pad" else c
            d.line([(x * S, y * S) for x, y in pts], fill=col, width=int(w), joint="curve")
            for x, y in (pts[0], pts[-1]):
                d.ellipse([x * S - w / 2, y * S - w / 2, x * S + w / 2, y * S + w / 2], fill=col)
        elif it["t"] == "rect":
            x, y, w, h = it["r"]
            d.rectangle([x * S, y * S, (x + w) * S, (y + h) * S], fill=c)
            if it.get("c") == "stack":
                for k in range(1, int(h // 3)):
                    d.line([(x * S, (y + k * 3) * S), ((x + w) * S, (y + k * 3) * S)], fill=(255, 255, 255), width=2)
        elif it["t"] == "circle":
            x, y = resolve(it["p"], J); r = it["r"] * S
            if it.get("fill", True):
                d.ellipse([x * S - r, y * S - r, x * S + r, y * S + r], fill=c)
            else:
                d.ellipse([x * S - r, y * S - r, x * S + r, y * S + r], outline=c, width=int(1.6 * S))

def seg(d, a, b, w, col):
    d.line([(a[0] * S, a[1] * S), (b[0] * S, b[1] * S)], fill=col, width=int(w * S))
    for x, y in (a, b):
        r = w * S / 2
        d.ellipse([x * S - r, y * S - r, x * S + r, y * S + r], fill=col)

def render(ex, t):
    img = Image.new("RGB", (120 * S, 80 * S), "white")
    d = ImageDraw.Draw(img)
    J = solve(ex, t)
    draw_items(d, ex.get("items", []), J)
    # membres éloignés
    seg(d, J["hip"], J["knee2"], 3.4, FIG2); seg(d, J["knee2"], J["foot2"], 3.0, FIG2); seg(d, J["foot2"], J["toe2"], 2.2, FIG2)
    seg(d, J["shoulder"], J["elbow2"], 2.8, FIG2); seg(d, J["elbow2"], J["hand2"], 2.5, FIG2)
    # corps
    seg(d, J["hip"], J["neck"], 4.4, FIG)
    seg(d, J["hip"], J["knee"], 3.6, FIG); seg(d, J["knee"], J["foot"], 3.2, FIG); seg(d, J["foot"], J["toe"], 2.4, FIG)
    hx, hy = J["head"]; r = 4.6 * S
    d.ellipse([hx * S - r, hy * S - r, hx * S + r, hy * S + r], fill=FIG)
    seg(d, J["shoulder"], J["elbow"], 3.0, FIG); seg(d, J["elbow"], J["hand"], 2.7, FIG)
    draw_items(d, ex.get("front", []), J)
    return img

if __name__ == "__main__":
    data = json.load(open(sys.argv[1]))
    names = sys.argv[3:] or list(data)
    tiles = []
    for n in names:
        ex = data[n]
        ts = [0, 0.25, 0.5] if ex.get("loop") else [0, 1]
        row = [render(ex, t) for t in ts]
        w = sum(i.size[0] for i in row) + 10 * (len(row) - 1)
        tile = Image.new("RGB", (w, 80 * S + 30), (235, 238, 243))
        x = 0
        for i in row:
            tile.paste(i, (x, 30)); x += i.size[0] + 10
        ImageDraw.Draw(tile).text((6, 6), n, fill=(0, 0, 0), font=ImageFont.load_default(size=22))
        tiles.append(tile)
    cols = 2
    W = max(t.size[0] for t in tiles); H = max(t.size[1] for t in tiles)
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (W + 16), rows * (H + 16)), "white")
    for k, t in enumerate(tiles):
        sheet.paste(t, ((k % cols) * (W + 16), (k // cols) * (H + 16)))
    sheet = sheet.resize((sheet.size[0] // 2, sheet.size[1] // 2))
    sheet.save(sys.argv[2])
    print(sheet.size)
